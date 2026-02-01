import SwiftUI
import Combine

/// Central application state container.
///
/// AppState is the single source of truth for the application.
/// All views observe this object and update reactively when state changes.
///
/// Responsibilities:
/// - Manage current deck and card navigation
/// - Track overlay visibility and settings
/// - Coordinate with persistence service for saving/loading
/// - Provide methods for all state mutations
@MainActor
final class AppState: ObservableObject {

    // MARK: - Deck State

    /// The currently open deck
    @Published var currentDeck: Deck?

    /// Index of the currently displayed card in the overlay
    @Published var currentCardIndex: Int = 0

    /// All available decks (for future deck switching)
    @Published var decks: [Deck] = []

    // MARK: - Overlay State

    /// Whether the overlay window is visible
    @Published var isOverlayVisible: Bool = false

    /// Overlay window opacity (0.0 to 1.0)
    @Published var overlayOpacity: Double = 0.85

    /// Font scale multiplier for overlay text
    @Published var overlayFontScale: Double = 1.0

    /// Saved overlay window frame
    @Published var overlayFrame: OverlayFrame = .default

    /// Whether click-through mode is enabled
    @Published var isClickThroughEnabled: Bool = false

    /// Whether Protected Mode is enabled
    @Published var isProtectedModeEnabled: Bool = true

    /// Current scroll offset within the overlay (for long content)
    @Published var overlayScrollOffset: CGFloat = 0

    // MARK: - Editor State

    /// Whether the deck editor window is open
    @Published var isEditorOpen: Bool = false

    /// ID of the currently selected card in the editor
    @Published var selectedCardId: UUID?

    // MARK: - Private Properties

    /// Cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    /// The currently displayed card, if any
    var currentCard: Card? {
        guard let deck = currentDeck,
              currentCardIndex >= 0,
              currentCardIndex < deck.cards.count else {
            return nil
        }
        return deck.cards[currentCardIndex]
    }

    /// Total number of cards in the current deck
    var totalCards: Int {
        currentDeck?.cards.count ?? 0
    }

    /// Whether navigation to the next card is possible
    var canGoNext: Bool {
        currentCardIndex < totalCards - 1
    }

    /// Whether navigation to the previous card is possible
    var canGoPrevious: Bool {
        currentCardIndex > 0
    }

    // MARK: - Initialization

    init() {
        setupAutoSave()
    }

    // MARK: - Deck Operations

    /// Loads the last opened deck and settings from disk
    func loadLastOpenedDeck() {
        // TODO: Implement with PersistenceService in Phase 3
        // For now, create a default deck if none exists
        if currentDeck == nil {
            currentDeck = Deck.createDefault()
        }
    }

    /// Creates a new empty deck
    /// - Parameter title: Title for the new deck
    func createNewDeck(title: String = "Untitled Deck") {
        let deck = Deck(title: title)
        currentDeck = deck
        currentCardIndex = 0
        selectedCardId = deck.cards.first?.id
        saveDeck()
    }

    /// Opens a deck for editing and presenting
    func openDeck(_ deck: Deck) {
        currentDeck = deck
        currentCardIndex = 0
        selectedCardId = deck.cards.first?.id
        saveSettings()
    }

    // MARK: - Card Navigation

    /// Advances to the next card
    func nextCard() {
        guard canGoNext else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            currentCardIndex += 1
            overlayScrollOffset = 0
        }
    }

    /// Goes back to the previous card
    func previousCard() {
        guard canGoPrevious else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            currentCardIndex -= 1
            overlayScrollOffset = 0
        }
    }

    /// Jumps to a specific card by index
    func goToCard(at index: Int) {
        guard index >= 0, index < totalCards else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            currentCardIndex = index
            overlayScrollOffset = 0
        }
    }

    // MARK: - Card Editing

    /// Adds a new card to the current deck
    /// - Parameter layout: Layout template for the new card
    func addCard(layout: LayoutType = .titleBullets) {
        guard var deck = currentDeck else { return }
        let card = Card(layout: layout)
        deck.addCard(card)
        currentDeck = deck
        currentCardIndex = deck.cards.count - 1
        selectedCardId = card.id
        saveDeck()
    }

    /// Updates a card in the current deck
    func updateCard(_ card: Card) {
        guard var deck = currentDeck else { return }
        deck.updateCard(card)
        currentDeck = deck
        saveDeck()
    }

    /// Deletes a card at the specified index
    func deleteCard(at index: Int) {
        guard var deck = currentDeck else { return }
        deck.removeCard(at: index)
        currentDeck = deck

        // Adjust selection
        if let selectedId = selectedCardId,
           !deck.cards.contains(where: { $0.id == selectedId }) {
            selectedCardId = deck.cards.first?.id
        }

        // Adjust current card index if needed
        if currentCardIndex >= deck.cards.count {
            currentCardIndex = max(0, deck.cards.count - 1)
        }

        saveDeck()
    }

    /// Duplicates a card at the specified index
    func duplicateCard(at index: Int) {
        guard var deck = currentDeck else { return }
        if let newCard = deck.duplicateCard(at: index) {
            currentDeck = deck
            currentCardIndex = index + 1
            selectedCardId = newCard.id
            saveDeck()
        }
    }

    /// Moves a card from one position to another
    func moveCard(from source: IndexSet, to destination: Int) {
        guard var deck = currentDeck,
              let sourceIndex = source.first else { return }
        deck.moveCard(from: sourceIndex, to: destination)
        currentDeck = deck
        saveDeck()
    }

    // MARK: - Overlay Controls

    /// Toggles overlay visibility
    func toggleOverlay() {
        isOverlayVisible.toggle()
    }

    /// Toggles click-through mode
    func toggleClickThrough() {
        isClickThroughEnabled.toggle()
        saveSettings()
    }

    /// Toggles Protected Mode
    func toggleProtectedMode() {
        isProtectedModeEnabled.toggle()
        saveSettings()
    }

    /// Increases overlay font size
    func increaseFontSize() {
        overlayFontScale = min(2.0, overlayFontScale + 0.1)
        saveSettings()
    }

    /// Decreases overlay font size
    func decreaseFontSize() {
        overlayFontScale = max(0.5, overlayFontScale - 0.1)
        saveSettings()
    }

    /// Scrolls overlay content up
    func scrollUp() {
        overlayScrollOffset = max(0, overlayScrollOffset - 50)
    }

    /// Scrolls overlay content down
    func scrollDown() {
        overlayScrollOffset += 50
    }

    /// Updates the overlay window frame
    func updateOverlayFrame(_ frame: OverlayFrame) {
        overlayFrame = frame
        saveSettings()
    }

    // MARK: - Persistence

    /// Sets up auto-save on deck changes
    private func setupAutoSave() {
        // TODO: Implement debounced auto-save in Phase 3
        // For now, saving is triggered explicitly
    }

    /// Saves the current deck to disk
    func saveDeck() {
        // TODO: Implement with PersistenceService in Phase 3
        print("Deck saved (placeholder)")
    }

    /// Saves settings to disk
    func saveSettings() {
        // TODO: Implement with PersistenceService in Phase 3
        print("Settings saved (placeholder)")
    }
}
