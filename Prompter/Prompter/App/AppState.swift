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

    // MARK: - Constants

    /// Maximum number of decks allowed
    static let maxDecks = 10

    // MARK: - Deck State

    /// The currently open deck
    @Published var currentDeck: Deck?

    /// Index of the currently displayed card in the overlay
    @Published var currentCardIndex: Int = 0

    /// All available decks
    @Published var decks: [Deck] = []

    /// Whether the maximum deck limit has been reached
    var canCreateNewDeck: Bool {
        decks.count < Self.maxDecks
    }

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

    /// Debouncer for auto-saving deck changes
    private let deckDebouncer = Debouncer(delay: 1.0)

    /// Debouncer for auto-saving settings changes
    private let settingsDebouncer = Debouncer(delay: 0.5)

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
        loadSettings()
        setupAutoSave()
    }

    /// Loads settings from persistence
    private func loadSettings() {
        let settings = PersistenceService.shared.loadSettings()
        overlayOpacity = settings.overlayOpacity
        overlayFontScale = settings.overlayFontScale
        overlayFrame = settings.overlayFrame
        isClickThroughEnabled = settings.clickThroughEnabled
        isProtectedModeEnabled = settings.protectedModeEnabled
    }

    // MARK: - Deck Operations

    /// Loads all decks and the last opened deck from disk
    func loadLastOpenedDeck() {
        // Load all decks
        decks = PersistenceService.shared.loadAllDecks()
            .sorted { $0.updatedAt > $1.updatedAt }

        let settings = PersistenceService.shared.loadSettings()

        // Try to load the last opened deck
        if let lastDeckId = settings.lastOpenedDeckId,
           let deck = decks.first(where: { $0.id == lastDeckId }) {
            currentDeck = deck
            currentCardIndex = 0
            selectedCardId = deck.cards.first?.id
            print("AppState: Loaded last opened deck '\(deck.title)'")
            return
        }

        // Try to use the first existing deck
        if let firstDeck = decks.first {
            currentDeck = firstDeck
            currentCardIndex = 0
            selectedCardId = firstDeck.cards.first?.id
            print("AppState: Loaded existing deck '\(firstDeck.title)'")
            return
        }

        // Create a default deck if none exists
        let defaultDeck = Deck.createDefault()
        currentDeck = defaultDeck
        decks = [defaultDeck]
        currentCardIndex = 0
        selectedCardId = defaultDeck.cards.first?.id
        PersistenceService.shared.saveDeck(defaultDeck)
        print("AppState: Created default deck")
    }

    /// Reloads the deck list from persistence
    func reloadDecks() {
        decks = PersistenceService.shared.loadAllDecks()
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    /// Creates a new empty deck
    /// - Parameter title: Title for the new deck
    /// - Returns: True if deck was created, false if limit reached
    @discardableResult
    func createNewDeck(title: String = "Untitled Deck") -> Bool {
        guard canCreateNewDeck else {
            print("AppState: Cannot create deck - limit of \(Self.maxDecks) reached")
            return false
        }

        let deck = Deck(title: title, cards: [
            Card(layout: .titleBullets, title: "New Card", bullets: ["Your first bullet point"])
        ])
        currentDeck = deck
        decks.insert(deck, at: 0)
        currentCardIndex = 0
        selectedCardId = deck.cards.first?.id
        overlayScrollOffset = .zero
        saveDeck()
        return true
    }

    /// Switches to a different deck
    func switchToDeck(_ deck: Deck) {
        currentDeck = deck
        currentCardIndex = 0
        selectedCardId = deck.cards.first?.id
        overlayScrollOffset = 0
        saveSettings()
    }

    /// Deletes a deck
    func deleteDeck(_ deck: Deck) {
        // Remove from list
        decks.removeAll { $0.id == deck.id }

        // Delete from persistence
        PersistenceService.shared.deleteDeck(id: deck.id)

        // If we deleted the current deck, switch to another
        if currentDeck?.id == deck.id {
            if let firstDeck = decks.first {
                switchToDeck(firstDeck)
            } else {
                // Create a new default deck if none left
                createNewDeck(title: "My Deck")
            }
        }
    }

    /// Opens a deck for editing and presenting
    func openDeck(_ deck: Deck) {
        currentDeck = deck
        currentCardIndex = 0
        selectedCardId = deck.cards.first?.id
        saveSettings()
    }

    /// Loads a deck (alias for openDeck for compatibility)
    func loadDeck(_ deck: Deck) {
        openDeck(deck)
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

    /// Navigates to a specific card (alias for goToCard)
    func navigateToCard(_ index: Int) {
        goToCard(at: index)
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

    /// Adds an existing card to the current deck
    func addCard(_ card: Card) {
        guard var deck = currentDeck else { return }
        deck.addCard(card)
        currentDeck = deck
        currentCardIndex = deck.cards.count - 1
        selectedCardId = card.id
        saveDeck()
    }

    /// Inserts a card at a specific index
    func insertCard(_ card: Card, at index: Int) {
        guard var deck = currentDeck else { return }

        // Clamp index to valid range
        let safeIndex = max(0, min(index, deck.cards.count))
        deck.insertCard(card, at: safeIndex)
        deck.updatedAt = Date()

        currentDeck = deck
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

    /// Updates a card at a specific index
    func updateCard(_ card: Card, at index: Int) {
        guard var deck = currentDeck,
              index >= 0 && index < deck.cards.count else { return }

        // Update the card with proper timestamp via Deck's API
        var updatedCard = card
        updatedCard.updatedAt = Date()
        deck.cards[index] = updatedCard
        deck.updatedAt = Date()

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

    /// Moves a card from one position to another (IndexSet version)
    func moveCard(from source: IndexSet, to destination: Int) {
        guard var deck = currentDeck,
              let sourceIndex = source.first else { return }
        deck.moveCard(from: sourceIndex, to: destination)
        currentDeck = deck
        saveDeck()
    }

    /// Moves a card from one index to another (Int version)
    func moveCard(from sourceIndex: Int, to destinationIndex: Int) {
        guard var deck = currentDeck,
              sourceIndex >= 0 && sourceIndex < deck.cards.count,
              destinationIndex >= 0 && destinationIndex <= deck.cards.count else { return }

        var cards = deck.cards
        let card = cards.remove(at: sourceIndex)

        // Adjust destination after removal to account for index shift
        let adjustedDestination: Int
        if destinationIndex > sourceIndex {
            adjustedDestination = destinationIndex - 1
        } else {
            adjustedDestination = destinationIndex
        }

        // Clamp to valid range (0...cards.count allows appending)
        let finalDestination = max(0, min(adjustedDestination, cards.count))
        cards.insert(card, at: finalDestination)

        deck.cards = cards
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

    /// Increases overlay opacity (more opaque)
    func increaseOpacity() {
        overlayOpacity = min(1.0, overlayOpacity + 0.1)
        saveSettings()
    }

    /// Decreases overlay opacity (more transparent)
    func decreaseOpacity() {
        overlayOpacity = max(0.3, overlayOpacity - 0.1)
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

    /// Sets up auto-save on settings changes
    private func setupAutoSave() {
        // Auto-save settings when overlay properties change
        $overlayOpacity
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $overlayFontScale
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $overlayFrame
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $isClickThroughEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $isProtectedModeEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        // Auto-save when current deck changes
        $currentDeck
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)
    }

    /// Saves the current deck to disk (debounced)
    func saveDeck() {
        guard let deck = currentDeck else { return }

        // Update the deck in the decks array
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            decks[index] = deck
        }

        deckDebouncer.debounce { [weak self] in
            guard self != nil else { return }
            PersistenceService.shared.saveDeck(deck)
        }
    }

    /// Saves the current deck immediately (for app termination)
    func saveDeckSync() {
        guard let deck = currentDeck else { return }
        deckDebouncer.cancel()
        PersistenceService.shared.saveDeckSync(deck)
    }

    /// Saves settings to disk (debounced)
    func saveSettings() {
        let settings = buildSettings()

        settingsDebouncer.debounce { [weak self] in
            guard self != nil else { return }
            PersistenceService.shared.saveSettings(settings)
        }
    }

    /// Saves settings immediately (for app termination)
    func saveSettingsSync() {
        let settings = buildSettings()
        settingsDebouncer.cancel()
        PersistenceService.shared.saveSettingsSync(settings)
    }

    /// Builds a Settings object from current state
    private func buildSettings() -> Settings {
        Settings(
            overlayOpacity: overlayOpacity,
            overlayFontScale: overlayFontScale,
            overlayFrame: overlayFrame,
            clickThroughEnabled: isClickThroughEnabled,
            protectedModeEnabled: isProtectedModeEnabled,
            lastOpenedDeckId: currentDeck?.id
        )
    }
}
