// ContentView.swift
// Main app container with tab navigation and theme support

import SwiftUI

/// Main content view with navigation and layout
struct ContentView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background
            viewModel.currentTheme.colors.bgPrimary
                .ignoresSafeArea()

            if viewModel.viewMode == .timelineOnly {
                // Timeline Only Mode
                TimelineOnlyView()
            } else {
                // Full View Mode
                HStack(spacing: 0) {
                    // Timeline Sidebar
                    TimelineSidebarView()
                        .frame(width: viewModel.timelineExpanded ? 169 : 78)

                    // Main Content
                    VStack(spacing: 0) {
                        // Header
                        HeaderView(selectedTab: $selectedTab)

                        // Tab Content
                        TabView(selection: $selectedTab) {
                            ScheduleView()
                                .tag(0)

                            MedicationsView()
                                .tag(1)

                            AdherenceView()
                                .tag(2)

                            SettingsView()
                                .tag(3)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Theme Selector (Top Right)
            VStack {
                HStack {
                    Spacer()
                    ThemeSelectorView()
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                }
                Spacer()
            }

            // View Mode Toggle (Below Theme Selector)
            VStack {
                HStack {
                    Spacer()
                    ViewModeToggleButton()
                        .padding(.trailing, 16)
                        .padding(.top, 50)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PillBackViewModel())
}
