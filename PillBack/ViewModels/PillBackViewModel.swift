// PillBackViewModel.swift
// Main view model managing app state, schedule generation, and persistence

import Foundation
import SwiftUI
import Combine

/// Main view model for PillBack app
/// Manages doses, medications, schedule, theme, and persistence
@MainActor
class PillBackViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var doses: [Dose] = []
    @Published var medications: [Medication] = []
    @Published var scheduleConfig: ScheduleConfig
    @Published var currentTheme: AppTheme = .clinical
    @Published var viewMode: ViewMode = .full
    @Published var userName: String = "My Name"
    @Published var timelineExpanded: Bool = false

    // MARK: - Computed Properties

    /// Overall timing accuracy percentage (0-100) for all taken doses
    var overallTimingAccuracy: Int {
        let takenDoses = doses.filter { $0.status == .taken }
        guard !takenDoses.isEmpty else { return 0 }

        let totalAccuracy = takenDoses.reduce(0.0) { $0 + $1.timingAccuracy }
        return Int((totalAccuracy / Double(takenDoses.count)) * 100)
    }

    /// Next pending dose scheduled after now
    var nextDose: Dose? {
        doses.first { $0.status == .pending && $0.scheduledTime > Date() }
    }

    /// Current date for display
    var currentDate: Date {
        Date()
    }

    /// Number of doses taken today
    var dosesTakenToday: Int {
        doses.filter { $0.status == .taken }.count
    }

    /// Number of pending doses
    var pendingDoses: Int {
        doses.filter { $0.status == .pending }.count
    }

    // MARK: - Private Properties

    private let defaults = UserDefaults.standard
    private let dosesKey = "pillback_doses"
    private let medicationsKey = "pillback_medications"
    private let configKey = "pillback_config"
    private let themeKey = "pillback_theme"
    private let viewModeKey = "pillback_viewMode"
    private let userNameKey = "pillback_userName"
    private let timelineExpandedKey = "pillback_timelineExpanded"
    private let lastResetKey = "pillback_lastReset"

    // MARK: - Initialization

    init() {
        // Initialize with default schedule config
        self.scheduleConfig = ScheduleConfig.default

        // Load persisted data
        loadUserPreferences()
        loadScheduleConfig()
        loadMedications()
        loadDoses()

        // Generate schedule if no doses exist
        if doses.isEmpty {
            generateSchedule()
        }

        // Check for midnight reset
        checkMidnightReset()
    }

    // MARK: - Schedule Generation

    /// Generate a new schedule based on current configuration
    func generateSchedule() {
        let calendar = Calendar.current
        var newDoses: [Dose] = []

        switch scheduleConfig.strategy {
        case .equalDistribution:
            let interval = scheduleConfig.equalDistributionInterval
            for i in 0..<6 {
                let minutesOffset = interval * i
                if let doseTime = calendar.date(byAdding: .minute, value: minutesOffset, to: scheduleConfig.startTime) {
                    let dose = Dose(
                        portNumber: i + 1,
                        scheduledTime: doseTime,
                        actualTime: nil,
                        medications: medicationsForPort(i + 1),
                        status: .pending
                    )
                    newDoses.append(dose)
                }
            }

        case .fixedInterval:
            var currentTime = scheduleConfig.startTime
            var portNumber = 1

            while currentTime <= scheduleConfig.endTime && portNumber <= 6 {
                let dose = Dose(
                    portNumber: portNumber,
                    scheduledTime: currentTime,
                    actualTime: nil,
                    medications: medicationsForPort(portNumber),
                    status: .pending
                )
                newDoses.append(dose)

                if let nextTime = calendar.date(byAdding: .minute, value: scheduleConfig.keyDrugInterval, to: currentTime) {
                    currentTime = nextTime
                } else {
                    break
                }
                portNumber += 1
            }
        }

        doses = newDoses
        saveDoses()
    }

    // MARK: - Dose Actions

    /// Mark a dose as taken at the specified time
    func markDoseTaken(dose: Dose, at time: Date = Date()) {
        if let index = doses.firstIndex(where: { $0.id == dose.id }) {
            doses[index].actualTime = time
            doses[index].status = .taken
            saveDoses()

            // TODO: Cancel notifications for this dose (Issue #009)
        }
    }

    /// Revert a dose back to pending status
    func untakeDose(dose: Dose) {
        if let index = doses.firstIndex(where: { $0.id == dose.id }) {
            doses[index].actualTime = nil
            doses[index].status = .pending
            saveDoses()

            // TODO: Reschedule notifications for this dose (Issue #009)
        }
    }

    /// Update the actual time for a taken dose
    func updateDoseTime(dose: Dose, newTime: Date) {
        if let index = doses.firstIndex(where: { $0.id == dose.id }) {
            doses[index].actualTime = newTime
            doses[index].status = .taken
            saveDoses()
        }
    }

    /// Mark a dose as missed
    func markDoseMissed(dose: Dose) {
        if let index = doses.firstIndex(where: { $0.id == dose.id }) {
            doses[index].status = .missed
            saveDoses()
        }
    }

    // MARK: - Medication Management

    /// Add a new medication
    func addMedication(_ medication: Medication) {
        medications.append(medication)
        saveMedications()
        regenerateScheduleWithNewMedications()
    }

    /// Update an existing medication
    func updateMedication(_ medication: Medication) {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
            saveMedications()
            regenerateScheduleWithNewMedications()
        }
    }

    /// Delete a medication
    func deleteMedication(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
        saveMedications()
        regenerateScheduleWithNewMedications()
    }

    /// Get all medications assigned to a specific port
    func medicationsForPort(_ portNumber: Int) -> [Medication] {
        medications.filter { $0.isInPort(portNumber) }
    }

    /// Regenerate schedule to include updated medications
    private func regenerateScheduleWithNewMedications() {
        for i in doses.indices {
            doses[i].medications = medicationsForPort(doses[i].portNumber)
        }
        saveDoses()
    }

    // MARK: - Theme Management

    /// Set the app theme
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        defaults.set(theme.rawValue, forKey: themeKey)
    }

    /// Set the view mode
    func setViewMode(_ mode: ViewMode) {
        viewMode = mode
        defaults.set(mode.rawValue, forKey: viewModeKey)
    }

    /// Toggle timeline sidebar expansion
    func toggleTimeline() {
        timelineExpanded.toggle()
        defaults.set(timelineExpanded, forKey: timelineExpandedKey)
    }

    /// Set user name
    func setUserName(_ name: String) {
        userName = name
        defaults.set(name, forKey: userNameKey)
    }

    // MARK: - Schedule Configuration

    /// Update schedule configuration and regenerate schedule
    func updateScheduleConfig(_ config: ScheduleConfig) {
        scheduleConfig = config
        saveScheduleConfig()
        generateSchedule()
    }

    // MARK: - Persistence

    private func saveDoses() {
        if let encoded = try? JSONEncoder().encode(doses) {
            defaults.set(encoded, forKey: dosesKey)
        }
    }

    private func loadDoses() {
        if let data = defaults.data(forKey: dosesKey),
           let decoded = try? JSONDecoder().decode([Dose].self, from: data) {
            doses = decoded
        }
    }

    private func saveMedications() {
        if let encoded = try? JSONEncoder().encode(medications) {
            defaults.set(encoded, forKey: medicationsKey)
        }
    }

    private func loadMedications() {
        if let data = defaults.data(forKey: medicationsKey),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            medications = decoded
        } else {
            // Use default medications
            medications = Medication.defaults
            saveMedications()
        }
    }

    private func saveScheduleConfig() {
        if let encoded = try? JSONEncoder().encode(scheduleConfig) {
            defaults.set(encoded, forKey: configKey)
        }
    }

    private func loadScheduleConfig() {
        if let data = defaults.data(forKey: configKey),
           let decoded = try? JSONDecoder().decode(ScheduleConfig.self, from: data) {
            scheduleConfig = decoded
        }
    }

    private func loadUserPreferences() {
        // Theme
        if let themeString = defaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeString) {
            currentTheme = theme
        }

        // View Mode
        if let modeString = defaults.string(forKey: viewModeKey),
           let mode = ViewMode(rawValue: modeString) {
            viewMode = mode
        }

        // User Name
        if let name = defaults.string(forKey: userNameKey) {
            userName = name
        }

        // Timeline Expanded
        timelineExpanded = defaults.bool(forKey: timelineExpandedKey)
    }

    // MARK: - Midnight Reset

    /// Check if we need to reset the schedule for a new day
    func checkMidnightReset() {
        let calendar = Calendar.current
        let lastResetDate = defaults.object(forKey: lastResetKey) as? Date ?? Date.distantPast

        if !calendar.isDateInToday(lastResetDate) {
            // New day - reset schedule
            doses = []
            generateSchedule()
            defaults.set(Date(), forKey: lastResetKey)
        }
    }

    // MARK: - Pattern Detection

    /// Detect timing patterns across doses
    /// Returns ports that are consistently taken late (>20 min) with average lateness
    func detectTimingPatterns() -> [(port: Int, avgLateness: Int)] {
        var portLateness: [Int: [Int]] = [:]

        for dose in doses where dose.status == .taken {
            if let diff = dose.timingDifference, diff > 20 {
                portLateness[dose.portNumber, default: []].append(diff)
            }
        }

        return portLateness.compactMap { port, diffs in
            // Only report if 2+ late doses for this port
            guard diffs.count >= 2 else { return nil }
            let avg = diffs.reduce(0, +) / diffs.count
            return (port: port, avgLateness: avg)
        }.sorted { $0.avgLateness > $1.avgLateness }
    }

    // MARK: - Data Reset

    /// Reset all data to defaults (for testing or user request)
    func resetAllData() {
        // Clear UserDefaults
        let keys = [dosesKey, medicationsKey, configKey, themeKey, viewModeKey, userNameKey, timelineExpandedKey, lastResetKey]
        keys.forEach { defaults.removeObject(forKey: $0) }

        // Reset to defaults
        scheduleConfig = ScheduleConfig.default
        currentTheme = .clinical
        viewMode = .full
        userName = "My Name"
        timelineExpanded = false
        medications = Medication.defaults
        saveMedications()
        generateSchedule()
    }

    // MARK: - Export (Stub for Issue #011)

    /// Export data to CSV format
    func exportToCSV(dateRange: ClosedRange<Date>? = nil) -> String {
        // TODO: Implement in Issue #011
        return ""
    }

    /// Export data to JSON format
    func exportToJSON(dateRange: ClosedRange<Date>? = nil) -> Data? {
        // TODO: Implement in Issue #011
        return nil
    }
}
