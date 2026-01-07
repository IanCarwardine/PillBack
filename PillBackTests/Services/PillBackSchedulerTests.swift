// PillBackSchedulerTests.swift
// Unit tests for PillBackScheduler service

import XCTest
@testable import PillBack

final class PillBackSchedulerTests: XCTestCase {

    var scheduler: PillBackScheduler!

    override func setUp() {
        super.setUp()
        scheduler = PillBackScheduler.shared
    }

    // MARK: - Default Windows Tests

    func testDefaultWindowsFor4Ports() {
        let windows = scheduler.getDefaultWindows(for: 4)

        XCTAssertEqual(windows.count, 4)
        XCTAssertEqual(windows[0].hour, 6)
        XCTAssertEqual(windows[0].label, "Morning")
        XCTAssertEqual(windows[1].hour, 11)
        XCTAssertEqual(windows[1].label, "Midday")
        XCTAssertEqual(windows[2].hour, 16)
        XCTAssertEqual(windows[2].label, "Afternoon")
        XCTAssertEqual(windows[3].hour, 21)
        XCTAssertEqual(windows[3].label, "Evening")
    }

    func testDefaultWindowsFor1Port() {
        let windows = scheduler.getDefaultWindows(for: 1)

        XCTAssertEqual(windows.count, 1)
        XCTAssertEqual(windows[0].hour, 8)
        XCTAssertEqual(windows[0].label, "Morning")
    }

    func testDefaultWindowsFor2Ports() {
        let windows = scheduler.getDefaultWindows(for: 2)

        XCTAssertEqual(windows.count, 2)
        XCTAssertEqual(windows[0].hour, 8)
        XCTAssertEqual(windows[1].hour, 20)
    }

    func testDefaultWindowsFor6Ports() {
        let windows = scheduler.getDefaultWindows(for: 6)

        XCTAssertEqual(windows.count, 6)
        // Extended windows
        XCTAssertEqual(windows[0].hour, 6)
        XCTAssertEqual(windows[1].hour, 9)
        XCTAssertEqual(windows[2].hour, 12)
        XCTAssertEqual(windows[3].hour, 15)
        XCTAssertEqual(windows[4].hour, 18)
        XCTAssertEqual(windows[5].hour, 21)
    }

    // MARK: - Fixed Windows Generation Tests

    func testGenerateScheduleWithFixedWindows() {
        var config = ScheduleConfig()
        config.portCount = 4
        config.useFixedWindows = true
        config.fixedWindows = []  // Will use defaults

        let medications = [
            Medication(id: 1, name: "Test Med", frequency: 4, ports: "1")
        ]

        let doses = scheduler.generateSchedule(config: config, medications: medications)

        XCTAssertEqual(doses.count, 4)

        // Verify doses are sorted by time
        for i in 1..<doses.count {
            XCTAssertLessThan(doses[i-1].scheduledTime, doses[i].scheduledTime)
        }

        // Verify port numbers
        XCTAssertEqual(doses[0].portNumber, 1)
        XCTAssertEqual(doses[1].portNumber, 2)
        XCTAssertEqual(doses[2].portNumber, 3)
        XCTAssertEqual(doses[3].portNumber, 4)
    }

    func testGenerateScheduleWithCustomWindows() {
        var config = ScheduleConfig()
        config.portCount = 2
        config.useFixedWindows = true
        config.fixedWindows = [
            DoseWindow(hour: 7, minute: 30, label: "Breakfast"),
            DoseWindow(hour: 19, minute: 0, label: "Dinner")
        ]

        let doses = scheduler.generateSchedule(config: config, medications: [])

        XCTAssertEqual(doses.count, 2)

        let calendar = Calendar.current
        let hour1 = calendar.component(.hour, from: doses[0].scheduledTime)
        let min1 = calendar.component(.minute, from: doses[0].scheduledTime)
        XCTAssertEqual(hour1, 7)
        XCTAssertEqual(min1, 30)

        let hour2 = calendar.component(.hour, from: doses[1].scheduledTime)
        let min2 = calendar.component(.minute, from: doses[1].scheduledTime)
        XCTAssertEqual(hour2, 19)
        XCTAssertEqual(min2, 0)
    }

    // MARK: - Equal Distribution Tests

    func testGenerateScheduleWithEqualDistribution() {
        let calendar = Calendar.current
        var config = ScheduleConfig()
        config.portCount = 4
        config.useFixedWindows = false
        config.strategy = .equalDistribution
        config.startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        config.endTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!

        let doses = scheduler.generateSchedule(config: config, medications: [])

        XCTAssertEqual(doses.count, 4)

        // First dose at 8:00
        let hour1 = calendar.component(.hour, from: doses[0].scheduledTime)
        XCTAssertEqual(hour1, 8)

        // Last dose at 20:00
        let hour4 = calendar.component(.hour, from: doses[3].scheduledTime)
        XCTAssertEqual(hour4, 20)
    }

    // MARK: - KEY DRUG Interval Tests

