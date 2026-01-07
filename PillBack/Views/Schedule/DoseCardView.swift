// DoseCardView.swift
// Individual dose card showing port, time, medications, and status

import SwiftUI

/// Card view for a single dose
struct DoseCardView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let dose: Dose
    let onTake: () -> Void
    let onEdit: () -> Void

    @State private var isExpanded = false

    private var statusColor: Color {
        switch dose.status {
        case .pending:
            return dose.isOverdue ? Color(hex: "#eab308") : viewModel.currentTheme.colors.border
        case .taken:
            return dose.timingCategory.color
        case .missed:
            return Color(hex: "#eab308")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button(action: {
                HapticManager.lightImpact()
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Port indicator
                    PortIndicator(portNumber: dose.portNumber, status: dose.status)

                    // Time and status
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(dose.scheduledTimeString)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                            if dose.status == .taken, let diff = dose.timingDifference {
                                TimingDifferenceBadge(minutes: diff)
                            }

                            if dose.isOverdue {
                                Text("OVERDUE")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(hex: "#eab308")))
                            }
                        }

                        Text("\(dose.medications.count) medication\(dose.medications.count == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    }

                    Spacer()

                    // Status badge or action button
                    if dose.status == .taken {
                        TimingBadge(category: dose.timingCategory)
                    } else if dose.status == .missed {
                        Text("Missed")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "#eab308"))
                    } else {
                        // Take button
                        Button(action: {
                            HapticManager.doseTaken()
                            onTake()
                        }) {
                            Text("Take")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(viewModel.currentTheme.colors.accent)
                                )
                        }
                        .accessibilityLabel("Mark Port \(dose.portNumber) dose as taken")
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(viewModel.currentTheme.colors.border)

                    // Medications list
                    ForEach(dose.medications, id: \.id) { medication in
                        MedicationRow(medication: medication)
                    }

                    // Taken dose info
                    if dose.status == .taken {
                        HStack {
                            Text("Taken at: \(dose.actualTimeString ?? "")")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                            Spacer()

                            Button(action: onEdit) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pencil")
                                    Text("Edit")
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(viewModel.currentTheme.colors.accent)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(statusColor, lineWidth: dose.status == .pending ? 1 : 2)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Port \(dose.portNumber), scheduled for \(dose.scheduledTimeString), \(dose.status.rawValue)")
    }
}

/// Port number indicator circle
struct PortIndicator: View {
    let portNumber: Int
    let status: DoseStatus

    private var backgroundColor: Color {
        switch status {
        case .pending: return Color.gray.opacity(0.3)
        case .taken: return Color(hex: "#22c55e")
        case .missed: return Color(hex: "#eab308")
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 44, height: 44)

            Text("\(portNumber)")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.white)
        }
        .accessibilityLabel("Port \(portNumber)")
    }
}

/// Medication row in expanded card
struct MedicationRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let medication: Medication

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: medication.isKeyDrug ? "star.fill" : "pill.fill")
                .font(.system(size: 12))
                .foregroundColor(medication.isKeyDrug ? Color(hex: "#eab308") : viewModel.currentTheme.colors.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                if !medication.notes.isEmpty {
                    Text(medication.notes)
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
            }

            Spacer()

            if medication.isKeyDrug {
                Text("KEY")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(hex: "#eab308"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .stroke(Color(hex: "#eab308"), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Pending dose
            DoseCardView(
                dose: Dose(portNumber: 1, scheduledTime: Date().addingTimeInterval(3600), medications: Medication.defaults.filter { $0.isInPort(1) }),
                onTake: {},
                onEdit: {}
            )

            // Taken dose - perfect
            DoseCardView(
                dose: Dose(portNumber: 2, scheduledTime: Date().addingTimeInterval(-7200), actualTime: Date().addingTimeInterval(-7200 + 180), medications: Medication.defaults.filter { $0.isInPort(2) }, status: .taken),
                onTake: {},
                onEdit: {}
            )
        }
        .padding()
    }
    .background(Color.black)
    .environmentObject(PillBackViewModel())
}
