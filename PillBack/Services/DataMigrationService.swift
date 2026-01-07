// DataMigrationService.swift
// Service for migrating data from UserDefaults to SwiftData

import Foundation
import SwiftData

/// Service for handling data migration from UserDefaults to SwiftData
@MainActor
class DataMigrationService {

    // MARK: - Migration Keys

    private let migrationCompletedKey = "pillback_migration_completed"
    private let migrationVersionKey = "pillback_migration_version"
    private let currentMigrationVersion = 1

    // MARK: - Properties

    private let modelContext: ModelContext
    private let historyService: HistoryService

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.historyService = HistoryService(modelContext: modelContext)
    }

    // MARK: - Migration Status

    /// Check if migration has been completed
    var isMigrationComplete: Bool {
        let completed = UserDefaults.standard.bool(forKey: migrationCompletedKey)
        let version = UserDefaults.standard.integer(forKey: migrationVersionKey)
        return completed && version >= currentMigrationVersion
    }

    /// Check if migration is needed
    var needsMigration: Bool {
        // Check if there's legacy data and migration hasn't been done
        let hasDoses = UserDefaults.standard.data(forKey: "pillback_doses") != nil
        return hasDoses && !isMigrationComplete
    }

    // MARK: - Migration

    /// Perform migration from UserDefaults to SwiftData
    /// - Returns: Number of records migrated
    @discardableResult
    func performMigration() -> Int {
        guard needsMigration else {
            print("DataMigrationService: Migration not needed or already complete")
            return 0
        }

        print("DataMigrationService: Starting migration...")

        var migratedCount = 0

        // Migrate doses
        if let dosesData = UserDefaults.standard.data(forKey: "pillback_doses") {
            do {
                let doses = try JSONDecoder().decode([Dose].self, from: dosesData)
                let medications = loadMedications()

                for dose in doses where dose.status != .pending {
                    let record = AdherenceRecord(
                        from: dose,
                        medications: medications,
                        source: .manual
                    )
                    modelContext.insert(record)
                    migratedCount += 1
                }

                try modelContext.save()

                // Update daily histories for migrated data
                let uniqueDates = Set(doses.map { Calendar.current.startOfDay(for: $0.scheduledTime) })
                for date in uniqueDates {
                    updateDailyHistory(for: date)
                }

                print("DataMigrationService: Migrated \(migratedCount) dose records")
            } catch {
                print("DataMigrationService: Failed to migrate doses - \(error)")
            }
        }

        // Mark migration as complete
        UserDefaults.standard.set(true, forKey: migrationCompletedKey)
        UserDefaults.standard.set(currentMigrationVersion, forKey: migrationVersionKey)

        print("DataMigrationService: Migration complete")
        return migratedCount
    }

    /// Load medications from UserDefaults
    private func loadMedications() -> [Medication] {
        guard let data = UserDefaults.standard.data(forKey: "pillback_medications"),
              let medications = try? JSONDecoder().decode([Medication].self, from: data) else {
            return Medication.defaults
        }
        return medications
    }

    /// Update daily history for a date
    private func updateDailyHistory(for date: Date) {
        let dateKey = Calendar.current.startOfDay(for: date)

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

            let recordsDescriptor = FetchDescriptor<AdherenceRecord>(
                predicate: AdherenceRecord.forDate(dateKey)
            )
            let records = try modelContext.fetch(recordsDescriptor)
            history.updateFromRecords(records)

            try modelContext.save()
        } catch {
            print("DataMigrationService: Failed to update daily history - \(error)")
        }
    }

    // MARK: - Utility

    /// Reset migration status (for testing)
    func resetMigration() {
        UserDefaults.standard.removeObject(forKey: migrationCompletedKey)
        UserDefaults.standard.removeObject(forKey: migrationVersionKey)
        print("DataMigrationService: Migration status reset")
    }

    /// Get migration info
    func getMigrationInfo() -> MigrationInfo {
        MigrationInfo(
            isComplete: isMigrationComplete,
            currentVersion: UserDefaults.standard.integer(forKey: migrationVersionKey),
            targetVersion: currentMigrationVersion,
            needsMigration: needsMigration
        )
    }
}

// MARK: - Migration Info

struct MigrationInfo {
    let isComplete: Bool
    let currentVersion: Int
    let targetVersion: Int
    let needsMigration: Bool

    var statusText: String {
        if isComplete {
            return "Migration complete (v\(currentVersion))"
        } else if needsMigration {
            return "Migration pending (v\(currentVersion) → v\(targetVersion))"
        } else {
            return "No migration needed"
        }
    }
}

// MARK: - App Extension

extension PillBackApp {

    /// Perform migration if needed on app launch
    static func performMigrationIfNeeded(modelContext: ModelContext) {
        Task { @MainActor in
            let migrationService = DataMigrationService(modelContext: modelContext)
            if migrationService.needsMigration {
                migrationService.performMigration()
            }
        }
    }
}
