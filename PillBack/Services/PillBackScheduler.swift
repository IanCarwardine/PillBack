// PillBackScheduler.swift
// Centralized scheduling service for dose generation

import Foundation

/// Service for generating dose schedules with support for fixed windows and KEY DRUG alignment
class PillBackScheduler {

    // MARK: - Singleton

    static let shared = PillBackScheduler()

    private init() {}

    // MARK: - Fixed Dose Windows

    /// Pre-defined dose windows for v0.3
    static let defaultWindows: [DoseWindow] = [
        DoseWindow(hour: 6, minute: 0, label: "Morning"),
        DoseWindow(hour: 11, minute: 0, label: "Midday"),
        DoseWindow(hour: 16, minute: 0, label: "Afternoon"),
        DoseWindow(hour: 21, minute: 0, label: "Evening")
    ]

    /// Extended windows for 6-port configuration
    static let extendedWindows: [DoseWindow] = [
        DoseWindow(hour: 6, minute: 0, label: "Early Morning"),
        DoseWindow(hour: 9, minute: 0, label: "Morning"),
        DoseWindow(hour: 12, minute: 0, label: "Noon"),
        DoseWindow(hour: 15, minute: 0, label: "Afternoon"),
        DoseWindow(hour: 18, minute: 0, label: "Evening"),
        DoseWindow(hour: 21, minute: 0, label: "Night")
    ]

    // MARK: - Schedule Generation

    /// Generate a daily dose schedule
    /// - Parameters:
    ///   - config: Schedule configuration
    ///   - medications: Available medications
    ///   - date: Date to generate schedule for (defaults to today)
    /// - Returns: Array of scheduled doses
    func generateSchedule(
        config: ScheduleConfig,
        medications: [Medication],
        for date: Date = Date()
    ) -> [Dose] {
        let portCount = config.portCount

        // Choose generation strategy
        if config.useFixedWindows {
            return generateFromFixedWindows(
                portCount: portCount,
                windows: config.fixedWindows.isEmpty ? getDefaultWindows(for: portCount) : config.fixedWindows,
                medications: medications,
                date: date
            )
        } else {
            switch config.strategy {
            case .equalDistribution:
                return generateEqualDistribution(
                    config: config,
                    medications: medications,
                    date: date
                )
            case .fixedInterval:
                return generateKeyDrugInterval(
                    config: config,
                    medications: medications,
                    date: date
                )
            }
        }
    }

    // MARK: - Fixed Windows Generation

