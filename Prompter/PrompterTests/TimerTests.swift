import XCTest
@testable import Prompter

@MainActor
final class TimerTests: XCTestCase {

    var appState: AppState!

    /// Helper: creates and loads a multi-card deck with timer enabled
    private func loadTimerDeck(cardCount: Int = 3) {
        let cards = (0..<cardCount).map { _ in Card(layout: .titleBullets) }
        let deck = Deck(title: "Timer Test", cards: cards)
        appState.loadDeck(deck)
        appState.isTimerEnabled = true
        appState.timerApplyMode = "all"
    }

    override func setUp() async throws {
        PersistenceService.shared.saveSettingsSync(.default)
        appState = AppState()
    }

    override func tearDown() async throws {
        appState.stopTimer()
        appState = nil
    }

    // MARK: - Timer Display Formatting

    func testTimerDisplayText_typical() {
        appState.timerSecondsRemaining = 125
        XCTAssertEqual(appState.timerDisplayText, "02:05")
    }

    func testTimerDisplayText_zero() {
        appState.timerSecondsRemaining = 0
        XCTAssertEqual(appState.timerDisplayText, "00:00")
    }

    func testTimerDisplayText_exactMinute() {
        appState.timerSecondsRemaining = 60
        XCTAssertEqual(appState.timerDisplayText, "01:00")
    }

    // MARK: - Effective Per-Card Seconds

    func testEffectivePerCardSeconds_deckMode() {
        loadTimerDeck(cardCount: 3)
        appState.timerMode = "deck"
        appState.timerTotalSeconds = 300

        XCTAssertEqual(appState.effectivePerCardSeconds, 100)
    }

    func testEffectivePerCardSeconds_perCardMode() {
        loadTimerDeck(cardCount: 3)
        appState.timerMode = "perCard"
        appState.timerPerCardSeconds = 45

        XCTAssertEqual(appState.effectivePerCardSeconds, 45)
    }

    func testEffectivePerCardSeconds_deckMode_noDeck() {
        // No deck loaded should disable deck-mode timing
        appState.timerMode = "deck"
        appState.timerTotalSeconds = 300

        XCTAssertEqual(appState.effectivePerCardSeconds, 0)
    }

    // MARK: - Timer Activation Scope

    func testIsTimerActiveForCurrentDeck_allMode_enabled() {
        loadTimerDeck()
        appState.isTimerEnabled = true
        appState.timerApplyMode = "all"

        XCTAssertTrue(appState.isTimerActiveForCurrentDeck)
    }

    func testIsTimerActiveForCurrentDeck_disabled() {
        loadTimerDeck()
        appState.isTimerEnabled = false

        XCTAssertFalse(appState.isTimerActiveForCurrentDeck)
    }

    func testIsTimerActiveForCurrentDeck_selectedMode_included() {
        loadTimerDeck()
        appState.timerApplyMode = "selected"
        appState.timerSelectedDeckIds = [appState.currentDeck!.id]

        XCTAssertTrue(appState.isTimerActiveForCurrentDeck)
    }

    func testIsTimerActiveForCurrentDeck_selectedMode_excluded() {
        loadTimerDeck()
        appState.timerApplyMode = "selected"
        appState.timerSelectedDeckIds = []

        XCTAssertFalse(appState.isTimerActiveForCurrentDeck)
    }

    func testIsTimerActiveForCurrentDeck_noDeck() {
        appState.isTimerEnabled = true
        appState.timerApplyMode = "selected"
        // No deck loaded
        XCTAssertFalse(appState.isTimerActiveForCurrentDeck)
    }

    func testIsTimerActiveForCurrentDeck_allMode_noCards() {
        appState.isTimerEnabled = true
        appState.timerApplyMode = "all"
        appState.loadDeck(Deck(title: "Empty", cards: []))

        XCTAssertFalse(appState.isTimerActiveForCurrentDeck)
    }

    // MARK: - Start Timer

    func testStartTimer_setsInitialState() {
        loadTimerDeck()
        appState.timerMode = "perCard"
        appState.timerPerCardSeconds = 60

        appState.startTimer()

        XCTAssertTrue(appState.isTimerRunning)
        XCTAssertFalse(appState.isTimerPaused)
        XCTAssertFalse(appState.isTimerWarning)
        XCTAssertEqual(appState.timerSecondsRemaining, 60)
    }

