// HistoryServiceTests.swift
// Unit tests for HistoryService

import XCTest
import SwiftData
@testable import PillBack

@MainActor
final class HistoryServiceTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var historyService: HistoryService!

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([AdherenceRecord.self, DoseHistory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)

        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
        historyService = HistoryService(modelContext: modelContext)
    }

    override func tearDown() async throws {
        historyService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }

    // MARK: - Save Record Tests

    func testSaveRecord() {
        let dose = createTestDose(portNumber: 1, status: .taken)
        let medications = [Medication(id: 1, name: "Test Med", frequency: 1, ports: "1")]

        historyService.saveRecord(from: dose, medications: medications, source: .manual)

        let records = historyService.fetchRecords(for: Date())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.portNumber, 1)
        XCTAssertEqual(records.first?.status, "taken")
    }

    func testSaveMultipleRecords() {
        let doses = [
            createTestDose(portNumber: 1, status: .taken),
            createTestDose(portNumber: 2, status: .taken),
            createTestDose(portNumber: 3, status: .missed)
        ]
        let medications: [Medication] = []

        historyService.saveRecords(from: doses, medications: medications, source: .manual)

        let records = historyService.fetchRecords(for: Date())
        XCTAssertEqual(records.count, 3)
    }

    func testSaveRecordSkipsPending() {
        let doses = [
            createTestDose(portNumber: 1, status: .taken),
            createTestDose(portNumber: 2, status: .pending)  // Should not be saved
        ]

        historyService.saveRecords(from: doses, medications: [], source: .manual)

        let records = historyService.fetchRecords(for: Date())
        XCTAssertEqual(records.count, 1)
    }

    // MARK: - Fetch Records Tests

    func testFetchRecordsForDate() {
        // Create records for today
        for i in 1...3 {
            let record = AdherenceRecord(portNumber: i, scheduledTime: Date(), status: "taken")
            modelContext.insert(record)
        }

        // Create record for yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let oldRecord = AdherenceRecord(portNumber: 1, scheduledTime: yesterday, status: "taken")
        modelContext.insert(oldRecord)

        try? modelContext.save()

        let todayRecords = historyService.fetchRecords(for: Date())
        XCTAssertEqual(todayRecords.count, 3)

        let yesterdayRecords = historyService.fetchRecords(for: yesterday)
        XCTAssertEqual(yesterdayRecords.count, 1)
    }

    func testFetchRecordsInRange() {
        let calendar = Calendar.current

        // Create records for last 5 days
        for day in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let record = AdherenceRecord(portNumber: 1, scheduledTime: date, status: "taken")
            modelContext.insert(record)
        }

        try? modelContext.save()

        let startDate = calendar.date(byAdding: .day, value: -2, to: Date())!
        let records = historyService.fetchRecords(from: startDate, to: Date())

        XCTAssertEqual(records.count, 3)  // Today, yesterday, 2 days ago
    }

    func testFetchRecordsForPort() {
        let record1 = AdherenceRecord(portNumber: 1, scheduledTime: Date(), status: "taken")
        let record2 = AdherenceRecord(portNumber: 1, scheduledTime: Date(), status: "taken")
        let record3 = AdherenceRecord(portNumber: 2, scheduledTime: Date(), status: "taken")

        modelContext.insert(record1)
        modelContext.insert(record2)
        modelContext.insert(record3)
        try? modelContext.save()

        let port1Records = historyService.fetchRecords(forPort: 1)
        XCTAssertEqual(port1Records.count, 2)

        let port2Records = historyService.fetchRecords(forPort: 2)
        XCTAssertEqual(port2Records.count, 1)
    }

    // MARK: - Fetch History Tests

    func testFetchHistoryForDate() {
        let history = DoseHistory(date: Date(), totalDoses: 4, dosesTaken: 3)
        modelContext.insert(history)
        try? modelContext.save()

        let fetched = historyService.fetchHistory(for: Date())
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.totalDoses, 4)
        XCTAssertEqual(fetched?.dosesTaken, 3)
    }

    func testFetchHistoryLastDays() {
        let calendar = Calendar.current

        // Create history for last 7 days
        for day in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let history = DoseHistory(date: date, totalDoses: 4, dosesTaken: 4 - (day % 2))
            modelContext.insert(history)
        }

        try? modelContext.save()

        let last3Days = historyService.fetchHistory(lastDays: 3)
        XCTAssertEqual(last3Days.count, 3)

        let last7Days = historyService.fetchHistory(lastDays: 7)
        XCTAssertEqual(last7Days.count, 7)
    }

    func testFetchPerfectDays() {
        let calendar = Calendar.current

        // Create mix of perfect and non-perfect days
        for day in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let isPerfect = day % 2 == 0  // Days 0, 2, 4 are perfect
            let history = DoseHistory(
                date: date,
                totalDoses: 4,
                dosesTaken: isPerfect ? 4 : 2,
                isPerfectDay: isPerfect
            )
            modelContext.insert(history)
        }

        try? modelContext.save()

        let perfectDays = historyService.fetchPerfectDays()
        XCTAssertEqual(perfectDays.count, 3)
    }

    // MARK: - Statistics Tests

    func testCalculateStatistics() {
        let calendar = Calendar.current

        // Create history for last 5 days
        for day in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let history = DoseHistory(
                date: date,
                totalDoses: 4,
                dosesTaken: 3,
                dosesMissed: 1,
                adherenceScore: 75,
                averageTimingAccuracy: 0.90,
                isPerfectDay: false
            )
            modelContext.insert(history)
        }

        try? modelContext.save()

        let startDate = calendar.date(byAdding: .day, value: -4, to: Date())!
        let stats = historyService.calculateStatistics(from: startDate, to: Date())

        XCTAssertEqual(stats.totalDays, 5)
        XCTAssertEqual(stats.totalDoses, 20)
        XCTAssertEqual(stats.dosesTaken, 15)
        XCTAssertEqual(stats.dosesMissed, 5)
        XCTAssertEqual(stats.adherenceRate, 75, accuracy: 0.1)
    }

    func testCalculateCurrentStreak() {
        let calendar = Calendar.current

        // Create 3 consecutive perfect days
        for day in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let history = DoseHistory(date: date, isPerfectDay: true)
            modelContext.insert(history)
        }

        // Add a non-perfect day before the streak
        let breakDay = calendar.date(byAdding: .day, value: -3, to: Date())!
        let breakHistory = DoseHistory(date: breakDay, isPerfectDay: false)
        modelContext.insert(breakHistory)

        try? modelContext.save()

        let streak = historyService.calculateCurrentStreak()
        XCTAssertEqual(streak, 3)
    }

    func testCalculateLongestStreak() {
        let calendar = Calendar.current

        // Create a streak of 5 perfect days, a break, then 3 perfect days
        for day in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let history = DoseHistory(date: date, isPerfectDay: true)
            modelContext.insert(history)
        }

        // Break
        let breakDate = calendar.date(byAdding: .day, value: -5, to: Date())!
        let breakHistory = DoseHistory(date: breakDate, isPerfectDay: false)
        modelContext.insert(breakHistory)

        // Earlier streak of 3
        for day in 6..<9 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let history = DoseHistory(date: date, isPerfectDay: true)
            modelContext.insert(history)
        }

        try? modelContext.save()

        let longestStreak = historyService.calculateLongestStreak()
        XCTAssertEqual(longestStreak, 5)
    }

    // MARK: - Data Management Tests

    func testGetRecordCount() {
        for i in 1...5 {
            let record = AdherenceRecord(portNumber: i, scheduledTime: Date(), status: "taken")
            modelContext.insert(record)
        }
        try? modelContext.save()

        XCTAssertEqual(historyService.getRecordCount(), 5)
    }

    func testGetHistoryDayCount() {
        let calendar = Calendar.current

        for day in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date())!
            let history = DoseHistory(date: date)
            modelContext.insert(history)
        }
        try? modelContext.save()

        XCTAssertEqual(historyService.getHistoryDayCount(), 3)
    }

    func testDeleteAllData() {
        // Add some data
        let record = AdherenceRecord(portNumber: 1, scheduledTime: Date(), status: "taken")
        let history = DoseHistory(date: Date())

        modelContext.insert(record)
        modelContext.insert(history)
        try? modelContext.save()

        XCTAssertEqual(historyService.getRecordCount(), 1)
        XCTAssertEqual(historyService.getHistoryDayCount(), 1)

        // Delete all
        historyService.deleteAllData()

        XCTAssertEqual(historyService.getRecordCount(), 0)
        XCTAssertEqual(historyService.getHistoryDayCount(), 0)
    }

    // MARK: - Helper Methods

    private func createTestDose(portNumber: Int, status: DoseStatus) -> Dose {
        var dose = Dose(portNumber: portNumber, scheduledTime: Date(), medications: [])
        dose.status = status
        if status == .taken {
            dose.actualTime = Date()
        }
        return dose
    }
}

// MARK: - HistoryStatistics Tests

final class HistoryStatisticsTests: XCTestCase {

    func testAdherenceRateText() {
        let stats = HistoryStatistics(adherenceRate: 87.5)
        XCTAssertEqual(stats.adherenceRateText, "88%")
    }

    func testTimingAccuracyText() {
        let stats = HistoryStatistics(averageTimingAccuracy: 0.95)
        XCTAssertEqual(stats.timingAccuracyText, "95%")
    }

    func testPerfectDayRate() {
        let stats = HistoryStatistics(totalDays: 10, perfectDays: 7)
        XCTAssertEqual(stats.perfectDayRate, 70, accuracy: 0.1)
    }

    func testPerfectDayRateWithZeroDays() {
        let stats = HistoryStatistics(totalDays: 0, perfectDays: 0)
        XCTAssertEqual(stats.perfectDayRate, 0)
    }
}
