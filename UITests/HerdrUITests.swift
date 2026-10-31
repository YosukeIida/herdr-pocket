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

    /// Waits for a list row, scrolling down when it is off screen (lists load rows lazily).
    private func reveal(_ row: XCUIElement, in app: XCUIApplication) -> Bool {
        if row.waitForExistence(timeout: 15) && row.isHittable { return true }
        for _ in 0..<8 where !(row.exists && row.isHittable) { app.swipeUp() }
        for _ in 0..<16 where !(row.exists && row.isHittable) { app.swipeDown() }
        return row.exists && row.isHittable
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

    /// A fresh install connecting for the first time stops at the host key, shows the
    /// fingerprint the box really has, and reaches home only after approval.
    /// Needs HERDR_TEST_HOST, HERDR_TEST_USER and HERDR_TEST_HOST_FP (ssh-keygen -lf of the
    /// box's ed25519 host key); run after uninstalling the app and resetting the simulator keychain.
    func testFirstConnectAsksForHostKey() throws {
        let env = ProcessInfo.processInfo.environment
        let host = try XCTUnwrap(env["HERDR_TEST_HOST"]), user = try XCTUnwrap(env["HERDR_TEST_USER"])
        let app = XCUIApplication()
        app.launchEnvironment["HERDR_DEBUG_KEY_PATH"] = env["HERDR_DEBUG_KEY_PATH"] ?? ""
        app.launchEnvironment["HERDR_DEBUG_OBSERVE"] = "1"
        app.launch()
        let hostField = app.textFields["100.x.y.z or my-box.local"]
        XCTAssertTrue(hostField.waitForExistence(timeout: 15), "no onboarding form")
        hostField.tap(); hostField.typeText(host)
        let userField = app.textFields["username"]
        userField.tap(); userField.typeText(user)
        app.buttons["Connect"].tap()

        let fp = app.staticTexts["hostKeyFingerprint"]
        XCTAssertTrue(fp.waitForExistence(timeout: 30), "no host key approval")
        shot(app, "host-key-approval")
        XCTAssertEqual(fp.label, env["HERDR_TEST_HOST_FP"], "fingerprint differs from the box's host key")
        XCTAssertFalse(app.buttons["New agent"].exists, "reached home before approval")

        app.buttons["Trust and connect"].tap()
        XCTAssertTrue(app.buttons["New agent"].waitForExistence(timeout: 30), "did not reach home after approval")
        shot(app, "home-after-approval")
    }

    /// Files: from a space ($HERDR_TEST_SPACE) walk $HERDR_TEST_FILES_PATH (slash-separated folders
    /// under the space folder) and open each of $HERDR_TEST_FILES (comma-separated) in Quick Look.
    /// Needs a pinned host key (run testFirstConnectAsksForHostKey first).
    func testFilesPreviewInQuickLook() throws {
        let env = ProcessInfo.processInfo.environment
        let app = launch(["HERDR_DEBUG_OPEN": try XCTUnwrap(env["HERDR_TEST_SPACE"])])
        let files = app.buttons["Files"]
        XCTAssertTrue(files.waitForExistence(timeout: 30), "no Files button in the space")
        files.tap()
        for folder in (env["HERDR_TEST_FILES_PATH"] ?? "").split(separator: "/") {
            let row = app.buttons[String(folder)]
            XCTAssertTrue(reveal(row, in: app), "no folder \(folder)")
            row.tap()
        }
        for name in try XCTUnwrap(env["HERDR_TEST_FILES"]).split(separator: ",").map(String.init) {
            let row = app.buttons[name]
            XCTAssertTrue(reveal(row, in: app), "no file \(name)")
            row.tap()
            // Quick Look, or the app's own sheet for Markdown.
            let done = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'QLOverlayDoneButton' OR identifier == 'markdownClose'")).firstMatch
            // Images open full screen with the controls hidden; a tap brings them back.
            if !done.waitForExistence(timeout: 15) { app.tap() }
            XCTAssertTrue(done.waitForExistence(timeout: 15), "Quick Look did not open \(name)")
            sleep(2)
            shot(app, "preview-\(name)")
            done.tap()
            XCTAssertTrue(row.waitForExistence(timeout: 10), "did not return to the list after \(name)")
        }
    }

    /// Chat sends: types $HERDR_TEST_SEND_TEXT into the composer of $HERDR_TEST_SEND_TERMINAL (a
    /// throwaway Claude Code or Codex), sends it, and waits for a reply line equal to
    /// $HERDR_TEST_SEND_EXPECT, which must not appear in the text sent.
    func testChatSendGetsReply() throws {
        let env = ProcessInfo.processInfo.environment
        let text = try XCTUnwrap(env["HERDR_TEST_SEND_TEXT"]), expect = try XCTUnwrap(env["HERDR_TEST_SEND_EXPECT"])
        XCTAssertFalse(text.contains(expect), "the expected reply is part of the prompt")
        let app = launch(["HERDR_DEBUG_OPEN": try XCTUnwrap(env["HERDR_TEST_SEND_TERMINAL"])])
        let field = app.textViews.firstMatch.exists ? app.textViews.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 30), "no composer")
        field.tap()
        field.typeText(text)
        app.buttons["Send"].tap()
        let reply = app.staticTexts.matching(NSPredicate(format: "label == %@", expect)).firstMatch
        XCTAssertTrue(reply.waitForExistence(timeout: 120), "no reply \(expect) in Chat")
        shot(app, "chat-after-send")
    }

    /// A blocked agent's dialog becomes buttons: opens $HERDR_TEST_BLOCKED_TERMINAL (a throwaway
    /// agent left waiting on a multiple-choice question), taps the option labelled
    /// $HERDR_TEST_BLOCKED_OPTION and waits for the card to go away.
    func testBlockedDialogButtons() throws {
        let env = ProcessInfo.processInfo.environment
        let option = try XCTUnwrap(env["HERDR_TEST_BLOCKED_OPTION"])
        let app = launch(["HERDR_DEBUG_OPEN": try XCTUnwrap(env["HERDR_TEST_BLOCKED_TERMINAL"])])
        let button = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", option)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 30), "no button for \(option)")
        shot(app, "blocked-card")
        button.tap()
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: button)
        waitForExpectations(timeout: 60)
        shot(app, "after-answer")
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
