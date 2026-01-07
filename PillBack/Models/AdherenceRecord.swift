// AdherenceRecord.swift
// SwiftData model for persistent dose adherence records

import Foundation
import SwiftData

/// Represents a single dose adherence record for historical tracking
@Model
final class AdherenceRecord {

    // MARK: - Properties

    /// Unique identifier
    var id: UUID

    /// Port number (1-6)
    var portNumber: Int

    /// Scheduled time for the dose
    var scheduledTime: Date

    /// Actual time the dose was taken (nil if missed/skipped)
    var actualTime: Date?

    /// Dose status: taken, missed, skipped
    var status: String

    /// Timing difference in minutes (positive = late, negative = early)
    var timingDifferenceMinutes: Int?

    /// Timing accuracy score (0-1)
    var timingAccuracy: Double?

    /// Timing category: excellent, good, fair, poor
    var timingCategory: String

    /// How the dose was recorded: manual, notification, motion
    var recordSource: String

    /// Medications in this dose (stored as JSON string)
    var medicationsJSON: String

    /// Date component for efficient querying (start of day)
    var dateKey: Date

    /// Timestamp when record was created
    var createdAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        portNumber: Int,
        scheduledTime: Date,
        actualTime: Date? = nil,
        status: String = "pending",
        timingDifferenceMinutes: Int? = nil,
        timingAccuracy: Double? = nil,
        timingCategory: String = "pending",
        recordSource: String = "manual",
        medications: [String] = []
    ) {
        self.id = id
        self.portNumber = portNumber
        self.scheduledTime = scheduledTime
        self.actualTime = actualTime
        self.status = status
        self.timingDifferenceMinutes = timingDifferenceMinutes
        self.timingAccuracy = timingAccuracy
        self.timingCategory = timingCategory
        self.recordSource = recordSource
        self.medicationsJSON = Self.encodeMedications(medications)
        self.dateKey = Calendar.current.startOfDay(for: scheduledTime)
        self.createdAt = Date()
    }

    // MARK: - Convenience Initializer from Dose

    convenience init(from dose: Dose, medications: [Medication], source: RecordSource = .manual) {
        let medNames = medications.filter { $0.isInPort(dose.portNumber) }.map { $0.name }

        self.init(
            id: dose.id,
            portNumber: dose.portNumber,
            scheduledTime: dose.scheduledTime,
            actualTime: dose.actualTime,
            status: dose.status.rawValue.lowercased(),
            timingDifferenceMinutes: dose.timingDifference,
            timingAccuracy: dose.status == .taken ? dose.timingAccuracy : nil,
            timingCategory: dose.timingCategory.rawValue.lowercased(),
            recordSource: source.rawValue,
            medications: medNames
        )
    }

    // MARK: - Medication Encoding/Decoding

    private static func encodeMedications(_ medications: [String]) -> String {
        guard let data = try? JSONEncoder().encode(medications),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    var medications: [String] {
        guard let data = medicationsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return decoded
    }

    // MARK: - Computed Properties

    /// Check if dose was taken
    var isTaken: Bool {
        status == "taken"
    }

    /// Check if dose was missed
    var isMissed: Bool {
        status == "missed"
    }

    /// Check if dose was on time (within 5 minutes)
    var isOnTime: Bool {
        guard let diff = timingDifferenceMinutes else { return false }
        return abs(diff) <= 5
    }

    /// Formatted scheduled time string
    var scheduledTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledTime)
    }

    /// Formatted actual time string
    var actualTimeString: String? {
        guard let time = actualTime else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }

    /// Formatted date string
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: scheduledTime)
    }
}

// MARK: - Record Source

enum RecordSource: String, Codable {
    case manual = "manual"
    case notification = "notification"
    case motion = "motion"
    case automatic = "automatic"
}

// MARK: - Query Helpers

extension AdherenceRecord {

    /// Create a predicate for records on a specific date
    static func forDate(_ date: Date) -> Predicate<AdherenceRecord> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return #Predicate<AdherenceRecord> { record in
            record.dateKey == startOfDay
        }
    }

    /// Create a predicate for records in a date range
    static func inRange(from startDate: Date, to endDate: Date) -> Predicate<AdherenceRecord> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        return #Predicate<AdherenceRecord> { record in
            record.dateKey >= start && record.dateKey <= end
        }
    }

    /// Create a predicate for taken doses only
    static var takenOnly: Predicate<AdherenceRecord> {
        #Predicate<AdherenceRecord> { record in
            record.status == "taken"
        }
    }

    /// Create a predicate for a specific port
    static func forPort(_ portNumber: Int) -> Predicate<AdherenceRecord> {
        #Predicate<AdherenceRecord> { record in
            record.portNumber == portNumber
        }
    }
}
