// HomeView.swift
// Main home tab with 6-port grid - v0.4 Design

import SwiftUI

/// Home view displaying today's doses in a 6-port grid layout
struct HomeView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics
    @State private var selectedDose: Dose?
    @State private var showingEditSheet = false

    private var takenCount: Int {
        viewModel.dosesTakenToday
    }

    private var totalCount: Int {
        viewModel.doses.count
    }

    private var nextDose: Dose? {
        viewModel.nextDose
    }

    private var keyDrug: Medication? {
        viewModel.medications.first { $0.isKeyDrug }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello, \(viewModel.userName)")
                        .font(.system(size: metrics.titleSize, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    Text("\(takenCount) of \(totalCount) taken today")
                        .font(.system(size: metrics.bodySize - 2))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 20)

                // Next Dose Card
                if let dose = nextDose {
                    NextDoseCard(dose: dose, onTap: {
                        viewModel.markDoseTaken(dose: dose)
                        StreakTracker.shared.updateStreaks(with: viewModel.doses)
                        HapticManager.success()
                    })
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.bottom, 24)
                }

                // Section header
                Text("Your PillBack")
                    .font(.system(size: metrics.bodySize - 2, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.bottom, 12)

                // 6-Port Grid (2x3)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(viewModel.doses) { dose in
                        PortGridCell(
                            dose: dose,
                            onTap: {
                                if dose.status == .pending {
                                    viewModel.markDoseTaken(dose: dose)
                                    StreakTracker.shared.updateStreaks(with: viewModel.doses)
                                    HapticManager.success()
                                }
                            },
                            onLongPress: {
                                selectedDose = dose
                                showingEditSheet = true
                            }
                        )
                    }
                }
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.bottom, 20)

                // Key Drug indicator
                if let drug = keyDrug {
                    KeyDrugIndicator(medication: drug)
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.bottom, 20)
                }
            }
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

// MARK: - Next Dose Card

private struct NextDoseCard: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let dose: Dose
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Dose")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(dose.portNumber)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(viewModel.currentTheme.colors.warning)

                        Text(dose.scheduledTimeString)
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                    }
                }

                Spacer()

                // Tap indicator
                VStack(spacing: 2) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.currentTheme.colors.warning)

                    Text("Tap")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.currentTheme.colors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.currentTheme.colors.warning.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Port Grid Cell

private struct PortGridCell: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let dose: Dose
    let onTap: () -> Void
    let onLongPress: () -> Void

    private var isTaken: Bool {
        dose.status == .taken
    }

    private var isPending: Bool {
        dose.status == .pending
    }

    private var isNext: Bool {
        isPending && viewModel.nextDose?.id == dose.id
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Port number
                Text("\(dose.portNumber)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(isTaken
                                     ? viewModel.currentTheme.colors.accent
                                     : viewModel.currentTheme.colors.warning)

                // Time
                Text(dose.scheduledTimeString)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                // Status indicator
                if isTaken {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                } else {
                    Circle()
                        .stroke(viewModel.currentTheme.colors.warning, lineWidth: 2)
                        .frame(width: 16, height: 16)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isTaken
                          ? viewModel.currentTheme.colors.accent.opacity(0.15)
                          : viewModel.currentTheme.colors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isTaken
                                    ? viewModel.currentTheme.colors.accent.opacity(0.5)
                                    : viewModel.currentTheme.colors.warning.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .onLongPressGesture {
            HapticManager.impact(.medium)
            onLongPress()
        }
    }
}

// MARK: - Key Drug Indicator

private struct KeyDrugIndicator: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let medication: Medication

    private var companionCount: Int {
        viewModel.medications.filter { !$0.isKeyDrug }.count
    }

    var body: some View {
        HStack {
            Image(systemName: "pills.fill")
                .font(.system(size: 16))
                .foregroundColor(viewModel.currentTheme.colors.warning)

            Text(medication.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Spacer()

            if companionCount > 0 {
                Text("+\(companionCount) more")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(PillBackViewModel())
        .environment(\.metrics, ResponsiveMetrics())
}
