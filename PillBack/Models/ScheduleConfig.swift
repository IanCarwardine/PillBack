// ScheduleConfig.swift
// Schedule configuration model for dose timing and distribution strategy

import Foundation

/// Configuration for generating the daily dose schedule
struct ScheduleConfig: Codable, Equatable {
    var startTime: Date
    var endTime: Date
    var strategy: ScheduleStrategy
    var keyDrugInterval: Int // minutes between KEY DRUG doses

    // MARK: - v0.3 Properties

    var portCount: Int = 4                    // Number of ports (1-6)
    var useFixedWindows: Bool = true          // Use fixed time windows vs calculated
    var fixedWindows: [DoseWindow] = []       // Custom fixed windows (empty = use defaults)

    // MARK: - v0.4 Waking Hours (explicit hour/minute for UI)

    /// Wake hour (0-23) - derived from startTime, used by UI
    var wakeHour: Int {
        get { Calendar.current.component(.hour, from: startTime) }
        set { updateStartTime(hour: newValue, minute: wakeMinute) }
    }

    /// Wake minute (0-59) - derived from startTime, used by UI
    var wakeMinute: Int {
        get { Calendar.current.component(.minute, from: startTime) }
        set { updateStartTime(hour: wakeHour, minute: newValue) }
    }

    /// Sleep hour (0-23) - derived from endTime, used by UI
    var sleepHour: Int {
        get { Calendar.current.component(.hour, from: endTime) }
        set { updateEndTime(hour: newValue, minute: sleepMinute) }
    }

    /// Sleep minute (0-59) - derived from endTime, used by UI
    var sleepMinute: Int {
        get { Calendar.current.component(.minute, from: endTime) }
        set { updateEndTime(hour: sleepHour, minute: newValue) }
    }

    // MARK: - Initialization

    init(
        startTime: Date? = nil,
        endTime: Date? = nil,
        strategy: ScheduleStrategy = .equalDistribution,
        keyDrugInterval: Int = 150,
        portCount: Int = 4,
        useFixedWindows: Bool = true,
        fixedWindows: [DoseWindow] = []
    ) {
        let calendar = Calendar.current
        let now = Date()
        self.startTime = startTime ?? calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        self.endTime = endTime ?? calendar.date(bySettingHour: 20, minute: 30, second: 0, of: now) ?? now
        self.strategy = strategy
        self.keyDrugInterval = keyDrugInterval
        self.portCount = portCount
        self.useFixedWindows = useFixedWindows
        self.fixedWindows = fixedWindows
    }

    /// Initialize with explicit wake/sleep hours and minutes
    init(
        wakeHour: Int,
        wakeMinute: Int,
        sleepHour: Int,
        sleepMinute: Int,
        strategy: ScheduleStrategy = .equalDistribution,
        keyDrugInterval: Int = 150,
        portCount: Int = 4,
        useFixedWindows: Bool = true,
        fixedWindows: [DoseWindow] = []
    ) {
        let calendar = Calendar.current
        let now = Date()
        self.startTime = calendar.date(bySettingHour: wakeHour, minute: wakeMinute, second: 0, of: now) ?? now
        self.endTime = calendar.date(bySettingHour: sleepHour, minute: sleepMinute, second: 0, of: now) ?? now
        self.strategy = strategy
        self.keyDrugInterval = keyDrugInterval
        self.portCount = portCount
        self.useFixedWindows = useFixedWindows
        self.fixedWindows = fixedWindows
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

    /// Formatted wake time string (e.g., "7:00 AM")
    var wakeTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    /// Formatted sleep time string (e.g., "10:00 PM")
    var sleepTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: endTime)
    }

    /// Total waking hours (for display)
    var wakingHoursDescription: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if minutes == 0 {
            return "\(hours) hours"
        }
        return "\(hours)h \(minutes)m"
    }

    // MARK: - Private Methods

    private mutating func updateStartTime(hour: Int, minute: Int) {
        let calendar = Calendar.current
        if let newTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: startTime) {
            startTime = newTime
        }
    }

    private mutating func updateEndTime(hour: Int, minute: Int) {
        let calendar = Calendar.current
        if let newTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: endTime) {
            endTime = newTime
        }
    }

    // MARK: - Default Configuration

    /// Default schedule: 8:00 AM to 8:30 PM, fixed windows, 4 ports
    static var `default`: ScheduleConfig {
        ScheduleConfig()
    }
}

// MARK: - Validation

extension ScheduleConfig {
    /// Validate configuration and return any errors
    var validationErrors: [String] {
        var errors: [String] = []

        if portCount < 1 || portCount > 6 {
            errors.append("Port count must be between 1 and 6")
        }

        if startTime >= endTime {
            errors.append("Start time must be before end time")
        }

        if keyDrugInterval < 30 || keyDrugInterval > 480 {
            errors.append("KEY DRUG interval must be between 30 and 480 minutes")
        }

        return errors
    }

    /// Check if configuration is valid
    var isValid: Bool {
        validationErrors.isEmpty
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
