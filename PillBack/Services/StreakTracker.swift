// StreakTracker.swift
// Service for tracking adherence streaks and statistics

import Foundation

/// Service for calculating and persisting adherence streaks
class StreakTracker {

    // MARK: - Singleton

    static let shared = StreakTracker()

    private init() {
        loadStreakData()
    }

    // MARK: - Streak Data

    private(set) var streakData: StreakData = StreakData()

    // MARK: - UserDefaults Keys

    private let streakDataKey = "pillback_streakData"

    // MARK: - Persistence

    private func loadStreakData() {
        guard let data = UserDefaults.standard.data(forKey: streakDataKey),
              let decoded = try? JSONDecoder().decode(StreakData.self, from: data) else {
            return
        }
        streakData = decoded
    }

    private func saveStreakData() {
        guard let data = try? JSONEncoder().encode(streakData) else { return }
        UserDefaults.standard.set(data, forKey: streakDataKey)
    }

    // MARK: - Streak Calculations

    /// Update streaks based on today's doses
    /// - Parameter doses: Today's doses
    func updateStreaks(with doses: [Dose]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculate today's adherence
        let completedDoses = doses.filter { $0.status == .taken }
        let totalDoses = doses.count
        let todayAdherence = totalDoses > 0 ? Double(completedDoses.count) / Double(totalDoses) : 0

        // Update today's record
        streakData.todayAdherence = todayAdherence
        streakData.todayDosesTaken = completedDoses.count
        streakData.todayDosesTotal = totalDoses

        // Check if today is a perfect day (100% adherence)
        let isPerfectDay = totalDoses > 0 && completedDoses.count == totalDoses

        // Update current streak
        if isPerfectDay {
            if let lastPerfect = streakData.lastPerfectDay {
                let daysSinceLast = calendar.dateComponents([.day], from: lastPerfect, to: today).day ?? 0

                if daysSinceLast == 0 {
                    // Same day, streak unchanged
                } else if daysSinceLast == 1 {
                    // Consecutive day, increment streak
                    streakData.currentStreak += 1
                } else {
                    // Gap in days, reset streak
                    streakData.currentStreak = 1
                }
            } else {
                // First perfect day
                streakData.currentStreak = 1
            }

            streakData.lastPerfectDay = today

            // Update longest streak
            if streakData.currentStreak > streakData.longestStreak {
                streakData.longestStreak = streakData.currentStreak
            }
        }

        saveStreakData()
    }

    /// Calculate adherence for a specific date range
    /// - Parameters:
    ///   - doses: All doses to analyze
    ///   - days: Number of days to look back
    /// - Returns: Adherence percentage (0-100)
    func calculateAdherence(from doses: [Dose], days: Int) -> Double {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return 0
        }

        let filteredDoses = doses.filter { dose in
            dose.scheduledTime >= startDate && dose.scheduledTime <= endDate
        }

        guard !filteredDoses.isEmpty else { return 0 }

