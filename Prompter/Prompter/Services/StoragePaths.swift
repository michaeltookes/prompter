import Foundation
import os

private let logger = Logger(subsystem: "com.tookes.Prompter", category: "StoragePaths")

/// Where one flavor of the app keeps its data.
///
/// Layout under `root`:
/// - `Decks/<uuid>.json`
/// - `Decks/Unreadable/` (quarantine for files that fail to decode)
/// - `Assets/<uuid>.<ext>`
/// - `Assets/.Trash/`
/// - `Settings.json`
///
/// `PersistenceService` and `AssetManager` take a `StoragePaths` in their
/// initializers; tests build one on a temporary directory.
struct StoragePaths: Equatable, Sendable {

    /// Base directory of all data for this flavor.
    let root: URL

    init(root: URL) {
        self.root = root
    }

    var decks: URL { root.appendingPathComponent("Decks", isDirectory: true) }
    var decksUnreadable: URL { decks.appendingPathComponent("Unreadable", isDirectory: true) }
    var assets: URL { root.appendingPathComponent("Assets", isDirectory: true) }
    var assetsTrash: URL { assets.appendingPathComponent(".Trash", isDirectory: true) }
    var settings: URL { root.appendingPathComponent("Settings.json") }

    // MARK: - Current

    /// The user's Application Support folder.
    static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    /// Storage of the running flavor (`AppEnvironment.current`).
    static let current = AppEnvironment.current.storagePaths(applicationSupport: applicationSupportDirectory)

    // MARK: - Hunt reset

    /// Deletes the data root and re-seeds it from `seed`.
    ///
    /// Used by the hunt flavor on every launch. The seed folder mirrors the
    /// storage layout (`Decks/`, `Assets/`, optional `Settings.json`); when it
    /// is missing the root is left as empty folders.
    func resetAndSeed(from seed: URL?, fileManager: FileManager = .default) {
        if fileManager.fileExists(atPath: root.path) {
            do {
                try fileManager.removeItem(at: root)
            } catch {
                logger.error("Failed to wipe data root: \(error.localizedDescription)")
            }
        }

        if let seed, fileManager.fileExists(atPath: seed.path) {
            do {
                try fileManager.createDirectory(
                    at: root.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try fileManager.copyItem(at: seed, to: root)
                logger.info("Seeded data root from bundled hunt seed")
            } catch {
                logger.error("Failed to seed data root: \(error.localizedDescription)")
            }
        }

        try? fileManager.createDirectory(at: decks, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: assets, withIntermediateDirectories: true)
    }
}
