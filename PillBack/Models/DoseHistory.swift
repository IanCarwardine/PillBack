// DoseHistory.swift
// SwiftData model for daily dose history aggregation

import Foundation
import SwiftData

/// Represents a single day's dose history with aggregated statistics
@Model
final class DoseHistory {

    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Date for this history entry (start of day)
    var date: Date

    /// Total number of doses scheduled for the day
    var totalDoses: Int

    /// Number of doses taken
    var dosesTaken: Int

    /// Number of doses missed
    var dosesMissed: Int

    /// Number of doses skipped
    var dosesSkipped: Int

    /// Adherence score for the day (0-100)
    var adherenceScore: Double

    /// Average timing accuracy for taken doses (0-1)
    var averageTimingAccuracy: Double

    /// Whether this was a perfect day (100% adherence)
    var isPerfectDay: Bool

    /// Current streak count as of this day
    var streakCount: Int

    /// Port count for this day
    var portCount: Int

    /// Timestamp when record was created
    var createdAt: Date

    /// Timestamp when record was last updated
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date,
        totalDoses: Int = 0,
        dosesTaken: Int = 0,
        dosesMissed: Int = 0,
        dosesSkipped: Int = 0,
        adherenceScore: Double = 0,
        averageTimingAccuracy: Double = 0,
        isPerfectDay: Bool = false,
        streakCount: Int = 0,
        portCount: Int = 4
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.totalDoses = totalDoses
        self.dosesTaken = dosesTaken
        self.dosesMissed = dosesMissed
        self.dosesSkipped = dosesSkipped
        self.adherenceScore = adherenceScore
        self.averageTimingAccuracy = averageTimingAccuracy
        self.isPerfectDay = isPerfectDay
        self.streakCount = streakCount
        self.portCount = portCount
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Update from Records

    /// Update statistics from adherence records
    func updateFromRecords(_ records: [AdherenceRecord]) {
        totalDoses = records.count
        dosesTaken = records.filter { $0.status == "taken" }.count
        dosesMissed = records.filter { $0.status == "missed" }.count
        dosesSkipped = records.filter { $0.status == "skipped" }.count

        // Calculate adherence score
        adherenceScore = totalDoses > 0
            ? Double(dosesTaken) / Double(totalDoses) * 100
            : 0

        // Calculate average timing accuracy
        let takenRecords = records.filter { $0.status == "taken" }
        let accuracies = takenRecords.compactMap { $0.timingAccuracy }
        averageTimingAccuracy = accuracies.isEmpty
            ? 0
            : accuracies.reduce(0, +) / Double(accuracies.count)

        // Check for perfect day
        isPerfectDay = totalDoses > 0 && dosesTaken == totalDoses

        updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Pending doses count
    var dosesPending: Int {
        max(0, totalDoses - dosesTaken - dosesMissed - dosesSkipped)
    }

    /// Adherence score formatted as percentage string
    var adherenceScoreText: String {
        String(format: "%.0f%%", adherenceScore)
    }

    /// Timing accuracy formatted as percentage string
    var timingAccuracyText: String {
        String(format: "%.0f%%", averageTimingAccuracy * 100)
    }

    /// Formatted date string
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Short date string (e.g., "Dec 31")
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    /// Day of week string
    var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// Check if this is today
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Check if this is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(date)
    }

    /// Status indicator for the day
    var dayStatus: DayStatus {
        if isPerfectDay {
            return .perfect
        } else if adherenceScore >= 80 {
            return .good
        } else if adherenceScore >= 50 {
            return .fair
        } else if dosesTaken > 0 {
            return .poor
        } else {
            return .missed
        }
    }
}

// MARK: - Day Status

enum DayStatus: String {
    case perfect = "Perfect"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case missed = "Missed"

    var emoji: String {
        switch self {
        case .perfect: return "🌟"
        case .good: return "✅"
        case .fair: return "⚠️"
        case .poor: return "❌"
        case .missed: return "⛔"
        }
    }

    var color: String {
        switch self {
        case .perfect: return "success"
        case .good: return "success"
        case .fair: return "warning"
        case .poor: return "danger"
        case .missed: return "danger"
        }
    }
}

// MARK: - Query Helpers

extension DoseHistory {

    /// Create a predicate for a specific date
    static func forDate(_ date: Date) -> Predicate<DoseHistory> {
        let dateKey = Calendar.current.startOfDay(for: date)
        return #Predicate<DoseHistory> { history in
            history.date == dateKey
        }
    }

    /// Create a predicate for a date range
    static func inRange(from startDate: Date, to endDate: Date) -> Predicate<DoseHistory> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return #Predicate<DoseHistory> { history in
            history.date >= start && history.date <= end
        }
    }

    /// Create a predicate for perfect days only
    static var perfectDaysOnly: Predicate<DoseHistory> {
        #Predicate<DoseHistory> { history in
            history.isPerfectDay == true
        }
    }

    /// Create a predicate for last N days
    static func lastDays(_ count: Int) -> Predicate<DoseHistory> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -(count - 1), to: today) else {
            return #Predicate<DoseHistory> { _ in true }
        }
        return #Predicate<DoseHistory> { history in
            history.date >= startDate && history.date <= today
        }
    }
}

// MARK: - Sorting

extension DoseHistory {
    /// Sort descriptor for date descending (newest first)
    static var newestFirst: SortDescriptor<DoseHistory> {
        SortDescriptor(\.date, order: .reverse)
    }

    /// Sort descriptor for date ascending (oldest first)
    static var oldestFirst: SortDescriptor<DoseHistory> {
        SortDescriptor(\.date, order: .forward)
    }
}
