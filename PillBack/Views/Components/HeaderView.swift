// HeaderView.swift
// Bottom tab bar for navigation

import SwiftUI

/// Bottom tab bar for navigation
struct BottomTabBar: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Home", icon: "house.fill", isSelected: selectedTab == 0) {
                selectedTab = 0
            }

            TabButton(title: "Ports", icon: "square.grid.2x2.fill", isSelected: selectedTab == 1) {
                selectedTab = 1
            }

            TabButton(title: "History", icon: "clock.arrow.circlepath", isSelected: selectedTab == 2) {
                selectedTab = 2
            }

            TabButton(title: "Settings", icon: "gearshape.fill", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(viewModel.currentTheme.colors.bgSecondary)
    }
}

/// Individual tab button with icon and label
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        Button(action: {
            if !isSelected {
                HapticManager.tabChanged()
            }
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(isSelected ? viewModel.currentTheme.colors.accent : viewModel.currentTheme.colors.textSecondary)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel("\(title) tab")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack {
        Spacer()
        BottomTabBar(selectedTab: .constant(0))
    }
    .background(Color.black)
    .environmentObject(PillBackViewModel())
}
