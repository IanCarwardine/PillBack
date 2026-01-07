// Dose.swift
// Dose model representing a scheduled medication dose with timing tracking

import Foundation
import SwiftUI

/// Represents a single scheduled dose from one port of the pill organizer
struct Dose: Identifiable, Codable, Equatable {
    let id: UUID
    var portNumber: Int
    var scheduledTime: Date
    var actualTime: Date?
    var medications: [Medication]
    var keyMedicationId: Int?  // ID of the key medication for this port
    var status: DoseStatus

    // MARK: - Initialization

    init(id: UUID = UUID(), portNumber: Int, scheduledTime: Date, actualTime: Date? = nil, medications: [Medication] = [], keyMedicationId: Int? = nil, status: DoseStatus = .pending) {
        self.id = id
        self.portNumber = portNumber
        self.scheduledTime = scheduledTime
        self.actualTime = actualTime
        self.medications = medications
        self.keyMedicationId = keyMedicationId
        self.status = status
    }

    // MARK: - Medication Helpers

    /// The key medication for this port (if set)
    var keyMedication: Medication? {
        guard let keyId = keyMedicationId else { return nil }
        return medications.first { $0.id == keyId }
    }

    /// Companion medications (all medications except the key drug)
    var companionMedications: [Medication] {
        guard let keyId = keyMedicationId else { return medications }
        return medications.filter { $0.id != keyId }
    }

    // MARK: - Formatted Time Strings

    /// Scheduled time formatted as "8:00 AM"
    var scheduledTimeString: String {
        scheduledTime.formatted(date: .omitted, time: .shortened)
    }

    /// Actual time formatted as "8:03 AM" or nil if not taken
    var actualTimeString: String? {
        actualTime?.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - Timing Calculations

    /// Difference in minutes between scheduled and actual time
    /// Positive = late, Negative = early, nil = not taken
    var timingDifference: Int? {
        guard let actual = actualTime else { return nil }
        return Int(actual.timeIntervalSince(scheduledTime) / 60)
    }

    /// Timing accuracy as a decimal (1.0 = perfect, 0.5 = very poor)
    /// Uses weighted scoring based on clinical importance of timing
    var timingAccuracy: Double {
        guard let diff = timingDifference else { return 0 }
        let absDiff = abs(diff)

        // Weighted scoring algorithm:
        // Critical for Parkinson's patients to maintain consistent drug levels
        if absDiff <= 5 { return 1.0 }      // Perfect - optimal drug absorption
        if absDiff <= 10 { return 0.95 }    // Good - minimal impact
        if absDiff <= 20 { return 0.85 }    // Fair - some impact on symptom control
        if absDiff <= 30 { return 0.70 }    // Poor - noticeable impact
        return 0.50                          // Very Poor - significant impact, needs review
    }

    /// Category for display purposes
    var timingCategory: TimingCategory {
        guard let diff = timingDifference else { return .pending }
        let absDiff = abs(diff)

        if absDiff <= 5 { return .excellent }
        if absDiff <= 10 { return .good }
        if absDiff <= 20 { return .fair }
        return .poor
    }

    /// Whether this dose is overdue (past scheduled time and not taken)
    var isOverdue: Bool {
        status == .pending && scheduledTime < Date()
    }

    /// Whether this dose is upcoming (within next 30 minutes)
    var isUpcoming: Bool {
        guard status == .pending else { return false }
        let now = Date()
        let thirtyMinutesFromNow = now.addingTimeInterval(30 * 60)
        return scheduledTime > now && scheduledTime <= thirtyMinutesFromNow
    }
}

// MARK: - Dose Status

enum DoseStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case taken = "Taken"
    case missed = "Missed"

    var color: Color {
        switch self {
        case .pending: return .gray
        case .taken: return Color(hex: "#22c55e")
        case .missed: return Color(hex: "#eab308")
        }
    }
}

// MARK: - Timing Category

enum TimingCategory: String, CaseIterable {
    case pending = "Pending"
    case excellent = "Perfect"
    case good = "Good"
    case fair = "Fair"
    case poor = "Review"

    var color: Color {
        switch self {
        case .pending: return .gray
        case .excellent: return Color(hex: "#22c55e") // Bright green
        case .good: return Color(hex: "#16a34a")      // Dark green
        case .fair: return Color(hex: "#eab308")      // Amber
        case .poor: return Color(hex: "#c9a66b")      // Coral/gold (non-threatening)
        }
    }

    var icon: String {
        switch self {
        case .pending: return "circle"
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle.fill"
        case .fair: return "exclamationmark.circle.fill"
        case .poor: return "exclamationmark.triangle.fill"
        }
    }

    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        switch self {
        case .pending: return "Pending"
        case .excellent: return "Perfect timing, within 5 minutes"
        case .good: return "Good timing, within 10 minutes"
        case .fair: return "Fair timing, within 20 minutes"
        case .poor: return "Needs review, more than 20 minutes off schedule"
        }
    }
}
