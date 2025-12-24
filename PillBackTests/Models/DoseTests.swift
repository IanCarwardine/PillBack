// DoseTests.swift
// Unit tests for Dose model timing accuracy calculations

import XCTest
@testable import PillBack

final class DoseTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeDose(scheduledTime: Date, actualTime: Date?) -> Dose {
        Dose(
            portNumber: 1,
            scheduledTime: scheduledTime,
            actualTime: actualTime,
            medications: [],
            status: actualTime != nil ? .taken : .pending
        )
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
    }

    // MARK: - Timing Difference Tests

    func test_timingDifference_nil_whenNotTaken() {
        let dose = makeDose(scheduledTime: makeDate(hour: 8, minute: 0), actualTime: nil)
        XCTAssertNil(dose.timingDifference)
    }

    func test_timingDifference_zero_whenOnTime() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let dose = makeDose(scheduledTime: scheduled, actualTime: scheduled)
        XCTAssertEqual(dose.timingDifference, 0)
    }

    func test_timingDifference_positive_whenLate() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 10)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingDifference, 10)
    }

    func test_timingDifference_negative_whenEarly() {
        let scheduled = makeDate(hour: 8, minute: 10)
        let actual = makeDate(hour: 8, minute: 0)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingDifference, -10)
    }

    // MARK: - Timing Accuracy Tests

    func test_timingAccuracy_perfect_whenWithin5Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 3)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 1.0)
    }

    func test_timingAccuracy_perfect_whenExactly5Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 5)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 1.0)
    }

    func test_timingAccuracy_good_when6Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 6)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 0.95)
    }

    func test_timingAccuracy_good_whenWithin10Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 10)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 0.95)
    }

    func test_timingAccuracy_fair_when15Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 15)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 0.85)
    }

    func test_timingAccuracy_fair_whenWithin20Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 20)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 0.85)
    }

    func test_timingAccuracy_poor_when25Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 25)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 0.70)
    }

    func test_timingAccuracy_poor_whenWithin30Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 30)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 0.70)
    }

    func test_timingAccuracy_veryPoor_whenOver30Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 45)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 0.50)
    }

    func test_timingAccuracy_zero_whenNotTaken() {
        let dose = makeDose(scheduledTime: makeDate(hour: 8, minute: 0), actualTime: nil)
        XCTAssertEqual(dose.timingAccuracy, 0.0)
    }

    func test_timingAccuracy_worksForEarlyDoses() {
        let scheduled = makeDate(hour: 8, minute: 10)
        let actual = makeDate(hour: 8, minute: 7) // 3 minutes early
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingAccuracy, 1.0) // Still perfect
    }

    // MARK: - Timing Category Tests

    func test_timingCategory_pending_whenNotTaken() {
        let dose = makeDose(scheduledTime: makeDate(hour: 8, minute: 0), actualTime: nil)
        XCTAssertEqual(dose.timingCategory, .pending)
    }

    func test_timingCategory_excellent_whenWithin5Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 3)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingCategory, .excellent)
    }

    func test_timingCategory_good_whenWithin10Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 8)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingCategory, .good)
    }

    func test_timingCategory_fair_whenWithin20Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 15)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingCategory, .fair)
    }

    func test_timingCategory_poor_whenOver20Minutes() {
        let scheduled = makeDate(hour: 8, minute: 0)
        let actual = makeDate(hour: 8, minute: 25)
        let dose = makeDose(scheduledTime: scheduled, actualTime: actual)
        XCTAssertEqual(dose.timingCategory, .poor)
    }

    // MARK: - Status Tests

    func test_isOverdue_true_whenPendingAndPastSchedule() {
        let pastTime = Date().addingTimeInterval(-60 * 60) // 1 hour ago
        let dose = makeDose(scheduledTime: pastTime, actualTime: nil)
        XCTAssertTrue(dose.isOverdue)
    }

    func test_isOverdue_false_whenTaken() {
        let pastTime = Date().addingTimeInterval(-60 * 60) // 1 hour ago
        var dose = makeDose(scheduledTime: pastTime, actualTime: pastTime)
        dose.status = .taken
        XCTAssertFalse(dose.isOverdue)
    }

    func test_isOverdue_false_whenFutureSchedule() {
        let futureTime = Date().addingTimeInterval(60 * 60) // 1 hour from now
        let dose = makeDose(scheduledTime: futureTime, actualTime: nil)
        XCTAssertFalse(dose.isOverdue)
    }

    // MARK: - Codable Tests

    func test_dose_encodesAndDecodes() throws {
        let original = Dose(
            portNumber: 3,
            scheduledTime: Date(),
            actualTime: Date(),
            medications: [Medication(id: 1, name: "Test Med", frequency: 1, ports: "3")],
            status: .taken
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Dose.self, from: encoded)

        XCTAssertEqual(decoded.portNumber, original.portNumber)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.medications.count, 1)
    }
}
