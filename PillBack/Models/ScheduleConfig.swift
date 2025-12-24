// ScheduleConfig.swift
// Schedule configuration model for dose timing and distribution strategy

import Foundation

/// Configuration for generating the daily dose schedule
struct ScheduleConfig: Codable, Equatable {
    var startTime: Date
    var endTime: Date
    var strategy: ScheduleStrategy
    var keyDrugInterval: Int // minutes between KEY DRUG doses

    // MARK: - Initialization

    init(startTime: Date, endTime: Date, strategy: ScheduleStrategy = .equalDistribution, keyDrugInterval: Int = 150) {
        self.startTime = startTime
        self.endTime = endTime
        self.strategy = strategy
        self.keyDrugInterval = keyDrugInterval
    }

    // MARK: - Computed Properties

    /// Total waking minutes from start to end
    var totalMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    /// Calculated interval between doses for equal distribution
    var equalDistributionInterval: Int {
        totalMinutes / 6
    }

    // MARK: - Default Configuration

    /// Default schedule: 8:00 AM to 8:30 PM, equal distribution
    static var `default`: ScheduleConfig {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        let endTime = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: now) ?? now

        return ScheduleConfig(
            startTime: startTime,
            endTime: endTime,
            strategy: .equalDistribution,
            keyDrugInterval: 150
        )
    }
}

// MARK: - Schedule Strategy

enum ScheduleStrategy: String, Codable, CaseIterable {
    case equalDistribution = "Equal Distribution"
    case fixedInterval = "Fixed Interval"

    var description: String {
        switch self {
        case .equalDistribution:
            return "Spreads 6 doses evenly across your waking hours"
        case .fixedInterval:
            return "Spaces doses by KEY DRUG interval (e.g., every 2.5 hours)"
        }
    }

    var shortDescription: String {
        switch self {
        case .equalDistribution:
            return "Even spacing"
        case .fixedInterval:
            return "KEY DRUG timing"
        }
    }
}
