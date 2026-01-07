// DoseHistoryTests.swift
// Unit tests for DoseHistory SwiftData model

import XCTest
import SwiftData
@testable import PillBack

final class DoseHistoryTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() {
        super.setUp()

        let schema = Schema([AdherenceRecord.self, DoseHistory.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testBasicInitialization() {
        let history = DoseHistory(date: Date())

        XCTAssertEqual(history.totalDoses, 0)
        XCTAssertEqual(history.dosesTaken, 0)
        XCTAssertEqual(history.dosesMissed, 0)
        XCTAssertEqual(history.adherenceScore, 0)
        XCTAssertFalse(history.isPerfectDay)
    }

    func testFullInitialization() {
        let history = DoseHistory(
            date: Date(),
            totalDoses: 4,
            dosesTaken: 4,
            dosesMissed: 0,
            adherenceScore: 100,
            averageTimingAccuracy: 0.95,
            isPerfectDay: true,
            streakCount: 5,
            portCount: 4
        )

        XCTAssertEqual(history.totalDoses, 4)
        XCTAssertEqual(history.dosesTaken, 4)
        XCTAssertEqual(history.adherenceScore, 100)
        XCTAssertEqual(history.averageTimingAccuracy, 0.95)
        XCTAssertTrue(history.isPerfectDay)
        XCTAssertEqual(history.streakCount, 5)
        XCTAssertEqual(history.portCount, 4)
    }

    func testDateIsStartOfDay() {
        let calendar = Calendar.current
        let specificTime = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date())!

        let history = DoseHistory(date: specificTime)

        let startOfDay = calendar.startOfDay(for: specificTime)
        XCTAssertEqual(history.date, startOfDay)
    }

    // MARK: - Update From Records Tests

    func testUpdateFromRecordsPerfectDay() {
        let history = DoseHistory(date: Date())

        let records = [
            createRecord(status: "taken", timingAccuracy: 1.0),
            createRecord(status: "taken", timingAccuracy: 0.95),
            createRecord(status: "taken", timingAccuracy: 0.90),
            createRecord(status: "taken", timingAccuracy: 0.85)
        ]

        history.updateFromRecords(records)

        XCTAssertEqual(history.totalDoses, 4)
        XCTAssertEqual(history.dosesTaken, 4)
        XCTAssertEqual(history.dosesMissed, 0)
        XCTAssertEqual(history.adherenceScore, 100)
        XCTAssertTrue(history.isPerfectDay)
    }

    func testUpdateFromRecordsMixedDay() {
        let history = DoseHistory(date: Date())

        let records = [
            createRecord(status: "taken", timingAccuracy: 1.0),
            createRecord(status: "taken", timingAccuracy: 0.90),
            createRecord(status: "missed", timingAccuracy: nil),
            createRecord(status: "skipped", timingAccuracy: nil)
        ]

        history.updateFromRecords(records)

        XCTAssertEqual(history.totalDoses, 4)
        XCTAssertEqual(history.dosesTaken, 2)
        XCTAssertEqual(history.dosesMissed, 1)
        XCTAssertEqual(history.dosesSkipped, 1)
        XCTAssertEqual(history.adherenceScore, 50)
        XCTAssertFalse(history.isPerfectDay)
    }

    func testUpdateFromEmptyRecords() {
        let history = DoseHistory(date: Date())

        history.updateFromRecords([])

        XCTAssertEqual(history.totalDoses, 0)
        XCTAssertEqual(history.adherenceScore, 0)
        XCTAssertFalse(history.isPerfectDay)
    }

    func testAverageTimingAccuracyCalculation() {
        let history = DoseHistory(date: Date())

        let records = [
            createRecord(status: "taken", timingAccuracy: 1.0),
            createRecord(status: "taken", timingAccuracy: 0.80),
            createRecord(status: "missed", timingAccuracy: nil)  // Should not count
        ]

        history.updateFromRecords(records)

        // Average of 1.0 and 0.80 = 0.90
        XCTAssertEqual(history.averageTimingAccuracy, 0.90, accuracy: 0.01)
    }

    // MARK: - Computed Properties Tests

    func testDosesPending() {
        let history = DoseHistory(
            date: Date(),
            totalDoses: 4,
            dosesTaken: 1,
            dosesMissed: 1,
            dosesSkipped: 0
        )

        XCTAssertEqual(history.dosesPending, 2)
    }

    func testAdherenceScoreText() {
        let history = DoseHistory(date: Date(), adherenceScore: 87.5)

        XCTAssertEqual(history.adherenceScoreText, "88%")
    }

    func testTimingAccuracyText() {
        let history = DoseHistory(date: Date(), averageTimingAccuracy: 0.95)

        XCTAssertEqual(history.timingAccuracyText, "95%")
    }

    func testIsToday() {
        let today = DoseHistory(date: Date())
        XCTAssertTrue(today.isToday)

        let yesterday = DoseHistory(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        XCTAssertFalse(yesterday.isToday)
    }

    func testIsYesterday() {
        let yesterday = DoseHistory(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        XCTAssertTrue(yesterday.isYesterday)

        let today = DoseHistory(date: Date())
        XCTAssertFalse(today.isYesterday)
    }

    // MARK: - Day Status Tests

    func testDayStatusPerfect() {
        let history = DoseHistory(date: Date(), isPerfectDay: true)

        XCTAssertEqual(history.dayStatus, .perfect)
    }

    func testDayStatusGood() {
        let history = DoseHistory(
            date: Date(),
            adherenceScore: 85,
            isPerfectDay: false
        )

        XCTAssertEqual(history.dayStatus, .good)
    }

    func testDayStatusFair() {
        let history = DoseHistory(
            date: Date(),
            dosesTaken: 2,
            adherenceScore: 60,
            isPerfectDay: false
        )

        XCTAssertEqual(history.dayStatus, .fair)
    }

    func testDayStatusPoor() {
        let history = DoseHistory(
            date: Date(),
            dosesTaken: 1,
            adherenceScore: 25,
            isPerfectDay: false
        )

        XCTAssertEqual(history.dayStatus, .poor)
    }

    func testDayStatusMissed() {
        let history = DoseHistory(
            date: Date(),
            dosesTaken: 0,
            adherenceScore: 0,
            isPerfectDay: false
        )

        XCTAssertEqual(history.dayStatus, .missed)
    }

    // MARK: - Persistence Tests

    func testPersistence() {
        let history = DoseHistory(
            date: Date(),
            totalDoses: 4,
            dosesTaken: 3,
            adherenceScore: 75,
            isPerfectDay: false
        )

        modelContext.insert(history)

        do {
            try modelContext.save()

            let descriptor = FetchDescriptor<DoseHistory>()
            let fetched = try modelContext.fetch(descriptor)

            XCTAssertEqual(fetched.count, 1)
            XCTAssertEqual(fetched.first?.totalDoses, 4)
            XCTAssertEqual(fetched.first?.dosesTaken, 3)
            XCTAssertEqual(fetched.first?.adherenceScore, 75)
        } catch {
            XCTFail("Persistence failed: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func createRecord(status: String, timingAccuracy: Double?) -> AdherenceRecord {
        AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            actualTime: status == "taken" ? Date() : nil,
            status: status,
            timingAccuracy: timingAccuracy
        )
    }
}

// MARK: - DayStatus Tests

final class DayStatusTests: XCTestCase {

    func testDayStatusEmoji() {
        XCTAssertEqual(DayStatus.perfect.emoji, "🌟")
        XCTAssertEqual(DayStatus.good.emoji, "✅")
        XCTAssertEqual(DayStatus.fair.emoji, "⚠️")
        XCTAssertEqual(DayStatus.poor.emoji, "❌")
        XCTAssertEqual(DayStatus.missed.emoji, "⛔")
    }

    func testDayStatusColor() {
        XCTAssertEqual(DayStatus.perfect.color, "success")
        XCTAssertEqual(DayStatus.good.color, "success")
        XCTAssertEqual(DayStatus.fair.color, "warning")
        XCTAssertEqual(DayStatus.poor.color, "danger")
        XCTAssertEqual(DayStatus.missed.color, "danger")
    }
}
