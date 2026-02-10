import Foundation
import os

private let logger = Logger(subsystem: "com.tookes.Prompter", category: "Persistence")

/// Protocol defining persistence operations used by AppState.
///
/// Allows substituting an in-memory implementation for tests
/// so they don't write to the real disk.
@MainActor
protocol PersistenceProvider {
    func loadSettings() -> Settings
    func saveSettings(_ settings: Settings)
    func saveSettingsSync(_ settings: Settings)
    func loadAllDecks() -> [Deck]
    func loadDeck(id: UUID) -> Deck?
    func saveDeck(_ deck: Deck)
    func saveDeckSync(_ deck: Deck)
    func deleteDeck(id: UUID)
}

/// Handles all file-based persistence for the application.
///
/// Data is stored in ~/Library/Application Support/Prompter/:
/// - Decks/<deckId>.json - Individual deck files
/// - Settings.json - Application settings
///
/// This service is thread-safe and performs I/O on a background queue.
@MainActor
final class PersistenceService: PersistenceProvider {

    // MARK: - Singleton

    static let shared = PersistenceService()

    // MARK: - Properties

    /// Base directory for all app data
    private let appSupportURL: URL

    /// Directory for storing deck files
    private let decksURL: URL

    /// Path to settings file
    private let settingsURL: URL

    /// JSON encoder configured for pretty printing
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    /// JSON decoder
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Background queue for I/O operations
    private let ioQueue = DispatchQueue(label: "com.tookes.prompter.persistence", qos: .utility)

    /// Migration flag to avoid repeating legacy data migration
    private static let migrationFlagKey = "PrompterPersistenceMigratedFromPresenterOverlay"

    // MARK: - Initialization

    private init() {
        // Get Application Support directory
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportURL = appSupport.appendingPathComponent("Prompter", isDirectory: true)
        decksURL = appSupportURL.appendingPathComponent("Decks", isDirectory: true)
        settingsURL = appSupportURL.appendingPathComponent("Settings.json")

        // Create directories if needed
        try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: decksURL, withIntermediateDirectories: true)

