// ViewMode.swift
// View mode enum for switching between full view and timeline-only modes

import Foundation

/// Display mode for the main app interface
enum ViewMode: String, Codable, CaseIterable {
    case full = "Full View"
    case timelineOnly = "Timeline Only"

    var icon: String {
        switch self {
        case .full: return "rectangle.split.2x1"
        case .timelineOnly: return "list.bullet"
        }
    }

    var description: String {
        switch self {
        case .full: return "Show sidebar and tabs"
        case .timelineOnly: return "Focus on timeline"
        }
    }

    /// Toggle to the other mode
    var toggled: ViewMode {
        self == .full ? .timelineOnly : .full
    }
}
