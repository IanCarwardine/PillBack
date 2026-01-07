// EasyModeView.swift
// Accessibility-first interface with swipe-to-confirm for Parkinson's patients

import SwiftUI

/// Easy Mode - Simplified interface with large elements and swipe gestures
/// Designed for users with motor impairments (Parkinson's patients)
struct EasyModeView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics

    @State private var dragOffset: CGFloat = 0
    @State private var showingConfirmation = false
    @State private var lastConfirmedPort: Int? = nil
    @State private var exitTapCount = 0

    private let swipeThreshold: CGFloat = 120
    private let feedbackManager = FeedbackManager.shared

    // MARK: - Computed Properties

    /// Find the next pending or due dose
    private var nextDose: Dose? {
        viewModel.doses.first { $0.status == .pending }
    }

    /// Count of completed doses today
    private var completedCount: Int {
        viewModel.dosesTakenToday
    }

    /// Total doses for today
    private var totalCount: Int {
        viewModel.doses.count
    }

    /// All doses completed?
    private var allDone: Bool {
        nextDose == nil && totalCount > 0
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                viewModel.currentTheme.colors.bgPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Status dots at top
                    statusDotsRow
                        .padding(.top, 60)

                    // Progress text
                    Text("\(completedCount) of \(totalCount) taken")
                        .font(.system(size: metrics.bodySize + 2, weight: .semibold))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                        .padding(.top, 16)

                    Spacer()

                    // Main content area
                    if totalCount == 0 {
                        emptyStateView
                    } else if allDone {
                        allDoneView
                    } else if showingConfirmation {
                        confirmationView
                    } else if let dose = nextDose {
                        doseCard(for: dose)
                    }

                    Spacer()

                    // Exit hint
                    Text("Triple-tap corners to exit Easy Mode")
                        .font(.system(size: metrics.captionSize))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted.opacity(0.5))
                        .padding(.bottom, 40)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 3) {
                exitEasyMode()
            }
        }
        .onAppear {
            feedbackManager.prepare()
        }
    }

    // MARK: - Status Dots

    private var statusDotsRow: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.doses) { dose in
                Circle()
                    .fill(statusColor(for: dose))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Group {
                            if dose.status == .taken {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)

            Text("No Schedule")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            Text("Set up your schedule to use Easy Mode")
                .font(.system(size: metrics.bodySize))
                .foregroundColor(viewModel.currentTheme.colors.textMuted)
        }
    }

    // MARK: - All Done View

    private var allDoneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "#22c55e"))

            Text("All Done!")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(hex: "#22c55e"))

            Text("Great work today")
                .font(.system(size: metrics.bodySize + 4))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
        }
    }

    // MARK: - Confirmation View

    private var confirmationView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(Color(hex: "#22c55e"))

            Text("Dose \(lastConfirmedPort ?? 0) Taken!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#22c55e"))
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Dose Card

    private func doseCard(for dose: Dose) -> some View {
        VStack(spacing: 0) {
            // Dose info card
            VStack(spacing: 16) {
                // HUGE port number
                Text("\(dose.portNumber)")
                    .font(.system(size: metrics.easyModePortSize, weight: .black, design: .rounded))
                    .foregroundColor(dose.isOverdue
                                     ? Color(hex: "#eab308")
                                     : viewModel.currentTheme.colors.accent)

                // Time
                Text(dose.scheduledTimeString)
                    .font(.system(size: metrics.heroNumberSize, weight: .bold, design: .monospaced))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                // Status badge - v0.4 Design: dark pill with white text
                Text(dose.isOverdue ? "OVERDUE" : "NEXT")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(dose.isOverdue
                                     ? Color(hex: "#eab308")
                                     : .white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(dose.isOverdue
                                  ? Color(hex: "#eab308").opacity(0.2)
                                  : viewModel.currentTheme.colors.bgElevated)
                    )

                // Medication name (if KEY DRUG is set)
                if !viewModel.medications.isEmpty {
                    let keyDrug = viewModel.medications.first { $0.isKeyDrug }
                    if let drug = keyDrug {
                        Text(drug.name)
                            .font(.system(size: metrics.bodySize))
                            .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                            .padding(.top, 8)
                    }
                }
            }
            .offset(x: dragOffset)
            .gesture(swipeGesture(for: dose))

            // Swipe hint
            VStack(spacing: 20) {
                // Swipe instruction
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right")
                    Text("Swipe right to confirm")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: metrics.bodySize - 2))
                .foregroundColor(viewModel.currentTheme.colors.textMuted.opacity(0.6))

                // Progress indicator for swipe
                if dragOffset > 0 {
                    swipeProgressIndicator
                }
            }
            .padding(.top, 40)
        }
    }

    // MARK: - Swipe Progress

    private var swipeProgressIndicator: some View {
        HStack {
            Rectangle()
                .fill(Color(hex: "#22c55e"))
                .frame(
                    width: min(dragOffset, swipeThreshold) / swipeThreshold * 200,
                    height: 6
                )
                .cornerRadius(3)

            if dragOffset >= swipeThreshold {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "#22c55e"))
                    .transition(.scale)
            }
        }
        .frame(width: 220, alignment: .leading)
    }

    // MARK: - Gestures

    private func swipeGesture(for dose: Dose) -> some Gesture {
        DragGesture()
            .onChanged { value in
                // Only allow right swipe
                if value.translation.width > 0 {
                    dragOffset = value.translation.width

                    // Haptic at threshold
                    if abs(dragOffset - swipeThreshold) < 10 {
                        HapticManager.impact(.medium)
                    }
                }
            }
            .onEnded { _ in
                if dragOffset > swipeThreshold {
                    confirmDose(dose)
                }

                // Reset position
                withAnimation(.spring(response: 0.3)) {
                    dragOffset = 0
                }
            }
    }

    // MARK: - Actions

    private func confirmDose(_ dose: Dose) {
        // Play feedback
        feedbackManager.doseTaken(
            sound: AudioFeedbackService.shared.currentSound,
            hapticEnabled: true
        )

        // Mark as taken
        viewModel.markDoseTaken(dose: dose)
        StreakTracker.shared.updateStreaks(with: viewModel.doses)
        lastConfirmedPort = dose.portNumber

        // Show confirmation briefly
        withAnimation(.easeInOut(duration: 0.3)) {
            showingConfirmation = true
        }

        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingConfirmation = false
            }
        }
    }

    private func exitEasyMode() {
        HapticManager.impact(.heavy)
        viewModel.easyModeEnabled = false
    }

    // MARK: - Helpers

    private func statusColor(for dose: Dose) -> Color {
        switch dose.status {
        case .taken:
            return Color(hex: "#22c55e")
        case .pending:
            return dose.isOverdue
                ? Color(hex: "#eab308")
                : viewModel.currentTheme.colors.textMuted.opacity(0.3)
        case .missed:
            return viewModel.currentTheme.colors.textMuted
        }
    }
}

// MARK: - Preview

#Preview {
    EasyModeView()
        .environmentObject(PillBackViewModel())
        .environment(\.metrics, ResponsiveMetrics())
}
