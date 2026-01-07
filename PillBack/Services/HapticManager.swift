// HapticManager.swift
// Centralized haptic feedback management

import UIKit

/// Centralized manager for haptic feedback throughout the app
enum HapticManager {

    // MARK: - Feedback Generators

    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selection = UISelectionFeedbackGenerator()

    // MARK: - Prepare (for low latency)

    /// Prepare haptic engine for immediate feedback
    static func prepare() {
        impactMedium.prepare()
        notification.prepare()
    }

    // MARK: - Impact Feedback

    /// Impact with specified style
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactLight.impactOccurred()
        case .rigid:
            impactHeavy.impactOccurred()
        @unknown default:
            impactMedium.impactOccurred()
        }
    }

    /// Light impact - for subtle UI interactions
    static func lightImpact() {
        impactLight.impactOccurred()
    }

    /// Medium impact - for standard interactions
    static func mediumImpact() {
        impactMedium.impactOccurred()
    }

    /// Heavy impact - for significant actions
    static func heavyImpact() {
        impactHeavy.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Success feedback - for completed actions like taking a dose
    static func success() {
        notification.notificationOccurred(.success)
    }

    /// Warning feedback - for caution states
    static func warning() {
        notification.notificationOccurred(.warning)
    }

    /// Error feedback - for failed actions
    static func error() {
        notification.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Selection feedback - for picker/toggle changes
    static func selectionChanged() {
        selection.selectionChanged()
    }

    // MARK: - App-Specific Haptics

    /// Dose taken - celebratory success feedback
    static func doseTaken() {
        notification.notificationOccurred(.success)
    }

    /// Dose missed - warning feedback
    static func doseMissed() {
        notification.notificationOccurred(.warning)
    }

    /// Tab changed - light selection feedback
    static func tabChanged() {
        selection.selectionChanged()
    }

    /// Button tapped - light impact
    static func buttonTap() {
        impactLight.impactOccurred()
    }

    /// Port selected - medium impact
    static func portSelected() {
        impactMedium.impactOccurred()
    }

    /// Streak achieved - heavy celebratory impact
    static func streakAchieved() {
        impactHeavy.impactOccurred()
    }

    /// Theme changed - medium impact
    static func themeChanged() {
        impactMedium.impactOccurred()
    }

    /// Onboarding step completed - light success
    static func onboardingStep() {
        impactLight.impactOccurred()
    }

    /// Schedule regenerated - medium impact with success
    static func scheduleRegenerated() {
        impactMedium.impactOccurred()
    }
}
