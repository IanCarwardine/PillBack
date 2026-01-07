// ThemeSelectorView.swift
// Visual theme selector with color preview circles

import SwiftUI

/// Theme selector showing all available themes as color circles
struct ThemeSelectorView: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                ThemeButton(theme: theme)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(viewModel.currentTheme.colors.bgSecondary)
                .shadow(color: .black.opacity(0.3), radius: 4)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Theme selector")
    }
}

/// Individual theme button with gradient preview
struct ThemeButton: View {
    @EnvironmentObject var viewModel: PillBackViewModel
    let theme: AppTheme

    private var isSelected: Bool {
        viewModel.currentTheme == theme
    }

    var body: some View {
        Button(action: {
            if !isSelected {
                HapticManager.themeChanged()
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.setTheme(theme)
            }
        }) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: theme.previewColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(isSelected ? theme.colors.accent : Color.clear, lineWidth: 2)
                )
                .shadow(color: isSelected ? theme.colors.accent.opacity(0.5) : .clear, radius: 6)
        }
        .accessibilityLabel("\(theme.rawValue) theme")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to apply this theme")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ThemeSelectorView()
            .environmentObject(PillBackViewModel())
    }
}