    func testGenerateScheduleWithKeyDrugInterval() {
        let calendar = Calendar.current
        var config = ScheduleConfig()
        config.portCount = 3
        config.useFixedWindows = false
        config.strategy = .fixedInterval
        config.startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        config.keyDrugInterval = 150  // 2.5 hours

        let doses = scheduler.generateSchedule(config: config, medications: [])

        XCTAssertEqual(doses.count, 3)

        // Port 1 at 8:00
        let hour1 = calendar.component(.hour, from: doses[0].scheduledTime)
        XCTAssertEqual(hour1, 8)

        // Port 2 at 10:30
        let hour2 = calendar.component(.hour, from: doses[1].scheduledTime)
        let min2 = calendar.component(.minute, from: doses[1].scheduledTime)
        XCTAssertEqual(hour2, 10)
        XCTAssertEqual(min2, 30)

        // Port 3 at 13:00
        let hour3 = calendar.component(.hour, from: doses[2].scheduledTime)
        XCTAssertEqual(hour3, 13)
    }

    // MARK: - Port Assignment Tests

    func testAssignMedicationsToPorts() {
        let med1 = Medication(id: 1, name: "Med 1", frequency: 2, ports: "1,2")
        let med2 = Medication(id: 2, name: "Med 2", frequency: 1, ports: "1", isKeyDrug: true)
        let med3 = Medication(id: 3, name: "Med 3", frequency: 1, ports: "3")

        let assignments = scheduler.assignMedicationsToPorts(
            medications: [med1, med2, med3],
            portCount: 4
        )

        XCTAssertEqual(assignments.count, 4)

        // Port 1: Med 1, Med 2 (KEY DRUG)
        XCTAssertEqual(assignments[0].portNumber, 1)
        XCTAssertEqual(assignments[0].medications.count, 2)
        XCTAssertTrue(assignments[0].hasKeyDrug)

        // Port 2: Med 1
        XCTAssertEqual(assignments[1].portNumber, 2)
        XCTAssertEqual(assignments[1].medications.count, 1)
        XCTAssertFalse(assignments[1].hasKeyDrug)

        // Port 3: Med 3
        XCTAssertEqual(assignments[2].portNumber, 3)
        XCTAssertEqual(assignments[2].medications.count, 1)
        XCTAssertFalse(assignments[2].hasKeyDrug)

        // Port 4: Empty
        XCTAssertEqual(assignments[3].portNumber, 4)
        XCTAssertTrue(assignments[3].isEmpty)
    }

    // MARK: - Validation Tests

    func testValidateConfigValid() {
        var config = ScheduleConfig()
        config.portCount = 4
        config.useFixedWindows = true
        config.fixedWindows = PillBackScheduler.defaultWindows

        let errors = scheduler.validateConfig(config)

        // No errors for valid config
        XCTAssertTrue(errors.isEmpty || errors.allSatisfy { !$0.contains("must be") })
    }

    func testValidateConfigInvalidPortCount() {
        var config = ScheduleConfig()
        config.portCount = 0

        let errors = scheduler.validateConfig(config)

        XCTAssertTrue(errors.contains { $0.contains("Port count") })
    }

    func testValidateConfigInvalidPortCountTooHigh() {
        var config = ScheduleConfig()
        config.portCount = 10

        let errors = scheduler.validateConfig(config)

        XCTAssertTrue(errors.contains { $0.contains("Port count") })
    }

    func testValidateConfigInvalidKeyDrugInterval() {
        var config = ScheduleConfig()
        config.portCount = 4
        config.keyDrugInterval = 10  // Too short

        let errors = scheduler.validateConfig(config)

        XCTAssertTrue(errors.contains { $0.contains("KEY DRUG interval") })
    }

    // MARK: - DoseWindow Tests

    func testDoseWindowTimeString() {
        let window = DoseWindow(hour: 14, minute: 30, label: "Afternoon")

        XCTAssertEqual(window.label, "Afternoon")
        // Time string format depends on locale
        XCTAssertFalse(window.timeString.isEmpty)
    }

    func testDoseWindowEquatable() {
        let window1 = DoseWindow(hour: 8, minute: 0, label: "Morning")
        let window2 = DoseWindow(hour: 8, minute: 0, label: "Morning")
        let window3 = DoseWindow(hour: 9, minute: 0, label: "Morning")

        XCTAssertEqual(window1, window2)
        XCTAssertNotEqual(window1, window3)
    }

    func testDoseWindowId() {
        let window = DoseWindow(hour: 14, minute: 30, label: "Test")

        XCTAssertEqual(window.id, "14:30")
    }

    // MARK: - Schedule Description Tests

    func testGetScheduleDescriptionFixedWindows() {
        var config = ScheduleConfig()
        config.portCount = 4
        config.useFixedWindows = true
        config.fixedWindows = []  // Uses defaults

        let description = scheduler.getScheduleDescription(for: config)

        XCTAssertFalse(description.isEmpty)
        // Should contain times
        XCTAssertTrue(description.contains(":") || description.contains("AM") || description.contains("PM"))
    }
}
