// OCRService.swift
// Vision framework integration for medication label scanning

import Foundation
@preconcurrency import Vision
import UIKit
import AVFoundation

/// Service for OCR text recognition from medication labels
/// Uses Apple's Vision framework for on-device processing (no cloud dependency)
final class OCRService {

    // MARK: - Singleton

    static let shared = OCRService()

    // MARK: - Properties

    /// Minimum confidence threshold for text recognition
    private let minimumConfidence: Float = 0.5

    // MARK: - Regex Patterns

    private static let strengthPattern = try! NSRegularExpression(
        pattern: "\\b(\\d+(?:\\.\\d+)?\\s*(?:mg|mcg|g|ml|iu)(?:\\s*/\\s*\\d+(?:\\.\\d+)?\\s*(?:mg|mcg|g|ml))?)\\b",
        options: .caseInsensitive
    )

    private static let formPatterns: [(pattern: String, form: MedicationForm)] = [
        ("\\btablet?s?\\b", .tablet),
        ("\\btabs?\\b", .tablet),
        ("\\bcapsules?\\b", .capsule),
        ("\\bcaps?\\b", .capsule),
        ("\\bliquid\\b", .liquid),
        ("\\bsolution\\b", .liquid),
        ("\\bsyrup\\b", .liquid),
        ("\\binjection\\b", .injection),
        ("\\bpatch(es)?\\b", .patch)
    ]

    /// Words to exclude from medication names (privacy-sensitive or irrelevant)
    private static let excludedWords = Set([
        "pharmacy", "pharmacies", "rx", "prescription",
        "dr", "dr.", "doctor", "md", "m.d.",
        "patient", "name", "address", "phone",
        "refill", "refills", "repeat", "repeats",
        "qty", "quantity", "take", "daily", "twice",
        "din", "date", "filled", "dispensed",
        "warning", "caution", "keep", "store"
    ])

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Recognize text from an image
    /// - Parameter image: The image to process
    /// - Returns: Array of recognized text results with confidence scores
    func recognizeText(from image: UIImage) async throws -> [OCRResult] {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.visionError(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let results = observations.compactMap { observation -> OCRResult? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    guard candidate.confidence >= self.minimumConfidence else { return nil }

                    return OCRResult(
                        recognizedText: candidate.string,
                        confidence: Double(candidate.confidence),
                        boundingBox: observation.boundingBox
                    )
                }

                continuation.resume(returning: results)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            let orientation = Self.cgOrientation(from: image.imageOrientation)
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.visionError(error))
                }
            }
        }
    }

    /// Extract minimal medication information from OCR results
    /// - Parameter results: Array of OCR results from text recognition
    /// - Returns: Extracted medication information
    func extractMedication(from results: [OCRResult]) -> MinimalMedication? {
        guard !results.isEmpty else { return nil }

        let allText = results.map { $0.recognizedText }.joined(separator: " ")
        let averageConfidence = results.map { $0.confidence }.reduce(0, +) / Double(results.count)

        // Extract strength
        let strength = extractStrength(from: allText)

        // Extract form
        let form = extractForm(from: allText)

        // Extract medication name (filtered for privacy)
        let name = extractMedicationName(from: results, excludingStrength: strength)

        guard !name.isEmpty else { return nil }

        return MinimalMedication.fromOCR(
            name: name,
            strength: strength,
            form: form,
            confidence: averageConfidence,
            rawText: allText
        )
    }

    /// Scan an image and extract medication information in one step
    /// - Parameter image: The image to scan
    /// - Returns: Extraction result with medication and raw OCR data
    func scanMedicationLabel(from image: UIImage) async throws -> MedicationExtractionResult? {
        let results = try await recognizeText(from: image)
        guard let medication = extractMedication(from: results) else { return nil }

        return MedicationExtractionResult(
            medication: medication,
            rawResults: results
        )
    }

    // MARK: - Private Extraction Methods

    private func extractStrength(from text: String) -> String? {
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)

        guard let match = Self.strengthPattern.firstMatch(in: text, options: [], range: range) else {
            return nil
        }

        if match.numberOfRanges >= 2, match.range(at: 1).location != NSNotFound {
            return nsText.substring(with: match.range(at: 1))
        }
        return nsText.substring(with: match.range)
    }

    private func extractForm(from text: String) -> MedicationForm {
        let lowercased = text.lowercased()

        for (pattern, form) in Self.formPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: lowercased.utf16.count)
                if regex.firstMatch(in: lowercased, options: [], range: range) != nil {
                    return form
                }
            }
        }

        return .unknown
    }

    private func extractMedicationName(from results: [OCRResult], excludingStrength strength: String?) -> String {
        // Sort by Y position (top to bottom in Vision coordinates means larger Y first)
        let sortedResults = results.sorted { ($0.boundingBox?.midY ?? 0) > ($1.boundingBox?.midY ?? 0) }

        // Look for the first line that appears to be a medication name
        for result in sortedResults {
            let text = result.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip very short or very long lines
            guard text.count >= 3 && text.count <= 100 else { continue }

            // Skip lines that are mostly numbers
            let letterCount = text.filter { $0.isLetter }.count
            guard Double(letterCount) / Double(text.count) > 0.5 else { continue }

            // Check if this line contains excluded words
            let lowercased = text.lowercased()
            let containsExcluded = Self.excludedWords.contains { lowercased.contains($0) }
            if containsExcluded { continue }

            // Remove strength from the name if present
            var name = text
            if let strength = strength {
                name = name.replacingOccurrences(of: strength, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Clean up the name
            name = cleanMedicationName(name)

            if !name.isEmpty {
                return name
            }
        }

        // Fallback: use the first result that has alphabetic characters
        for result in sortedResults {
            let cleaned = cleanMedicationName(result.recognizedText)
            if !cleaned.isEmpty {
                return cleaned
            }
        }

        return ""
    }

    private func cleanMedicationName(_ name: String) -> String {
        var cleaned = name

        // Remove common prefixes/suffixes that aren't part of the drug name
        let removePrefixes = ["APO-", "TEVA-", "PMS-", "RATIO-", "MYLAN-", "SANDOZ-"]
        for prefix in removePrefixes {
            if cleaned.uppercased().hasPrefix(prefix) {
                // Keep the prefix as it's part of the brand name, just standardize case
                break
            }
        }

        // Remove any remaining numbers at the end (likely dosage info)
        cleaned = cleaned.replacingOccurrences(
            of: "\\s*\\d+\\s*$",
            with: "",
            options: .regularExpression
        )

        // Remove special characters except hyphens and apostrophes
        cleaned = cleaned.replacingOccurrences(
            of: "[^a-zA-Z\\s\\-']",
            with: "",
            options: .regularExpression
        )

        // Normalize whitespace
        cleaned = cleaned.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Image Orientation Helper

    private static func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

// MARK: - OCR Errors

enum OCRError: LocalizedError {
    case invalidImage
    case visionError(Error)
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The image could not be processed"
        case .visionError(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        case .noTextFound:
            return "No text was found in the image"
        }
    }
}

// MARK: - Camera Permission Helper

enum CameraPermission {
    case authorized
    case denied
    case notDetermined

    static var current: CameraPermission {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    static func request() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}
