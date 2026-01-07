// MinimalMedication.swift
// Privacy-first medication model for OCR-captured data

import Foundation

/// How the medication was added to the system
enum MedicationSource: String, Codable {
    case manual = "manual"
    case ocr = "ocr"
}

/// Form of the medication (optional metadata)
enum MedicationForm: String, Codable, CaseIterable {
    case tablet = "tablet"
    case capsule = "capsule"
    case liquid = "liquid"
    case injection = "injection"
    case patch = "patch"
    case other = "other"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .tablet: return "Tablet"
        case .capsule: return "Capsule"
        case .liquid: return "Liquid"
        case .injection: return "Injection"
        case .patch: return "Patch"
        case .other: return "Other"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .tablet: return "pill.circle.fill"
        case .capsule: return "pills.fill"
        case .liquid: return "drop.fill"
        case .injection: return "syringe.fill"
        case .patch: return "bandage.fill"
        case .other, .unknown: return "cross.circle.fill"
        }
    }
}

/// Privacy-first medication model storing only essential information
///
/// This model is designed to capture the minimum data needed for medication tracking
/// while avoiding storage of sensitive health information like prescriber details,
/// pharmacy information, or detailed health conditions.
///
/// Fields NOT stored (privacy by design):
/// - Prescriber name/details
/// - Pharmacy information
/// - Patient identifiers
/// - Diagnosis/condition
/// - Refill information
/// - Insurance details
struct MinimalMedication: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var strength: String?
    var form: MedicationForm
    var source: MedicationSource

    // Timestamps
    var createdAt: Date
    var updatedAt: Date

    // OCR metadata (only populated when source == .ocr)
    var ocrConfidence: Double?
    var ocrRawText: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String,
        strength: String? = nil,
        form: MedicationForm = .unknown,
        source: MedicationSource = .manual,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        ocrConfidence: Double? = nil,
        ocrRawText: String? = nil
    ) {
        self.id = id
        self.name = name
        self.strength = strength
        self.form = form
        self.source = source
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ocrConfidence = ocrConfidence
        self.ocrRawText = ocrRawText
    }

    // MARK: - Factory Methods

    /// Create from OCR scan result
    static func fromOCR(
        name: String,
        strength: String? = nil,
        form: MedicationForm = .unknown,
        confidence: Double,
        rawText: String
    ) -> MinimalMedication {
        MinimalMedication(
            name: name,
            strength: strength,
            form: form,
            source: .ocr,
            ocrConfidence: confidence,
            ocrRawText: rawText
        )
    }

    /// Create manually entered medication
    static func manual(
        name: String,
        strength: String? = nil,
        form: MedicationForm = .unknown
    ) -> MinimalMedication {
        MinimalMedication(
            name: name,
            strength: strength,
            form: form,
            source: .manual
        )
    }

    // MARK: - Display Helpers

    /// Display name with strength if available
    var displayName: String {
        if let strength = strength, !strength.isEmpty {
            return "\(name) \(strength)"
        }
        return name
    }

    /// Short display for compact views
    var shortDisplayName: String {
        if name.count > 20 {
            return String(name.prefix(17)) + "..."
        }
        return name
    }

    /// Confidence level description for OCR results
    var confidenceLevel: String? {
        guard source == .ocr, let confidence = ocrConfidence else { return nil }
        switch confidence {
        case 0.9...:
            return "High confidence"
        case 0.7..<0.9:
            return "Medium confidence"
        case 0.5..<0.7:
            return "Low confidence"
        default:
            return "Very low confidence"
        }
    }

    /// Whether this OCR result should be reviewed by user
    var needsReview: Bool {
        guard source == .ocr, let confidence = ocrConfidence else { return false }
        return confidence < 0.9
    }

    // MARK: - Mutation

    /// Update the medication and refresh updatedAt timestamp
    mutating func update(
        name: String? = nil,
        strength: String? = nil,
        form: MedicationForm? = nil
    ) {
        if let name = name {
            self.name = name
        }
        if let strength = strength {
            self.strength = strength
        }
        if let form = form {
            self.form = form
        }
        self.updatedAt = Date()
    }
}

// MARK: - OCR Result

/// Result from OCR text recognition
struct OCRResult: Equatable {
    let recognizedText: String
    let confidence: Double
    let boundingBox: CGRect?

    init(recognizedText: String, confidence: Double, boundingBox: CGRect? = nil) {
        self.recognizedText = recognizedText
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

// MARK: - Medication Extraction Result

/// Extracted medication information from OCR
struct MedicationExtractionResult: Equatable {
    let medication: MinimalMedication
    let rawResults: [OCRResult]
    let extractionDate: Date

    init(medication: MinimalMedication, rawResults: [OCRResult], extractionDate: Date = Date()) {
        self.medication = medication
        self.rawResults = rawResults
        self.extractionDate = extractionDate
    }
}

// MARK: - Preview Helpers

extension MinimalMedication {
    /// Sample medications for previews and testing
    static let samples: [MinimalMedication] = [
        MinimalMedication.manual(
            name: "Stalevo",
            strength: "200/50/37mg",
            form: .tablet
        ),
        MinimalMedication.fromOCR(
            name: "Pramipexole",
            strength: "0.25mg",
            form: .tablet,
            confidence: 0.95,
            rawText: "PRAMIPEXOLE 0.25 MG TABLET"
        ),
        MinimalMedication.fromOCR(
            name: "Unknown Med",
            strength: "10mg",
            form: .capsule,
            confidence: 0.65,
            rawText: "UNKN0WN M3D 10 MG CAP"
        )
    ]
}
