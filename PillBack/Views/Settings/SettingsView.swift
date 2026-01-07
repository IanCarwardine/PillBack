// SettingsView.swift
// Settings tab for configuring app preferences - v0.4 Design

import SwiftUI

/// Settings view for app configuration - v0.4 Design
struct SettingsView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics
    @State private var showingResetConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("Settings")
                    .font(.system(size: metrics.titleSize, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)

                // Notifications Section
                NotificationsSettingsSection()

                // Display Section
                SettingsSectionV4(title: "DISPLAY") {
                    // Theme row
                    ThemePickerRow()

                    Divider()
                        .background(viewModel.currentTheme.colors.border)

                    // 24-hour time toggle
                    ToggleRowWithAction(
                        icon: "clock",
                        title: "24-hour time",
                        isOn: viewModel.use24HourFormat,
                        onChange: { viewModel.set24HourFormat($0) }
                    )
                }

                // Accessibility Section
                SettingsSectionV4(title: "ACCESSIBILITY") {
                    // Easy Mode toggle
                    ToggleRowWithAction(
                        icon: "hand.tap",
                        title: "Easy Mode",
                        isOn: viewModel.easyModeEnabled,
                        onChange: { viewModel.setEasyMode($0) }
                    )

                    Divider()
                        .background(viewModel.currentTheme.colors.border)

                    // Haptic Feedback toggle
                    ToggleRowWithAction(
                        icon: "waveform",
                        title: "Haptic Feedback",
                        isOn: viewModel.hapticFeedbackEnabled,
                        onChange: { viewModel.setHapticFeedback($0) }
                    )

                    Divider()
                        .background(viewModel.currentTheme.colors.border)

                    // Confirmation Sound
                    SoundPickerRow()
                }

                // Version Section
                SettingsSectionV4(title: nil) {
                    HStack {
                        Text("Version")
                            .font(.system(size: 16))
                            .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                        Spacer()
                        Text("0.4")
                            .font(.system(size: 16))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    }

                    Divider()
                        .background(viewModel.currentTheme.colors.border)

                    Button(action: { showingResetConfirmation = true }) {
                        Text("Reset App")
                            .font(.system(size: 16))
                            .foregroundColor(viewModel.currentTheme.colors.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Footer
                Text("© 2025 Eurekaport Inc.")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, metrics.horizontalPadding)
        }
        .background(viewModel.currentTheme.colors.bgPrimary)
        .confirmationDialog(
            "Reset All Data?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                viewModel.resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all medications, port schedule, and preferences. This action cannot be undone.")
        }
    }
}

// MARK: - Notifications Settings Section

private struct NotificationsSettingsSection: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Notification options with checkmarks
            VStack(alignment: .leading, spacing: 8) {
                NotificationOptionRow(icon: "clock", text: "1 min before each dose")
                NotificationOptionRow(icon: "bell", text: "At scheduled time")
                NotificationOptionRow(icon: "arrow.clockwise", text: "Follow-up after 5 min")
            }
            .padding(.horizontal, 16)

            // Update Notifications button
            Button(action: {
                HapticManager.impact(.medium)
                // TODO: Request notification permissions
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                    Text("Update Notifications")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(viewModel.currentTheme.colors.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .stroke(viewModel.currentTheme.colors.accent, lineWidth: 1)
                )
            }

            // Status text
            Text("18 notifications scheduled")
                .font(.system(size: 12))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
        }
        .padding(.vertical, 16)
    }
}

private struct NotificationOptionRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
        }
    }
}

// MARK: - Section Container

private struct SettingsSectionV4<Content: View>: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let title: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
            }

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.currentTheme.colors.bgCard)
            )
        }
    }
}

// MARK: - Theme Picker Row

private struct ThemePickerRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        HStack {
            Text("Theme")
                .font(.system(size: 16))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Spacer()

            Menu {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button(action: { viewModel.setTheme(theme) }) {
                        HStack {
                            Text(theme.rawValue)
                            if viewModel.currentTheme == theme {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.currentTheme.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(viewModel.currentTheme.colors.bgElevated)
                )
            }
        }
    }
}

// MARK: - Toggle Row With Action

private struct ToggleRowWithAction: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let icon: String
    let title: String
    let isOn: Bool
    let onChange: (Bool) -> Void

    @State private var localIsOn: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Spacer()

            Toggle("", isOn: $localIsOn)
                .labelsHidden()
                .tint(viewModel.currentTheme.colors.accent)
                .onChange(of: localIsOn) { _, newValue in
                    onChange(newValue)
                }
        }
        .onAppear {
            localIsOn = isOn
        }
    }
}

// MARK: - Sound Picker Row

private struct SoundPickerRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var selectedSound: ConfirmationSound = .gentle

    var body: some View {
        HStack {
            Image(systemName: "speaker.wave.2")
                .font(.system(size: 16))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
                .frame(width: 24)

            Text("Confirmation Sound")
                .font(.system(size: 16))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Spacer()

            Menu {
                ForEach(ConfirmationSound.allCases, id: \.self) { sound in
                    Button(action: {
                        selectedSound = sound
                        AudioFeedbackService.shared.configure(sound: sound)
                        AudioFeedbackService.shared.playSound(sound)
                    }) {
                        HStack {
                            Text(sound.rawValue)
                            if selectedSound == sound {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedSound.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(viewModel.currentTheme.colors.bgElevated)
                )
            }
        }
        .onAppear {
            selectedSound = AudioFeedbackService.shared.currentSound
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(PillBackViewModel())
        .environment(\.metrics, ResponsiveMetrics())
}
