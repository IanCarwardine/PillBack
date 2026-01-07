// HistoryService.swift
// Service for managing adherence history with SwiftData

import Foundation
import SwiftData

/// Service for saving and querying dose history using SwiftData
@MainActor
class HistoryService: ObservableObject {

    // MARK: - Properties

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Record Management

    /// Save a dose as an adherence record
    /// - Parameters:
    ///   - dose: The dose to save
    ///   - medications: All medications (to extract names for the dose's port)
    ///   - source: How the dose was recorded
    func saveRecord(from dose: Dose, medications: [Medication], source: RecordSource = .manual) {
        let record = AdherenceRecord(from: dose, medications: medications, source: source)
        modelContext.insert(record)

        // Update or create daily history
        updateDailyHistory(for: dose.scheduledTime)

        do {
            try modelContext.save()
        } catch {
            print("HistoryService: Failed to save record - \(error)")
        }
    }

    /// Save multiple doses as adherence records
    func saveRecords(from doses: [Dose], medications: [Medication], source: RecordSource = .manual) {
        for dose in doses where dose.status != .pending {
            let record = AdherenceRecord(from: dose, medications: medications, source: source)
            modelContext.insert(record)
        }

        // Update daily histories for affected dates
        let uniqueDates = Set(doses.map { Calendar.current.startOfDay(for: $0.scheduledTime) })
        for date in uniqueDates {
            updateDailyHistory(for: date)
        }

        do {
            try modelContext.save()
        } catch {
            print("HistoryService: Failed to save records - \(error)")
        }
    }

    /// Update an existing record
    func updateRecord(_ record: AdherenceRecord) {
        do {
            try modelContext.save()
            updateDailyHistory(for: record.scheduledTime)
        } catch {
            print("HistoryService: Failed to update record - \(error)")
        }
    }

    /// Delete a record
    func deleteRecord(_ record: AdherenceRecord) {
        let date = record.scheduledTime
        modelContext.delete(record)

        do {
            try modelContext.save()
            updateDailyHistory(for: date)
        } catch {
            print("HistoryService: Failed to delete record - \(error)")
        }
    }

    // MARK: - Daily History Management

    /// Update or create daily history for a given date
    private func updateDailyHistory(for date: Date) {
        let dateKey = Calendar.current.startOfDay(for: date)

        // Fetch existing history for this date
        let descriptor = FetchDescriptor<DoseHistory>(
            predicate: DoseHistory.forDate(dateKey)
        )

        do {
            let existing = try modelContext.fetch(descriptor)
            let history: DoseHistory

            if let existingHistory = existing.first {
                history = existingHistory
            } else {
                history = DoseHistory(date: dateKey)
                modelContext.insert(history)
            }

            // Fetch all records for this date
            let recordsDescriptor = FetchDescriptor<AdherenceRecord>(
                predicate: AdherenceRecord.forDate(dateKey)
            )
            let records = try modelContext.fetch(recordsDescriptor)

            // Update history from records
            history.updateFromRecords(records)

            try modelContext.save()
        } catch {
            print("HistoryService: Failed to update daily history - \(error)")
        }
    }

    // MARK: - Queries: Records

