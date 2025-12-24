// OnboardingContainerView.swift
// Container for onboarding flow with page navigation

import SwiftUI

/// Container view managing the onboarding flow
struct OnboardingContainerView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0

    var body: some View {
        ZStack {
            viewModel.currentTheme.colors.bgPrimary
                .ignoresSafeArea()

            VStack {
                // Page content
                TabView(selection: $currentPage) {
                    WelcomeView(onContinue: nextPage)
                        .tag(0)

                    NameEntryView(onContinue: nextPage)
                        .tag(1)

                    NotificationPermissionView(onContinue: nextPage)
                        .tag(2)

                    ScheduleSetupView(onComplete: completeOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(index == currentPage ? viewModel.currentTheme.colors.accent : viewModel.currentTheme.colors.bgElevated)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }

    private func nextPage() {
        withAnimation {
            currentPage += 1
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingContainerView(hasCompletedOnboarding: .constant(false))
        .environmentObject(PillBackViewModel())
}
