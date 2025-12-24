// ScheduleSetupView.swift
// Onboarding screen for setting up wake/sleep times

import SwiftUI

/// Screen for setting up schedule during onboarding
struct ScheduleSetupView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let onComplete: () -> Void

    @State private var wakeTime: Date
    @State private var sleepTime: Date

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete

        let calendar = Calendar.current
        let now = Date()
        _wakeTime = State(initialValue: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now)
        _sleepTime = State(initialValue: calendar.date(bySettingHour: 20, minute: 30, second: 0, of: now) ?? now)
    }

    private var schedulePreview: [String] {
        let calendar = Calendar.current
        let totalMinutes = Int(sleepTime.timeIntervalSince(wakeTime) / 60)
        let interval = totalMinutes / 6

        return (0..<6).compactMap { i in
            let offset = interval * i
            if let time = calendar.date(byAdding: .minute, value: offset, to: wakeTime) {
                return time.formatted(date: .omitted, time: .shortened)
            }
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Title
            VStack(spacing: 12) {
                Text("Set Your Schedule")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text("We'll create a 6-dose schedule based on when you wake up and go to sleep")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // Time pickers
            VStack(spacing: 24) {
                // Wake time
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sunrise.fill")
                            .foregroundColor(Color(hex: "#eab308"))
                        Text("I wake up around")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    }

                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 100)
                }

                // Sleep time
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(Color(hex: "#6366f1"))
                        Text("I go to sleep around")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    }

                    DatePicker("", selection: $sleepTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 100)
                }
            }
            .padding(.horizontal, 24)

            // Schedule preview
            VStack(spacing: 12) {
                Text("Your Dose Times")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                HStack(spacing: 0) {
                    ForEach(0..<6) { i in
                        VStack(spacing: 4) {
                            Text("Port \(i + 1)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(viewModel.currentTheme.colors.textMuted)

                            Text(schedulePreview[safe: i] ?? "--")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.currentTheme.colors.bgCard)
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Complete button
            Button(action: createSchedule) {
                Text("Create My Schedule")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(viewModel.currentTheme.colors.accent)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    private func createSchedule() {
        let config = ScheduleConfig(
            startTime: wakeTime,
            endTime: sleepTime,
            strategy: .equalDistribution,
            keyDrugInterval: 150
        )
        viewModel.updateScheduleConfig(config)
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
    ScheduleSetupView(onComplete: {})
        .environmentObject(PillBackViewModel())
}