        migrateLegacyDataIfNeeded(fileManager: fileManager, appSupport: appSupport)
    }

    private func migrateLegacyDataIfNeeded(fileManager: FileManager, appSupport: URL) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Self.migrationFlagKey) {
            return
        }

        let legacySupportURL = appSupport.appendingPathComponent("PresenterOverlay", isDirectory: true)
        let legacyDecksURL = legacySupportURL.appendingPathComponent("Decks", isDirectory: true)
        let legacySettingsURL = legacySupportURL.appendingPathComponent("Settings.json")

        let newHasSettings = fileManager.fileExists(atPath: settingsURL.path)
        let newDecksEmpty: Bool = {
            guard let files = try? fileManager.contentsOfDirectory(at: decksURL, includingPropertiesForKeys: nil) else {
                return true
            }
            return files.isEmpty
        }()

        let legacyHasSettings = fileManager.fileExists(atPath: legacySettingsURL.path)
        let legacyHasDecks = fileManager.fileExists(atPath: legacyDecksURL.path)

        guard (!newHasSettings || newDecksEmpty), (legacyHasSettings || legacyHasDecks) else {
            defaults.set(true, forKey: Self.migrationFlagKey)
            return
        }

        var migrationSucceeded = true

        if !newHasSettings && legacyHasSettings {
            do {
                try fileManager.copyItem(at: legacySettingsURL, to: settingsURL)
                logger.info("Migrated legacy settings")
            } catch {
                migrationSucceeded = false
                logger.error("Failed to migrate legacy settings: \(error.localizedDescription)")
            }
        }

        if newDecksEmpty && legacyHasDecks {
            do {
                let legacyFiles = try fileManager.contentsOfDirectory(at: legacyDecksURL, includingPropertiesForKeys: nil)
                for fileURL in legacyFiles {
                    let destinationURL = decksURL.appendingPathComponent(fileURL.lastPathComponent)
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        continue
                    }
                    do {
                        try fileManager.copyItem(at: fileURL, to: destinationURL)
                    } catch {
                        migrationSucceeded = false
                        logger.error("Failed to migrate deck \(fileURL.lastPathComponent): \(error.localizedDescription)")
                    }
                }
                logger.info("Migrated legacy decks")
            } catch {
                migrationSucceeded = false
                logger.error("Failed to read legacy decks: \(error.localizedDescription)")
            }
        }

        if migrationSucceeded {
            defaults.set(true, forKey: Self.migrationFlagKey)
        }
    }

    // MARK: - Settings

    /// Loads settings from disk
    /// - Returns: The saved settings, or default settings if none exist
    func loadSettings() -> Settings {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            logger.debug("No settings file, using defaults")
            return .default
        }

        do {
            let data = try Data(contentsOf: settingsURL)
            let settings = try decoder.decode(Settings.self, from: data)
            logger.debug("Loaded settings")
            return settings.validated()
        } catch {
            logger.error("Failed to load settings: \(error.localizedDescription)")
            return .default
        }
    }

    /// Saves settings to disk
    /// - Parameter settings: The settings to save
    func saveSettings(_ settings: Settings) {
        let validatedSettings = settings.validated()

        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }

            do {
                let data = try self.encoder.encode(validatedSettings)
                try data.write(to: self.settingsURL, options: .atomic)
                logger.debug("Saved settings")
            } catch {
                logger.error("Failed to save settings: \(error.localizedDescription)")
            }
        }
    }

    /// Saves settings synchronously (for app termination)
    func saveSettingsSync(_ settings: Settings) {
        let validatedSettings = settings.validated()

        do {
            let data = try encoder.encode(validatedSettings)
            try data.write(to: settingsURL, options: .atomic)
            logger.debug("Saved settings (sync)")
        } catch {
            logger.error("Failed to save settings: \(error.localizedDescription)")
        }
    }

    // MARK: - Decks

    /// Loads a deck from disk
    /// - Parameter id: The deck's UUID
    /// - Returns: The deck, or nil if not found
    func loadDeck(id: UUID) -> Deck? {
        let deckURL = decksURL.appendingPathComponent("\(id.uuidString).json")

        guard FileManager.default.fileExists(atPath: deckURL.path) else {
            logger.debug("Deck \(id) not found")
            return nil
        }

        do {
            let data = try Data(contentsOf: deckURL)
            let deck = try decoder.decode(Deck.self, from: data)
            logger.debug("Loaded deck '\(deck.title)'")
            return deck
        } catch {
            logger.error("Failed to load deck \(id): \(error.localizedDescription)")
            return nil
        }
    }

    /// Saves a deck to disk
    /// - Parameter deck: The deck to save
    func saveDeck(_ deck: Deck) {
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }

            let deckURL = self.decksURL.appendingPathComponent("\(deck.id.uuidString).json")

            do {
                let data = try self.encoder.encode(deck)
                try data.write(to: deckURL, options: .atomic)
                logger.debug("Saved deck '\(deck.title)'")
            } catch {
                logger.error("Failed to save deck: \(error.localizedDescription)")
            }
        }
    }

    /// Saves a deck synchronously (for app termination)
    func saveDeckSync(_ deck: Deck) {
        let deckURL = decksURL.appendingPathComponent("\(deck.id.uuidString).json")

        do {
            let data = try encoder.encode(deck)
            try data.write(to: deckURL, options: .atomic)
            logger.debug("Saved deck '\(deck.title)' (sync)")
        } catch {
            logger.error("Failed to save deck: \(error.localizedDescription)")
        }
    }

    /// Deletes a deck from disk
    /// - Parameter id: The deck's UUID
    func deleteDeck(id: UUID) {
        let deckURL = decksURL.appendingPathComponent("\(id.uuidString).json")

        do {
            try FileManager.default.removeItem(at: deckURL)
            logger.info("Deleted deck \(id)")
        } catch {
            logger.error("Failed to delete deck \(id): \(error.localizedDescription)")
        }
    }

    /// Lists all saved deck IDs
    /// - Returns: Array of deck UUIDs
    func listDeckIds() -> [UUID] {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: decksURL, includingPropertiesForKeys: nil)
            return files.compactMap { url -> UUID? in
                let filename = url.deletingPathExtension().lastPathComponent
                return UUID(uuidString: filename)
            }
        } catch {
            logger.error("Failed to list decks: \(error.localizedDescription)")
            return []
        }
    }

    /// Loads all decks from disk
    /// - Returns: Array of all saved decks
    func loadAllDecks() -> [Deck] {
        let ids = listDeckIds()
        return ids.compactMap { loadDeck(id: $0) }
    }

    /// Loads deck metadata (title, card count) without loading full deck
    /// - Returns: Array of (id, title, cardCount) tuples
    func loadDeckMetadata() -> [(id: UUID, title: String, cardCount: Int, updatedAt: Date)] {
        let decks = loadAllDecks()
        return decks.map { ($0.id, $0.title, $0.cards.count, $0.updatedAt) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - Utility

    /// Returns the total size of all data in bytes
    func totalDataSize() -> Int64 {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: appSupportURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            totalSize += Int64(size)
        }

        return totalSize
    }

    /// Clears all persisted data (for testing/reset)
    func clearAllData() {
        do {
            try FileManager.default.removeItem(at: appSupportURL)
            try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: decksURL, withIntermediateDirectories: true)
            logger.info("Cleared all data")
        } catch {
            logger.error("Failed to clear data: \(error.localizedDescription)")
        }
    }
}
