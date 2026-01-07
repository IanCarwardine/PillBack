// ResponsiveMetrics.swift
// Responsive scaling system for different iPhone screen sizes

import SwiftUI

/// Provides responsive scaling for different iPhone screen sizes
/// Reference: iPhone 15 = 393pt width (base design)
struct ResponsiveMetrics: Equatable {
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    // Base design width (iPhone 15)
    private let baseWidth: CGFloat = 393

    // MARK: - Initializers

    init(geometry: GeometryProxy) {
        self.screenWidth = geometry.size.width
        self.screenHeight = geometry.size.height
    }

    init(width: CGFloat = 393, height: CGFloat = 852) {
        self.screenWidth = width
        self.screenHeight = height
    }

    // MARK: - Device Classification

    /// Scale factor relative to base design (capped at 1.2x)
    var scale: CGFloat {
        min(screenWidth / baseWidth, 1.2)
    }

    /// iPhone SE, iPhone 8 (width < 375pt)
    var isCompact: Bool {
        screenWidth < 375
    }

    /// iPhone Pro Max, Plus models (width > 400pt)
    var isLarge: Bool {
        screenWidth > 400
    }

    /// Standard iPhones (375-400pt)
    var isStandard: Bool {
        !isCompact && !isLarge
    }

    // MARK: - Spacing & Padding

    /// Horizontal padding for content
    var horizontalPadding: CGFloat {
        isCompact ? 16 : 20
    }

    /// Card spacing in lists
    var cardSpacing: CGFloat {
        isCompact ? 12 : 16
    }

    /// Section spacing between groups
    var sectionSpacing: CGFloat {
        isCompact ? 16 : 24
    }

    /// Inner padding for cards
    var cardPadding: CGFloat {
        isCompact ? 12 : 16
    }

    // MARK: - Sizes

    /// Port card height
    var portCardHeight: CGFloat {
        isCompact ? 80 : (isLarge ? 100 : 90)
    }

    /// Dose card minimum height
    var doseCardHeight: CGFloat {
        isCompact ? 70 : (isLarge ? 90 : 80)
    }

    /// Tab bar safe area padding
    var tabBarPadding: CGFloat {
        isCompact ? 80 : 100
    }

    /// Card icon size
    var cardIconSize: CGFloat {
        isCompact ? 32 : 40
    }

    /// Small icon size (in lists)
    var smallIconSize: CGFloat {
        isCompact ? 20 : 24
    }

    // MARK: - Corner Radius

    /// Standard corner radius
    var cornerRadius: CGFloat {
        isCompact ? 10 : 12
    }

    /// Large corner radius (cards)
    var largeCornerRadius: CGFloat {
        isCompact ? 14 : 16
    }

    // MARK: - Font Sizes

    /// Title font size (screen headers)
    var titleSize: CGFloat {
        isCompact ? 24 : 28
    }

    /// Large number font size (time displays)
    var largeNumberSize: CGFloat {
        isCompact ? 18 : (isLarge ? 24 : 20)
    }

    /// Hero number size (next dose, Easy Mode)
    var heroNumberSize: CGFloat {
        isCompact ? 28 : (isLarge ? 36 : 32)
    }

    /// Easy Mode port number (extra large)
    var easyModePortSize: CGFloat {
        isCompact ? 100 : (isLarge ? 140 : 120)
    }

    /// Body text size
    var bodySize: CGFloat {
        isCompact ? 14 : 16
    }

    /// Caption text size
    var captionSize: CGFloat {
        isCompact ? 11 : 12
    }

    // MARK: - Button Sizes

    /// Minimum button height
    var buttonHeight: CGFloat {
        isCompact ? 44 : 50
    }

    /// Large button height (primary actions)
    var largeButtonHeight: CGFloat {
        isCompact ? 50 : 56
    }

    // MARK: - Convenience Methods

    /// Scale a value based on screen width
    func scaled(_ value: CGFloat) -> CGFloat {
        value * scale
    }
}

// MARK: - Environment Key

struct ResponsiveMetricsKey: EnvironmentKey {
    static let defaultValue = ResponsiveMetrics()
}

extension EnvironmentValues {
    var metrics: ResponsiveMetrics {
        get { self[ResponsiveMetricsKey.self] }
        set { self[ResponsiveMetricsKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Inject responsive metrics based on geometry
    func withResponsiveMetrics() -> some View {
        GeometryReader { geometry in
            self.environment(\.metrics, ResponsiveMetrics(geometry: geometry))
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
struct ResponsiveMetricsPreview: View {
    @Environment(\.metrics) var metrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Responsive Metrics")
                .font(.system(size: metrics.titleSize, weight: .bold))

            Group {
                Text("Screen: \(Int(metrics.screenWidth)) x \(Int(metrics.screenHeight))")
                Text("Device: \(deviceType)")
                Text("Scale: \(String(format: "%.2f", metrics.scale))")
            }
            .font(.system(size: metrics.bodySize))

            Divider()

            Group {
                Text("Horizontal Padding: \(Int(metrics.horizontalPadding))")
                Text("Card Spacing: \(Int(metrics.cardSpacing))")
                Text("Corner Radius: \(Int(metrics.cornerRadius))")
                Text("Title Size: \(Int(metrics.titleSize))")
                Text("Hero Number: \(Int(metrics.heroNumberSize))")
            }
            .font(.system(size: metrics.captionSize))
            .foregroundStyle(.secondary)
        }
        .padding(metrics.horizontalPadding)
    }

    var deviceType: String {
        if metrics.isCompact { return "Compact (SE)" }
        if metrics.isLarge { return "Large (Pro Max)" }
        return "Standard"
    }
}

#Preview("iPhone SE") {
    ResponsiveMetricsPreview()
        .environment(\.metrics, ResponsiveMetrics(width: 320, height: 568))
}

#Preview("iPhone 15") {
    ResponsiveMetricsPreview()
        .environment(\.metrics, ResponsiveMetrics(width: 393, height: 852))
}

#Preview("iPhone 15 Pro Max") {
    ResponsiveMetricsPreview()
        .environment(\.metrics, ResponsiveMetrics(width: 430, height: 932))
}
#endif
