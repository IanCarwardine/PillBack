// ScheduleSetupView.swift
// Onboarding screen for setting up schedule - v0.4 Design

import SwiftUI

/// Screen for setting up schedule during onboarding
/// Wake/sleep times are read from previous screen (WakingHoursView)
struct ScheduleSetupView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics
    let onComplete: () -> Void
    let onBack: (() -> Void)?

    @State private var portCount: Int = 6
    @State private var previewDoses: [Dose] = []
    @State private var selectedDose: Dose?

    init(onComplete: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onBack = onBack
    }

    /// Format time from hour and minute
    private func formatTime(hour: Int, minute: Int) -> String {
        if viewModel.use24HourFormat {
            return String(format: "%02d:%02d", hour, minute)
        } else {
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
            return String(format: "%d:%02d %@", displayHour, minute, period)
        }
    }

    /// Wake time from schedule config
    private var wakeTimeString: String {
        formatTime(hour: viewModel.scheduleConfig.wakeHour, minute: viewModel.scheduleConfig.wakeMinute)
    }

    /// Sleep time from schedule config
    private var sleepTimeString: String {
        formatTime(hour: viewModel.scheduleConfig.sleepHour, minute: viewModel.scheduleConfig.sleepMinute)
    }

    /// Generate preview doses based on current settings
    private func generatePreviewDoses() {
        let calendar = Calendar.current
        let now = Date()

        let wakeTime = calendar.date(bySettingHour: viewModel.scheduleConfig.wakeHour,
                                      minute: viewModel.scheduleConfig.wakeMinute,
                                      second: 0, of: now) ?? now
        var sleepTime = calendar.date(bySettingHour: viewModel.scheduleConfig.sleepHour,
                                       minute: viewModel.scheduleConfig.sleepMinute,
                                       second: 0, of: now) ?? now

        // Handle overnight (sleep before wake)
        if sleepTime <= wakeTime {
            sleepTime = calendar.date(byAdding: .day, value: 1, to: sleepTime) ?? sleepTime
        }

        let totalMinutes = Int(sleepTime.timeIntervalSince(wakeTime) / 60)
        guard portCount > 0 else {
            previewDoses = []
            return
        }
        let interval = totalMinutes / portCount

        // Get medications
        let keyMedication = viewModel.medications.first { $0.isKeyDrug }
        let allMedications = viewModel.medications

        previewDoses = (0..<portCount).map { i in
            let doseTime = calendar.date(byAdding: .minute, value: interval * i, to: wakeTime) ?? wakeTime
            return Dose(
                portNumber: i + 1,
                scheduledTime: doseTime,
                actualTime: nil,
                medications: allMedications,
                keyMedicationId: keyMedication?.id,
                status: .pending
            )
        }

        // Sync to viewModel so PortSettingsSheet can save changes
        viewModel.doses = previewDoses
    }

    /// Format time for display
    private func formatDoseTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return formatTime(hour: hour, minute: minute)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Progress (step 6 of 6 after Welcome)
            OnboardingProgressView(currentStep: 6, totalSteps: 6)
                .padding(.top, 20)

            Spacer()

            // Title
            VStack(spacing: 12) {
                Text("Set Your Schedule")
                    .font(.system(size: metrics.titleSize, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text("We'll create a schedule based on your waking hours and how many ports you use")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Wake/Sleep times (read-only, from previous screen)
            HStack(spacing: 16) {
                // Wake time display
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#f59e0b"))
                        Text("Wake up")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    }

                    Text(wakeTimeString)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.currentTheme.colors.bgCard)
                )

                // Sleep time display
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#60a5fa"))
                        Text("Sleep")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    }

                    Text(sleepTimeString)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.currentTheme.colors.bgCard)
                )
            }
            .padding(.horizontal, 24)

            // Port count selector
            VStack(spacing: 12) {
                Text("How many ports do you use?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                HStack(spacing: 8) {
                    ForEach(1...6, id: \.self) { count in
                        Button(action: {
                            if portCount != count {
                                HapticManager.selectionChanged()
                                portCount = count
                            }
                        }) {
                            Text("\(count)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(portCount == count ? .black : viewModel.currentTheme.colors.textSecondary)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(portCount == count ? viewModel.currentTheme.colors.accent : viewModel.currentTheme.colors.bgElevated)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(count) ports")
                        .accessibilityAddTraits(portCount == count ? .isSelected : [])
                    }
                }
            }
            .padding(.horizontal, 24)

            // Schedule preview - tappable dose times
            VStack(spacing: 12) {
                HStack {
                    Text("Your Dose Times")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                    Spacer()

                    Text("Tap to edit")
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(portCount, 3)), spacing: 8) {
                    ForEach(previewDoses, id: \.portNumber) { dose in
                        Button(action: {
                            HapticManager.selectionChanged()
                            selectedDose = dose
                        }) {
                            VStack(spacing: 4) {
                                Text("\(dose.portNumber)")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(viewModel.currentTheme.colors.accent)

                                Text(formatDoseTime(dose.scheduledTime))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(viewModel.currentTheme.colors.bgElevated)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.currentTheme.colors.bgCard)
                )
                .animation(.easeInOut, value: portCount)
            }
            .padding(.horizontal, 24)

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

                // Finished button
                Button(action: createSchedule) {
                    HStack(spacing: 6) {
                        Text("Finished")
                            .font(.system(size: 16, weight: .semibold))
                        Image(systemName: "checkmark")
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
        .onAppear {
            generatePreviewDoses()
        }
        .onChange(of: portCount) { _, _ in
            generatePreviewDoses()
        }
        .sheet(item: $selectedDose) { dose in
            PortSettingsSheet(dose: dose)
                .environmentObject(viewModel)
                .onDisappear {
                    // Sync all doses back from viewModel after editing
                    previewDoses = viewModel.doses
                }
        }
    }

    private func createSchedule() {
        HapticManager.success()

        // Create Date objects from hour/minute
        let calendar = Calendar.current
        let now = Date()
        let wakeTime = calendar.date(bySettingHour: viewModel.scheduleConfig.wakeHour,
                                      minute: viewModel.scheduleConfig.wakeMinute,
                                      second: 0, of: now) ?? now
        let sleepTime = calendar.date(bySettingHour: viewModel.scheduleConfig.sleepHour,
                                       minute: viewModel.scheduleConfig.sleepMinute,
                                       second: 0, of: now) ?? now

        // Update schedule config
        let config = ScheduleConfig(
            startTime: wakeTime,
            endTime: sleepTime,
            strategy: .equalDistribution,
            keyDrugInterval: 150,
            portCount: portCount
        )
        viewModel.scheduleConfig = config

        // Save doses and config (doses were already synced via PortSettingsSheet edits)
        viewModel.saveDosesPublic()
        viewModel.saveScheduleConfigPublic()

        onComplete()
    }
}

// Safe array subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ScheduleSetupView(
        onComplete: { print("Complete") },
        onBack: { print("Back") }
    )
    .environmentObject(PillBackViewModel())
    .environment(\.metrics, ResponsiveMetrics())
}
