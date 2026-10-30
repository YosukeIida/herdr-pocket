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
}