    /// Generate schedule from fixed time windows
    private func generateFromFixedWindows(
        portCount: Int,
        windows: [DoseWindow],
        medications: [Medication],
        date: Date
    ) -> [Dose] {
        let calendar = Calendar.current
        var doses: [Dose] = []

        // Use only the number of windows needed for port count
        let activeWindows = Array(windows.prefix(portCount))

        for (index, window) in activeWindows.enumerated() {
            let portNumber = index + 1

            // Create scheduled time for this window
            guard let scheduledTime = calendar.date(
                bySettingHour: window.hour,
                minute: window.minute,
                second: 0,
                of: date
            ) else { continue }

            // Find medications for this port
            let portMedications = medications.filter { $0.isInPort(portNumber) }

            let dose = Dose(
                portNumber: portNumber,
                scheduledTime: scheduledTime,
                medications: portMedications
            )

            doses.append(dose)
        }

        return doses.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    /// Get default windows based on port count
    func getDefaultWindows(for portCount: Int) -> [DoseWindow] {
        switch portCount {
        case 1:
            return [DoseWindow(hour: 8, minute: 0, label: "Morning")]
        case 2:
            return [
                DoseWindow(hour: 8, minute: 0, label: "Morning"),
                DoseWindow(hour: 20, minute: 0, label: "Evening")
            ]
        case 3:
            return [
                DoseWindow(hour: 8, minute: 0, label: "Morning"),
                DoseWindow(hour: 14, minute: 0, label: "Afternoon"),
                DoseWindow(hour: 20, minute: 0, label: "Evening")
            ]
        case 4:
            return Self.defaultWindows
        case 5:
            return [
                DoseWindow(hour: 7, minute: 0, label: "Early Morning"),
                DoseWindow(hour: 10, minute: 30, label: "Morning"),
                DoseWindow(hour: 14, minute: 0, label: "Afternoon"),
                DoseWindow(hour: 17, minute: 30, label: "Late Afternoon"),
                DoseWindow(hour: 21, minute: 0, label: "Evening")
            ]
        case 6:
            return Self.extendedWindows
        default:
            return Self.defaultWindows
        }
    }

    // MARK: - Equal Distribution Generation

    /// Generate schedule with equal time distribution
    private func generateEqualDistribution(
        config: ScheduleConfig,
        medications: [Medication],
        date: Date
    ) -> [Dose] {
        let calendar = Calendar.current
        var doses: [Dose] = []

        // Get start and end times for the given date
        let startComponents = calendar.dateComponents([.hour, .minute], from: config.startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: config.endTime)

        guard let startTime = calendar.date(
            bySettingHour: startComponents.hour ?? 8,
            minute: startComponents.minute ?? 0,
            second: 0,
            of: date
        ),
        let endTime = calendar.date(
            bySettingHour: endComponents.hour ?? 20,
            minute: endComponents.minute ?? 30,
            second: 0,
            of: date
        ) else {
            return []
        }

        // Calculate interval between doses
        let totalMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        let interval = config.portCount > 1 ? totalMinutes / (config.portCount - 1) : 0

        for portNumber in 1...config.portCount {
            let minutesOffset = (portNumber - 1) * interval
            guard let scheduledTime = calendar.date(
                byAdding: .minute,
                value: minutesOffset,
                to: startTime
            ) else { continue }

            let portMedications = medications.filter { $0.isInPort(portNumber) }

            let dose = Dose(
                portNumber: portNumber,
                scheduledTime: scheduledTime,
                medications: portMedications
            )

            doses.append(dose)
        }

        return doses
    }

    // MARK: - KEY DRUG Interval Generation

    /// Generate schedule based on KEY DRUG interval
    private func generateKeyDrugInterval(
        config: ScheduleConfig,
        medications: [Medication],
        date: Date
    ) -> [Dose] {
        let calendar = Calendar.current
        var doses: [Dose] = []

        // Get start time for the given date
        let startComponents = calendar.dateComponents([.hour, .minute], from: config.startTime)

        guard let startTime = calendar.date(
            bySettingHour: startComponents.hour ?? 8,
            minute: startComponents.minute ?? 0,
            second: 0,
            of: date
        ) else {
            return []
        }

        for portNumber in 1...config.portCount {
            let minutesOffset = (portNumber - 1) * config.keyDrugInterval

            guard let scheduledTime = calendar.date(
                byAdding: .minute,
                value: minutesOffset,
                to: startTime
            ) else { continue }

            let portMedications = medications.filter { $0.isInPort(portNumber) }

            let dose = Dose(
                portNumber: portNumber,
                scheduledTime: scheduledTime,
                medications: portMedications
            )

            doses.append(dose)
        }

        return doses
    }

    // MARK: - Port Assignment

    /// Assign medications to ports based on frequency and KEY DRUG status
    /// - Parameters:
    ///   - medications: All medications to assign
    ///   - portCount: Number of available ports
    /// - Returns: Array of port assignments
    func assignMedicationsToPorts(
        medications: [Medication],
        portCount: Int
    ) -> [PortAssignment] {
        var assignments: [PortAssignment] = []

        for portNumber in 1...portCount {
            let portMeds = medications.filter { $0.isInPort(portNumber) }
            let hasKeyDrug = portMeds.contains { $0.isKeyDrug }

            assignments.append(PortAssignment(
                portNumber: portNumber,
                medications: portMeds,
                hasKeyDrug: hasKeyDrug
            ))
        }

        return assignments
    }

    // MARK: - Validation

    /// Validate a schedule configuration
    /// - Parameter config: Configuration to validate
    /// - Returns: Array of validation errors (empty if valid)
    func validateConfig(_ config: ScheduleConfig) -> [String] {
        var errors: [String] = []

        if config.portCount < 1 || config.portCount > 6 {
            errors.append("Port count must be between 1 and 6")
        }

        if config.startTime >= config.endTime {
            errors.append("Start time must be before end time")
        }

        if config.keyDrugInterval < 30 || config.keyDrugInterval > 480 {
            errors.append("KEY DRUG interval must be between 30 and 480 minutes")
        }

        if config.useFixedWindows && config.fixedWindows.isEmpty {
            // Will use defaults, but warn
            errors.append("No fixed windows specified, will use defaults")
        }

        return errors
    }

    // MARK: - Schedule Info

    /// Get human-readable description of schedule times
    func getScheduleDescription(for config: ScheduleConfig) -> String {
        let windows = config.useFixedWindows
            ? (config.fixedWindows.isEmpty ? getDefaultWindows(for: config.portCount) : config.fixedWindows)
            : []

        if config.useFixedWindows && !windows.isEmpty {
            let times = windows.prefix(config.portCount).map { $0.timeString }
            return times.joined(separator: ", ")
        } else if config.strategy == .equalDistribution {
            let startStr = formatTime(config.startTime)
            let endStr = formatTime(config.endTime)
            return "Every \(config.equalDistributionInterval) min from \(startStr) to \(endStr)"
        } else {
            let startStr = formatTime(config.startTime)
            return "Every \(config.keyDrugInterval) min from \(startStr)"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

/// Represents a fixed time window for dosing
struct DoseWindow: Codable, Equatable, Identifiable {
    var id: String { "\(hour):\(minute)" }

    let hour: Int
    let minute: Int
    let label: String

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):\(String(format: "%02d", minute))"
    }

    var date: Date? {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
    }
}

/// Represents medications assigned to a specific port
struct PortAssignment: Identifiable {
    var id: Int { portNumber }

    let portNumber: Int
    let medications: [Medication]
    let hasKeyDrug: Bool

    var medicationNames: String {
        medications.map { $0.name }.joined(separator: ", ")
    }

    var isEmpty: Bool {
        medications.isEmpty
    }
}
