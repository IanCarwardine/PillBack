// TimelineOnlyView.swift
// Focused timeline view mode with enlarged display

import SwiftUI

/// Full-screen focused timeline view
struct TimelineOnlyView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var selectedDose: Dose?

    var body: some View {
        VStack(spacing: 0) {
            // Header with accuracy score
            TimelineOnlyHeader()

            // NOW indicator
            NowIndicatorBanner()

            // Timeline
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.doses) { dose in
                            TimelineOnlyDoseCard(
                                dose: dose,
                                onTap: { selectedDose = dose }
                            )
                            .id(dose.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    if let nextDose = viewModel.nextDose {
                        withAnimation {
                            proxy.scrollTo(nextDose.id, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(viewModel.currentTheme.colors.bgPrimary)
        .sheet(item: $selectedDose) { dose in
            if dose.status == .taken {
                EditDoseSheet(dose: dose)
                    .environmentObject(viewModel)
            }
        }
    }
}

/// Header for timeline only mode showing overall accuracy
struct TimelineOnlyHeader: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text("Today's Timing")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            Text("\(viewModel.overallTimingAccuracy)%")
                .font(.system(size: 64, weight: .black))
                .foregroundColor(viewModel.currentTheme.colors.accent)

            Text("\(viewModel.dosesTakenToday) of 6 doses taken")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(viewModel.currentTheme.colors.bgCard)
    }
}

/// NOW indicator banner
struct NowIndicatorBanner: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(viewModel.currentTheme.colors.accent)

            Text("NOW")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(viewModel.currentTheme.colors.accent)

            Text(currentTime, style: .time)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Spacer()

            if let nextDose = viewModel.nextDose {
                Text("Next: Port \(nextDose.portNumber) at \(nextDose.scheduledTimeString)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(viewModel.currentTheme.colors.bgSecondary)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

/// Dose card for timeline only view
struct TimelineOnlyDoseCard: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let dose: Dose
    let onTap: () -> Void

    private var isNextDose: Bool {
        viewModel.nextDose?.id == dose.id
    }

    private var borderColor: Color {
        if isNextDose {
            return viewModel.currentTheme.colors.accent
        }
        switch dose.status {
        case .pending: return viewModel.currentTheme.colors.border
        case .taken: return dose.timingCategory.color
        case .missed: return Color(hex: "#eab308")
        }
    }

    var body: some View {
        Button(action: {
            if dose.status == .pending {
                viewModel.markDoseTaken(dose: dose)
            } else {
                onTap()
            }
        }) {
            HStack(spacing: 16) {
                // Large port indicator
                ZStack {
                    Circle()
                        .fill(dose.status == .taken ? dose.timingCategory.color : Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)

                    Text("\(dose.portNumber)")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                }

                // Time and status
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(dose.scheduledTimeString)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                        if isNextDose {
                            Text("NEXT")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(viewModel.currentTheme.colors.accent))
                        }
                    }

                    if dose.status == .taken {
                        HStack(spacing: 8) {
                            TimingBadge(category: dose.timingCategory)

                            if let diff = dose.timingDifference {
                                TimingDifferenceBadge(minutes: diff)
                            }
                        }
                    } else {
                        Text(dose.isOverdue ? "Overdue - Tap to take" : "Tap to mark as taken")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(dose.isOverdue ? Color(hex: "#eab308") : viewModel.currentTheme.colors.textMuted)
                    }
                }

                Spacer()

                // Action indicator
                if dose.status == .taken {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(dose.timingCategory.color)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 32))
                        .foregroundColor(viewModel.currentTheme.colors.border)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.currentTheme.colors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: isNextDose ? 3 : 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TimelineOnlyView()
        .environmentObject(PillBackViewModel())
}
