// MedicationTests.swift
// Unit tests for Medication model port parsing

import XCTest
@testable import PillBack

final class MedicationTests: XCTestCase {

    // MARK: - Port Parsing Tests - Range Format

    func test_portNumbers_parsesRangeFormat() {
        let med = Medication(id: 1, name: "Test", frequency: 6, ports: "1-6")
        XCTAssertEqual(med.portNumbers, [1, 2, 3, 4, 5, 6])
    }

    func test_portNumbers_parsesPartialRange() {
        let med = Medication(id: 1, name: "Test", frequency: 3, ports: "1-3")
        XCTAssertEqual(med.portNumbers, [1, 2, 3])
    }

    func test_portNumbers_parsesRangeWithSpaces() {
        let med = Medication(id: 1, name: "Test", frequency: 2, ports: "2 - 4")
        XCTAssertEqual(med.portNumbers, [2, 3, 4])
    }

    // MARK: - Port Parsing Tests - Comma Separated

    func test_portNumbers_parsesCommaSeparated() {
        let med = Medication(id: 1, name: "Test", frequency: 3, ports: "1,3,5")
        XCTAssertEqual(med.portNumbers, [1, 3, 5])
    }

    func test_portNumbers_parsesCommaSeparatedWithSpaces() {
        let med = Medication(id: 1, name: "Test", frequency: 2, ports: "2, 4, 6")
        XCTAssertEqual(med.portNumbers, [2, 4, 6])
    }

    // MARK: - Port Parsing Tests - Single Port

    func test_portNumbers_parsesSinglePort() {
        let med = Medication(id: 1, name: "Test", frequency: 1, ports: "1")
        XCTAssertEqual(med.portNumbers, [1])
    }

    func test_portNumbers_parsesSinglePortWithSpaces() {
        let med = Medication(id: 1, name: "Test", frequency: 1, ports: " 3 ")
        XCTAssertEqual(med.portNumbers, [3])
    }

    // MARK: - Port Parsing Tests - Edge Cases

    func test_portNumbers_returnsEmpty_forInvalidFormat() {
        let med = Medication(id: 1, name: "Test", frequency: 1, ports: "invalid")
        XCTAssertEqual(med.portNumbers, [])
    }

    func test_portNumbers_returnsEmpty_forEmptyString() {
        let med = Medication(id: 1, name: "Test", frequency: 1, ports: "")
        XCTAssertEqual(med.portNumbers, [])
    }

    // MARK: - isInPort Tests

    func test_isInPort_true_forPortInRange() {
        let med = Medication(id: 1, name: "Test", frequency: 6, ports: "1-6")
        XCTAssertTrue(med.isInPort(3))
    }

    func test_isInPort_false_forPortOutOfRange() {
        let med = Medication(id: 1, name: "Test", frequency: 3, ports: "1-3")
        XCTAssertFalse(med.isInPort(5))
    }

    func test_isInPort_true_forPortInList() {
        let med = Medication(id: 1, name: "Test", frequency: 3, ports: "1,3,5")
        XCTAssertTrue(med.isInPort(3))
    }

    func test_isInPort_false_forPortNotInList() {
        let med = Medication(id: 1, name: "Test", frequency: 3, ports: "1,3,5")
        XCTAssertFalse(med.isInPort(2))
    }

    // MARK: - Codable Tests

    func test_medication_encodesAndDecodes() throws {
        let original = Medication(
            id: 1,
            name: "Stalevo 200mg",
            frequency: 6,
            ports: "1-6",
            notes: "Parkinson's medication",
            isKeyDrug: true
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Medication.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.frequency, original.frequency)
        XCTAssertEqual(decoded.ports, original.ports)
        XCTAssertEqual(decoded.notes, original.notes)
        XCTAssertEqual(decoded.isKeyDrug, original.isKeyDrug)
    }

    // MARK: - Default Medications Tests

    func test_defaultMedications_hasSevenItems() {
        XCTAssertEqual(Medication.defaults.count, 7)
    }

    func test_defaultMedications_hasKeyDrug() {
        let keyDrugs = Medication.defaults.filter { $0.isKeyDrug }
        XCTAssertEqual(keyDrugs.count, 1)
        XCTAssertEqual(keyDrugs.first?.name, "Stalevo 200/50/37mg")
    }

    func test_defaultMedications_keyDrugInAllPorts() {
        let keyDrug = Medication.defaults.first { $0.isKeyDrug }!
        XCTAssertEqual(keyDrug.portNumbers, [1, 2, 3, 4, 5, 6])
    }

    // MARK: - Equatable Tests

    func test_medications_areEqual_whenSameId() {
        let med1 = Medication(id: 1, name: "Med A", frequency: 1, ports: "1")
        let med2 = Medication(id: 1, name: "Med A", frequency: 1, ports: "1")
        XCTAssertEqual(med1, med2)
    }

    func test_medications_areNotEqual_whenDifferentIds() {
        let med1 = Medication(id: 1, name: "Med A", frequency: 1, ports: "1")
        let med2 = Medication(id: 2, name: "Med A", frequency: 1, ports: "1")
        XCTAssertNotEqual(med1, med2)
    }
}
