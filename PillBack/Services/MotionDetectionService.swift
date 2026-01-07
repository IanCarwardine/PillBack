// MotionDetectionService.swift
// Hidden motion detection service using dual-gate sensor algorithm

import Foundation
import CoreMotion
import Combine

/// Service for detecting pill dispenser lid opens using magnetometer and accelerometer
/// HIDDEN FEATURE: Activated via triple-tap on Port 5 in tech debug mode
@MainActor
class MotionDetectionService: ObservableObject {

    // MARK: - Singleton

    static let shared = MotionDetectionService()

    // MARK: - Published Properties

    @Published private(set) var isEnabled = false
    @Published private(set) var isMonitoring = false
    @Published private(set) var detectedPort: Int?
    @Published private(set) var lastDetectionTime: Date?
    @Published private(set) var debugMode = false

    // MARK: - Sensor Data (for debug display)

    @Published private(set) var currentMagnetometerZ: Double = 0
    @Published private(set) var currentAccelerometerMagnitude: Double = 0

    // MARK: - Core Motion

    private let motionManager = CMMotionManager()
    private var magnetometerData: CMMagnetometerData?
    private var accelerometerData: CMAccelerometerData?

    // MARK: - Detection Thresholds

    /// Magnetometer Z threshold range for lid detection (in microteslas)
    private let magnetometerZMin: Double = 15.0
    private let magnetometerZMax: Double = 24.0

    /// Accelerometer magnitude threshold for motion validation (in g)
    private let accelerometerThreshold: Double = 0.5

    /// Cooldown between detections (seconds)
    private let detectionCooldown: TimeInterval = 2.0

    // MARK: - Activation

    /// Tap counter for activation gesture
    private var activationTapCount = 0
    private var lastTapTime: Date?
    private let tapTimeout: TimeInterval = 1.0
    private let requiredTaps = 3

    // MARK: - Initialization

    private init() {}

    // MARK: - Activation Gesture

    /// Handle tap on Port 5 for activation gesture
    /// - Returns: true if tech debug mode was activated
    func handlePort5Tap() -> Bool {
        let now = Date()

        // Reset tap count if too much time has passed
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > tapTimeout {
            activationTapCount = 0
        }

        activationTapCount += 1
        lastTapTime = now

        // Check for triple-tap
        if activationTapCount >= requiredTaps {
            activationTapCount = 0
            toggleTechDebugMode()
            return true
        }

        return false
    }

    /// Toggle tech debug mode
    private func toggleTechDebugMode() {
        debugMode.toggle()

        if debugMode {
            print("MotionDetectionService: Tech debug mode ACTIVATED")
            // Don't auto-enable monitoring, just show the option
        } else {
            print("MotionDetectionService: Tech debug mode DEACTIVATED")
            stopMonitoring()
            isEnabled = false
        }
    }

    // MARK: - Sensor Management

    /// Enable motion detection (requires debug mode)
    func enable() {
        guard debugMode else {
            print("MotionDetectionService: Cannot enable - debug mode not active")
            return
        }

        guard motionManager.isMagnetometerAvailable && motionManager.isAccelerometerAvailable else {
            print("MotionDetectionService: Required sensors not available")
            return
        }

        isEnabled = true
        print("MotionDetectionService: Enabled")
    }

    /// Disable motion detection
    func disable() {
        stopMonitoring()
        isEnabled = false
        print("MotionDetectionService: Disabled")
    }

    /// Start monitoring sensors
    func startMonitoring() {
        guard isEnabled else {
            print("MotionDetectionService: Cannot start - not enabled")
            return
        }

        guard !isMonitoring else { return }

        // Configure update intervals
        motionManager.magnetometerUpdateInterval = 0.1  // 10 Hz
        motionManager.accelerometerUpdateInterval = 0.1

        // Start magnetometer
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            Task { @MainActor in
                self.magnetometerData = data
                self.currentMagnetometerZ = data.magneticField.z
                self.processMotionData()
            }
        }

