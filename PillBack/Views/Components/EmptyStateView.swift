// EmptyStateView.swift
// Reusable empty state component for views without data

import SwiftUI

/// Reusable empty state view with icon, title, and description
struct EmptyStateView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.buttonTap()
                    action()
                }) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(viewModel.currentTheme.colors.accent)
                        )
                }
            }
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// Empty state for no doses scheduled
    static func noDoses(action: @escaping () -> Void) -> some View {
        EmptyStateView(
            icon: "calendar.badge.exclamationmark",
            title: "No Doses Scheduled",
            description: "Set up your schedule to start tracking your medication doses.",
            actionTitle: "Set Up Schedule",
            action: action
        )
    }

    /// Empty state for history with no records
    static var noHistory: some View {
        EmptyStateView(
            icon: "clock.badge.questionmark",
            title: "No History Yet",
            description: "Your dose history will appear here as you track your medications."
        )
    }

    /// Empty state for no medications configured
    static func noMedications(action: @escaping () -> Void) -> some View {
        EmptyStateView(
            icon: "pill",
            title: "No Medications",
            description: "Add your medications to see them in your dose schedule.",
            actionTitle: "Add Medication",
            action: action
        )
    }

    /// Empty state for no streak data
    static var noStreakData: some View {
        EmptyStateView(
            icon: "flame",
            title: "Start Your Streak",
            description: "Complete all your doses today to start building your adherence streak."
        )
    }

    /// Empty state for export with no data
    static var noExportData: some View {
        EmptyStateView(
            icon: "square.and.arrow.up",
            title: "No Data to Export",
            description: "Start tracking your doses to generate exportable reports."
        )
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            EmptyStateView.noDoses {}
            EmptyStateView.noHistory
            EmptyStateView.noMedications {}
        }
        .padding()
    }
    .background(Color.black)
    .environmentObject(PillBackViewModel())
}