    func testStartTimer_inactiveDeck_doesNothing() {
        loadTimerDeck()
        appState.isTimerEnabled = false

        appState.startTimer()

        XCTAssertFalse(appState.isTimerRunning)
        XCTAssertEqual(appState.timerSecondsRemaining, 0)
    }

    // MARK: - Stop Timer

    func testStopTimer_resetsAllState() {
        loadTimerDeck()
        appState.startTimer()
        XCTAssertTrue(appState.isTimerRunning)

        appState.stopTimer()

        XCTAssertFalse(appState.isTimerRunning)
        XCTAssertFalse(appState.isTimerPaused)
        XCTAssertFalse(appState.isTimerWarning)
        XCTAssertEqual(appState.timerSecondsRemaining, 0)
    }

    // MARK: - Pause / Resume

    func testPauseTimer_whenRunning() {
        loadTimerDeck()
        appState.startTimer()

        appState.pauseTimer()

        XCTAssertTrue(appState.isTimerRunning)
        XCTAssertTrue(appState.isTimerPaused)
    }

    func testPauseTimer_whenNotRunning_doesNothing() {
        loadTimerDeck()

        appState.pauseTimer()

        XCTAssertFalse(appState.isTimerRunning)
        XCTAssertFalse(appState.isTimerPaused)
    }

    func testPauseTimer_whenAlreadyPaused_doesNothing() {
        loadTimerDeck()
        appState.startTimer()
        appState.pauseTimer()
        XCTAssertTrue(appState.isTimerPaused)

        // Pause again — should remain paused, no crash
        appState.pauseTimer()
        XCTAssertTrue(appState.isTimerPaused)
    }

    func testResumeTimer_fromPaused() {
        loadTimerDeck()
        appState.startTimer()
        appState.pauseTimer()
        XCTAssertTrue(appState.isTimerPaused)

        appState.resumeTimer()

        XCTAssertTrue(appState.isTimerRunning)
        XCTAssertFalse(appState.isTimerPaused)
    }

    func testResumeTimer_whenNotPaused_doesNothing() {
        loadTimerDeck()
        appState.startTimer()
        // Running but not paused
        XCTAssertFalse(appState.isTimerPaused)

        appState.resumeTimer()

        // No change
        XCTAssertTrue(appState.isTimerRunning)
        XCTAssertFalse(appState.isTimerPaused)
    }

    func testResumeTimer_whenNotRunning_doesNothing() {
        loadTimerDeck()
        // Not running
        appState.resumeTimer()

        XCTAssertFalse(appState.isTimerRunning)
        XCTAssertFalse(appState.isTimerPaused)
    }

    // MARK: - Toggle Timer Start/Pause Cycle

    func testToggle_stopped_starts() {
        loadTimerDeck()
        XCTAssertFalse(appState.isTimerRunning)

        appState.toggleTimerStartPause()

        XCTAssertTrue(appState.isTimerRunning)
    }

    func testToggle_running_withPauseButton_pauses() {
        loadTimerDeck()
        appState.timerShowPauseButton = true
        appState.startTimer()

        appState.toggleTimerStartPause()

        XCTAssertTrue(appState.isTimerRunning)
        XCTAssertTrue(appState.isTimerPaused)
    }

    func testToggle_running_noPauseButton_stops() {
        loadTimerDeck()
        appState.timerShowPauseButton = false
        appState.startTimer()

        appState.toggleTimerStartPause()

        XCTAssertFalse(appState.isTimerRunning)
    }

    func testToggle_paused_resumes() {
        loadTimerDeck()
        appState.timerShowPauseButton = true
        appState.startTimer()
        appState.pauseTimer()
        XCTAssertTrue(appState.isTimerPaused)

        appState.toggleTimerStartPause()

        XCTAssertTrue(appState.isTimerRunning)
        XCTAssertFalse(appState.isTimerPaused)
    }

    // MARK: - Card Navigation Timer Integration

