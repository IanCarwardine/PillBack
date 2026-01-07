// PillBackApp.swift
// Main app entry point for PillBack iOS application

import SwiftUI
import SwiftData

@main
struct PillBackApp: App {
    @StateObject private var viewModel = PillBackViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// SwiftData model container for persistent history
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                AdherenceRecord.self,
                DoseHistory.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environmentObject(viewModel)
                    .preferredColorScheme(viewModel.currentTheme == .daylight ? .light : .dark)
                    .onAppear {
                        performMigrationIfNeeded()
                    }
            } else {
                OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(viewModel)
            }
        }
        .modelContainer(modelContainer)
    }

    /// Perform data migration from UserDefaults to SwiftData if needed
    @MainActor
    private func performMigrationIfNeeded() {
        let migrationService = DataMigrationService(modelContext: modelContainer.mainContext)
        if migrationService.needsMigration {
            migrationService.performMigration()
        }
    }
}
