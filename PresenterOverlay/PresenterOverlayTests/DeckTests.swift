import XCTest
@testable import PresenterOverlay

final class DeckTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDeckInitializationEmpty() {
        let deck = Deck(title: "Test Deck")

        XCTAssertEqual(deck.title, "Test Deck")
        XCTAssertTrue(deck.cards.isEmpty)
    }

    func testDeckInitializationWithCards() {
        let cards = [
            Card(layout: .titleBullets, title: "Card 1"),
            Card(layout: .imageTopNotes)
        ]
        let deck = Deck(title: "Test Deck", cards: cards)

        XCTAssertEqual(deck.cards.count, 2)
        XCTAssertEqual(deck.cards[0].title, "Card 1")
    }

    func testCreateDefault() {
        let deck = Deck.createDefault()

        XCTAssertEqual(deck.title, "My First Deck")
        XCTAssertEqual(deck.cards.count, 1)
        XCTAssertEqual(deck.cards[0].layout, .titleBullets)
    }

    // MARK: - Card Management Tests

    func testAddCard() {
        var deck = Deck(title: "Test")
        let card = Card(layout: .titleBullets)

        deck.addCard(card)

        XCTAssertEqual(deck.cards.count, 1)
        XCTAssertEqual(deck.cards[0].id, card.id)
    }

    func testRemoveCard() {
        let cards = [
            Card(layout: .titleBullets),
            Card(layout: .imageTopNotes),
            Card(layout: .twoImagesNotes)
        ]
        var deck = Deck(title: "Test", cards: cards)

        deck.removeCard(at: 1)

        XCTAssertEqual(deck.cards.count, 2)
        XCTAssertEqual(deck.cards[0].layout, .titleBullets)
        XCTAssertEqual(deck.cards[1].layout, .twoImagesNotes)
    }

    func testUpdateCard() {
        var deck = Deck(title: "Test", cards: [Card(layout: .titleBullets)])
        var updatedCard = deck.cards[0]
        updatedCard.title = "Updated Title"

        deck.updateCard(updatedCard)

        XCTAssertEqual(deck.cards[0].title, "Updated Title")
    }

    func testDuplicateCard() {
        var deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets, title: "Original", bullets: ["A", "B"])
        ])

        let duplicate = deck.duplicateCard(at: 0)

        XCTAssertNotNil(duplicate)
        XCTAssertEqual(deck.cards.count, 2)
        XCTAssertNotEqual(duplicate?.id, deck.cards[0].id)
        XCTAssertEqual(duplicate?.title, "Original")
        XCTAssertEqual(duplicate?.bullets, ["A", "B"])
    }

    func testMoveCard() {
        var deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets, title: "A"),
            Card(layout: .titleBullets, title: "B"),
            Card(layout: .titleBullets, title: "C")
        ])

        // Move first card to end (pass destination past last element)
        deck.moveCard(from: 0, to: 3)

        XCTAssertEqual(deck.cards[0].title, "B")
        XCTAssertEqual(deck.cards[1].title, "C")
        XCTAssertEqual(deck.cards[2].title, "A")
    }

    func testMoveCardMiddle() {
        var deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets, title: "A"),
            Card(layout: .titleBullets, title: "B"),
            Card(layout: .titleBullets, title: "C")
        ])

        // Move last card to first position
        deck.moveCard(from: 2, to: 0)

        XCTAssertEqual(deck.cards[0].title, "C")
        XCTAssertEqual(deck.cards[1].title, "A")
        XCTAssertEqual(deck.cards[2].title, "B")
    }

    func testInsertCard() {
        var deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets, title: "A"),
            Card(layout: .titleBullets, title: "C")
        ])
        let newCard = Card(layout: .titleBullets, title: "B")

        deck.insertCard(newCard, at: 1)

        XCTAssertEqual(deck.cards.count, 3)
        XCTAssertEqual(deck.cards[1].title, "B")
    }

    // MARK: - Computed Properties Tests

    func testIsEmpty() {
        let emptyDeck = Deck(title: "Empty")
        let nonEmptyDeck = Deck(title: "Has Cards", cards: [Card(layout: .titleBullets)])

        XCTAssertTrue(emptyDeck.isEmpty)
        XCTAssertFalse(nonEmptyDeck.isEmpty)
    }

    func testCardCount() {
        let deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets),
            Card(layout: .imageTopNotes)
        ])

        XCTAssertEqual(deck.cardCount, 2)
    }

    func testCurrentCard() {
        var deck = Deck(title: "Test", cards: [
            Card(layout: .titleBullets, title: "First"),
            Card(layout: .titleBullets, title: "Second")
        ])

        XCTAssertEqual(deck.currentCard?.title, "First")

        deck.currentCardIndex = 1
        XCTAssertEqual(deck.currentCard?.title, "Second")
    }

    func testCurrentCardWhenEmpty() {
        let deck = Deck(title: "Empty")
        XCTAssertNil(deck.currentCard)
    }

    // MARK: - Codable Tests

    func testDeckEncodeDecode() throws {
        let original = Deck(title: "Test Deck", cards: [
            Card(layout: .titleBullets, title: "Card 1"),
            Card(layout: .imageTopNotes)
        ])

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Deck.self, from: encoded)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.cards.count, 2)
    }
}
