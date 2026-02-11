import Foundation

/// A collection of presenter cards.
///
/// A deck represents one set of presenter notes, typically
/// for a single demo or presentation. Users flip through
/// cards in the deck during their presentation.
struct Deck: Identifiable, Codable, Equatable {
    /// Unique identifier for this deck
    var id: UUID

    /// Display title for the deck
    var title: String

    /// When this deck was created
    var createdAt: Date

    /// When this deck was last modified
    var updatedAt: Date

    /// The cards in this deck, in display order
    var cards: [Card]

    /// Index of the currently displayed card (for overlay state)
    /// This is persisted so users return to where they left off
    var currentCardIndex: Int

    // MARK: - Initialization

    /// Creates a new deck
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Display title (defaults to "Untitled Deck")
    ///   - cards: Initial cards (defaults to empty)
    ///   - currentCardIndex: Starting card index (defaults to 0)
    init(
        id: UUID = UUID(),
        title: String = "Untitled Deck",
        cards: [Card] = [],
        currentCardIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.cards = cards
        self.currentCardIndex = currentCardIndex
    }

    // MARK: - Factory Methods

    /// Creates a default deck with a sample welcome card
    static func createDefault() -> Deck {
        let sampleCard = Card(
            layout: .titleBullets,
            title: "Welcome to Prompter",
            bullets: [
                "Press Cmd+Shift+O to toggle this overlay",
                "Use Cmd+Shift+Arrow keys to navigate cards",
                "Open the Deck Editor from the menu bar to customize",
                "Enable Protected Mode to hide from screen sharing"
            ]
        )
        return Deck(
            title: "My First Deck",
            cards: [sampleCard]
        )
    }

    // MARK: - Card Operations

    /// Adds a new card to the deck
    /// - Parameter card: The card to add
    mutating func addCard(_ card: Card) {
        cards.append(card)
        updatedAt = Date()
    }

    /// Inserts a card at the specified index
    mutating func insertCard(_ card: Card, at index: Int) {
        let safeIndex = max(0, min(index, cards.count))
        cards.insert(card, at: safeIndex)
        updatedAt = Date()
    }

    /// Removes a card at the specified index
    /// - Returns: The removed card, or nil if index was invalid
    @discardableResult
    mutating func removeCard(at index: Int) -> Card? {
        guard index >= 0, index < cards.count else { return nil }
        let removed = cards.remove(at: index)
        updatedAt = Date()

        // Adjust currentCardIndex if needed
        if currentCardIndex >= cards.count {
            currentCardIndex = max(0, cards.count - 1)
        }

        return removed
    }

    /// Moves a card from one position to another
    mutating func moveCard(from source: Int, to destination: Int) {
        guard source >= 0, source < cards.count,
              destination >= 0, destination <= cards.count else { return }

        let card = cards.remove(at: source)
        let adjustedDestination = destination > source ? destination - 1 : destination
        cards.insert(card, at: min(adjustedDestination, cards.count))
        updatedAt = Date()
    }

    /// Duplicates a card at the specified index
    /// - Returns: The new duplicated card
    @discardableResult
    mutating func duplicateCard(at index: Int) -> Card? {
        guard index >= 0, index < cards.count else { return nil }

        var duplicate = cards[index]
        duplicate.id = UUID()
        duplicate.createdAt = Date()
        duplicate.updatedAt = Date()

        cards.insert(duplicate, at: index + 1)
        updatedAt = Date()

        return duplicate
    }

    /// Updates a card in the deck
    mutating func updateCard(_ card: Card) {
        guard let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        var updatedCard = card
        updatedCard.updatedAt = Date()
        cards[index] = updatedCard
        updatedAt = Date()
    }

    // MARK: - Computed Properties

    /// Whether the deck has any cards
    var isEmpty: Bool {
        cards.isEmpty
    }

    /// Total number of cards in the deck
    var cardCount: Int {
        cards.count
    }

    /// The currently selected card, if any
    var currentCard: Card? {
        guard currentCardIndex >= 0, currentCardIndex < cards.count else { return nil }
        return cards[currentCardIndex]
    }

    /// All asset references used in this deck (for cleanup purposes)
    var allAssetRefs: [AssetRef] {
        cards.flatMap { $0.imageSlots.compactMap { $0 } }
    }
}
