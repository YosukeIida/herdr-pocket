import XCTest

/// Drives the app against the real box in watch-only mode (DEBUG hooks), the
/// way a finger would. Needs HERDR_DEBUG_KEY_PATH in the test runner's env.
final class HerdrUITests: XCTestCase {
    private func launch(_ extra: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication()
        let env = ProcessInfo.processInfo.environment
        app.launchEnvironment["HERDR_DEBUG_KEY_PATH"] = env["HERDR_DEBUG_KEY_PATH"] ?? ""
        app.launchEnvironment["HERDR_DEBUG_AUTOCONNECT"] = "1"
        app.launchEnvironment["HERDR_DEBUG_OBSERVE"] = "1"
        for (k, v) in extra { app.launchEnvironment[k] = v }
        app.launch()
        return app
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    func testPlusOpensNewAgentSheet() throws {
        let app = launch()
        let plus = app.buttons["New agent"]
        XCTAssertTrue(plus.waitForExistence(timeout: 30), "no + button")
        shot(app, "home")
        // A thumb lands off the glyph, inside the glass circle.
        plus.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.75)).tap()
        let start = app.buttons["Start"]
        let opened = start.waitForExistence(timeout: 5)
        shot(app, "after-plus")
        XCTAssertTrue(opened, "New agent sheet did not open")
        XCTAssertTrue(start.isEnabled, "Start disabled with a space selected")
    }

    /// Chat reads a Claude agent's transcript ($HERDR_TEST_TERMINAL); folds open on tap. Never sends anything.
    func testChatRendersAndFolds() throws {
        let app = launch(["HERDR_DEBUG_OPEN": ProcessInfo.processInfo.environment["HERDR_TEST_TERMINAL"] ?? "t1"])
        let field = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 30), "no composer")
        sleep(4)
        shot(app, "chat-bottom")
        let folds = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Worked'"))
        var tries = 0
        while folds.count == 0 && tries < 6 { app.swipeDown(); tries += 1 }
        XCTAssertGreaterThan(folds.count, 0, "no Worked-for row")
        folds.element(boundBy: folds.count - 1).tap()
        sleep(1)
        shot(app, "chat-fold-open")
        let tool = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Bash'")).firstMatch
        if tool.exists { tool.tap(); sleep(1); shot(app, "chat-tool-open") }
    }

    /// A scripted tour for the README video (demo data only). Run while
    /// recording; the harness sends a push with `xcrun simctl push` once
    /// the app is in the background.
    func testDemoTour() throws {
        let app = XCUIApplication()
        app.launchEnvironment["HERDR_DEMO"] = "1"
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        app.launch()
        // Notification permission (demo mode asks too, so the push can show).
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 5) { allow.tap() }
        sleep(3)
        // Home -> an agent's chat.
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Global time slider'")).firstMatch.tap()
        sleep(3)
        let fold = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Worked'")).firstMatch
        if fold.waitForExistence(timeout: 3) { fold.tap(); sleep(3); app.swipeUp(); sleep(2) }
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(2)
        // A space with its tabs, then the new-agent sheet.
        app.swipeUp(); sleep(1)
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'webapp'")).firstMatch.tap()
        sleep(3)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        app.swipeDown(); sleep(1)
        app.buttons["New agent"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(3)
        app.buttons["Cancel"].tap()
        sleep(1)
        // Background the app; the harness pushes "OAuth needs you".
        XCUIDevice.shared.press(.home)
        try? "ready".write(toFile: "/tmp/herdr-tour-ready", atomically: true, encoding: .utf8)
        let banner = springboard.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'needs you'")).firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 60), "no notification banner")
        sleep(2)
        banner.tap()
        sleep(5)
    }
}
