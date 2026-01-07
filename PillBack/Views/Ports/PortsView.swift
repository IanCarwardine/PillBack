// PortsView.swift
// Full-screen view of the 6-port pill organizer

import SwiftUI

/// Ports tab showing visual representation of the pill organizer
struct PortsView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics

    @State private var selectedDoseForSettings: Dose?

    private var portCount: Int {
        viewModel.doses.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: metrics.sectionSpacing) {
                // Header
                PortsHeader()

                if viewModel.doses.isEmpty {
                    // Empty state
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "No Ports Configured",
                        description: "Set up your schedule to see your pill organizer ports here."
                    )
                    .padding(.horizontal, metrics.horizontalPadding)
                } else {
                    // Visual Port Grid
                    PortGridView(onPortTap: { dose in
                        selectedDoseForSettings = dose
                    })
                    .padding(.horizontal, metrics.horizontalPadding)

                    // Port Details List
                    PortDetailsList(onPortTap: { dose in
                        selectedDoseForSettings = dose
                    })
                    .padding(.horizontal, metrics.horizontalPadding)

                    // Legend
                    PortsLegend()
                        .padding(.horizontal, metrics.horizontalPadding)
                }
            }
            .padding(.vertical, metrics.cardSpacing)
        }
        .background(viewModel.currentTheme.colors.bgPrimary)
        .sheet(item: $selectedDoseForSettings) { dose in
            PortSettingsSheet(dose: dose)
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Header

private struct PortsHeader: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    private var completedCount: Int {
        viewModel.doses.filter { $0.status == .taken }.count
    }

    private var totalCount: Int {
        viewModel.doses.count
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Pill Organizer")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Text("\(completedCount) of \(totalCount) ports completed")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
        }
        .padding()
    }
}

// MARK: - Port Grid

/// Visual grid representation of the 6-port organizer
private struct PortGridView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let onPortTap: (Dose) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.doses) { dose in
                PortCell(dose: dose, onTap: { onPortTap(dose) })
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

/// Individual port cell in the grid
private struct PortCell: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let dose: Dose
    let onTap: () -> Void

    private var isNext: Bool {
        viewModel.nextDose?.id == dose.id
    }

    private var statusColor: Color {
        switch dose.status {
        case .pending:
            return dose.isOverdue ? Color(hex: "#eab308") : viewModel.currentTheme.colors.bgElevated
        case .taken:
            return dose.timingCategory.color
        case .missed:
            return Color(hex: "#eab308")
        }
    }

    private var statusIcon: String {
        switch dose.status {
        case .pending:
            return dose.isOverdue ? "exclamationmark" : "circle"
        case .taken:
            return "checkmark"
        case .missed:
            return "xmark"
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.selectionChanged()
            onTap()
        }) {
            VStack(spacing: 8) {
                // Port visual
                ZStack {
                    // Bay background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(statusColor.opacity(dose.status == .pending && !dose.isOverdue ? 1 : 0.2))
                        .frame(height: 80)

                    // Status indicator
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 36, height: 36)

                            if dose.status != .pending || dose.isOverdue {
                                Image(systemName: statusIcon)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text("Port \(dose.portNumber)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                    }

                    // Next indicator ring
                    if isNext {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.currentTheme.colors.accent, lineWidth: 3)
                            .frame(height: 80)
                    }
                }

                // Time
                Text(dose.scheduledTimeString)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                // Status badge
                if dose.status == .taken {
                    TimingBadge(category: dose.timingCategory, compact: true)
                } else if isNext {
                    Text("NEXT")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .stroke(viewModel.currentTheme.colors.accent, lineWidth: 1)
                        )
                } else if dose.isOverdue {
                    Text("OVERDUE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Color(hex: "#eab308"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#eab308").opacity(0.2))
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Port \(dose.portNumber), \(dose.scheduledTimeString), \(dose.status.rawValue)")
        .accessibilityHint("Double tap to edit port settings")
    }
}

// MARK: - Port Details List

/// Detailed list of each port with timing info
private struct PortDetailsList: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let onPortTap: (Dose) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Port Details")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            VStack(spacing: 0) {
                ForEach(viewModel.doses) { dose in
                    PortDetailRow(dose: dose, onTap: { onPortTap(dose) })

                    if dose.portNumber < viewModel.doses.count {
                        Divider()
                            .background(viewModel.currentTheme.colors.border)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.currentTheme.colors.bgCard)
            )
        }
    }
}

/// Row showing detailed port information
private struct PortDetailRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let dose: Dose
    let onTap: () -> Void

    private var isNext: Bool {
        viewModel.nextDose?.id == dose.id
    }

    private var statusColor: Color {
        switch dose.status {
        case .pending:
            return dose.isOverdue ? Color(hex: "#eab308") : .gray
        case .taken:
            return dose.timingCategory.color
        case .missed:
            return Color(hex: "#eab308")
        }
    }

    var body: some View {
        Button(action: {
            HapticManager.selectionChanged()
            onTap()
        }) {
            rowContent
        }
        .buttonStyle(.plain)
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 28, height: 28)

                if dose.status == .taken {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Port info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Port \(dose.portNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    if isNext {
                        Text("NEXT")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(viewModel.currentTheme.colors.accent)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .stroke(viewModel.currentTheme.colors.accent, lineWidth: 1)
                            )
                    }
                }

                Text("Scheduled: \(dose.scheduledTimeString)")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }

            Spacer()

            // Status/timing
            VStack(alignment: .trailing, spacing: 2) {
                if dose.status == .taken {
                    if let actual = dose.actualTimeString {
                        Text("Taken: \(actual)")
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    }

                    if let diff = dose.timingDifference {
                        let sign = diff >= 0 ? "+" : ""
                        Text("\(sign)\(diff) min")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(dose.timingCategory.color)
                    }
                } else if dose.status == .missed {
                    Text("Missed")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(hex: "#eab308"))
                } else {
                    Text("Pending")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
            }
        }
        .padding()
        .background(
            isNext ? viewModel.currentTheme.colors.bgElevated.opacity(0.5) : Color.clear
        )
    }
}

// MARK: - Legend

/// Legend explaining timing categories
private struct PortsLegend: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    let categories: [(TimingCategory, String, String)] = [
        (.excellent, "Perfect", "≤5 min"),
        (.good, "Good", "≤10 min"),
        (.fair, "Fair", "≤20 min"),
        (.poor, "Review", ">20 min")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timing Legend")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            HStack(spacing: 16) {
                ForEach(categories, id: \.0) { category, name, threshold in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                            Text(threshold)
                                .font(.system(size: 9))
                                .foregroundColor(viewModel.currentTheme.colors.textMuted)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.currentTheme.colors.bgCard)
            )
        }
    }
}

#Preview {
    PortsView()
        .environmentObject(PillBackViewModel())
}
