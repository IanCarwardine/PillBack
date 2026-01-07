// OnboardingProgressView.swift
// Animated progress indicator with expandable capsules

import SwiftUI

/// Progress indicator showing onboarding step completion
/// Current step expands while others remain compact
struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep
                          ? viewModel.currentTheme.colors.accent
                          : viewModel.currentTheme.colors.bgElevated)
                    .frame(
                        width: step == currentStep ? 24 : 8,
                        height: 8
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .padding(.top, 20)
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
    }
}

// MARK: - Alternative Style

/// Larger progress indicator with labels
struct OnboardingProgressViewLabeled: View {
    let currentStep: Int
    let totalSteps: Int
    let stepLabels: [String]

    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Progress bar
            HStack(spacing: 4) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Rectangle()
                        .fill(step <= currentStep
                              ? viewModel.currentTheme.colors.accent
                              : viewModel.currentTheme.colors.bgElevated)
                        .frame(height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }

            // Step label
            if currentStep > 0 && currentStep <= stepLabels.count {
                Text(stepLabels[currentStep - 1])
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Numbered Progress

/// Progress indicator with step numbers
struct OnboardingProgressViewNumbered: View {
    let currentStep: Int
    let totalSteps: Int

    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics

    var body: some View {
        HStack(spacing: 12) {
            ForEach(1...totalSteps, id: \.self) { step in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(step <= currentStep
                                  ? viewModel.currentTheme.colors.accent
                                  : viewModel.currentTheme.colors.bgElevated)
                            .frame(width: 28, height: 28)

                        if step < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(step)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(step <= currentStep
                                                 ? .white
                                                 : viewModel.currentTheme.colors.textMuted)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                // Connector line (except after last step)
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep
                              ? viewModel.currentTheme.colors.accent
                              : viewModel.currentTheme.colors.bgElevated)
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.top, 16)
    }
}

// MARK: - Preview

#Preview("Capsules") {
    VStack(spacing: 40) {
        OnboardingProgressView(currentStep: 1, totalSteps: 6)
        OnboardingProgressView(currentStep: 3, totalSteps: 6)
        OnboardingProgressView(currentStep: 6, totalSteps: 6)
    }
    .padding()
    .background(Color.black)
    .environmentObject(PillBackViewModel())
}

#Preview("Numbered") {
    VStack(spacing: 40) {
        OnboardingProgressViewNumbered(currentStep: 1, totalSteps: 6)
        OnboardingProgressViewNumbered(currentStep: 3, totalSteps: 6)
        OnboardingProgressViewNumbered(currentStep: 6, totalSteps: 6)
    }
    .padding()
    .background(Color.black)
    .environmentObject(PillBackViewModel())
    .environment(\.metrics, ResponsiveMetrics())
}
