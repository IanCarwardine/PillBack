// ExportService.swift
// Export service for clinical trial data in CSV and JSON formats

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Service for exporting adherence data in clinical trial formats
class ExportService {

    // MARK: - Singleton

    static let shared = ExportService()

    private init() {}

    // MARK: - Export Formats

    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"

        var fileExtension: String {
            switch self {
            case .csv: return "csv"
            case .json: return "json"
            }
        }

        var utType: UTType {
            switch self {
            case .csv: return .commaSeparatedText
            case .json: return .json
            }
        }

        var mimeType: String {
            switch self {
            case .csv: return "text/csv"
            case .json: return "application/json"
            }
        }
    }

    // MARK: - Export Data Structures

    /// Complete clinical export package
    struct ClinicalExport: Codable {
        let patientId: String
        let patientName: String
        let exportDate: Date
        let startDate: Date
        let endDate: Date
        let records: [ExportRecord]
        let summary: ExportSummary
        let appVersion: String
        let exportFormat: String
    }

    /// Individual dose record for export
    struct ExportRecord: Codable {
        let date: String
        let port: Int
        let medications: [String]
        let scheduledTime: String
        let actualTime: String?
        let timingDifferenceMinutes: Int?
        let timingAccuracy: Double?
        let timingCategory: String
        let status: String
    }

    /// Summary statistics for export
    struct ExportSummary: Codable {
        let totalDoses: Int
        let dosesTaken: Int
        let dosesMissed: Int
        let dosesSkipped: Int
        let adherenceRate: Double
        let averageTimingAccuracy: Double
        let perfectTimingCount: Int      // ≤5 min
        let goodTimingCount: Int         // ≤10 min
        let fairTimingCount: Int         // ≤20 min
        let poorTimingCount: Int         // >20 min
        let averageTimingDifference: Double
        let earliestDose: String?
        let latestDose: String?
    }

    // MARK: - Export Generation

    /// Generate export data from doses
    /// - Parameters:
    ///   - doses: Array of doses to export
    ///   - medications: All medications
    ///   - userName: Patient name
    ///   - dateRange: Optional date range filter
    /// - Returns: ClinicalExport structure
    func generateExportData(
        doses: [Dose],
        medications: [Medication],
        userName: String,
        dateRange: ClosedRange<Date>? = nil
    ) -> ClinicalExport {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        // Filter doses by date range if provided
        let filteredDoses: [Dose]
        if let range = dateRange {
            filteredDoses = doses.filter { range.contains($0.scheduledTime) }
        } else {
            filteredDoses = doses
        }

        // Generate records
        let records: [ExportRecord] = filteredDoses.map { dose in
            let doseMedications = medications.filter { $0.isInPort(dose.portNumber) }

            return ExportRecord(
                date: dateFormatter.string(from: dose.scheduledTime),
                port: dose.portNumber,
                medications: doseMedications.map { $0.name },
                scheduledTime: timeFormatter.string(from: dose.scheduledTime),
                actualTime: dose.actualTime.map { timeFormatter.string(from: $0) },
                timingDifferenceMinutes: dose.timingDifference,
                timingAccuracy: dose.status == .taken ? dose.timingAccuracy : nil,
                timingCategory: dose.timingCategory.rawValue,
                status: dose.status.rawValue
            )
        }

        // Calculate summary
        let takenDoses = filteredDoses.filter { $0.status == .taken }
        let missedDoses = filteredDoses.filter { $0.status == .missed }

        let timingDifferences = takenDoses.compactMap { $0.timingDifference }
        let avgTimingDiff = timingDifferences.isEmpty ? 0.0 :
            Double(timingDifferences.reduce(0, +)) / Double(timingDifferences.count)

        let timingAccuracies = takenDoses.map { $0.timingAccuracy }
        let avgAccuracy = timingAccuracies.isEmpty ? 0.0 :
            timingAccuracies.reduce(0, +) / Double(timingAccuracies.count)

        // Count timing categories
        var perfectCount = 0, goodCount = 0, fairCount = 0, poorCount = 0
        for dose in takenDoses {
            switch dose.timingCategory {
            case .excellent: perfectCount += 1
            case .good: goodCount += 1
            case .fair: fairCount += 1
            case .poor: poorCount += 1
            case .pending: break
            }
        }

        // Find earliest/latest actual times
        let actualTimes = takenDoses.compactMap { $0.actualTime }
        let earliestTime = actualTimes.min().map { timeFormatter.string(from: $0) }
        let latestTime = actualTimes.max().map { timeFormatter.string(from: $0) }

        let summary = ExportSummary(
            totalDoses: filteredDoses.count,
            dosesTaken: takenDoses.count,
            dosesMissed: missedDoses.count,
            dosesSkipped: filteredDoses.count - takenDoses.count - missedDoses.count,
            adherenceRate: filteredDoses.isEmpty ? 0 :
                Double(takenDoses.count) / Double(filteredDoses.count) * 100,
            averageTimingAccuracy: avgAccuracy * 100,
            perfectTimingCount: perfectCount,
            goodTimingCount: goodCount,
            fairTimingCount: fairCount,
            poorTimingCount: poorCount,
            averageTimingDifference: avgTimingDiff,
            earliestDose: earliestTime,
            latestDose: latestTime
        )

        // Determine date range
        let sortedDates = filteredDoses.map { $0.scheduledTime }.sorted()
        let startDate = dateRange?.lowerBound ?? sortedDates.first ?? Date()
        let endDate = dateRange?.upperBound ?? sortedDates.last ?? Date()

        return ClinicalExport(
            patientId: UUID().uuidString.prefix(8).uppercased().description,
            patientName: userName,
            exportDate: Date(),
            startDate: startDate,
            endDate: endDate,
            records: records,
            summary: summary,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            exportFormat: "PillBack Clinical Export v1.0"
        )
    }

    // MARK: - CSV Export

    /// Export data as CSV string
    func exportToCSV(_ exportData: ClinicalExport) -> String {
        var csv = ""

        // Header section
        csv += "# PillBack Clinical Export\n"
        csv += "# Patient: \(exportData.patientName)\n"
        csv += "# Patient ID: \(exportData.patientId)\n"
        csv += "# Export Date: \(formatDate(exportData.exportDate))\n"
        csv += "# Date Range: \(formatDate(exportData.startDate)) to \(formatDate(exportData.endDate))\n"
        csv += "# App Version: \(exportData.appVersion)\n"
        csv += "#\n"

        // Summary section
        csv += "# SUMMARY\n"
        csv += "# Total Doses: \(exportData.summary.totalDoses)\n"
        csv += "# Doses Taken: \(exportData.summary.dosesTaken)\n"
        csv += "# Doses Missed: \(exportData.summary.dosesMissed)\n"
        csv += "# Adherence Rate: \(String(format: "%.1f", exportData.summary.adherenceRate))%\n"
        csv += "# Average Timing Accuracy: \(String(format: "%.1f", exportData.summary.averageTimingAccuracy))%\n"
        csv += "# Average Timing Difference: \(String(format: "%.1f", exportData.summary.averageTimingDifference)) minutes\n"
        csv += "#\n"

        // Column headers
        csv += "Date,Port,Medications,Scheduled Time,Actual Time,Timing Difference (min),Timing Accuracy (%),Timing Category,Status\n"

        // Data rows
        for record in exportData.records {
            let medications = record.medications.joined(separator: "; ")
            let actualTime = record.actualTime ?? ""
            let timingDiff = record.timingDifferenceMinutes.map { String($0) } ?? ""
            let timingAcc = record.timingAccuracy.map { String(format: "%.1f", $0 * 100) } ?? ""

            csv += "\(record.date),"
            csv += "\(record.port),"
            csv += "\"\(medications)\","
            csv += "\(record.scheduledTime),"
            csv += "\(actualTime),"
            csv += "\(timingDiff),"
            csv += "\(timingAcc),"
            csv += "\(record.timingCategory),"
            csv += "\(record.status)\n"
        }

        return csv
    }

    // MARK: - JSON Export

    /// Export data as JSON string
    func exportToJSON(_ exportData: ClinicalExport) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(exportData)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            print("ExportService: JSON encoding failed - \(error)")
            return "{}"
        }
    }

    // MARK: - File Generation

    /// Generate export file data
    /// - Parameters:
    ///   - format: Export format (CSV or JSON)
    ///   - exportData: The clinical export data
    /// - Returns: Tuple of (data, filename)
    func generateExportFile(format: ExportFormat, exportData: ClinicalExport) -> (data: Data, filename: String) {
        let content: String
        switch format {
        case .csv:
            content = exportToCSV(exportData)
        case .json:
            content = exportToJSON(exportData)
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())

        let filename = "PillBack_Export_\(timestamp).\(format.fileExtension)"
        let data = content.data(using: .utf8) ?? Data()

        return (data, filename)
    }

    // MARK: - Share Sheet

    /// Create a share sheet for exporting data
    /// - Parameters:
    ///   - format: Export format
    ///   - exportData: The clinical export data
    /// - Returns: UIActivityViewController for presentation
    func createShareSheet(format: ExportFormat, exportData: ClinicalExport) -> UIActivityViewController {
        let (data, filename) = generateExportFile(format: format, exportData: exportData)

        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)

        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        // Exclude some activities that don't make sense
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .postToFacebook,
            .postToTwitter,
            .postToWeibo
        ]

        return activityVC
    }

    // MARK: - Convenience Methods

    /// Quick export for today's doses
    func exportToday(doses: [Dose], medications: [Medication], userName: String, format: ExportFormat) -> (data: Data, filename: String) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let exportData = generateExportData(
            doses: doses,
            medications: medications,
            userName: userName,
            dateRange: startOfDay...endOfDay
        )

        return generateExportFile(format: format, exportData: exportData)
    }

    /// Quick export for last 7 days
    func exportLastWeek(doses: [Dose], medications: [Medication], userName: String, format: ExportFormat) -> (data: Data, filename: String) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!

        let exportData = generateExportData(
            doses: doses,
            medications: medications,
            userName: userName,
            dateRange: startDate...endDate
        )

        return generateExportFile(format: format, exportData: exportData)
    }

    /// Quick export for last 30 days
    func exportLastMonth(doses: [Dose], medications: [Medication], userName: String, format: ExportFormat) -> (data: Data, filename: String) {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!

        let exportData = generateExportData(
            doses: doses,
            medications: medications,
            userName: userName,
            dateRange: startDate...endDate
        )

        return generateExportFile(format: format, exportData: exportData)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - SwiftUI Share Sheet Wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?

    init(activityItems: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.activityItems = activityItems
        self.excludedActivityTypes = excludedActivityTypes
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
