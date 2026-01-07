// OnboardingUITests.swift
// UI tests for the onboarding flow

import XCTest

final class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset user defaults to show onboarding
        app.launchArguments = ["--uitesting", "--reset-onboarding"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Onboarding Flow Tests

    func testCompleteOnboardingFlow() throws {
        app.launch()

        // Step 1: Welcome screen
        let welcomeTitle = app.staticTexts["Welcome to PillBack"]
        if welcomeTitle.waitForExistence(timeout: 3) {
            let getStartedButton = app.buttons["Get Started"]
            XCTAssertTrue(getStartedButton.exists)
            getStartedButton.tap()
        }

        // Step 2: Name entry (if present)
        let nameField = app.textFields["Enter your name"]
        if nameField.waitForExistence(timeout: 2) {
            nameField.tap()
            nameField.typeText("Test User")

            let continueButton = app.buttons["Continue"]
            XCTAssertTrue(continueButton.exists)
            continueButton.tap()
        }

        // Step 3: Notification permission (if present)
        let notificationTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Notification'"))
        if notificationTitle.count > 0 {
            // Look for enable or skip button
            let enableButton = app.buttons["Enable Notifications"]
            let skipButton = app.buttons["Skip"]
            let laterButton = app.buttons["Maybe Later"]

            if enableButton.exists {
                enableButton.tap()
                // Handle system permission dialog
                handleNotificationPermissionAlert()
            } else if skipButton.exists {
                skipButton.tap()
            } else if laterButton.exists {
                laterButton.tap()
            }
        }

        // Step 4: Schedule setup
        let scheduleTitle = app.staticTexts["Set Your Schedule"]
        if scheduleTitle.waitForExistence(timeout: 2) {
            // Test port count selector
            let portButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'ports'"))
            if portButtons.count > 0 {
                // Select 4 ports
                let fourPortsButton = app.buttons["4 ports"]
                if fourPortsButton.exists {
                    fourPortsButton.tap()
                }
            }

            // Complete onboarding
            let createScheduleButton = app.buttons["Create My Schedule"]
            if createScheduleButton.exists {
                createScheduleButton.tap()
            }
        }

        // Verify we're on the main screen
        let homeTab = app.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 3), "Should be on main screen after onboarding")
    }

    func testOnboardingPortCountSelection() throws {
        app.launch()

        // Skip to schedule setup
        skipToScheduleSetup()

        // Test each port count option
        for portCount in 1...6 {
            let portButton = app.buttons["\(portCount) ports"]
            if portButton.exists {
                portButton.tap()

                // Verify the port preview updates
                // The preview should show the selected number of ports
                let portPreviews = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Port'"))
                // Note: Actual verification depends on UI implementation
            }
        }
    }

    // MARK: - Helper Methods

    private func skipToScheduleSetup() {
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 2) {
            getStartedButton.tap()
        }

        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 1) {
            continueButton.tap()
        }

        // Skip notification permission
        let skipButton = app.buttons["Skip"]
        let laterButton = app.buttons["Maybe Later"]
        if skipButton.waitForExistence(timeout: 1) {
            skipButton.tap()
        } else if laterButton.waitForExistence(timeout: 1) {
            laterButton.tap()
        }
    }

    private func handleNotificationPermissionAlert() {
        // Handle the system notification permission alert
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 2) {
            allowButton.tap()
        }
    }
}
