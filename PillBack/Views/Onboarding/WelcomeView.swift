// WelcomeView.swift
// First onboarding screen with app introduction

import SwiftUI

/// Welcome screen introducing the app
struct WelcomeView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Logo and title
            VStack(spacing: 16) {
                // App icon placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(viewModel.currentTheme.colors.accent.opacity(0.2))
                        .frame(width: 100, height: 100)

                    Image(systemName: "pill.fill")
                        .font(.system(size: 48))
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                }

                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Text("PillBack")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(viewModel.currentTheme.colors.accent)
                        Text("\u{2122}")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(viewModel.currentTheme.colors.accent)
                    }

                    Text("Medication Timing Tracker")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                }
            }

            // Features
            VStack(spacing: 20) {
                FeatureRow(
                    icon: "clock.fill",
                    title: "Track Timing",
                    description: "Record when you take each dose from your 6-port organizer"
                )

                FeatureRow(
                    icon: "chart.bar.fill",
                    title: "See Patterns",
                    description: "Understand your timing accuracy and identify areas to improve"
                )

                FeatureRow(
                    icon: "bell.fill",
                    title: "Stay on Track",
                    description: "Get reminders to help maintain consistent medication timing"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Get Started button
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(viewModel.currentTheme.colors.accent)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

/// Feature row for welcome screen
struct FeatureRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(viewModel.currentTheme.colors.accent)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(viewModel.currentTheme.colors.bgCard)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.currentTheme.colors.textSecondary)
            }

            Spacer()
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
        .environmentObject(PillBackViewModel())
}
