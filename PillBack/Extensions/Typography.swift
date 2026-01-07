// Typography.swift
// Centralized typography system for consistent font usage and Dynamic Type support

import SwiftUI

/// Typography system for PillBack app
/// Provides consistent font definitions with Dynamic Type scaling support
enum Typography {

    // MARK: - Scaled Metrics

    /// Base font size for body text
    @ScaledMetric(relativeTo: .body) static var bodySize: CGFloat = 15

    /// Base font size for captions
    @ScaledMetric(relativeTo: .caption) static var captionSize: CGFloat = 12

    /// Base font size for titles
    @ScaledMetric(relativeTo: .title) static var titleSize: CGFloat = 20

    /// Base font size for headlines
    @ScaledMetric(relativeTo: .headline) static var headlineSize: CGFloat = 17

    // MARK: - Semantic Font Styles

    /// Large title for screen headers
    static var largeTitle: Font {
        .system(size: 24, weight: .bold)
    }

    /// Title for section headers
    static var title: Font {
        .system(size: 20, weight: .bold)
    }

    /// Headline for card titles
    static var headline: Font {
        .system(size: 18, weight: .bold)
    }

    /// Subheadline for secondary titles
    static var subheadline: Font {
        .system(size: 15, weight: .semibold)
    }

    /// Body text for main content
    static var body: Font {
        .system(size: 15, weight: .regular)
    }

    /// Callout for emphasized body text
    static var callout: Font {
        .system(size: 14, weight: .medium)
    }

    /// Caption for metadata and labels
    static var caption: Font {
        .system(size: 12, weight: .medium)
    }

    /// Small caption for timestamps and minor labels
    static var caption2: Font {
        .system(size: 11, weight: .medium)
    }

    /// Tiny text for badges and status indicators
    static var badge: Font {
        .system(size: 10, weight: .black)
    }

    /// Mono-spaced for numbers and times
    static var time: Font {
        .system(size: 18, weight: .bold).monospacedDigit()
    }

    // MARK: - Port Number Typography

    /// Large port number in circles
    static var portNumber: Font {
        .system(size: 18, weight: .black)
    }

    /// Small port label
    static var portLabel: Font {
        .system(size: 10, weight: .medium)
    }

    // MARK: - Button Typography

    /// Primary button text
    static var buttonPrimary: Font {
        .system(size: 16, weight: .bold)
    }

    /// Secondary button text
    static var buttonSecondary: Font {
        .system(size: 14, weight: .semibold)
    }

    /// Tab button text
    static var tabButton: Font {
        .system(size: 12, weight: .semibold)
    }

    // MARK: - Stats Typography

    /// Large stat value
    static var statValue: Font {
        .system(size: 24, weight: .black)
    }

    /// Medium stat value
    static var statValueMedium: Font {
        .system(size: 18, weight: .bold)
    }

    /// Stat label
    static var statLabel: Font {
        .system(size: 10, weight: .medium)
    }
}

// MARK: - View Extension for Accessibility

extension View {
    /// Apply minimum scale factor for accessibility
    func accessibleText(minScale: CGFloat = 0.7) -> some View {
        self.minimumScaleFactor(minScale)
            .lineLimit(nil)
    }

    /// Ensure minimum tap target size for accessibility
    func accessibleTapTarget(minSize: CGFloat = 44) -> some View {
        self.frame(minWidth: minSize, minHeight: minSize)
    }
}

// MARK: - Dynamic Type Preview Helper

struct TypographyPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    Text("Large Title")
                        .font(Typography.largeTitle)
                    Text("Title")
                        .font(Typography.title)
                    Text("Headline")
                        .font(Typography.headline)
                    Text("Subheadline")
                        .font(Typography.subheadline)
                    Text("Body")
                        .font(Typography.body)
                    Text("Callout")
                        .font(Typography.callout)
                }

                Divider()

                Group {
                    Text("Caption")
                        .font(Typography.caption)
                    Text("Caption 2")
                        .font(Typography.caption2)
                    Text("BADGE")
                        .font(Typography.badge)
                    Text("12:30 PM")
                        .font(Typography.time)
                }

                Divider()

                Group {
                    Text("Stat Value: 85%")
                        .font(Typography.statValue)
                    Text("Stat Label")
                        .font(Typography.statLabel)
                    Text("Primary Button")
                        .font(Typography.buttonPrimary)
                    Text("Tab Button")
                        .font(Typography.tabButton)
                }
            }
            .padding()
        }
    }
}

#Preview {
    TypographyPreview()
}
