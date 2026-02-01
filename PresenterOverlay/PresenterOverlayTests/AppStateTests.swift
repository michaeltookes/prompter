import XCTest
@testable import PresenterOverlay

@MainActor
final class AppStateTests: XCTestCase {

    var appState: AppState!

    override func setUp() async throws {
        // Reset settings to defaults before each test
        PersistenceService.shared.saveSettingsSync(.default)
        appState = AppState()
    }

    override func tearDown() async throws {
        appState = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertNil(appState.currentDeck)
        XCTAssertEqual(appState.currentCardIndex, 0)
        XCTAssertFalse(appState.isOverlayVisible)
        XCTAssertFalse(appState.isClickThroughEnabled)
        XCTAssertTrue(appState.isProtectedModeEnabled)
        XCTAssertEqual(appState.overlayOpacity, 0.85)
        XCTAssertEqual(appState.overlayFontScale, 1.0)
    }

    // MARK: - Deck Operations Tests

    func testCreateNewDeck() {
        appState.createNewDeck(title: "Test Deck")

        XCTAssertNotNil(appState.currentDeck)
        XCTAssertEqual(appState.currentDeck?.title, "Test Deck")
        // currentCardIndex is 0 for empty deck
        XCTAssertEqual(appState.currentCardIndex, 0)
    }

    func testCreateNewDeckDefaultTitle() {
        appState.createNewDeck()

        XCTAssertNotNil(appState.currentDeck)
        XCTAssertEqual(appState.currentDeck?.title, "Untitled Deck")
    }

    func testLoadDeck() {
        let deck = Deck(title: "Loaded Deck", cards: [
            Card(layout: .titleBullets, title: "Card 1"),
            Card(layout: .titleBullets, title: "Card 2")
        ])

        appState.loadDeck(deck)

        XCTAssertEqual(appState.currentDeck?.title, "Loaded Deck")
        XCTAssertEqual(appState.currentDeck?.cards.count, 2)
        XCTAssertEqual(appState.currentCardIndex, 0)
    }

    // MARK: - Card Navigation Tests

