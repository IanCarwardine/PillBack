// AdherenceRecordTests.swift
// Unit tests for AdherenceRecord SwiftData model

import XCTest
import SwiftData
@testable import PillBack

final class AdherenceRecordTests: XCTestCase {

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
        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date()
        )

        XCTAssertEqual(record.portNumber, 1)
        XCTAssertEqual(record.status, "pending")
        XCTAssertNil(record.actualTime)
        XCTAssertNil(record.timingDifferenceMinutes)
    }

    func testFullInitialization() {
        let now = Date()
        let actualTime = now.addingTimeInterval(5 * 60) // 5 minutes later

        let record = AdherenceRecord(
            portNumber: 2,
            scheduledTime: now,
            actualTime: actualTime,
            status: "taken",
            timingDifferenceMinutes: 5,
            timingAccuracy: 1.0,
            timingCategory: "excellent",
            recordSource: "manual",
            medications: ["Med A", "Med B"]
        )

        XCTAssertEqual(record.portNumber, 2)
        XCTAssertEqual(record.status, "taken")
        XCTAssertEqual(record.actualTime, actualTime)
        XCTAssertEqual(record.timingDifferenceMinutes, 5)
        XCTAssertEqual(record.timingAccuracy, 1.0)
        XCTAssertEqual(record.timingCategory, "excellent")
        XCTAssertEqual(record.recordSource, "manual")
        XCTAssertEqual(record.medications, ["Med A", "Med B"])
    }

    func testInitializationFromDose() {
        let dose = Dose(portNumber: 3, scheduledTime: Date(), medications: [])
        var mutableDose = dose
        mutableDose.status = .taken
        mutableDose.actualTime = Date()

        let medications = [
            Medication(id: 1, name: "Test Med", frequency: 1, ports: "3")
        ]

        let record = AdherenceRecord(from: mutableDose, medications: medications, source: .manual)

        XCTAssertEqual(record.portNumber, 3)
        XCTAssertEqual(record.status, "taken")
        XCTAssertNotNil(record.actualTime)
        XCTAssertEqual(record.medications, ["Test Med"])
    }

    // MARK: - DateKey Tests

    func testDateKeyIsStartOfDay() {
        let calendar = Calendar.current
        let specificTime = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date())!

        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: specificTime
        )

        let startOfDay = calendar.startOfDay(for: specificTime)
        XCTAssertEqual(record.dateKey, startOfDay)
    }

    // MARK: - Medication Encoding Tests

    func testMedicationsEncoding() {
        let medications = ["Stalevo", "Vitamin D", "Aspirin"]

        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            medications: medications
        )

        XCTAssertEqual(record.medications, medications)
    }

    func testEmptyMedications() {
        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            medications: []
        )

        XCTAssertTrue(record.medications.isEmpty)
    }

    // MARK: - Computed Properties Tests

    func testIsTaken() {
        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            status: "taken"
        )

        XCTAssertTrue(record.isTaken)
        XCTAssertFalse(record.isMissed)
    }

    func testIsMissed() {
        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            status: "missed"
        )

        XCTAssertTrue(record.isMissed)
        XCTAssertFalse(record.isTaken)
    }

    func testIsOnTime() {
        let recordOnTime = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            timingDifferenceMinutes: 3
        )
        XCTAssertTrue(recordOnTime.isOnTime)

        let recordLate = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            timingDifferenceMinutes: 10
        )
        XCTAssertFalse(recordLate.isOnTime)
    }

    func testIsOnTimeEarly() {
        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            timingDifferenceMinutes: -3  // 3 minutes early
        )
        XCTAssertTrue(record.isOnTime)
    }

    // MARK: - Persistence Tests

    func testPersistence() {
        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            status: "taken"
        )

        modelContext.insert(record)

        do {
            try modelContext.save()

            let descriptor = FetchDescriptor<AdherenceRecord>()
            let fetched = try modelContext.fetch(descriptor)

            XCTAssertEqual(fetched.count, 1)
            XCTAssertEqual(fetched.first?.portNumber, 1)
            XCTAssertEqual(fetched.first?.status, "taken")
        } catch {
            XCTFail("Persistence failed: \(error)")
        }
    }

    func testMultipleRecordsPersistence() {
        for i in 1...4 {
            let record = AdherenceRecord(
                portNumber: i,
                scheduledTime: Date(),
                status: i <= 2 ? "taken" : "missed"
            )
            modelContext.insert(record)
        }

        do {
            try modelContext.save()

            let descriptor = FetchDescriptor<AdherenceRecord>()
            let fetched = try modelContext.fetch(descriptor)

            XCTAssertEqual(fetched.count, 4)

            let taken = fetched.filter { $0.status == "taken" }
            let missed = fetched.filter { $0.status == "missed" }

            XCTAssertEqual(taken.count, 2)
            XCTAssertEqual(missed.count, 2)
        } catch {
            XCTFail("Multiple records persistence failed: \(error)")
        }
    }

    // MARK: - Formatting Tests

    func testScheduledTimeString() {
        let calendar = Calendar.current
        let time = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: Date())!

        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: time
        )

        XCTAssertFalse(record.scheduledTimeString.isEmpty)
    }

    func testActualTimeStringWhenNil() {
        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date()
        )

        XCTAssertNil(record.actualTimeString)
    }

    func testActualTimeStringWhenSet() {
        let record = AdherenceRecord(
            portNumber: 1,
            scheduledTime: Date(),
            actualTime: Date()
        )

        XCTAssertNotNil(record.actualTimeString)
    }
}

// MARK: - RecordSource Tests

final class RecordSourceTests: XCTestCase {

    func testRecordSourceRawValues() {
        XCTAssertEqual(RecordSource.manual.rawValue, "manual")
        XCTAssertEqual(RecordSource.notification.rawValue, "notification")
        XCTAssertEqual(RecordSource.motion.rawValue, "motion")
        XCTAssertEqual(RecordSource.automatic.rawValue, "automatic")
    }
}
