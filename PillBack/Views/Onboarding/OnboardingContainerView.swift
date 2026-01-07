// OnboardingContainerView.swift
// Container for onboarding flow with page navigation

import SwiftUI

/// Onboarding step enum for type-safe navigation
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case name = 1
    case notifications = 2
    case wakingHours = 3
    case keyMedication = 4
    case companionMedications = 5
    case scheduleSetup = 6

    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .name: return "Your Name"
        case .notifications: return "Notifications"
        case .wakingHours: return "Waking Hours"
        case .keyMedication: return "Key Medication"
        case .companionMedications: return "Companion Meds"
        case .scheduleSetup: return "Schedule"
        }
    }

    static var totalSteps: Int { allCases.count }
}

/// Container view managing the onboarding flow
struct OnboardingContainerView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentStep: OnboardingStep = .welcome

    private var currentPage: Int {
        currentStep.rawValue
    }

    var body: some View {
        ZStack {
            viewModel.currentTheme.colors.bgPrimary
                .ignoresSafeArea()

            // Step content
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeView(onContinue: { goToStep(.name) })

                case .name:
                    NameEntryView(
                        onContinue: { goToStep(.notifications) },
                        onBack: { goToStep(.welcome) }
                    )

                case .notifications:
                    NotificationPermissionView(
                        onContinue: { goToStep(.wakingHours) },
                        onBack: { goToStep(.name) }
                    )

                case .wakingHours:
                    WakingHoursView(
                        onContinue: { goToStep(.keyMedication) },
                        onBack: { goToStep(.notifications) }
                    )

                case .keyMedication:
                    KeyMedicationView(
                        onContinue: { goToStep(.companionMedications) },
                        onBack: { goToStep(.wakingHours) }
                    )

                case .companionMedications:
                    CompanionMedicationsView(
                        onContinue: { goToStep(.scheduleSetup) },
                        onBack: { goToStep(.keyMedication) }
                    )

                case .scheduleSetup:
                    ScheduleSetupView(
                        onComplete: completeOnboarding,
                        onBack: { goToStep(.companionMedications) }
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
    }

    private func goToStep(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = step
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingContainerView(hasCompletedOnboarding: .constant(false))
        .environmentObject(PillBackViewModel())
        .environment(\.metrics, ResponsiveMetrics())
}
