// AppTheme.swift
// Theme definitions for PillBack app with full color palettes

import SwiftUI

/// Available themes for the app
enum AppTheme: String, CaseIterable, Codable {
    case clinical = "Clinical"
    case warm = "Warm"
    case contrast = "High Contrast"
    case daylight = "Daylight"

    /// Full color palette for this theme
    var colors: ThemeColors {
        switch self {
        case .clinical:
            return ThemeColors(
                bgPrimary: Color(hex: "#0c0c10"),
                bgSecondary: Color(hex: "#16161c"),
                bgCard: Color(hex: "#1a1a1a"),
                bgElevated: Color(hex: "#26262f"),
                textPrimary: Color(hex: "#e8e8ec"),
                textSecondary: Color(hex: "#a0a0a8"),
                textMuted: Color(hex: "#6a6a72"),
                accent: Color(hex: "#5fb879"),
                accentDark: Color(hex: "#4a9660"),
                success: Color(hex: "#5fb879"),
                warning: Color(hex: "#d4a84b"),
                danger: Color(hex: "#9b7fbf"), // Purple instead of red (non-threatening)
                border: Color(hex: "#3d5a4a")
            )
        case .warm:
            return ThemeColors(
                bgPrimary: Color(hex: "#14110e"),
                bgSecondary: Color(hex: "#1e1a16"),
                bgCard: Color(hex: "#24201c"),
                bgElevated: Color(hex: "#2e2a26"),
                textPrimary: Color(hex: "#f5f0e8"),
                textSecondary: Color(hex: "#b0a898"),
                textMuted: Color(hex: "#706858"),
                accent: Color(hex: "#c4a060"),
                accentDark: Color(hex: "#a08048"),
                success: Color(hex: "#8aaa5a"),
                warning: Color(hex: "#dab04b"),
                danger: Color(hex: "#b8906a"),
                border: Color(hex: "#5a4a3a")
            )
        case .contrast:
            return ThemeColors(
                bgPrimary: .black,
                bgSecondary: Color(hex: "#0a0a0a"),
                bgCard: Color(hex: "#111111"),
                bgElevated: Color(hex: "#1a1a1a"),
                textPrimary: .white,
                textSecondary: Color(hex: "#cccccc"),
                textMuted: Color(hex: "#888888"),
                accent: Color(hex: "#00dddd"),
                accentDark: Color(hex: "#00aaaa"),
                success: Color(hex: "#00ff88"),
                warning: Color(hex: "#ffdd00"),
                danger: Color(hex: "#88aaff"),
                border: Color(hex: "#00aaaa")
            )
        case .daylight:
            return ThemeColors(
                bgPrimary: Color(hex: "#f5f3ef"),
                bgSecondary: .white,
                bgCard: .white,
                bgElevated: Color(hex: "#fafafa"),
                textPrimary: Color(hex: "#1a1a1a"),
                textSecondary: Color(hex: "#4a4a4a"),
                textMuted: Color(hex: "#7a7a7a"),
                accent: Color(hex: "#1a7a4a"),
                accentDark: Color(hex: "#145a38"),
                success: Color(hex: "#1a8a4a"),
                warning: Color(hex: "#b8860b"),
                danger: Color(hex: "#5a8a9a"),
                border: Color(hex: "#2a8a5a")
            )
        }
    }

    /// Preview gradient colors for theme selector
    var previewColors: [Color] {
        [colors.bgPrimary, colors.accent]
    }
}

// MARK: - Theme Colors

/// Complete color palette for a theme
struct ThemeColors {
    // Backgrounds
    let bgPrimary: Color
    let bgSecondary: Color
    let bgCard: Color
    let bgElevated: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color

    // Accent
    let accent: Color
    let accentDark: Color

    // Semantic
    let success: Color
    let warning: Color
    let danger: Color

    // Border
    let border: Color
}