        // Start accelerometer
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self, let data = data else { return }
            Task { @MainActor in
                self.accelerometerData = data
                let magnitude = sqrt(
                    pow(data.acceleration.x, 2) +
                    pow(data.acceleration.y, 2) +
                    pow(data.acceleration.z, 2)
                )
                self.currentAccelerometerMagnitude = magnitude
            }
        }

        isMonitoring = true
        print("MotionDetectionService: Started monitoring")
    }

    /// Stop monitoring sensors
    func stopMonitoring() {
        motionManager.stopMagnetometerUpdates()
        motionManager.stopAccelerometerUpdates()
        isMonitoring = false
        magnetometerData = nil
        accelerometerData = nil
        print("MotionDetectionService: Stopped monitoring")
    }

    // MARK: - Dual-Gate Algorithm

    /// Process motion data through dual-gate algorithm
    private func processMotionData() {
        guard let magData = magnetometerData,
              let accelData = accelerometerData else { return }

        // Check cooldown
        if let lastDetection = lastDetectionTime,
           Date().timeIntervalSince(lastDetection) < detectionCooldown {
            return
        }

        // Gate 1: Magnetometer Z threshold
        let magnetZ = magData.magneticField.z
        guard magnetZ >= magnetometerZMin && magnetZ <= magnetometerZMax else {
            return
        }

        // Gate 2: Accelerometer magnitude validation
        let accelMagnitude = sqrt(
            pow(accelData.acceleration.x, 2) +
            pow(accelData.acceleration.y, 2) +
            pow(accelData.acceleration.z, 2)
        )
        guard accelMagnitude > accelerometerThreshold else {
            return
        }

        // Both gates passed - detect port
        if let port = identifyPort(magnetZ: magnetZ, accelMagnitude: accelMagnitude) {
            detectedPort = port
            lastDetectionTime = Date()
            print("MotionDetectionService: Detected Port \(port)")
        }
    }

    /// Identify which port was accessed based on sensor pattern
    /// - Parameters:
    ///   - magnetZ: Magnetometer Z reading
    ///   - accelMagnitude: Accelerometer magnitude
    /// - Returns: Port number (1-6) or nil if indeterminate
    private func identifyPort(magnetZ: Double, accelMagnitude: Double) -> Int? {
        // Port identification based on magnetometer Z variation
        // Different ports have slightly different magnetic signatures
        // due to their physical positions relative to the device

        // Note: In production, this would be calibrated for the specific
        // pill organizer hardware. For now, use a simplified heuristic.

        let normalizedZ = (magnetZ - magnetometerZMin) / (magnetometerZMax - magnetometerZMin)

        switch normalizedZ {
        case 0..<0.17:
            return 1
        case 0.17..<0.33:
            return 2
        case 0.33..<0.50:
            return 3
        case 0.50..<0.67:
            return 4
        case 0.67..<0.83:
            return 5
        case 0.83...1.0:
            return 6
        default:
            return nil
        }
    }

    // MARK: - Detection Callback

    /// Delegate callback when port is detected
    var onPortDetected: ((Int) -> Void)?

    /// Clear detected port
    func clearDetection() {
        detectedPort = nil
    }

    // MARK: - Calibration (Future)

    /// Calibration data for each port
    struct PortCalibration: Codable {
        var portNumber: Int
        var magnetZRange: ClosedRange<Double>
        var sampleCount: Int
    }

    /// Begin calibration process for a specific port
    func beginCalibration(for port: Int) {
        // TODO: Implement calibration workflow
        // 1. Prompt user to open specific port
        // 2. Collect sensor samples
        // 3. Calculate optimal thresholds
        // 4. Store calibration data
        print("MotionDetectionService: Calibration for Port \(port) - not yet implemented")
    }

    // MARK: - Sensor Status

    /// Check if required sensors are available
    var sensorsAvailable: Bool {
        motionManager.isMagnetometerAvailable && motionManager.isAccelerometerAvailable
    }

    /// Get sensor availability details
    var sensorStatus: SensorStatus {
        SensorStatus(
            magnetometerAvailable: motionManager.isMagnetometerAvailable,
            accelerometerAvailable: motionManager.isAccelerometerAvailable,
            gyroscopeAvailable: motionManager.isGyroAvailable
        )
    }
}

// MARK: - Supporting Types

struct SensorStatus {
    let magnetometerAvailable: Bool
    let accelerometerAvailable: Bool
    let gyroscopeAvailable: Bool

    var allRequiredAvailable: Bool {
        magnetometerAvailable && accelerometerAvailable
    }

    var statusText: String {
        if allRequiredAvailable {
            return "All sensors available"
        } else {
            var missing: [String] = []
            if !magnetometerAvailable { missing.append("magnetometer") }
            if !accelerometerAvailable { missing.append("accelerometer") }
            return "Missing: \(missing.joined(separator: ", "))"
        }
    }
}

// MARK: - Debug View Data

extension MotionDetectionService {
    /// Data structure for debug display
    struct DebugData {
        let magnetometerZ: Double
        let accelerometerMagnitude: Double
        let gate1Passed: Bool
        let gate2Passed: Bool
        let isMonitoring: Bool
        let lastDetection: Date?
        let detectedPort: Int?
    }

    /// Get current debug data
    var debugData: DebugData {
        let gate1 = currentMagnetometerZ >= magnetometerZMin &&
                    currentMagnetometerZ <= magnetometerZMax
        let gate2 = currentAccelerometerMagnitude > accelerometerThreshold

        return DebugData(
            magnetometerZ: currentMagnetometerZ,
            accelerometerMagnitude: currentAccelerometerMagnitude,
            gate1Passed: gate1,
            gate2Passed: gate2,
            isMonitoring: isMonitoring,
            lastDetection: lastDetectionTime,
            detectedPort: detectedPort
        )
    }
}
