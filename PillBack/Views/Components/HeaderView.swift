// HeaderView.swift
// App header with branding, user name, time, and tab navigation

import SwiftUI

/// Header view displaying app branding and tab navigation
struct HeaderView: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    @Binding var selectedTab: Int

    var body: some View {
        VStack(spacing: 0) {
            // Top section with logo and name
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PillBack")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(viewModel.currentTheme.colors.accent)
                    + Text("\u{2122}")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(viewModel.currentTheme.colors.accent)

                    Text(viewModel.userName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(viewModel.currentTheme.colors.textMuted)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("PillBack app for \(viewModel.userName)")

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(viewModel.currentDate, style: .time)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(viewModel.currentTheme.colors.textPrimary)

                    Text(viewModel.currentDate, style: .date)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(viewModel.currentTheme.colors.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Current time: \(viewModel.currentDate.formatted(date: .abbreviated, time: .shortened))")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(viewModel.currentTheme.colors.bgCard)

            // Tab Bar
            HStack(spacing: 0) {
                TabButton(title: "Schedule", icon: "calendar", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }

                TabButton(title: "Medications", icon: "pill.fill", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }

                TabButton(title: "Adherence", icon: "chart.bar.fill", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }

                TabButton(title: "Settings", icon: "gearshape.fill", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
            }
            .padding(8)
            .background(viewModel.currentTheme.colors.bgSecondary)
        }
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
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(isSelected ? viewModel.currentTheme.colors.accent : viewModel.currentTheme.colors.textSecondary)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? viewModel.currentTheme.colors.bgCard : Color.clear)
            )
        }
        .accessibilityLabel("\(title) tab")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HeaderView(selectedTab: .constant(0))
        .environmentObject(PillBackViewModel())
}
