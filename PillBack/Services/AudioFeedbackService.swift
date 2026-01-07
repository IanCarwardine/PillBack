// AudioFeedbackService.swift
// Audio confirmation sounds for dose acknowledgment

import AudioToolbox
import AVFoundation

/// Available confirmation sound options
enum ConfirmationSound: String, Codable, CaseIterable, Identifiable {
    case chime = "Chime"
    case bell = "Bell"
    case success = "Success"
    case gentle = "Gentle"
    case silent = "Silent"

    var id: String { rawValue }

    /// System sound ID for playback
    var systemSoundID: SystemSoundID {
        switch self {
        case .chime:   return 1057  // Tweet sound
        case .bell:    return 1013  // Mail sent
        case .success: return 1001  // Key pressed
        case .gentle:  return 1004  // Soft beep
        case .silent:  return 0
        }
    }

    /// SF Symbol icon for this sound
    var icon: String {
        switch self {
        case .chime:   return "bell.fill"
        case .bell:    return "bell.circle.fill"
        case .success: return "checkmark.seal.fill"
        case .gentle:  return "leaf.fill"
        case .silent:  return "speaker.slash.fill"
        }
    }

    /// Description for accessibility
    var description: String {
        switch self {
        case .chime:   return "A pleasant chime sound"
        case .bell:    return "A gentle bell tone"
        case .success: return "A positive confirmation beep"
        case .gentle:  return "A soft, subtle sound"
        case .silent:  return "No sound (haptic only)"
        }
    }
}

/// Service for playing audio feedback sounds
final class AudioFeedbackService {

    // MARK: - Singleton

    static let shared = AudioFeedbackService()

    // MARK: - Properties

    private var selectedSound: ConfirmationSound = .chime
    private var isEnabled: Bool = true

    // MARK: - Initialization

    private init() {
        loadSettings()
    }

    // MARK: - Configuration

    /// Configure the selected sound
    func configure(sound: ConfirmationSound) {
        selectedSound = sound
        saveSettings()
    }

    /// Enable or disable audio feedback
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        saveSettings()
    }

    /// Get current sound selection
    var currentSound: ConfirmationSound {
        selectedSound
    }

    /// Check if audio is enabled
    var audioEnabled: Bool {
        isEnabled
    }

    // MARK: - Playback

    /// Play the confirmation sound for dose taken
    func playConfirmation() {
        guard isEnabled && selectedSound != .silent else { return }
        AudioServicesPlaySystemSound(selectedSound.systemSoundID)
    }

    /// Play a warning sound
    func playWarning() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1005) // Low beep
    }

    /// Play an error sound
    func playError() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1006) // Error tone
    }

    /// Play a specific sound (for preview in settings)
    func playSound(_ sound: ConfirmationSound) {
        guard sound != .silent else { return }
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }

    /// Play confirmation with optional haptic
    func playConfirmationWithHaptic(hapticEnabled: Bool = true) {
        playConfirmation()
        if hapticEnabled {
            HapticManager.success()
        }
    }

    // MARK: - Persistence

    private let soundKey = "pillback_confirmation_sound"
    private let enabledKey = "pillback_audio_enabled"

    private func loadSettings() {
        if let savedSound = UserDefaults.standard.string(forKey: soundKey),
           let sound = ConfirmationSound(rawValue: savedSound) {
            selectedSound = sound
        }
        isEnabled = UserDefaults.standard.object(forKey: enabledKey) as? Bool ?? true
    }

    private func saveSettings() {
        UserDefaults.standard.set(selectedSound.rawValue, forKey: soundKey)
        UserDefaults.standard.set(isEnabled, forKey: enabledKey)
    }
}

// MARK: - Combined Feedback Manager

/// Unified feedback manager combining haptic and audio
final class FeedbackManager {

    // MARK: - Singleton

    static let shared = FeedbackManager()

    // MARK: - Properties

    private let audioService = AudioFeedbackService.shared

    // MARK: - Initialization

    private init() {}

    // MARK: - Feedback Methods

    /// Play dose taken confirmation (audio + haptic)
    func doseTaken(sound: ConfirmationSound? = nil, hapticEnabled: Bool = true) {
        if let sound = sound {
            audioService.playSound(sound)
        } else {
            audioService.playConfirmation()
        }

        if hapticEnabled {
            HapticManager.success()
        }
    }

    /// Play a light tap feedback
    func tap() {
        HapticManager.impact(.light)
    }

    /// Play selection changed feedback
    func selection() {
        HapticManager.selectionChanged()
    }

    /// Prepare generators for immediate playback
    func prepare() {
        HapticManager.prepare()
    }

    /// Play warning feedback
    func warning(hapticEnabled: Bool = true) {
        audioService.playWarning()
        if hapticEnabled {
            HapticManager.warning()
        }
    }

    /// Play error feedback
    func error(hapticEnabled: Bool = true) {
        audioService.playError()
        if hapticEnabled {
            HapticManager.error()
        }
    }
}
