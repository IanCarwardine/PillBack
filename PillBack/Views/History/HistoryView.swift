// HistoryView.swift
// History tab displaying past dose records using SwiftData

import SwiftUI
import SwiftData

/// History view showing past days' adherence records
struct HistoryView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \DoseHistory.date, order: .reverse)
    private var historyDays: [DoseHistory]

    @State private var selectedDay: DoseHistory?
    @State private var showingDayDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with stats
                HistoryHeader(historyDays: historyDays)
                    .padding(.horizontal)

                // History list
                if historyDays.isEmpty {
                    EmptyHistoryView()
                        .padding(.horizontal)
                } else {
                    HistoryListView(
                        historyDays: historyDays,
                        selectedDay: $selectedDay,
                        showingDayDetail: $showingDayDetail
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(viewModel.currentTheme.colors.bgPrimary)
        .sheet(isPresented: $showingDayDetail) {
            if let day = selectedDay {
                HistoryDayDetailView(day: day)
                    .environmentObject(viewModel)
            }
        }
    }
}

// MARK: - History Header

private struct HistoryHeader: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let historyDays: [DoseHistory]

    private var totalDays: Int {
        historyDays.count
    }

    private var perfectDays: Int {
        historyDays.filter { $0.isPerfectDay }.count
    }

    private var averageAdherence: Double {
        guard !historyDays.isEmpty else { return 0 }
        let total = historyDays.reduce(0) { $0 + $1.adherenceScore }
        return total / Double(historyDays.count)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("History")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            HStack(spacing: 12) {
                HistoryStatCard(
                    title: "Total Days",
                    value: "\(totalDays)",
                    icon: "calendar",
                    color: viewModel.currentTheme.colors.accent
                )

                HistoryStatCard(
                    title: "Perfect Days",
                    value: "\(perfectDays)",
                    icon: "star.fill",
                    color: Color(hex: "#eab308")
                )

                HistoryStatCard(
                    title: "Avg Adherence",
                    value: String(format: "%.0f%%", averageAdherence),
                    icon: "chart.line.uptrend.xyaxis",
                    color: Color(hex: "#22c55e")
                )
            }
        }
    }
}

private struct HistoryStatCard: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Text(title)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

// MARK: - Empty State

private struct EmptyHistoryView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            Text("No History Yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Text("Your dose history will appear here as you track your medications.")
                .font(.system(size: 14))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

// MARK: - History List

private struct HistoryListView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let historyDays: [DoseHistory]
    @Binding var selectedDay: DoseHistory?
    @Binding var showingDayDetail: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Past Days")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            LazyVStack(spacing: 8) {
                ForEach(historyDays) { day in
                    HistoryDayRow(day: day)
                        .onTapGesture {
                            selectedDay = day
                            showingDayDetail = true
                        }
                }
            }
        }
    }
}

// MARK: - History Day Row

struct HistoryDayRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let day: DoseHistory

    private var statusColor: Color {
        switch day.dayStatus {
        case .perfect:
            return Color(hex: "#22c55e")
        case .good:
            return Color(hex: "#22c55e")
        case .fair:
            return Color(hex: "#eab308")
        case .poor, .missed:
            return Color(hex: "#ef4444")
        }
    }

    private var displayDate: String {
        if day.isToday {
            return "Today"
        } else if day.isYesterday {
            return "Yesterday"
        } else {
            return day.dateString
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                if day.isPerfectDay {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#eab308"))
                } else {
                    Text(day.adherenceScoreText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(statusColor)
                }
            }

            // Day info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(displayDate)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    if day.isPerfectDay {
                        Text("PERFECT")
                            .font(.system(size: 8, weight: .black))
                            .foregroundColor(Color(hex: "#eab308"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "#eab308").opacity(0.2))
                            )
                    }
                }

                Text("\(day.dosesTaken)/\(day.totalDoses) doses taken")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }

            Spacer()

            // Timing accuracy
            if day.dosesTaken > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(day.timingAccuracyText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    Text("timing")
                        .font(.system(size: 10))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(displayDate), \(day.dosesTaken) of \(day.totalDoses) doses, \(day.adherenceScoreText) adherence")
    }
}

// MARK: - Day Detail View

struct HistoryDayDetailView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let day: DoseHistory

    @State private var records: [AdherenceRecord] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Day summary card
                    DaySummaryCard(day: day)
                        .padding(.horizontal)

                    // Dose records
                    if records.isEmpty {
                        Text("No records for this day")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.currentTheme.colors.textMuted)
                            .padding()
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dose Records")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                                .padding(.horizontal)

                            ForEach(records, id: \.id) { record in
                                RecordRow(record: record)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(viewModel.currentTheme.colors.bgPrimary)
            .navigationTitle(day.dateString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadRecords()
        }
    }

    private func loadRecords() {
        let descriptor = FetchDescriptor<AdherenceRecord>(
            predicate: AdherenceRecord.forDate(day.date),
            sortBy: [SortDescriptor(\.scheduledTime)]
        )

        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load records: \(error)")
        }
    }
}

// MARK: - Day Summary Card

private struct DaySummaryCard: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let day: DoseHistory

    var body: some View {
        VStack(spacing: 16) {
            // Status
            HStack {
                if day.isPerfectDay {
                    Image(systemName: "star.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#eab308"))

                    Text("Perfect Day!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                } else {
                    Text(day.dayStatus.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                }

                Spacer()

                Text(day.adherenceScoreText)
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(viewModel.currentTheme.colors.accent)
            }

            Divider()
                .background(viewModel.currentTheme.colors.border)

            // Stats grid
            HStack(spacing: 0) {
                SummaryStatItem(label: "Taken", value: "\(day.dosesTaken)")
                SummaryStatItem(label: "Missed", value: "\(day.dosesMissed)")
                SummaryStatItem(label: "Timing", value: day.timingAccuracyText)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(viewModel.currentTheme.colors.bgCard)
        )
    }
}

private struct SummaryStatItem: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Record Row

private struct RecordRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let record: AdherenceRecord

    private var statusColor: Color {
        if record.isTaken {
            switch record.timingCategory {
            case "excellent": return Color(hex: "#22c55e")
            case "good": return Color(hex: "#22c55e")
            case "fair": return Color(hex: "#eab308")
            case "poor": return Color(hex: "#ef4444")
            default: return .gray
            }
        } else if record.isMissed {
            return Color(hex: "#ef4444")
        }
        return .gray
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 28, height: 28)

                if record.isTaken {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else if record.isMissed {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            // Port info
            VStack(alignment: .leading, spacing: 2) {
                Text("Port \(record.portNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text("Scheduled: \(record.scheduledTimeString)")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)

                if !record.medications.isEmpty {
                    Text(record.medications.joined(separator: ", "))
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Timing info
            if record.isTaken {
                VStack(alignment: .trailing, spacing: 2) {
                    if let actual = record.actualTimeString {
                        Text(actual)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                    }

                    if let diff = record.timingDifferenceMinutes {
                        let sign = diff >= 0 ? "+" : ""
                        Text("\(sign)\(diff) min")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                }
            } else if record.isMissed {
                Text("Missed")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: "#ef4444"))
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
    HistoryView()
        .environmentObject(PillBackViewModel())
        .modelContainer(for: [DoseHistory.self, AdherenceRecord.self], inMemory: true)
}