    func testNextCard() {
        let deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets),
            Card(layout: .titleBullets),
            Card(layout: .titleBullets)
        ])
        appState.loadDeck(deck)

        XCTAssertEqual(appState.currentCardIndex, 0)
        XCTAssertTrue(appState.canGoNext)

        appState.nextCard()
        XCTAssertEqual(appState.currentCardIndex, 1)

        appState.nextCard()
        XCTAssertEqual(appState.currentCardIndex, 2)
        XCTAssertFalse(appState.canGoNext)

        // Shouldn't go beyond last card
        appState.nextCard()
        XCTAssertEqual(appState.currentCardIndex, 2)
    }

    func testPreviousCard() {
        let deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets),
            Card(layout: .titleBullets),
            Card(layout: .titleBullets)
        ])
        appState.loadDeck(deck)
        appState.goToCard(at: 2)

        XCTAssertEqual(appState.currentCardIndex, 2)
        XCTAssertTrue(appState.canGoPrevious)

        appState.previousCard()
        XCTAssertEqual(appState.currentCardIndex, 1)

        appState.previousCard()
        XCTAssertEqual(appState.currentCardIndex, 0)
        XCTAssertFalse(appState.canGoPrevious)

        // Shouldn't go before first card
        appState.previousCard()
        XCTAssertEqual(appState.currentCardIndex, 0)
    }

    func testGoToCard() {
        let deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets),
            Card(layout: .titleBullets),
            Card(layout: .titleBullets)
        ])
        appState.loadDeck(deck)

        appState.goToCard(at: 2)
        XCTAssertEqual(appState.currentCardIndex, 2)

        appState.goToCard(at: 0)
        XCTAssertEqual(appState.currentCardIndex, 0)

        // Invalid indices should be ignored
        appState.goToCard(at: -1)
        XCTAssertEqual(appState.currentCardIndex, 0)

        appState.goToCard(at: 100)
        XCTAssertEqual(appState.currentCardIndex, 0)
    }

    // MARK: - Card Editing Tests

    func testAddCard() {
        appState.createNewDeck(title: "Test")
        let initialCount = appState.currentDeck?.cards.count ?? 0

        appState.addCard(layout: .imageTopNotes)

        XCTAssertEqual(appState.currentDeck?.cards.count, initialCount + 1)
        XCTAssertEqual(appState.currentDeck?.cards.last?.layout, .imageTopNotes)
    }

    func testDeleteCard() {
        let deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets, title: "A"),
            Card(layout: .titleBullets, title: "B"),
            Card(layout: .titleBullets, title: "C")
        ])
        appState.loadDeck(deck)

        appState.deleteCard(at: 1)

        XCTAssertEqual(appState.currentDeck?.cards.count, 2)
        XCTAssertEqual(appState.currentDeck?.cards[0].title, "A")
        XCTAssertEqual(appState.currentDeck?.cards[1].title, "C")
    }

    func testUpdateCard() {
        let deck = Deck(title: "Test", cards: [Card(layout: .titleBullets)])
        appState.loadDeck(deck)

        var card = appState.currentDeck!.cards[0]
        card.title = "Updated"
        appState.updateCard(card, at: 0)

        XCTAssertEqual(appState.currentDeck?.cards[0].title, "Updated")
    }

    // MARK: - Overlay Controls Tests

    func testToggleOverlay() {
        XCTAssertFalse(appState.isOverlayVisible)

        appState.toggleOverlay()
        XCTAssertTrue(appState.isOverlayVisible)

        appState.toggleOverlay()
        XCTAssertFalse(appState.isOverlayVisible)
    }

    func testToggleClickThrough() {
        XCTAssertFalse(appState.isClickThroughEnabled)

        appState.toggleClickThrough()
        XCTAssertTrue(appState.isClickThroughEnabled)

        appState.toggleClickThrough()
        XCTAssertFalse(appState.isClickThroughEnabled)
    }

    func testToggleProtectedMode() {
        XCTAssertTrue(appState.isProtectedModeEnabled)

        appState.toggleProtectedMode()
        XCTAssertFalse(appState.isProtectedModeEnabled)

        appState.toggleProtectedMode()
        XCTAssertTrue(appState.isProtectedModeEnabled)
    }

    // MARK: - Font Size Tests

    func testIncreaseFontSize() {
        let initial = appState.overlayFontScale

        appState.increaseFontSize()
        XCTAssertEqual(appState.overlayFontScale, initial + 0.1, accuracy: 0.001)
    }

    func testDecreaseFontSize() {
        let initial = appState.overlayFontScale

        appState.decreaseFontSize()
        XCTAssertEqual(appState.overlayFontScale, initial - 0.1, accuracy: 0.001)
    }

    func testFontSizeMax() {
        // Set to max
        appState.overlayFontScale = 2.0
        appState.increaseFontSize()

        XCTAssertEqual(appState.overlayFontScale, 2.0) // Should not exceed max
    }

    func testFontSizeMin() {
        // Set to min
        appState.overlayFontScale = 0.5
        appState.decreaseFontSize()

        XCTAssertEqual(appState.overlayFontScale, 0.5) // Should not go below min
    }

    // MARK: - Computed Properties Tests

    func testCurrentCard() {
        XCTAssertNil(appState.currentCard)

        let deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets, title: "Current")
        ])
        appState.loadDeck(deck)

        XCTAssertEqual(appState.currentCard?.title, "Current")
    }

    func testTotalCards() {
        XCTAssertEqual(appState.totalCards, 0)

        let deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets),
            Card(layout: .titleBullets)
        ])
        appState.loadDeck(deck)

        XCTAssertEqual(appState.totalCards, 2)
    }
}
