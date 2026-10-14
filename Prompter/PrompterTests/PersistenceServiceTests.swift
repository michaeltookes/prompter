import XCTest
@testable import Prompter

/// Tests for PersistenceService.
///
/// Each test gets its own service rooted at a fresh temporary folder, which is
/// deleted in `tearDown`; nothing here touches `~/Library/Application Support`.
@MainActor
final class PersistenceServiceTests: XCTestCase {

    private var service: PersistenceService!
    private var rootURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrompterTests-\(UUID().uuidString)", isDirectory: true)
        service = PersistenceService(rootURL: rootURL)
    }

    override func tearDown() async throws {
        service = nil
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
        rootURL = nil
        try await super.tearDown()
    }

    // MARK: - Settings Tests

    func testLoadDefaultSettings() {
        // A fresh root has no settings file, so defaults come back
        let settings = service.loadSettings()

        XCTAssertEqual(settings, Settings.default)
        XCTAssertFalse(FileManager.default.fileExists(atPath: StoragePaths(root: rootURL).settings.path))
    }

    func testSaveSettingsWritesUnderInjectedRoot() {
        service.saveSettingsSync(Settings.default)

        XCTAssertTrue(FileManager.default.fileExists(atPath: StoragePaths(root: rootURL).settings.path))
    }

    func testSaveAndLoadSettings() {
        let settings = Settings(
            overlayOpacity: 0.75,
            overlayFontScale: 1.5,
            overlayFrame: OverlayFrame(x: 100, y: 200, width: 300, height: 400),
            clickThroughEnabled: true,
            protectedModeEnabled: false,
            lastOpenedDeckId: UUID()
        )

        // Save synchronously so we can test immediately
        service.saveSettingsSync(settings)

        // Load and verify
        let loaded = service.loadSettings()
        XCTAssertEqual(loaded.overlayOpacity, 0.75)
        XCTAssertEqual(loaded.overlayFontScale, 1.5)
        XCTAssertEqual(loaded.overlayFrame.x, 100)
        XCTAssertEqual(loaded.overlayFrame.y, 200)
        XCTAssertEqual(loaded.overlayFrame.width, 300)
        XCTAssertEqual(loaded.overlayFrame.height, 400)
        XCTAssertTrue(loaded.clickThroughEnabled)
        XCTAssertFalse(loaded.protectedModeEnabled)
    }

    func testSettingsValidation() {
        // Create settings with out-of-range values
        let settings = Settings(
            overlayOpacity: 0.1, // Below minimum of 0.3
            overlayFontScale: 3.0, // Above maximum of 2.0
            overlayFrame: .default,
            clickThroughEnabled: false,
            protectedModeEnabled: true,
            lastOpenedDeckId: nil
        )

        service.saveSettingsSync(settings)
        let loaded = service.loadSettings()

        // Values should be clamped to valid ranges
        XCTAssertEqual(loaded.overlayOpacity, 0.3, "Opacity should be clamped to minimum")
        XCTAssertEqual(loaded.overlayFontScale, 2.0, "Font scale should be clamped to maximum")
    }

    // MARK: - Deck Tests

    func testSaveAndLoadDeck() {
        var deck = Deck(title: "Test Deck")
        deck.addCard(Card(layout: .titleBullets))
        deck.addCard(Card(layout: .imageTopNotes))

        // Save synchronously
        service.saveDeckSync(deck)

        // Load and verify
        let loaded = service.loadDeck(id: deck.id)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, deck.id)
        XCTAssertEqual(loaded?.title, "Test Deck")
        XCTAssertEqual(loaded?.cards.count, 2)
        XCTAssertEqual(loaded?.cards[0].layout, .titleBullets)
        XCTAssertEqual(loaded?.cards[1].layout, .imageTopNotes)
    }

    func testLoadNonexistentDeck() {
        let fakeId = UUID()
        let loaded = service.loadDeck(id: fakeId)
        XCTAssertNil(loaded, "Loading nonexistent deck should return nil")
    }

    func testDeleteDeck() {
        var deck = Deck(title: "To Be Deleted")
        deck.addCard(Card(layout: .titleBullets))

        service.saveDeckSync(deck)

        // Verify it exists
        XCTAssertNotNil(service.loadDeck(id: deck.id))

        // Delete it
        service.deleteDeck(id: deck.id)

        // Verify it's gone
        XCTAssertNil(service.loadDeck(id: deck.id))
    }

    func testListDeckIds() {
        // Create a few test decks
        let deck1 = Deck(title: "Deck 1")
        let deck2 = Deck(title: "Deck 2")

        service.saveDeckSync(deck1)
        service.saveDeckSync(deck2)

        let ids = service.listDeckIds()

        XCTAssertTrue(ids.contains(deck1.id), "Should list deck1's ID")
        XCTAssertTrue(ids.contains(deck2.id), "Should list deck2's ID")
    }

    func testLoadAllDecks() {
        // Create test decks
        let deck1 = Deck(title: "All Decks Test 1")
        let deck2 = Deck(title: "All Decks Test 2")

        service.saveDeckSync(deck1)
        service.saveDeckSync(deck2)

        let allDecks = service.loadAllDecks()
        let titles = allDecks.map { $0.title }

        XCTAssertTrue(titles.contains("All Decks Test 1"))
        XCTAssertTrue(titles.contains("All Decks Test 2"))
    }

    func testLoadDeckMetadata() {
        var deck = Deck(title: "Metadata Test")
        deck.addCard(Card(layout: .titleBullets))
        deck.addCard(Card(layout: .imageTopNotes))
        deck.addCard(Card(layout: .grid2x2Caption))

        service.saveDeckSync(deck)

        let metadata = service.loadDeckMetadata()
        let testMetadata = metadata.first { $0.id == deck.id }

        XCTAssertNotNil(testMetadata)
        XCTAssertEqual(testMetadata?.title, "Metadata Test")
        XCTAssertEqual(testMetadata?.cardCount, 3)
    }

    func testDeckWithComplexContent() {
        var card = Card(layout: .titleBullets)
        card.title = "Complex Card"
        card.bullets = ["Bullet 1", "Bullet 2", "Bullet 3"]
        card.notes = "These are detailed notes about the card."

        var deck = Deck(title: "Complex Deck")
        deck.addCard(card)

        service.saveDeckSync(deck)

        let loaded = service.loadDeck(id: deck.id)
        XCTAssertNotNil(loaded)

        let loadedCard = loaded?.cards.first
        XCTAssertEqual(loadedCard?.title, "Complex Card")
        XCTAssertEqual(loadedCard?.bullets, ["Bullet 1", "Bullet 2", "Bullet 3"])
        XCTAssertEqual(loadedCard?.notes, "These are detailed notes about the card.")
    }

    // MARK: - Utility Tests

    func testTotalDataSize() {
        // Just verify it returns a non-negative value
        let size = service.totalDataSize()
        XCTAssertGreaterThanOrEqual(size, 0)
    }

    func testDeleteNonexistentDeck() {
        // Should not crash when deleting a deck that doesn't exist
        let fakeId = UUID()
        service.deleteDeck(id: fakeId)
        // If we get here without crashing, the test passes
    }
}
