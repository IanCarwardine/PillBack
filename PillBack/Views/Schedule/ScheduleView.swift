// ScheduleView.swift
// Main schedule tab showing all doses with their status and timing

import SwiftUI

/// Main schedule view displaying all 6 doses
struct ScheduleView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var selectedDose: Dose?
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Next Dose Alert
                if let nextDose = viewModel.nextDose {
                    NextDoseAlertView(dose: nextDose)
                        .padding(.horizontal)
                }

                // Daily Progress
                DailyProgressView()
                    .padding(.horizontal)

                // Dose Cards
                ForEach(viewModel.doses) { dose in
                    DoseCardView(
                        dose: dose,
                        onTake: {
                            viewModel.markDoseTaken(dose: dose)
                        },
                        onEdit: {
                            selectedDose = dose
                            showingEditSheet = true
                        }
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(viewModel.currentTheme.colors.bgPrimary)
        .sheet(isPresented: $showingEditSheet) {
            if let dose = selectedDose {
                EditDoseSheet(dose: dose)
                    .environmentObject(viewModel)
            }
        }
    }
}

/// Alert banner for the next upcoming dose
struct NextDoseAlertView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let dose: Dose

    private var timeUntilDose: String {
        let interval = dose.scheduledTime.timeIntervalSince(Date())
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "now"
        } else if minutes < 60 {
            return "in \(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "in \(hours)h"
            }
            return "in \(hours)h \(remainingMinutes)m"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 20))
                .foregroundColor(viewModel.currentTheme.colors.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Next Dose: Port \(dose.portNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text("\(dose.scheduledTimeString) (\(timeUntilDose))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.currentTheme.colors.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next dose, Port \(dose.portNumber), \(timeUntilDose)")
    }
}

/// Daily progress indicator
struct DailyProgressView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    private var progressText: String {
        "\(viewModel.dosesTakenToday) of 6 doses taken"
    }

    private var progressPercentage: Double {
        Double(viewModel.dosesTakenToday) / 6.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                Spacer()

                Text(progressText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.currentTheme.colors.bgElevated)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(viewModel.currentTheme.colors.accent)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .animation(.easeInOut, value: progressPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
        .accessibilityLabel("\(progressText). \(Int(progressPercentage * 100)) percent complete")
    }
}

#Preview {
    ScheduleView()
        .environmentObject(PillBackViewModel())
}
