// ScheduleConfigTests.swift
// Unit tests for ScheduleConfig model

import XCTest
@testable import PillBack

final class ScheduleConfigTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeConfig(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) -> ScheduleConfig {
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: now)!
        return ScheduleConfig(startTime: startTime, endTime: endTime)
    }

    // MARK: - Total Minutes Tests

    func test_totalMinutes_calculatesCorrectly() {
        let config = makeConfig(startHour: 8, startMinute: 0, endHour: 20, endMinute: 0)
        XCTAssertEqual(config.totalMinutes, 720) // 12 hours = 720 minutes
    }

    func test_totalMinutes_handlesHalfHours() {
        let config = makeConfig(startHour: 8, startMinute: 0, endHour: 20, endMinute: 30)
        XCTAssertEqual(config.totalMinutes, 750) // 12.5 hours = 750 minutes
    }

    // MARK: - Equal Distribution Interval Tests

    func test_equalDistributionInterval_calculatesCorrectly() {
        let config = makeConfig(startHour: 8, startMinute: 0, endHour: 20, endMinute: 0)
        // 720 minutes / 6 doses = 120 minutes between doses
        XCTAssertEqual(config.equalDistributionInterval, 120)
    }

    func test_equalDistributionInterval_defaultConfig() {
        let config = ScheduleConfig.default
        // 8:00 AM to 8:30 PM = 12.5 hours = 750 minutes
        // 750 / 6 = 125 minutes between doses
        XCTAssertEqual(config.equalDistributionInterval, 125)
    }

    // MARK: - Default Config Tests

    func test_defaultConfig_hasCorrectStartTime() {
        let config = ScheduleConfig.default
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: config.startTime)
        let minute = calendar.component(.minute, from: config.startTime)
        XCTAssertEqual(hour, 8)
        XCTAssertEqual(minute, 0)
    }

    func test_defaultConfig_hasCorrectEndTime() {
        let config = ScheduleConfig.default
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: config.endTime)
        let minute = calendar.component(.minute, from: config.endTime)
        XCTAssertEqual(hour, 20)
        XCTAssertEqual(minute, 30)
    }

    func test_defaultConfig_usesEqualDistribution() {
        let config = ScheduleConfig.default
        XCTAssertEqual(config.strategy, .equalDistribution)
    }

    func test_defaultConfig_has150MinuteInterval() {
        let config = ScheduleConfig.default
        XCTAssertEqual(config.keyDrugInterval, 150)
    }

    // MARK: - Codable Tests

    func test_scheduleConfig_encodesAndDecodes() throws {
        let original = makeConfig(startHour: 7, startMinute: 30, endHour: 21, endMinute: 0)

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScheduleConfig.self, from: encoded)

        XCTAssertEqual(decoded.totalMinutes, original.totalMinutes)
        XCTAssertEqual(decoded.strategy, original.strategy)
        XCTAssertEqual(decoded.keyDrugInterval, original.keyDrugInterval)
    }

    // MARK: - Strategy Tests

    func test_strategyDescriptions_areNotEmpty() {
        for strategy in ScheduleStrategy.allCases {
            XCTAssertFalse(strategy.description.isEmpty)
            XCTAssertFalse(strategy.shortDescription.isEmpty)
        }
    }

    // MARK: - Equatable Tests

    func test_configs_areEqual_whenSame() {
        let config1 = makeConfig(startHour: 8, startMinute: 0, endHour: 20, endMinute: 0)
        let config2 = makeConfig(startHour: 8, startMinute: 0, endHour: 20, endMinute: 0)
        XCTAssertEqual(config1, config2)
    }
}
