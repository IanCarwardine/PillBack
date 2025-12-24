// PillBackApp.swift
// Main app entry point for PillBack iOS application

import SwiftUI

@main
struct PillBackApp: App {
    @StateObject private var viewModel = PillBackViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(viewModel)
                    .preferredColorScheme(viewModel.currentTheme == .daylight ? .light : .dark)
            } else {
                OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(viewModel)
            }
        }
    }
}
