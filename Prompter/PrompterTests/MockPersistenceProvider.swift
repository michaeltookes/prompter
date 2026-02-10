import Foundation
@testable import Prompter

/// In-memory persistence provider for tests.
///
/// Stores settings and decks in memory to avoid writing to the real
/// ~/Library/Application Support/Prompter/ directory during tests.
@MainActor
final class MockPersistenceProvider: PersistenceProvider {

    var settings: Settings = .default
    var decks: [UUID: Deck] = [:]

    func loadSettings() -> Settings {
        settings.validated()
    }

    func saveSettings(_ settings: Settings) {
        self.settings = settings.validated()
    }

    func saveSettingsSync(_ settings: Settings) {
        self.settings = settings.validated()
    }

    func loadAllDecks() -> [Deck] {
        Array(decks.values)
    }

    func loadDeck(id: UUID) -> Deck? {
        decks[id]
    }

    func saveDeck(_ deck: Deck) {
        decks[deck.id] = deck
    }

    func saveDeckSync(_ deck: Deck) {
        decks[deck.id] = deck
    }

    func deleteDeck(id: UUID) {
        decks.removeValue(forKey: id)
    }
}
