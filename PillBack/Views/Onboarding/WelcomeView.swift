// WelcomeView.swift
// First onboarding screen with app introduction - v0.4 Design

import SwiftUI

/// Welcome screen introducing the app
struct WelcomeView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Environment(\.metrics) var metrics
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo - same layout as KeyMedicationView icon
            Image("PillBackLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Spacer()
                .frame(height: 32)

            // Title
            HStack(spacing: 0) {
                Text("Welcome to ")
                    .font(.system(size: metrics.titleSize, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text("PillBack")
                    .font(.system(size: metrics.titleSize, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                Text("™")
                    .font(.system(size: metrics.titleSize * 0.5, weight: .bold))
                    .foregroundColor(viewModel.currentTheme.colors.textPrimary)
                    .baselineOffset(metrics.titleSize * 0.3)
            }
            .padding(.bottom, 12)

            // Subtitle
            Text("Passive, phone-based medication\nadherence tracking.")
                .font(.system(size: metrics.bodySize))
                .multilineTextAlignment(.center)
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                .padding(.bottom, 48)

            // Features
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "bell.fill",
                    text: "Smart reminders at the right time"
                )

                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Track your adherence patterns"
                )

                FeatureRow(
                    icon: "iphone.radiowaves.left.and.right",
                    text: "No extra devices needed"
                )
            }
            .padding(.horizontal, 48)

            Spacer()
            Spacer()

            // Get Started button
            Button(action: {
                HapticManager.impact(.medium)
                onContinue()
            }) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(viewModel.currentTheme.colors.accent)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(viewModel.currentTheme.colors.accent.opacity(0.5), lineWidth: 2)
                            .padding(-2)
                    )
            }
            .padding(.horizontal, metrics.horizontalPadding + 8)
            .padding(.bottom, 50)
        }
    }
}

/// Feature row for welcome screen - v0.4 minimal style
private struct FeatureRow: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(viewModel.currentTheme.colors.accent)
                .frame(width: 28)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(viewModel.currentTheme.colors.textSecondary)

            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WelcomeView(onContinue: {})
    }
    .environmentObject(PillBackViewModel())
    .environment(\.metrics, ResponsiveMetrics())
}