    /// Fetch all records for a specific date
    func fetchRecords(for date: Date) -> [AdherenceRecord] {
        let descriptor = FetchDescriptor<AdherenceRecord>(
            predicate: AdherenceRecord.forDate(date),
            sortBy: [SortDescriptor(\.scheduledTime)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("HistoryService: Failed to fetch records - \(error)")
            return []
        }
    }

    /// Fetch records for a date range
    func fetchRecords(from startDate: Date, to endDate: Date) -> [AdherenceRecord] {
        let descriptor = FetchDescriptor<AdherenceRecord>(
            predicate: AdherenceRecord.inRange(from: startDate, to: endDate),
            sortBy: [SortDescriptor(\.scheduledTime)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("HistoryService: Failed to fetch records in range - \(error)")
            return []
        }
    }

    /// Fetch all records for a specific port
    func fetchRecords(forPort portNumber: Int) -> [AdherenceRecord] {
        let descriptor = FetchDescriptor<AdherenceRecord>(
            predicate: AdherenceRecord.forPort(portNumber),
            sortBy: [SortDescriptor(\.scheduledTime, order: .reverse)]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("HistoryService: Failed to fetch records for port - \(error)")
            return []
        }
    }

    // MARK: - Queries: History

    /// Fetch history for a specific date
    func fetchHistory(for date: Date) -> DoseHistory? {
        let descriptor = FetchDescriptor<DoseHistory>(
            predicate: DoseHistory.forDate(date)
        )

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("HistoryService: Failed to fetch history - \(error)")
            return nil
        }
    }

    /// Fetch history for a date range
    func fetchHistory(from startDate: Date, to endDate: Date) -> [DoseHistory] {
        let descriptor = FetchDescriptor<DoseHistory>(
            predicate: DoseHistory.inRange(from: startDate, to: endDate),
            sortBy: [DoseHistory.newestFirst]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("HistoryService: Failed to fetch history in range - \(error)")
            return []
        }
    }

    /// Fetch history for last N days
    func fetchHistory(lastDays count: Int) -> [DoseHistory] {
        let descriptor = FetchDescriptor<DoseHistory>(
            predicate: DoseHistory.lastDays(count),
            sortBy: [DoseHistory.newestFirst]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("HistoryService: Failed to fetch last days history - \(error)")
            return []
        }
    }

    /// Fetch all perfect days
    func fetchPerfectDays() -> [DoseHistory] {
        let descriptor = FetchDescriptor<DoseHistory>(
            predicate: DoseHistory.perfectDaysOnly,
            sortBy: [DoseHistory.newestFirst]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("HistoryService: Failed to fetch perfect days - \(error)")
            return []
        }
    }

    // MARK: - Statistics

    /// Calculate adherence statistics for a date range
    func calculateStatistics(from startDate: Date, to endDate: Date) -> HistoryStatistics {
        let histories = fetchHistory(from: startDate, to: endDate)

        guard !histories.isEmpty else {
            return HistoryStatistics()
        }

        let totalDoses = histories.reduce(0) { $0 + $1.totalDoses }
        let dosesTaken = histories.reduce(0) { $0 + $1.dosesTaken }
        let dosesMissed = histories.reduce(0) { $0 + $1.dosesMissed }
        let perfectDays = histories.filter { $0.isPerfectDay }.count

        let adherenceRate = totalDoses > 0
            ? Double(dosesTaken) / Double(totalDoses) * 100
            : 0

        let accuracies = histories.filter { $0.dosesTaken > 0 }.map { $0.averageTimingAccuracy }
        let avgTimingAccuracy = accuracies.isEmpty
            ? 0
            : accuracies.reduce(0, +) / Double(accuracies.count)

        return HistoryStatistics(
            totalDays: histories.count,
            totalDoses: totalDoses,
            dosesTaken: dosesTaken,
            dosesMissed: dosesMissed,
            perfectDays: perfectDays,
            adherenceRate: adherenceRate,
            averageTimingAccuracy: avgTimingAccuracy
        )
    }

    /// Calculate current streak
    func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        var streak = 0

        while true {
            guard let history = fetchHistory(for: currentDate) else {
                break
            }

            if history.isPerfectDay {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
                currentDate = previousDay
            } else {
                break
            }
        }

        return streak
    }

    /// Get longest streak
    func calculateLongestStreak() -> Int {
        let histories = fetchAllHistory()

        guard !histories.isEmpty else { return 0 }

        // Sort by date ascending
        let sorted = histories.sorted { $0.date < $1.date }

        var longestStreak = 0
        var currentStreak = 0
        var previousDate: Date?

        let calendar = Calendar.current

        for history in sorted {
            if history.isPerfectDay {
                if let prev = previousDate {
                    let daysBetween = calendar.dateComponents([.day], from: prev, to: history.date).day ?? 0
                    if daysBetween == 1 {
                        currentStreak += 1
                    } else {
                        currentStreak = 1
                    }
                } else {
                    currentStreak = 1
                }

                longestStreak = max(longestStreak, currentStreak)
                previousDate = history.date
            } else {
                currentStreak = 0
                previousDate = history.date
            }
        }

        return longestStreak
    }

    /// Fetch all history (use sparingly)
    private func fetchAllHistory() -> [DoseHistory] {
        let descriptor = FetchDescriptor<DoseHistory>(
            sortBy: [DoseHistory.oldestFirst]
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("HistoryService: Failed to fetch all history - \(error)")
            return []
        }
    }

    // MARK: - Data Management

    /// Delete all history data (for testing/reset)
    func deleteAllData() {
        do {
            try modelContext.delete(model: AdherenceRecord.self)
            try modelContext.delete(model: DoseHistory.self)
            try modelContext.save()
        } catch {
            print("HistoryService: Failed to delete all data - \(error)")
        }
    }

    /// Get total record count
    func getRecordCount() -> Int {
        let descriptor = FetchDescriptor<AdherenceRecord>()

        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("HistoryService: Failed to count records - \(error)")
            return 0
        }
    }

    /// Get total history day count
    func getHistoryDayCount() -> Int {
        let descriptor = FetchDescriptor<DoseHistory>()

        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("HistoryService: Failed to count history days - \(error)")
            return 0
        }
    }
}

// MARK: - Statistics Structure

struct HistoryStatistics {
    var totalDays: Int = 0
    var totalDoses: Int = 0
    var dosesTaken: Int = 0
    var dosesMissed: Int = 0
    var perfectDays: Int = 0
    var adherenceRate: Double = 0
    var averageTimingAccuracy: Double = 0

    var adherenceRateText: String {
        String(format: "%.0f%%", adherenceRate)
    }

    var timingAccuracyText: String {
        String(format: "%.0f%%", averageTimingAccuracy * 100)
    }

    var perfectDayRate: Double {
        totalDays > 0 ? Double(perfectDays) / Double(totalDays) * 100 : 0
    }

    var perfectDayRateText: String {
        String(format: "%.0f%%", perfectDayRate)
    }
}
