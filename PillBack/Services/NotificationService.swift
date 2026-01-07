// NotificationService.swift
// Notification service for dose reminders with cascade alerts

import Foundation
import UserNotifications
import UIKit

/// Service for managing dose notification scheduling and cascade alerts
/// Implements the v2.0 notification system: 1-min warning → DUE → 5-min escalation → 20-min timeout
@MainActor
class NotificationService: ObservableObject {

    // MARK: - Singleton

    static let shared = NotificationService()

    // MARK: - Published Properties

    @Published var isAuthorized = false
    @Published var pendingNotifications: [String] = []

    // MARK: - Constants

    private enum NotificationType: String {
        case warning = "warn"       // 1 minute before
        case due = "due"            // At scheduled time
        case escalation = "esc"     // 5 minutes after
        case timeout = "timeout"    // 20 minutes after

        var title: String {
            switch self {
            case .warning: return "Upcoming Dose"
            case .due: return "Dose Due Now"
            case .escalation: return "Reminder"
            case .timeout: return "Dose Window Closing"
            }
        }

        var sound: UNNotificationSound {
            switch self {
            case .warning: return .default
            case .due: return .defaultCritical
            case .escalation: return .default
            case .timeout: return .defaultCritical
            }
        }
    }

    // MARK: - Notification Category

    private let categoryIdentifier = "DOSE_REMINDER"
    private let markTakenActionIdentifier = "MARK_TAKEN"
    private let snoozeActionIdentifier = "SNOOZE"

    // MARK: - Initialization

