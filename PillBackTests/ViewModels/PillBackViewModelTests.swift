// PillBackViewModelTests.swift
// Unit tests for PillBackViewModel

import XCTest
@testable import PillBack

@MainActor
final class PillBackViewModelTests: XCTestCase {

    var viewModel: PillBackViewModel!

    override func setUp() async throws {
        // Clear UserDefaults before each test
        let defaults = UserDefaults.standard
        let keys = ["pillback_doses", "pillback_medications", "pillback_config",
                    "pillback_theme", "pillback_viewMode", "pillback_userName",
                    "pillback_timelineExpanded", "pillback_lastReset"]
        keys.forEach { defaults.removeObject(forKey: $0) }

        viewModel = PillBackViewModel()
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - Initialization Tests

    func test_init_creates6Doses() {
        XCTAssertEqual(viewModel.doses.count, 6)
    }

    func test_init_loadsDefaultMedications() {
        XCTAssertEqual(viewModel.medications.count, 7)
    }

    func test_init_setsDefaultTheme() {
        XCTAssertEqual(viewModel.currentTheme, .clinical)
    }

    func test_init_setsDefaultViewMode() {
        XCTAssertEqual(viewModel.viewMode, .full)
    }

    func test_init_setsDefaultUserName() {
        XCTAssertEqual(viewModel.userName, "My Name")
    }

    // MARK: - Schedule Generation Tests

    func test_generateSchedule_creates6Doses() {
        viewModel.generateSchedule()
        XCTAssertEqual(viewModel.doses.count, 6)
    }

    func test_generateSchedule_assignsPortNumbers1Through6() {
        viewModel.generateSchedule()
        let ports = viewModel.doses.map { $0.portNumber }
        XCTAssertEqual(ports, [1, 2, 3, 4, 5, 6])
    }

    func test_generateSchedule_allDosesArePending() {
        viewModel.generateSchedule()
        let allPending = viewModel.doses.allSatisfy { $0.status == .pending }
        XCTAssertTrue(allPending)
    }

    func test_generateSchedule_equalDistribution_evenlySpacesDoses() {
        viewModel.scheduleConfig.strategy = .equalDistribution
        viewModel.generateSchedule()

        // Check that doses are evenly spaced
        guard viewModel.doses.count == 6 else {
            XCTFail("Expected 6 doses")
            return
        }

        let intervals = (1..<6).map { i in
            viewModel.doses[i].scheduledTime.timeIntervalSince(viewModel.doses[i-1].scheduledTime)
        }

        // All intervals should be the same (equal distribution)
        let firstInterval = intervals[0]
        for interval in intervals {
            XCTAssertEqual(interval, firstInterval, accuracy: 60) // Within 1 minute
        }
    }

    func test_generateSchedule_fixedInterval_usesKeyDrugInterval() {
        viewModel.scheduleConfig.strategy = .fixedInterval
        viewModel.scheduleConfig.keyDrugInterval = 150 // 2.5 hours
        viewModel.generateSchedule()

        guard viewModel.doses.count >= 2 else {
            XCTFail("Expected at least 2 doses")
            return
        }

        let interval = viewModel.doses[1].scheduledTime.timeIntervalSince(viewModel.doses[0].scheduledTime)
        XCTAssertEqual(interval, 150 * 60, accuracy: 60) // 150 minutes in seconds
    }

    // MARK: - Dose Action Tests

    func test_markDoseTaken_updatesStatus() {
        let dose = viewModel.doses[0]
        viewModel.markDoseTaken(dose: dose)

        XCTAssertEqual(viewModel.doses[0].status, .taken)
    }

    func test_markDoseTaken_setsActualTime() {
        let dose = viewModel.doses[0]
        let now = Date()
        viewModel.markDoseTaken(dose: dose, at: now)

        XCTAssertNotNil(viewModel.doses[0].actualTime)
    }

    func test_untakeDose_resetsStatusToPending() {
        let dose = viewModel.doses[0]
        viewModel.markDoseTaken(dose: dose)
        viewModel.untakeDose(dose: viewModel.doses[0])

        XCTAssertEqual(viewModel.doses[0].status, .pending)
    }

    func test_untakeDose_clearsActualTime() {
        let dose = viewModel.doses[0]
        viewModel.markDoseTaken(dose: dose)
        viewModel.untakeDose(dose: viewModel.doses[0])

        XCTAssertNil(viewModel.doses[0].actualTime)
    }

    func test_updateDoseTime_updatesActualTime() {
        let dose = viewModel.doses[0]
        let newTime = Date().addingTimeInterval(300) // 5 minutes from now
        viewModel.updateDoseTime(dose: dose, newTime: newTime)

        XCTAssertEqual(viewModel.doses[0].actualTime, newTime)
    }

    func test_markDoseMissed_setsStatusToMissed() {
        let dose = viewModel.doses[0]
        viewModel.markDoseMissed(dose: dose)

        XCTAssertEqual(viewModel.doses[0].status, .missed)
    }

    // MARK: - Medication Management Tests

    func test_medicationsForPort_filtersCorrectly() {
        // Port 1 should have multiple medications (Stalevo, Pramipexole, Rasagiline, etc.)
        let port1Meds = viewModel.medicationsForPort(1)
        XCTAssertGreaterThan(port1Meds.count, 1)

        // Port 6 should have Stalevo, Dulcolax, and Zopiclone
        let port6Meds = viewModel.medicationsForPort(6)
        XCTAssertEqual(port6Meds.count, 3)
    }

    func test_addMedication_increasesCount() {
        let initialCount = viewModel.medications.count
        let newMed = Medication(id: 100, name: "New Med", frequency: 1, ports: "1")
        viewModel.addMedication(newMed)

        XCTAssertEqual(viewModel.medications.count, initialCount + 1)
    }

    func test_deleteMedication_decreasesCount() {
        let initialCount = viewModel.medications.count
        let medToDelete = viewModel.medications[0]
        viewModel.deleteMedication(medToDelete)

        XCTAssertEqual(viewModel.medications.count, initialCount - 1)
    }

    // MARK: - Overall Accuracy Tests

    func test_overallTimingAccuracy_zero_whenNoDosesTaken() {
        // All doses are pending initially
        XCTAssertEqual(viewModel.overallTimingAccuracy, 0)
    }

    func test_overallTimingAccuracy_calculatesCorrectly() {
        // Mark first dose as taken on time (perfect = 1.0)
        let dose = viewModel.doses[0]
        viewModel.markDoseTaken(dose: dose, at: dose.scheduledTime)

        // Should be 100%
        XCTAssertEqual(viewModel.overallTimingAccuracy, 100)
    }

    // MARK: - Next Dose Tests

    func test_nextDose_returnsPendingDose() {
        // All doses start as pending
        let nextDose = viewModel.nextDose
        XCTAssertNotNil(nextDose)
        XCTAssertEqual(nextDose?.status, .pending)
    }

    func test_nextDose_nil_whenAllDosesTaken() {
        // Mark all doses as taken
        for dose in viewModel.doses {
            viewModel.markDoseTaken(dose: dose)
        }

        XCTAssertNil(viewModel.nextDose)
    }

    // MARK: - Theme Management Tests

    func test_setTheme_updatesCurrentTheme() {
        viewModel.setTheme(.warm)
        XCTAssertEqual(viewModel.currentTheme, .warm)
    }

    func test_setViewMode_updatesViewMode() {
        viewModel.setViewMode(.timelineOnly)
        XCTAssertEqual(viewModel.viewMode, .timelineOnly)
    }

    func test_toggleTimeline_togglesExpanded() {
        let initial = viewModel.timelineExpanded
        viewModel.toggleTimeline()
        XCTAssertEqual(viewModel.timelineExpanded, !initial)
    }

    func test_setUserName_updatesUserName() {
        viewModel.setUserName("Test User")
        XCTAssertEqual(viewModel.userName, "Test User")
    }

    // MARK: - Pattern Detection Tests

    func test_detectTimingPatterns_emptyWhenNoDosesTaken() {
        let patterns = viewModel.detectTimingPatterns()
        XCTAssertTrue(patterns.isEmpty)
    }

    func test_detectTimingPatterns_emptyWhenAllOnTime() {
        // Mark doses as taken on time
        for dose in viewModel.doses {
            viewModel.markDoseTaken(dose: dose, at: dose.scheduledTime)
        }

        let patterns = viewModel.detectTimingPatterns()
        XCTAssertTrue(patterns.isEmpty)
    }

    // MARK: - Reset Tests

    func test_resetAllData_restoresDefaults() {
        // Make some changes
        viewModel.setTheme(.contrast)
        viewModel.setUserName("Changed")
        viewModel.markDoseTaken(dose: viewModel.doses[0])

        // Reset
        viewModel.resetAllData()

        // Check defaults restored
        XCTAssertEqual(viewModel.currentTheme, .clinical)
        XCTAssertEqual(viewModel.userName, "My Name")
        XCTAssertEqual(viewModel.doses.filter { $0.status == .taken }.count, 0)
    }

    // MARK: - Computed Property Tests

    func test_dosesTakenToday_countsCorrectly() {
        XCTAssertEqual(viewModel.dosesTakenToday, 0)

        viewModel.markDoseTaken(dose: viewModel.doses[0])
        viewModel.markDoseTaken(dose: viewModel.doses[1])

        XCTAssertEqual(viewModel.dosesTakenToday, 2)
    }

    func test_pendingDoses_countsCorrectly() {
        XCTAssertEqual(viewModel.pendingDoses, 6)

        viewModel.markDoseTaken(dose: viewModel.doses[0])

        XCTAssertEqual(viewModel.pendingDoses, 5)
    }
}
