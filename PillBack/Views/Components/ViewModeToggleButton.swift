// ViewModeToggleButton.swift
// Toggle button for switching between full view and timeline-only modes

import SwiftUI

/// Button to toggle between full view and timeline-only modes
struct ViewModeToggleButton: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.setViewMode(viewModel.viewMode.toggled)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.viewMode.icon)
                    .font(.system(size: 12))
                Text(viewModel.viewMode == .full ? "Timeline Only" : "Full View")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(viewModel.currentTheme.colors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.currentTheme.colors.bgSecondary)
                    .shadow(color: .black.opacity(0.3), radius: 4)
            )
        }
        .accessibilityLabel("View mode: \(viewModel.viewMode.rawValue)")
        .accessibilityHint("Double tap to switch to \(viewModel.viewMode.toggled.rawValue)")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ViewModeToggleButton()
            .environmentObject(PillBackViewModel())
    }
}
