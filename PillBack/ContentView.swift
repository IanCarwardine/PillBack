// ContentView.swift
// Main app container with tab navigation and theme support

import SwiftUI

/// Main content view with navigation and layout
struct ContentView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var selectedTab = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                viewModel.currentTheme.colors.bgPrimary
                    .ignoresSafeArea()

                if viewModel.viewMode == .timelineOnly {
                    // Timeline Only Mode (legacy - shows Ports view)
                    PortsView()
                } else {
                    // Full View Mode
                    VStack(spacing: 0) {
                        // Tab Content
                        TabView(selection: $selectedTab) {
                            HomeView()
                                .tag(0)

                            PortsView()
                                .tag(1)

                            HistoryView()
                                .tag(2)

                            SettingsView()
                                .tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))

                        // Bottom Tab Bar
                        BottomTabBar(selectedTab: $selectedTab)
                    }
                }
            }
            .environment(\.metrics, ResponsiveMetrics(geometry: geometry))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PillBackViewModel())
}
