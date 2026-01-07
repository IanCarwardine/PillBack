// StreakTrackerTests.swift
// Unit tests for StreakTracker service

import XCTest
@testable import PillBack

final class StreakTrackerTests: XCTestCase {

    var tracker: StreakTracker!

    override func setUp() {
        super.setUp()
        tracker = StreakTracker.shared
        tracker.resetAllData()  // Start fresh for each test
    }

    override func tearDown() {
        tracker.resetAllData()
        super.tearDown()
    }

    // MARK: - Test Data Helpers

    private func createCompleteDoses(count: Int) -> [Dose] {
        var doses: [Dose] = []
        for i in 1...count {
            var dose = Dose(portNumber: i, scheduledTime: Date(), medications: [])
            dose.status = .taken
            dose.actualTime = Date()
            doses.append(dose)
        }
        return doses
    }

    private func createMixedDoses(taken: Int, missed: Int) -> [Dose] {
        var doses: [Dose] = []

        for i in 1...taken {
            var dose = Dose(portNumber: i, scheduledTime: Date(), medications: [])
            dose.status = .taken
            dose.actualTime = Date()
            doses.append(dose)
        }

        for i in 1...missed {
            var dose = Dose(portNumber: taken + i, scheduledTime: Date(), medications: [])
            dose.status = .missed
            doses.append(dose)
        }

        return doses
    }

    // MARK: - Streak Update Tests

    func testUpdateStreaksWithPerfectDay() {
        let doses = createCompleteDoses(count: 4)

        tracker.updateStreaks(with: doses)

        let summary = tracker.getStreakSummary()
        XCTAssertEqual(summary.currentStreak, 1)
        XCTAssertEqual(summary.todayProgress, 1.0)
    }

    func testUpdateStreaksWithPartialDay() {
        let doses = createMixedDoses(taken: 3, missed: 1)

        tracker.updateStreaks(with: doses)

        let summary = tracker.getStreakSummary()
        XCTAssertEqual(summary.currentStreak, 0)  // Not perfect, no streak
        XCTAssertEqual(summary.todayProgress, 0.75, accuracy: 0.01)
    }

    func testUpdateStreaksWithNoDoses() {
        tracker.updateStreaks(with: [])

        let summary = tracker.getStreakSummary()
        XCTAssertEqual(summary.currentStreak, 0)
        XCTAssertEqual(summary.todayProgress, 0)
    }

    // MARK: - Adherence Calculation Tests

    func testCalculateAdherenceAllTaken() {
        let doses = createCompleteDoses(count: 4)

        let adherence = tracker.calculateAdherence(from: doses, days: 7)

        XCTAssertEqual(adherence, 100.0, accuracy: 0.1)
    }

    func testCalculateAdherencePartial() {
        let doses = createMixedDoses(taken: 2, missed: 2)

        let adherence = tracker.calculateAdherence(from: doses, days: 7)

        XCTAssertEqual(adherence, 50.0, accuracy: 0.1)
    }

    func testCalculateAdherenceNoDoses() {
        let adherence = tracker.calculateAdherence(from: [], days: 7)

        XCTAssertEqual(adherence, 0)
    }

    // MARK: - Period Stats Tests

    func testUpdatePeriodStats() {
        let doses = createMixedDoses(taken: 3, missed: 1)

        tracker.updatePeriodStats(with: doses)

        let summary = tracker.getStreakSummary()
        XCTAssertEqual(summary.adherence7Day, 75.0, accuracy: 0.1)
        XCTAssertEqual(summary.adherence30Day, 75.0, accuracy: 0.1)
        XCTAssertEqual(summary.adherenceAllTime, 75.0, accuracy: 0.1)
    }

    // MARK: - Timing Analysis Tests

    func testCalculateAverageTimingAccuracy() {
        let calendar = Calendar.current
        let now = Date()

        // Create dose with known timing
        var dose1 = Dose(
            portNumber: 1,
            scheduledTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!,
            medications: []
        )
        dose1.status = .taken
        dose1.actualTime = calendar.date(bySettingHour: 8, minute: 3, second: 0, of: now)!  // 3 min late = excellent

        var dose2 = Dose(
            portNumber: 2,
            scheduledTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!,
            medications: []
        )
        dose2.status = .taken
        dose2.actualTime = calendar.date(bySettingHour: 12, minute: 3, second: 0, of: now)!  // 3 min late = excellent

        let accuracy = tracker.calculateAverageTimingAccuracy(from: [dose1, dose2])

        XCTAssertEqual(accuracy, 1.0, accuracy: 0.01)  // Both excellent
    }

