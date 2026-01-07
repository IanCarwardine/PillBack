// WakingHoursView.swift
// Onboarding step for configuring wake and sleep times - v0.4 Design

import SwiftUI

/// Onboarding view for setting waking hours
/// Prevents notifications during sleep hours
struct WakingHoursView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics

    let onContinue: () -> Void
    let onBack: (() -> Void)?

    @State private var wakeHour: Int = 7
    @State private var wakeMinute: Int = 0
    @State private var sleepHour: Int = 22
    @State private var sleepMinute: Int = 0
    @State private var use24HourFormat: Bool = true
    @State private var showingWakePicker = false
    @State private var showingSleepPicker = false

    init(onContinue: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self.onContinue = onContinue
        self.onBack = onBack
    }

    private var wakingHoursDescription: String {
        let wakeMinutes = wakeHour * 60 + wakeMinute
        var sleepMinutes = sleepHour * 60 + sleepMinute
        if sleepMinutes <= wakeMinutes {
            sleepMinutes += 24 * 60
        }
        let totalMinutes = sleepMinutes - wakeMinutes
        let hours = totalMinutes / 60
        return "Waking hours: ~\(hours) hours"
    }

    private func formatTime(hour: Int, minute: Int) -> String {
        if use24HourFormat {
            return String(format: "%02d:%02d", hour, minute)
        } else {
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return String(format: "%d:%02d %@", displayHour, minute, period)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress (step 3 of 6 after Welcome)
            OnboardingProgressView(currentStep: 3, totalSteps: 6)
                .padding(.top, 20)

            Spacer()

            // Sunrise icon
            Image(systemName: "sun.and.horizon.fill")
                .font(.system(size: 56))
                .foregroundColor(viewModel.currentTheme.colors.accent)
                .padding(.bottom, 24)

            // Personalized greeting
            Text("Hi \(viewModel.userName)!")
                .font(.system(size: metrics.titleSize, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                .padding(.bottom, 8)

            // Subtitle
            Text("When are you typically awake?")
                .font(.system(size: metrics.bodySize))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                .padding(.bottom, 32)

            // Time rows
            VStack(spacing: 12) {
                // Wake up row
                TimeRowButton(
                    icon: "sunrise.fill",
                    iconColor: Color(hex: "#f59e0b"),
                    label: "Wake up",
                    time: formatTime(hour: wakeHour, minute: wakeMinute),
                    action: { showingWakePicker = true }
                )

                // Sleep row
                TimeRowButton(
                    icon: "moon.fill",
                    iconColor: Color(hex: "#60a5fa"),
                    label: "Sleep",
                    time: formatTime(hour: sleepHour, minute: sleepMinute),
                    action: { showingSleepPicker = true }
                )

                // 24-hour format toggle
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 18))
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                        .frame(width: 28)

                    Text("Use 24-hour format")
                        .font(.system(size: 16))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    Spacer()

                    Toggle("", isOn: $use24HourFormat)
                        .labelsHidden()
                        .tint(viewModel.currentTheme.colors.accent)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.currentTheme.colors.bgCard)
                )
            }
            .padding(.horizontal, metrics.horizontalPadding)

            // Waking hours summary
            Text(wakingHoursDescription)
                .font(.system(size: 14))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
                .padding(.top, 16)

            // Info text
            Text("We'll only send reminders during these hours.")
                .font(.system(size: 14))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
                .padding(.top, 8)

            Spacer()

            // Navigation buttons
            HStack(spacing: 16) {
                // Back button
                if let onBack = onBack {
                    Button(action: {
                        HapticManager.selectionChanged()
                        onBack()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.currentTheme.colors.bgElevated)
                        )
                    }
                    .frame(width: 120)
                }

                // Continue button
                Button(action: saveAndContinue) {
                    HStack(spacing: 6) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.currentTheme.colors.accent)
                    )
                }
            }
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.bottom, 50)
        }
        .sheet(isPresented: $showingWakePicker) {
            TimePickerSheet(
                title: "Set Wake up",
                hour: $wakeHour,
                minute: $sleepMinute,
                use24Hour: use24HourFormat
            )
            .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingSleepPicker) {
            TimePickerSheet(
                title: "Set Sleep",
                hour: $sleepHour,
                minute: $sleepMinute,
                use24Hour: use24HourFormat
            )
            .environmentObject(viewModel)
        }
        .onAppear {
            loadCurrentSettings()
        }
    }

    private func loadCurrentSettings() {
        wakeHour = viewModel.scheduleConfig.wakeHour
        wakeMinute = viewModel.scheduleConfig.wakeMinute
        sleepHour = viewModel.scheduleConfig.sleepHour
        sleepMinute = viewModel.scheduleConfig.sleepMinute
    }

    private func saveAndContinue() {
        HapticManager.impact(.medium)
        viewModel.scheduleConfig.wakeHour = wakeHour
        viewModel.scheduleConfig.wakeMinute = wakeMinute
        viewModel.scheduleConfig.sleepHour = sleepHour
        viewModel.scheduleConfig.sleepMinute = sleepMinute
        onContinue()
    }
}

