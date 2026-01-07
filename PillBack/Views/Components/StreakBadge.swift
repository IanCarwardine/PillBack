// StreakBadge.swift
// Component for displaying adherence streak status

import SwiftUI

/// Badge displaying current streak information
struct StreakBadge: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let streak: Int
    let status: StreakStatus
    let compact: Bool

    init(streak: Int, status: StreakStatus, compact: Bool = false) {
        self.streak = streak
        self.status = status
        self.compact = compact
    }

    private var streakIcon: String {
        switch status {
        case .activeToday:
            return "flame.fill"
        case .inProgress, .atRisk:
            return "flame"
        case .noStreak, .broken:
            return "flame"
        }
    }

    private var streakColor: Color {
        switch status {
        case .activeToday:
            return Color(hex: "#f97316") // Orange flame
        case .inProgress:
            return Color(hex: "#eab308") // Yellow
        case .atRisk:
            return Color(hex: "#ef4444") // Red warning
        case .noStreak, .broken:
            return Color(hex: "#6b7280") // Gray
        }
    }

    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }

    private var compactView: some View {
        HStack(spacing: 4) {
            Image(systemName: streakIcon)
                .font(.system(size: 12))
                .foregroundColor(streakColor)

            Text("\(streak)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(streakColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(streakColor.opacity(0.15))
        )
        .accessibilityLabel("\(streak) day streak")
    }

    private var fullView: some View {
        HStack(spacing: 12) {
            // Flame icon
            ZStack {
                Circle()
                    .fill(streakColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: streakIcon)
                    .font(.system(size: 20))
                    .foregroundColor(streakColor)
            }

            // Streak info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(streak == 0 ? "No Streak" : "\(streak) Day\(streak == 1 ? "" : "s")")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    if status == .activeToday && streak > 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#22c55e"))
                    }
                }

                Text(status.displayText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(status == .atRisk ? Color(hex: "#ef4444").opacity(0.5) : Color.clear, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streak) day streak. \(status.displayText)")
    }
}

/// Larger streak card with additional stats
struct StreakCard: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let summary: StreakSummary

    var body: some View {
        VStack(spacing: 16) {
            // Header with streak badge
            StreakBadge(streak: summary.currentStreak, status: summary.streakStatus)
                .environmentObject(viewModel)

            // Stats row
            HStack(spacing: 0) {
                StatItem(
                    label: "Best",
                    value: summary.longestStreakText,
                    icon: "trophy.fill",
                    color: Color(hex: "#eab308")
                )

                Divider()
                    .frame(height: 40)
                    .background(viewModel.currentTheme.colors.border)

                StatItem(
                    label: "7 Day",
                    value: summary.adherence7DayText,
                    icon: "calendar",
                    color: viewModel.currentTheme.colors.accent
                )

                Divider()
                    .frame(height: 40)
                    .background(viewModel.currentTheme.colors.border)

                StatItem(
                    label: "30 Day",
                    value: summary.adherence30DayText,
                    icon: "calendar.badge.clock",
                    color: viewModel.currentTheme.colors.accent
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

/// Individual stat item for StreakCard
private struct StatItem: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Full Badge") {
    VStack(spacing: 16) {
        StreakBadge(streak: 7, status: .activeToday)
        StreakBadge(streak: 3, status: .inProgress)
        StreakBadge(streak: 5, status: .atRisk)
        StreakBadge(streak: 0, status: .noStreak)
    }
    .padding()
    .background(Color.black)
    .environmentObject(PillBackViewModel())
}

#Preview("Compact Badge") {
    HStack(spacing: 12) {
        StreakBadge(streak: 7, status: .activeToday, compact: true)
        StreakBadge(streak: 3, status: .inProgress, compact: true)
        StreakBadge(streak: 0, status: .noStreak, compact: true)
    }
    .padding()
    .background(Color.black)
    .environmentObject(PillBackViewModel())
}