    func testNextCard_autoStartsTimer() {
        loadTimerDeck(cardCount: 3)
        XCTAssertFalse(appState.isTimerRunning)

        appState.nextCard()

        XCTAssertTrue(appState.isTimerRunning)
    }

    func testNextCard_resetsTimer_whenRunning() {
        loadTimerDeck(cardCount: 3)
        appState.timerMode = "perCard"
        appState.timerPerCardSeconds = 60
        appState.startTimer()

        // Simulate some time passing
        appState.timerSecondsRemaining = 30

        appState.nextCard()

        // Timer should have reset to full per-card time
        XCTAssertEqual(appState.timerSecondsRemaining, 60)
    }

    func testPreviousCard_autoStartsTimer() {
        loadTimerDeck(cardCount: 3)
        appState.goToCard(at: 2)
        XCTAssertFalse(appState.isTimerRunning)

        appState.previousCard()

        XCTAssertTrue(appState.isTimerRunning)
    }

    func testPreviousCard_resetsTimer_whenRunning() {
        loadTimerDeck(cardCount: 3)
        appState.timerMode = "perCard"
        appState.timerPerCardSeconds = 60
        appState.goToCard(at: 2)
        appState.startTimer()

        appState.timerSecondsRemaining = 25

        appState.previousCard()

        XCTAssertEqual(appState.timerSecondsRemaining, 60)
    }

    // MARK: - Reset Card Timer

    func testResetCardTimer_resetsRemaining() {
        loadTimerDeck()
        appState.timerMode = "perCard"
        appState.timerPerCardSeconds = 60
        appState.startTimer()

        appState.timerSecondsRemaining = 10
        appState.isTimerWarning = true

        appState.resetCardTimer()

        XCTAssertEqual(appState.timerSecondsRemaining, 60)
        XCTAssertFalse(appState.isTimerWarning)
    }

    func testResetCardTimer_whenNotRunning_doesNothing() {
        loadTimerDeck()
        appState.timerSecondsRemaining = 10

        appState.resetCardTimer()

        // Should not change since timer isn't running
        XCTAssertEqual(appState.timerSecondsRemaining, 10)
    }

    // MARK: - Timer Tick (real timer, short delays)

    func testTimerTick_decrementsSeconds() async {
        loadTimerDeck()
        appState.timerMode = "perCard"
        appState.timerPerCardSeconds = 10
        appState.startTimer()
        XCTAssertEqual(appState.timerSecondsRemaining, 10)

        // Wait for at least 1 tick (1 second + buffer)
        let expectation = XCTestExpectation(description: "Timer ticks at least once")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 3)

        XCTAssertLessThan(appState.timerSecondsRemaining, 10)
    }

    func testTimerTick_warningThreshold() async {
        loadTimerDeck()
        appState.timerMode = "perCard"
        appState.timerPerCardSeconds = 3  // Very short — warning at 20% = 0.6s, rounded to 0
        appState.startTimer()
        XCTAssertFalse(appState.isTimerWarning)

        // Wait for timer to count down past warning threshold
        let expectation = XCTestExpectation(description: "Timer reaches warning")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5)

        XCTAssertTrue(appState.isTimerWarning)
    }

    func testTimerPause_stopsCountdown() async {
        loadTimerDeck()
        appState.timerMode = "perCard"
        appState.timerPerCardSeconds = 10
        appState.startTimer()

        // Pause immediately
        appState.pauseTimer()
        let remainingAfterPause = appState.timerSecondsRemaining

        // Wait and verify it hasn't changed
        let expectation = XCTestExpectation(description: "Pause holds")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 3)

        XCTAssertEqual(appState.timerSecondsRemaining, remainingAfterPause)
    }

    func testTimerTick_marksStoppedAtZero() async {
        loadTimerDeck()
        appState.timerMode = "perCard"
        appState.timerPerCardSeconds = 1
        appState.startTimer()

        let expectation = XCTestExpectation(description: "Timer reaches zero and stops")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 3)

        XCTAssertFalse(appState.isTimerRunning)
        XCTAssertEqual(appState.timerSecondsRemaining, 0)
        XCTAssertTrue(appState.isTimerWarning)
    }
}