// MARK: - Time Row Button

private struct TimeRowButton: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    let icon: String
    let iconColor: Color
    let label: String
    let time: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Spacer()

                Text(time)
                    .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    .foregroundColor(viewModel.currentTheme.colors.accent)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.currentTheme.colors.bgCard)
            )
        }
    }
}

// MARK: - Time Picker Sheet

private struct TimePickerSheet: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.dismiss) var dismiss

    let title: String
    @Binding var hour: Int
    @Binding var minute: Int
    let use24Hour: Bool

    @State private var selectedHour: Int = 7
    @State private var selectedMinute: Int = 0
    @State private var selectedPeriod: String = "AM"

    private var displayTime: String {
        if use24Hour {
            return String(format: "%02d:%02d", selectedHour, selectedMinute)
        } else {
            return String(format: "%d:%02d %@", selectedHour == 0 ? 12 : selectedHour, selectedMinute, selectedPeriod)
        }
    }

    /// Determine if current theme uses dark background (needs light text in pickers)
    private var isDarkTheme: Bool {
        viewModel.currentTheme != .daylight
    }

    var body: some View {
        NavigationView {
            ZStack {
                viewModel.currentTheme.colors.bgPrimary.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                        .padding(.top, 20)

                    // Time preview
                    Text(displayTime)
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                        .padding(.vertical, 20)

                    // Picker wheels - force color scheme for readable text
                    if use24Hour {
                        HStack(spacing: 0) {
                            Picker("Hour", selection: $selectedHour) {
                                ForEach(0..<24, id: \.self) { h in
                                    Text(String(format: "%02d", h))
                                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                                        .tag(h)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            .colorScheme(isDarkTheme ? .dark : .light)

                            Text(":")
                                .font(.title)
                                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                            Picker("Minute", selection: $selectedMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { m in
                                    Text(String(format: "%02d", m))
                                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                                        .tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            .colorScheme(isDarkTheme ? .dark : .light)
                        }
                        .frame(height: 150)
                    } else {
                        HStack(spacing: 0) {
                            Picker("Hour", selection: $selectedHour) {
                                ForEach(1...12, id: \.self) { h in
                                    Text("\(h)")
                                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                                        .tag(h)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            .colorScheme(isDarkTheme ? .dark : .light)

                            Text(":")
                                .font(.title)
                                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                            Picker("Minute", selection: $selectedMinute) {
                                ForEach([0, 15, 30, 45], id: \.self) { m in
                                    Text(String(format: "%02d", m))
                                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                                        .tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            .colorScheme(isDarkTheme ? .dark : .light)

                            Picker("Period", selection: $selectedPeriod) {
                                Text("AM")
                                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                                    .tag("AM")
                                Text("PM")
                                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                                    .tag("PM")
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 70)
                            .colorScheme(isDarkTheme ? .dark : .light)
                        }
                        .frame(height: 150)
                    }

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applySelection()
                        dismiss()
                    }
                    .foregroundColor(viewModel.currentTheme.colors.accent)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                initializeFromBinding()
            }
        }
        .presentationDetents([.medium])
    }

    private func initializeFromBinding() {
        if use24Hour {
            selectedHour = hour
            selectedMinute = minute
        } else {
            selectedMinute = minute
            selectedPeriod = hour >= 12 ? "PM" : "AM"
            if hour == 0 {
                selectedHour = 12
            } else if hour > 12 {
                selectedHour = hour - 12
            } else {
                selectedHour = hour
            }
        }
    }

    private func applySelection() {
        minute = selectedMinute
        if use24Hour {
            hour = selectedHour
        } else {
            if selectedPeriod == "AM" {
                hour = selectedHour == 12 ? 0 : selectedHour
            } else {
                hour = selectedHour == 12 ? 12 : selectedHour + 12
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WakingHoursView(
            onContinue: { print("Continue tapped") },
            onBack: { print("Back tapped") }
        )
    }
    .environmentObject(PillBackViewModel())
    .environment(\.metrics, ResponsiveMetrics())
}