        let takenDoses = filteredDoses.filter { $0.status == .taken }
        return Double(takenDoses.count) / Double(filteredDoses.count) * 100
    }

    /// Update 7-day and 30-day adherence stats
    /// - Parameter allDoses: All historical doses
    func updatePeriodStats(with allDoses: [Dose]) {
        streakData.adherence7Day = calculateAdherence(from: allDoses, days: 7)
        streakData.adherence30Day = calculateAdherence(from: allDoses, days: 30)
        streakData.adherenceAllTime = calculateAllTimeAdherence(from: allDoses)

        saveStreakData()
    }

    /// Calculate all-time adherence
    private func calculateAllTimeAdherence(from doses: [Dose]) -> Double {
        guard !doses.isEmpty else { return 0 }

        let takenDoses = doses.filter { $0.status == .taken }
        return Double(takenDoses.count) / Double(doses.count) * 100
    }

    // MARK: - Streak Analysis

    /// Get streak summary for display
    func getStreakSummary() -> StreakSummary {
        StreakSummary(
            currentStreak: streakData.currentStreak,
            longestStreak: streakData.longestStreak,
            adherence7Day: streakData.adherence7Day,
            adherence30Day: streakData.adherence30Day,
            adherenceAllTime: streakData.adherenceAllTime,
            todayProgress: streakData.todayAdherence,
            streakStatus: getStreakStatus()
        )
    }

    /// Determine current streak status
    private func getStreakStatus() -> StreakStatus {
        guard let lastPerfect = streakData.lastPerfectDay else {
            return .noStreak
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysSinceLast = calendar.dateComponents([.day], from: lastPerfect, to: today).day ?? 0

        switch daysSinceLast {
        case 0:
            return streakData.todayAdherence >= 1.0 ? .activeToday : .inProgress
        case 1:
            return .atRisk  // Yesterday was perfect, today not yet
        default:
            return .broken
        }
    }

    /// Check if current streak is at risk of being broken
    func isStreakAtRisk() -> Bool {
        let status = getStreakStatus()
        return status == .atRisk || status == .inProgress
    }

    /// Get remaining doses needed to maintain streak
    func remainingForStreak(totalDoses: Int, takenDoses: Int) -> Int {
        return max(0, totalDoses - takenDoses)
    }

    // MARK: - Timing Analysis

    /// Calculate average timing accuracy from doses
    /// - Parameter doses: Doses to analyze
    /// - Returns: Average timing accuracy (0-1)
    func calculateAverageTimingAccuracy(from doses: [Dose]) -> Double {
        let takenDoses = doses.filter { $0.status == .taken }
        guard !takenDoses.isEmpty else { return 0 }

        let totalAccuracy = takenDoses.reduce(0.0) { $0 + $1.timingAccuracy }
        return totalAccuracy / Double(takenDoses.count)
    }

    /// Get timing category distribution
    /// - Parameter doses: Doses to analyze
    /// - Returns: Dictionary of category counts
    func getTimingDistribution(from doses: [Dose]) -> [TimingCategory: Int] {
        var distribution: [TimingCategory: Int] = [
            .excellent: 0,
            .good: 0,
            .fair: 0,
            .poor: 0
        ]

        for dose in doses where dose.status == .taken {
            distribution[dose.timingCategory, default: 0] += 1
        }

        return distribution
    }

    // MARK: - Reset

    /// Reset all streak data (for testing or user request)
    func resetAllData() {
        streakData = StreakData()
        saveStreakData()
    }

    /// Handle midnight reset - check if streak is broken
    func handleMidnightReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // If yesterday wasn't a perfect day, streak is broken
        if let lastPerfect = streakData.lastPerfectDay {
            let daysSinceLast = calendar.dateComponents([.day], from: lastPerfect, to: today).day ?? 0

            if daysSinceLast > 1 {
                // More than 1 day gap - streak is broken
                streakData.currentStreak = 0
                saveStreakData()
            }
        }

        // Reset today's counters
        streakData.todayAdherence = 0
        streakData.todayDosesTaken = 0
        streakData.todayDosesTotal = 0
        saveStreakData()
    }
}

// MARK: - Supporting Types

/// Persistent streak data
struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastPerfectDay: Date?

    var adherence7Day: Double = 0
    var adherence30Day: Double = 0
    var adherenceAllTime: Double = 0

    var todayAdherence: Double = 0
    var todayDosesTaken: Int = 0
    var todayDosesTotal: Int = 0
}

/// Summary for UI display
struct StreakSummary {
    let currentStreak: Int
    let longestStreak: Int
    let adherence7Day: Double
    let adherence30Day: Double
    let adherenceAllTime: Double
    let todayProgress: Double
    let streakStatus: StreakStatus

    var currentStreakText: String {
        if currentStreak == 0 {
            return "No streak"
        } else if currentStreak == 1 {
            return "1 day"
        } else {
            return "\(currentStreak) days"
        }
    }

    var longestStreakText: String {
        if longestStreak == 0 {
            return "None yet"
        } else if longestStreak == 1 {
            return "1 day"
        } else {
            return "\(longestStreak) days"
        }
    }

    var adherence7DayText: String {
        String(format: "%.0f%%", adherence7Day)
    }

    var adherence30DayText: String {
        String(format: "%.0f%%", adherence30Day)
    }

    var adherenceAllTimeText: String {
        String(format: "%.0f%%", adherenceAllTime)
    }
}

/// Current streak status
enum StreakStatus {
    case noStreak       // Never had a perfect day
    case activeToday    // Today is perfect, streak active
    case inProgress     // Today not yet complete
    case atRisk         // Yesterday was perfect, today not yet
    case broken         // Gap in perfect days

    var displayText: String {
        switch self {
        case .noStreak: return "Start your streak!"
        case .activeToday: return "Streak active"
        case .inProgress: return "Keep going today"
        case .atRisk: return "Complete today's doses"
        case .broken: return "Streak ended"
        }
    }

    var isActive: Bool {
        switch self {
        case .activeToday, .inProgress, .atRisk:
            return true
        default:
            return false
        }
    }
}
