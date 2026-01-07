// ExportServiceTests.swift
// Unit tests for ExportService

import XCTest
@testable import PillBack

final class ExportServiceTests: XCTestCase {

    var exportService: ExportService!

    override func setUp() {
        super.setUp()
        exportService = ExportService.shared
    }

    // MARK: - Test Data

    private func createTestDoses() -> [Dose] {
        let calendar = Calendar.current
        let now = Date()

        var doses: [Dose] = []

        // Dose 1: Taken on time
        var dose1 = Dose(
            portNumber: 1,
            scheduledTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!,
            medications: []
        )
        dose1.status = .taken
        dose1.actualTime = calendar.date(bySettingHour: 8, minute: 3, second: 0, of: now)!
        doses.append(dose1)

        // Dose 2: Taken late
        var dose2 = Dose(
            portNumber: 2,
            scheduledTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!,
            medications: []
        )
        dose2.status = .taken
        dose2.actualTime = calendar.date(bySettingHour: 12, minute: 25, second: 0, of: now)!
        doses.append(dose2)

        // Dose 3: Missed
        var dose3 = Dose(
            portNumber: 3,
            scheduledTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now)!,
            medications: []
        )
        dose3.status = .missed
        doses.append(dose3)

        // Dose 4: Pending
        let dose4 = Dose(
            portNumber: 4,
            scheduledTime: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)!,
            medications: []
        )
        doses.append(dose4)

        return doses
    }

    private func createTestMedications() -> [Medication] {
        return [
            Medication(id: 1, name: "Stalevo", frequency: 4, ports: "1-4", isKeyDrug: true),
            Medication(id: 2, name: "Vitamin D", frequency: 1, ports: "1")
        ]
    }

    // MARK: - Export Data Generation Tests

    func testGenerateExportData() {
        let doses = createTestDoses()
        let medications = createTestMedications()

        let exportData = exportService.generateExportData(
            doses: doses,
            medications: medications,
            userName: "Test Patient"
        )

        XCTAssertEqual(exportData.patientName, "Test Patient")
        XCTAssertEqual(exportData.records.count, 4)
        XCTAssertFalse(exportData.patientId.isEmpty)
    }

    func testExportSummaryCalculations() {
        let doses = createTestDoses()
        let medications = createTestMedications()

        let exportData = exportService.generateExportData(
            doses: doses,
            medications: medications,
            userName: "Test"
        )

        let summary = exportData.summary

        XCTAssertEqual(summary.totalDoses, 4)
        XCTAssertEqual(summary.dosesTaken, 2)
        XCTAssertEqual(summary.dosesMissed, 1)
        XCTAssertEqual(summary.dosesSkipped, 1)  // Pending counts as skipped for export purposes
    }

    func testAdherenceRateCalculation() {
        let doses = createTestDoses()

        let exportData = exportService.generateExportData(
            doses: doses,
            medications: [],
            userName: "Test"
        )

        // 2 taken out of 4 = 50%
        XCTAssertEqual(exportData.summary.adherenceRate, 50.0, accuracy: 0.1)
    }

    func testDateRangeFiltering() {
        let calendar = Calendar.current
        let now = Date()

        let doses = createTestDoses()

        // Filter to only include doses from first half of day
        let startOfDay = calendar.startOfDay(for: now)
        let midday = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now)!

        let exportData = exportService.generateExportData(
            doses: doses,
            medications: [],
            userName: "Test",
            dateRange: startOfDay...midday
        )

        // Should only include doses scheduled before 1 PM
        XCTAssertEqual(exportData.records.count, 2)
    }

    // MARK: - CSV Export Tests

    func testExportToCSV() {
        let doses = createTestDoses()
        let medications = createTestMedications()

        let exportData = exportService.generateExportData(
            doses: doses,
            medications: medications,
            userName: "Test Patient"
        )

        let csv = exportService.exportToCSV(exportData)

        // Check header
        XCTAssertTrue(csv.contains("# PillBack Clinical Export"))
        XCTAssertTrue(csv.contains("# Patient: Test Patient"))

        // Check column headers
        XCTAssertTrue(csv.contains("Date,Port,Medications,Scheduled Time"))

        // Check data rows
        XCTAssertTrue(csv.contains("Stalevo"))
        XCTAssertTrue(csv.contains("Taken"))
        XCTAssertTrue(csv.contains("Missed"))
    }

    func testCSVEscapesMedications() {
        let doses = [
            Dose(portNumber: 1, scheduledTime: Date(), medications: [])
        ]
        let medications = [
            Medication(id: 1, name: "Medication, With Comma", frequency: 1, ports: "1")
        ]

        let exportData = exportService.generateExportData(
            doses: doses,
            medications: medications,
            userName: "Test"
        )

        let csv = exportService.exportToCSV(exportData)

        // Medications with commas should be quoted
        XCTAssertTrue(csv.contains("\"Medication, With Comma\""))
    }

    // MARK: - JSON Export Tests

    func testExportToJSON() {
        let doses = createTestDoses()
        let medications = createTestMedications()

        let exportData = exportService.generateExportData(
            doses: doses,
            medications: medications,
            userName: "Test Patient"
        )

        let json = exportService.exportToJSON(exportData)

        XCTAssertFalse(json.isEmpty)
        XCTAssertNotEqual(json, "{}")

        // Should be valid JSON
        let data = json.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))

        // Check content
        XCTAssertTrue(json.contains("\"patientName\""))
        XCTAssertTrue(json.contains("Test Patient"))
        XCTAssertTrue(json.contains("\"records\""))
    }

    func testJSONContainsAllFields() {
        let doses = createTestDoses()

        let exportData = exportService.generateExportData(
            doses: doses,
            medications: [],
            userName: "Test"
        )

        let json = exportService.exportToJSON(exportData)

        // Required fields
        XCTAssertTrue(json.contains("\"patientId\""))
        XCTAssertTrue(json.contains("\"exportDate\""))
        XCTAssertTrue(json.contains("\"summary\""))
        XCTAssertTrue(json.contains("\"totalDoses\""))
        XCTAssertTrue(json.contains("\"adherenceRate\""))
    }

    // MARK: - File Generation Tests

    func testGenerateExportFileCSV() {
        let exportData = exportService.generateExportData(
            doses: createTestDoses(),
            medications: createTestMedications(),
            userName: "Test"
        )

        let (data, filename) = exportService.generateExportFile(
            format: .csv,
            exportData: exportData
        )

        XCTAssertFalse(data.isEmpty)
        XCTAssertTrue(filename.hasPrefix("PillBack_Export_"))
        XCTAssertTrue(filename.hasSuffix(".csv"))
    }

    func testGenerateExportFileJSON() {
        let exportData = exportService.generateExportData(
            doses: createTestDoses(),
            medications: createTestMedications(),
            userName: "Test"
        )

        let (data, filename) = exportService.generateExportFile(
            format: .json,
            exportData: exportData
        )

        XCTAssertFalse(data.isEmpty)
        XCTAssertTrue(filename.hasPrefix("PillBack_Export_"))
        XCTAssertTrue(filename.hasSuffix(".json"))
    }

    // MARK: - Export Format Tests

    func testExportFormatProperties() {
        XCTAssertEqual(ExportService.ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportService.ExportFormat.json.fileExtension, "json")

        XCTAssertEqual(ExportService.ExportFormat.csv.mimeType, "text/csv")
        XCTAssertEqual(ExportService.ExportFormat.json.mimeType, "application/json")
    }

    // MARK: - Timing Category Tests

    func testTimingCategoryInExport() {
        let calendar = Calendar.current
        let now = Date()

        var dose = Dose(
            portNumber: 1,
            scheduledTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!,
            medications: []
        )
        dose.status = .taken
        dose.actualTime = calendar.date(bySettingHour: 8, minute: 3, second: 0, of: now)!

        let exportData = exportService.generateExportData(
            doses: [dose],
            medications: [],
            userName: "Test"
        )

        XCTAssertEqual(exportData.records.count, 1)
        XCTAssertEqual(exportData.records[0].timingCategory, "Perfect")
    }

    // MARK: - Edge Cases

    func testExportWithNoDoses() {
        let exportData = exportService.generateExportData(
            doses: [],
            medications: [],
            userName: "Empty Test"
        )

        XCTAssertEqual(exportData.records.count, 0)
        XCTAssertEqual(exportData.summary.totalDoses, 0)
        XCTAssertEqual(exportData.summary.adherenceRate, 0)

        let csv = exportService.exportToCSV(exportData)
        XCTAssertTrue(csv.contains("# Total Doses: 0"))

        let json = exportService.exportToJSON(exportData)
        XCTAssertNotEqual(json, "{}")
    }

    func testExportWithOnlyMissedDoses() {
        var dose = Dose(portNumber: 1, scheduledTime: Date(), medications: [])
        dose.status = .missed

        let exportData = exportService.generateExportData(
            doses: [dose],
            medications: [],
            userName: "Test"
        )

        XCTAssertEqual(exportData.summary.dosesTaken, 0)
        XCTAssertEqual(exportData.summary.dosesMissed, 1)
        XCTAssertEqual(exportData.summary.adherenceRate, 0)
    }
}
