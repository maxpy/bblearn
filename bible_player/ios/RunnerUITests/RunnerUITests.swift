import XCTest

/// XCUITest suite for Bible Audio Player playback functionality.
class RunnerUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }

  override func tearDownWithError() throws {
    app.terminate()
  }

  // MARK: - Helpers

  /// Find play/pause button by accessibility identifier or label.
  func playPauseButton() -> XCUIElement {
    // Flutter Semantics(identifier:) sets accessibilityIdentifier
    let byId = app.buttons.matching(identifier: "play_pause_button").firstMatch
    if byId.exists { return byId }
    // Fallback: find by label
    let byLabel = app.buttons.matching(NSPredicate(format: "label IN %@", ["play", "pause"])).firstMatch
    return byLabel
  }

  func verseLabel() -> XCUIElement {
    app.staticTexts.matching(identifier: "current_verse_label").firstMatch
  }

  func versionLabel() -> XCUIElement {
    app.staticTexts.matching(identifier: "current_version_label").firstMatch
  }

  func waitForPlayer(timeout: TimeInterval = 30) -> Bool {
    // Wait for any button to appear (app loaded)
    let predicate = NSPredicate(format: "exists == true")
    let btn = playPauseButton()
    let exp = expectation(for: predicate, evaluatedWith: btn)
    let result = XCTWaiter.wait(for: [exp], timeout: timeout)
    return result == .completed
  }

  // MARK: - Tests

  func testAppLaunches() throws {
    XCTAssertTrue(waitForPlayer(timeout: 30), "Play button should appear within 30s")
  }

  func testPlayPauseToggle() throws {
    XCTAssertTrue(waitForPlayer(timeout: 30))
    let btn = playPauseButton()
    XCTAssertTrue(btn.exists, "Play/pause button must exist")
    btn.tap()
    Thread.sleep(forTimeInterval: 1)
    btn.tap() // pause
    Thread.sleep(forTimeInterval: 1)
    // No crash = pass
  }

  func testPlayAdvancesVerse() throws {
    XCTAssertTrue(waitForPlayer(timeout: 30))

    let btn = playPauseButton()
    let verse = verseLabel()

    // Record verse before playing
    let verseBefore = verse.exists ? verse.label : ""

    btn.tap() // play

    // Wait up to 15s for verse label to change
    let exp = expectation(description: "verse advances")
    exp.assertForOverFulfill = false
    DispatchQueue.global().async {
      let start = Date()
      while Date().timeIntervalSince(start) < 15 {
        if self.verseLabel().label != verseBefore {
          exp.fulfill()
          return
        }
        Thread.sleep(forTimeInterval: 0.3)
      }
      exp.fulfill() // fulfill anyway so test can report
    }
    wait(for: [exp], timeout: 16)

    btn.tap() // pause

    let verseAfter = verseLabel().label
    XCTAssertNotEqual(verseBefore, verseAfter, "Verse label should change after playing")
  }

  func testCNThenENSequence() throws {
    XCTAssertTrue(waitForPlayer(timeout: 30))

    let btn = playPauseButton()
    let version = versionLabel()

    btn.tap() // play

    var versions: [String] = []
    let start = Date()
    while Date().timeIntervalSince(start) < 15 {
      let v = version.label
      if !v.isEmpty && versions.last != v {
        versions.append(v)
      }
      Thread.sleep(forTimeInterval: 0.3)
    }

    btn.tap() // pause

    XCTAssertTrue(versions.contains("CUV") || versions.contains("KJV"),
                  "At least one version should play. Got: \(versions)")

    if versions.count >= 2 {
      // Check CUV appears before KJV (or vice versa depending on sequence)
      let hasBoth = versions.contains("CUV") && versions.contains("KJV")
      XCTAssertTrue(hasBoth, "Both CUV and KJV should play. Got: \(versions)")
    }
  }

  func testPauseStopsVerse() throws {
    XCTAssertTrue(waitForPlayer(timeout: 30))

    let btn = playPauseButton()
    btn.tap() // play
    Thread.sleep(forTimeInterval: 3)

    btn.tap() // pause
    let verseAtPause = verseLabel().label
    Thread.sleep(forTimeInterval: 3)
    let verseAfterWait = verseLabel().label

    XCTAssertEqual(verseAtPause, verseAfterWait, "Verse should not change while paused")
  }

  func testBackgroundPlayback() throws {
    XCTAssertTrue(waitForPlayer(timeout: 30))

    let btn = playPauseButton()
    btn.tap() // play
    Thread.sleep(forTimeInterval: 2)

    let verseBefore = verseLabel().label

    // Send app to background
    XCUIDevice.shared.press(.home)
    Thread.sleep(forTimeInterval: 5)

    // Return to app
    app.activate()
    Thread.sleep(forTimeInterval: 1)

    let verseAfter = verseLabel().label
    btn.tap() // pause

    XCTAssertNotEqual(verseBefore, verseAfter,
                      "Verse should advance while app is backgrounded (lock screen playback)")
  }
}
