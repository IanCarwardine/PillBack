// TimelineSidebarView.swift
// Collapsible sidebar showing visual timeline of doses

import SwiftUI

/// Sidebar showing visual timeline with dose status indicators
struct TimelineSidebarView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if viewModel.timelineExpanded {
                    Text("Timeline")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                }

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleTimeline()
                    }
                }) {
                    Image(systemName: viewModel.timelineExpanded ? "chevron.left" : "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                        .padding(8)
                        .background(Circle().fill(viewModel.currentTheme.colors.bgElevated))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()
                .background(viewModel.currentTheme.colors.border)

            // Timeline slots
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.doses) { dose in
                            TimelineSlotView(dose: dose, isExpanded: viewModel.timelineExpanded)
                                .id(dose.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onAppear {
                    // Scroll to next dose or first pending
                    if let nextDose = viewModel.nextDose {
                        withAnimation {
                            proxy.scrollTo(nextDose.id, anchor: .center)
                        }
                    }
                }
            }

            Divider()
                .background(viewModel.currentTheme.colors.border)

            // Legend (only when expanded)
            if viewModel.timelineExpanded {
                TimelineLegend()
                    .padding(12)
            }
        }
        .background(viewModel.currentTheme.colors.bgSecondary)
    }
}

/// Individual timeline slot for a dose
struct TimelineSlotView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let dose: Dose
    let isExpanded: Bool

    private var indicatorColor: Color {
        switch dose.status {
        case .pending:
            return dose.isOverdue ? Color(hex: "#eab308") : .gray
        case .taken:
            return dose.timingCategory.color
        case .missed:
            return Color(hex: "#eab308")
        }
    }

    private var isNextDose: Bool {
        viewModel.nextDose?.id == dose.id
    }

    var body: some View {
        HStack(spacing: isExpanded ? 12 : 8) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: isExpanded ? 24 : 16, height: isExpanded ? 24 : 16)

                if dose.status == .taken {
                    Image(systemName: "checkmark")
                        .font(.system(size: isExpanded ? 12 : 8, weight: .bold))
                        .foregroundColor(.white)
                }

                if isNextDose {
                    Circle()
                        .stroke(viewModel.currentTheme.colors.accent, lineWidth: 2)
                        .frame(width: isExpanded ? 32 : 24, height: isExpanded ? 32 : 24)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Port \(dose.portNumber)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                        if isNextDose {
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

                    Text(dose.scheduledTimeString)
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                    if dose.status == .taken, let actual = dose.actualTimeString {
                        Text("Taken: \(actual)")
                            .font(.system(size: 10))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    }
                }

                Spacer()

                if dose.status == .taken {
                    TimingBadge(category: dose.timingCategory, compact: true)
                }
            } else {
                Text("\(dose.portNumber)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isExpanded ? 10 : 8)
        .background(
            isNextDose
                ? viewModel.currentTheme.colors.bgElevated
                : Color.clear
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Port \(dose.portNumber), \(dose.scheduledTimeString), \(dose.status.rawValue)")
    }
}

/// Legend showing timing category colors
struct TimelineLegend: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    let categories: [(TimingCategory, String)] = [
        (.excellent, "≤5 min"),
        (.good, "≤10 min"),
        (.fair, "≤20 min"),
        (.poor, ">20 min")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timing")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(categories, id: \.0) { category, label in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(category.color)
                            .frame(width: 8, height: 8)
                        Text(label)
                            .font(.system(size: 9))
                            .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    }
                }
            }
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        TimelineSidebarView()
            .frame(width: 169)
        Spacer()
    }
    .background(Color.black)
    .environmentObject(PillBackViewModel())
}
