// PillBackUITests.swift
// UI tests for critical app flows

import XCTest

final class PillBackUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Navigation Tests

    func testTabNavigation() throws {
        app.launch()

        // Skip onboarding if present
        skipOnboardingIfPresent()

        // Test navigating to Ports tab
        let portsTab = app.buttons["Ports"]
        if portsTab.exists {
            portsTab.tap()
            XCTAssertTrue(app.staticTexts["Pill Organizer"].waitForExistence(timeout: 2))
        }

        // Test navigating to History tab
        let historyTab = app.buttons["History"]
        if historyTab.exists {
            historyTab.tap()
            XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 2))
        }

        // Test navigating to Settings tab
        let settingsTab = app.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            XCTAssertTrue(app.staticTexts["Personal"].waitForExistence(timeout: 2))
        }

        // Test navigating back to Home tab
        let homeTab = app.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
            XCTAssertTrue(app.staticTexts["Today's Doses"].waitForExistence(timeout: 2) ||
                         app.staticTexts["No Doses Today"].waitForExistence(timeout: 2))
        }
    }

    // MARK: - Theme Selection Tests

    func testThemeSelection() throws {
        app.launch()
        skipOnboardingIfPresent()

        // Navigate to Settings
        let settingsTab = app.buttons["Settings"]
        guard settingsTab.exists else {
            XCTFail("Settings tab not found")
            return
        }
        settingsTab.tap()

        // Find theme section
        let themeSection = app.staticTexts["Theme"]
        XCTAssertTrue(themeSection.waitForExistence(timeout: 2))

        // Tap on a theme circle (if visible)
        let themeButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'theme'"))
        if themeButtons.count > 0 {
            themeButtons.element(boundBy: 0).tap()
            // Theme should change without crashing
        }
    }

    // MARK: - Dose Card Tests

    func testDoseCardExpansion() throws {
        app.launch()
        skipOnboardingIfPresent()

        // Navigate to Home tab
        let homeTab = app.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
        }

        // Find a dose card (by looking for Port text)
        let portTexts = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Port'"))

        if portTexts.count > 0 {
            // Tap to expand
            portTexts.element(boundBy: 0).tap()

            // Check if expanded content appears (medications or edit button)
            let expanded = app.buttons["Edit"].waitForExistence(timeout: 2) ||
                          app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'medication'")).count > 0

            // Tap again to collapse
            portTexts.element(boundBy: 0).tap()
        }
    }

    // MARK: - Settings Tests

    func testSettingsNameEdit() throws {
        app.launch()
        skipOnboardingIfPresent()

        // Navigate to Settings
        let settingsTab = app.buttons["Settings"]
        guard settingsTab.exists else {
            XCTFail("Settings tab not found")
            return
        }
        settingsTab.tap()

        // Find name text field
        let nameField = app.textFields["Your name"]
        if nameField.exists {
            nameField.tap()
            nameField.clearAndEnterText("Test User")

            // Dismiss keyboard
            app.keyboards.buttons["Return"].tap()
        }
    }

    // MARK: - Accessibility Tests

    func testAccessibilityLabels() throws {
        app.launch()
        skipOnboardingIfPresent()

        // Check that main tabs have accessibility labels
        XCTAssertTrue(app.buttons["Home"].exists || app.buttons["home"].exists)
        XCTAssertTrue(app.buttons["Ports"].exists || app.buttons["ports"].exists)
        XCTAssertTrue(app.buttons["History"].exists || app.buttons["history"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists || app.buttons["settings"].exists)
    }

    // MARK: - Helper Methods

    private func skipOnboardingIfPresent() {
        // Look for onboarding elements and skip if present
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 2) {
            getStartedButton.tap()
        }

        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 1) {
            continueButton.tap()
        }

        let createScheduleButton = app.buttons["Create My Schedule"]
        if createScheduleButton.waitForExistence(timeout: 1) {
            createScheduleButton.tap()
        }

        // Wait for main content to appear
        _ = app.buttons["Home"].waitForExistence(timeout: 2)
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string element")
            return
        }

        self.tap()

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
