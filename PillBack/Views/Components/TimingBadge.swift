// TimingBadge.swift
// Badge displaying timing accuracy category with color coding

import SwiftUI

/// Badge showing timing category with appropriate color
struct TimingBadge: View {
    let category: TimingCategory
    let compact: Bool

    init(category: TimingCategory, compact: Bool = false) {
        self.category = category
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.system(size: compact ? 10 : 12))

            if !compact {
                Text(category.rawValue)
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, compact ? 6 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(
            Capsule()
                .fill(category.color)
        )
        .accessibilityLabel(category.accessibilityLabel)
    }
}

/// Badge showing timing difference in minutes
struct TimingDifferenceBadge: View {
    let minutes: Int

    var body: some View {
        let isLate = minutes > 0
        let absMinutes = abs(minutes)

        HStack(spacing: 2) {
            Image(systemName: isLate ? "clock.badge.exclamationmark" : "clock")
                .font(.system(size: 10))
            Text("\(isLate ? "+" : "-")\(absMinutes) min")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(isLate ? Color(hex: "#eab308") : Color(hex: "#22c55e"))
        .accessibilityLabel("\(absMinutes) minutes \(isLate ? "late" : "early")")
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(TimingCategory.allCases, id: \.self) { category in
            HStack {
                TimingBadge(category: category)
                TimingBadge(category: category, compact: true)
            }
        }

        Divider()

        TimingDifferenceBadge(minutes: 5)
        TimingDifferenceBadge(minutes: -3)
        TimingDifferenceBadge(minutes: 15)
    }
    .padding()
    .background(Color.black)
}
