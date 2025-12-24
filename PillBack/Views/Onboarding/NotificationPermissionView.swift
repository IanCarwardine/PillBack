// NotificationPermissionView.swift
// Onboarding screen for requesting notification permissions

import SwiftUI
import UserNotifications

/// Screen for requesting notification permissions during onboarding
struct NotificationPermissionView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let onContinue: () -> Void

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(viewModel.currentTheme.colors.bgCard)
                    .frame(width: 120, height: 120)

                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 56))
                    .foregroundColor(viewModel.currentTheme.colors.accent)
            }

            // Title and description
            VStack(spacing: 16) {
                Text("Stay on Track")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text("Get timely reminders before each dose to help maintain consistent medication timing.")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Notification preview
            NotificationPreview()
                .padding(.horizontal, 24)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button(action: requestPermission) {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "bell.fill")
                            Text("Enable Notifications")
                        }
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(viewModel.currentTheme.colors.accent)
                    )
                }
                .disabled(isRequesting)

                Button(action: onContinue) {
                    Text("Maybe Later")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    private func requestPermission() {
        isRequesting = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                isRequesting = false
                onContinue()
            }
        }
    }
}

/// Preview of what notifications look like
struct NotificationPreview: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "pill.fill")
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.currentTheme.colors.accent)

                Text("PillBack")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                Spacer()

                Text("now")
                    .font(.system(size: 11))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
            }

            Text("Dose Due: Port 2")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Text("Time to take your 10:30 AM dose")
                .font(.system(size: 13))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
    }
}

#Preview {
    NotificationPermissionView(onContinue: {})
        .environmentObject(PillBackViewModel())
}
