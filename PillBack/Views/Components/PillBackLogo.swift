// PillBackLogo.swift
// Reusable PillBack logo component matching v0.4 design

import SwiftUI

/// Two-tone capsule shape for the logo
struct TwoToneCapsule: View {
    let topColor: Color
    let bottomColor: Color
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            // Bottom half (dark)
            Capsule()
                .fill(bottomColor)
                .frame(width: width, height: height)

            // Top half (light) - mask to show only upper portion
            Capsule()
                .fill(topColor)
                .frame(width: width, height: height)
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: height / 2)
                        Spacer()
                    }
                    .frame(width: width, height: height)
                )

            // Divider line between halves
            Rectangle()
                .fill(bottomColor.opacity(0.3))
                .frame(width: width, height: 1)
        }
    }
}

/// PillBack logo - green circle with capsule and tablet icons
struct PillBackLogo: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    let size: CGFloat
    var useThemeColor: Bool = true

    private var backgroundColor: Color {
        useThemeColor ? viewModel.currentTheme.colors.accent : Color(hex: "#4ade80")
    }

    private var iconColor: Color {
        useThemeColor ? viewModel.currentTheme.colors.bgPrimary : Color(hex: "#0f172a")
    }

    var body: some View {
        ZStack {
            // Green circle background
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)

            // Pills arrangement matching logo
            ZStack {
                // Two-tone capsule pill (tilted, upper left)
                TwoToneCapsule(
                    topColor: backgroundColor,
                    bottomColor: iconColor,
                    width: size * 0.2,
                    height: size * 0.45
                )
                .rotationEffect(.degrees(-50))
                .offset(x: -size * 0.14, y: -size * 0.06)

                // Round tablet with line (lower right)
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: size * 0.38, height: size * 0.38)

                    // Horizontal line through tablet
                    Rectangle()
                        .fill(backgroundColor)
                        .frame(width: size * 0.30, height: size * 0.045)
                }
                .offset(x: size * 0.12, y: size * 0.12)
            }
        }
    }
}

/// Compact logo variant for smaller spaces
struct PillBackLogoCompact: View {
    @EnvironmentObject var viewModel: PillBackViewModel

    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(viewModel.currentTheme.colors.accent)
                .frame(width: size, height: size)

            Image(systemName: "pills.fill")
                .font(.system(size: size * 0.5))
                .foregroundColor(viewModel.currentTheme.colors.bgPrimary)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        PillBackLogo(size: 120)

        PillBackLogo(size: 80)

        PillBackLogo(size: 60)

        PillBackLogoCompact(size: 40)
    }
    .padding()
    .background(Color.black)
    .environmentObject(PillBackViewModel())
}