    private init() {
        setupNotificationCategories()
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Setup

    private func setupNotificationCategories() {
        let markTakenAction = UNNotificationAction(
            identifier: markTakenActionIdentifier,
            title: "Mark as Taken",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: snoozeActionIdentifier,
            title: "Snooze 5 min",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [markTakenAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    // MARK: - Authorization

    /// Request notification permissions from the user
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge, .provisional])

            await MainActor.run {
                self.isAuthorized = granted
            }

            return granted
        } catch {
            print("NotificationService: Permission request failed - \(error.localizedDescription)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized ||
                               settings.authorizationStatus == .provisional
        }
    }

    // MARK: - Cascade Scheduling

    /// Schedule the full notification cascade for a dose
    /// - Parameters:
    ///   - dose: The dose to schedule notifications for
    ///   - medications: Medications in this dose (for display)
    func scheduleNotificationCascade(for dose: Dose, medications: [Medication] = []) {
        let doseId = dose.id.uuidString
        let portNumber = dose.portNumber
        let scheduledTime = dose.scheduledTime

        // Build medication list string
        let medNames = medications.isEmpty
            ? "your medications"
            : medications.map { $0.name }.joined(separator: ", ")

        // 1. Warning notification: 1 minute before
        scheduleNotification(
            id: "\(doseId)-\(NotificationType.warning.rawValue)",
            type: .warning,
            body: "Port \(portNumber) due in 1 minute",
            subtitle: medNames,
            triggerDate: scheduledTime.addingTimeInterval(-60),
            portNumber: portNumber
        )

        // 2. DUE notification: At scheduled time
        scheduleNotification(
            id: "\(doseId)-\(NotificationType.due.rawValue)",
            type: .due,
            body: "Take Port \(portNumber) now",
            subtitle: medNames,
            triggerDate: scheduledTime,
            portNumber: portNumber
        )

        // 3. Escalation notification: 5 minutes after
        scheduleNotification(
            id: "\(doseId)-\(NotificationType.escalation.rawValue)",
            type: .escalation,
            body: "Port \(portNumber) is still pending",
            subtitle: "Tap to mark as taken",
            triggerDate: scheduledTime.addingTimeInterval(5 * 60),
            portNumber: portNumber
        )

        // 4. Timeout notification: 20 minutes after
        scheduleNotification(
            id: "\(doseId)-\(NotificationType.timeout.rawValue)",
            type: .timeout,
            body: "Port \(portNumber) window closing soon",
            subtitle: "Will be marked as missed",
            triggerDate: scheduledTime.addingTimeInterval(20 * 60),
            portNumber: portNumber
        )

        print("NotificationService: Scheduled cascade for Port \(portNumber) at \(scheduledTime)")
    }

    /// Schedule a single notification
    private func scheduleNotification(
        id: String,
        type: NotificationType,
        body: String,
        subtitle: String?,
        triggerDate: Date,
        portNumber: Int
    ) {
        // Don't schedule notifications in the past
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = body
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        content.sound = type.sound
        content.badge = 1
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = [
            "doseId": id.components(separatedBy: "-").first ?? id,
            "portNumber": portNumber,
            "notificationType": type.rawValue
        ]

        // Create trigger from date
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotificationService: Failed to schedule \(type.rawValue) - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Cancellation

    /// Cancel all notifications for a specific dose
    /// - Parameter doseId: The UUID of the dose
    func cancelNotifications(for doseId: UUID) {
        let idPrefix = doseId.uuidString
        let identifiers = [
            "\(idPrefix)-\(NotificationType.warning.rawValue)",
            "\(idPrefix)-\(NotificationType.due.rawValue)",
            "\(idPrefix)-\(NotificationType.escalation.rawValue)",
            "\(idPrefix)-\(NotificationType.timeout.rawValue)"
        ]

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)

        print("NotificationService: Cancelled notifications for dose \(doseId)")
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        clearBadge()

        print("NotificationService: Cancelled all notifications")
    }

    // MARK: - Scheduling for Multiple Doses

    /// Schedule notifications for all pending doses
    /// - Parameters:
    ///   - doses: Array of doses to schedule
    ///   - medications: All medications (to match to doses)
    func scheduleAllDoseNotifications(doses: [Dose], medications: [Medication]) {
        // Cancel existing notifications first
        cancelAllNotifications()

        // Schedule for each pending dose
        for dose in doses where dose.status == .pending {
            let doseMedications = medications.filter { $0.isInPort(dose.portNumber) }
            scheduleNotificationCascade(for: dose, medications: doseMedications)
        }

        print("NotificationService: Scheduled notifications for \(doses.filter { $0.status == .pending }.count) doses")
    }

    // MARK: - Action Handling

    /// Handle notification action response
    /// - Parameter response: The notification response
    /// - Returns: Tuple of (doseId, action) if valid, nil otherwise
    func handleNotificationAction(_ response: UNNotificationResponse) -> (doseId: String, action: NotificationAction)? {
        let userInfo = response.notification.request.content.userInfo

        guard let doseId = userInfo["doseId"] as? String else {
            return nil
        }

        switch response.actionIdentifier {
        case markTakenActionIdentifier:
            return (doseId, .markTaken)
        case snoozeActionIdentifier:
            return (doseId, .snooze)
        case UNNotificationDefaultActionIdentifier:
            return (doseId, .opened)
        case UNNotificationDismissActionIdentifier:
            return (doseId, .dismissed)
        default:
            return nil
        }
    }

    /// Schedule a snooze notification (5 minutes from now)
    func scheduleSnooze(for doseId: UUID, portNumber: Int) {
        let snoozeTime = Date().addingTimeInterval(5 * 60)

        scheduleNotification(
            id: "\(doseId.uuidString)-snooze",
            type: .escalation,
            body: "Snoozed reminder: Port \(portNumber)",
            subtitle: "Tap to mark as taken",
            triggerDate: snoozeTime,
            portNumber: portNumber
        )

        print("NotificationService: Scheduled snooze for Port \(portNumber)")
    }

    // MARK: - Badge Management

    /// Update the app badge count
    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                print("NotificationService: Failed to set badge count: \(error)")
            }
        }
    }

    /// Clear the app badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("NotificationService: Failed to clear badge: \(error)")
            }
        }
    }

    // MARK: - Pending Notifications

    /// Get all pending notification identifiers
    func getPendingNotifications() async -> [String] {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.map { $0.identifier }
    }
}

// MARK: - Notification Action Enum

enum NotificationAction {
    case markTaken
    case snooze
    case opened
    case dismissed
}
