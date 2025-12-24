// AdherenceView.swift
// Adherence statistics tab with timing accuracy breakdown

import SwiftUI

/// Adherence statistics dashboard
struct AdherenceView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall Accuracy Gauge
                AccuracyGaugeView()

                // Dose Breakdown
                DoseBreakdownView()

                // Pattern Alerts
                PatternAlertView()

                // Legend
                TimingLegendView()
            }
            .padding()
        }
        .background(viewModel.currentTheme.colors.bgPrimary)
    }
}

/// Large circular gauge showing overall timing accuracy
struct AccuracyGaugeView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    private var accuracy: Int {
        viewModel.overallTimingAccuracy
    }

    private var gaugeColor: Color {
        if accuracy >= 90 { return Color(hex: "#22c55e") }
        if accuracy >= 75 { return Color(hex: "#eab308") }
        return Color(hex: "#c9a66b")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Timing Accuracy")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            ZStack {
                // Background circle
                Circle()
                    .stroke(viewModel.currentTheme.colors.bgElevated, lineWidth: 16)
                    .frame(width: 180, height: 180)

                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(accuracy) / 100)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: accuracy)

                // Center text
                VStack(spacing: 4) {
                    Text("\(accuracy)%")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    Text("\(viewModel.dosesTakenToday)/6 doses")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Timing accuracy \(accuracy) percent. \(viewModel.dosesTakenToday) of 6 doses taken.")
    }
}

/// Breakdown of each dose's timing
struct DoseBreakdownView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dose Breakdown")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            ForEach(viewModel.doses) { dose in
                HStack(spacing: 12) {
                    // Port
                    Text("Port \(dose.portNumber)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                        .frame(width: 60, alignment: .leading)

                    // Scheduled time
                    Text(dose.scheduledTimeString)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                        .frame(width: 60)

                    Spacer()

                    // Status/Timing
                    if dose.status == .taken {
                        HStack(spacing: 8) {
                            if let diff = dose.timingDifference {
                                Text("\(diff > 0 ? "+" : "")\(diff) min")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
                            }
                            TimingBadge(category: dose.timingCategory, compact: true)
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
                .padding(.vertical, 8)

                if dose.portNumber < 6 {
                    Divider()
                        .background(viewModel.currentTheme.colors.border)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

/// Pattern alerts for consistently late ports
struct PatternAlertView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        let patterns = viewModel.detectTimingPatterns()

        if !patterns.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(hex: "#eab308"))
                    Text("Timing Patterns Detected")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                }

                ForEach(patterns, id: \.port) { pattern in
                    HStack {
                        Text("Port \(pattern.port)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                        Spacer()

                        Text("Avg. \(pattern.avgLateness) min late")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#eab308"))
                    }
                    .padding(.vertical, 4)
                }

                Text("Consider adjusting your schedule to better match your routine.")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.currentTheme.colors.textMuted)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(viewModel.currentTheme.colors.bgCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#eab308").opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
}

/// Legend explaining timing categories
struct TimingLegendView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    let categories: [(TimingCategory, String, String)] = [
        (.excellent, "Perfect", "Within 5 minutes of scheduled time"),
        (.good, "Good", "Within 10 minutes"),
        (.fair, "Fair", "Within 20 minutes"),
        (.poor, "Review", "More than 20 minutes off schedule")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timing Categories")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            ForEach(categories, id: \.0) { category, name, description in
                HStack(spacing: 12) {
                    Circle()
                        .fill(category.color)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                        Text(description)
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

#Preview {
    AdherenceView()
        .environmentObject(PillBackViewModel())
}