    func testGetTimingDistribution() {
        let calendar = Calendar.current
        let now = Date()

        // Create doses with different timing accuracies
        var dose1 = Dose(
            portNumber: 1,
            scheduledTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!,
            medications: []
        )
        dose1.status = .taken
        dose1.actualTime = calendar.date(bySettingHour: 8, minute: 3, second: 0, of: now)!  // Excellent

        var dose2 = Dose(
            portNumber: 2,
            scheduledTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!,
            medications: []
        )
        dose2.status = .taken
        dose2.actualTime = calendar.date(bySettingHour: 12, minute: 8, second: 0, of: now)!  // Good

        var dose3 = Dose(
            portNumber: 3,
            scheduledTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now)!,
            medications: []
        )
        dose3.status = .missed  // Should not count

        let distribution = tracker.getTimingDistribution(from: [dose1, dose2, dose3])

        XCTAssertEqual(distribution[.excellent], 1)
        XCTAssertEqual(distribution[.good], 1)
        XCTAssertEqual(distribution[.fair], 0)
        XCTAssertEqual(distribution[.poor], 0)
    }

    // MARK: - Streak Status Tests

    func testStreakStatusNoStreak() {
        // Fresh tracker with no data
        let summary = tracker.getStreakSummary()

        XCTAssertEqual(summary.streakStatus, .noStreak)
    }

    func testStreakStatusActiveToday() {
        let doses = createCompleteDoses(count: 4)
        tracker.updateStreaks(with: doses)

        let summary = tracker.getStreakSummary()

        XCTAssertEqual(summary.streakStatus, .activeToday)
    }

    // MARK: - Remaining for Streak Tests

    func testRemainingForStreak() {
        let remaining = tracker.remainingForStreak(totalDoses: 4, takenDoses: 2)

        XCTAssertEqual(remaining, 2)
    }

    func testRemainingForStreakComplete() {
        let remaining = tracker.remainingForStreak(totalDoses: 4, takenDoses: 4)

        XCTAssertEqual(remaining, 0)
    }

    // MARK: - Streak Summary Text Tests

    func testStreakSummaryTextNoStreak() {
        let summary = tracker.getStreakSummary()

        XCTAssertEqual(summary.currentStreakText, "No streak")
        XCTAssertEqual(summary.longestStreakText, "None yet")
    }

    func testStreakSummaryTextWithStreak() {
        let doses = createCompleteDoses(count: 4)
        tracker.updateStreaks(with: doses)

        let summary = tracker.getStreakSummary()

        XCTAssertEqual(summary.currentStreakText, "1 day")
    }

    func testAdherenceTextFormatting() {
        let doses = createMixedDoses(taken: 3, missed: 1)
        tracker.updatePeriodStats(with: doses)

        let summary = tracker.getStreakSummary()

        XCTAssertEqual(summary.adherence7DayText, "75%")
    }

    // MARK: - Reset Tests

    func testResetAllData() {
        // Add some data
        let doses = createCompleteDoses(count: 4)
        tracker.updateStreaks(with: doses)

        // Verify data exists
        var summary = tracker.getStreakSummary()
        XCTAssertEqual(summary.currentStreak, 1)

        // Reset
        tracker.resetAllData()

        // Verify data is cleared
        summary = tracker.getStreakSummary()
        XCTAssertEqual(summary.currentStreak, 0)
        XCTAssertEqual(summary.longestStreak, 0)
        XCTAssertEqual(summary.todayProgress, 0)
    }

    // MARK: - Midnight Reset Tests

    func testHandleMidnightReset() {
        // This would need to manipulate lastPerfectDay to properly test
        // For now, just verify it doesn't crash
        tracker.handleMidnightReset()

        let summary = tracker.getStreakSummary()
        XCTAssertEqual(summary.todayProgress, 0)
    }

    // MARK: - Streak Risk Tests

    func testIsStreakAtRiskNoStreak() {
        let atRisk = tracker.isStreakAtRisk()

        XCTAssertFalse(atRisk)
    }
}

// MARK: - StreakStatus Tests

final class StreakStatusTests: XCTestCase {

    func testStreakStatusDisplayText() {
        XCTAssertEqual(StreakStatus.noStreak.displayText, "Start your streak!")
        XCTAssertEqual(StreakStatus.activeToday.displayText, "Streak active")
        XCTAssertEqual(StreakStatus.inProgress.displayText, "Keep going today")
        XCTAssertEqual(StreakStatus.atRisk.displayText, "Complete today's doses")
        XCTAssertEqual(StreakStatus.broken.displayText, "Streak ended")
    }

    func testStreakStatusIsActive() {
        XCTAssertFalse(StreakStatus.noStreak.isActive)
        XCTAssertTrue(StreakStatus.activeToday.isActive)
        XCTAssertTrue(StreakStatus.inProgress.isActive)
        XCTAssertTrue(StreakStatus.atRisk.isActive)
        XCTAssertFalse(StreakStatus.broken.isActive)
    }
}
