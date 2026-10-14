import AppKit
import XCTest
@testable import Prompter

// MARK: - Snapshot of the user's real data

/// A fingerprint of the released app's data: every file under
/// `~/Library/Application Support/Prompter/` (path, size, modification date)
/// and the `com.tookes.Prompter` defaults domain.
struct RealDataSnapshot: Equatable {

    static let productionRoot = StoragePaths.applicationSupportDirectory
        .appendingPathComponent("Prompter", isDirectory: true)

    let files: [String: String]
    let defaults: NSDictionary?

    static func capture() -> RealDataSnapshot {
        var files: [String: String] = [:]
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]
        if let enumerator = FileManager.default.enumerator(at: productionRoot, includingPropertiesForKeys: keys) {
            for case let url as URL in enumerator {
                let values = try? url.resourceValues(forKeys: Set(keys))
                let size = values?.fileSize ?? -1
                let modified = values?.contentModificationDate?.timeIntervalSince1970 ?? 0
                let relative = String(url.path.dropFirst(productionRoot.path.count))
                files[relative] = "\(size)@\(modified)"
            }
        }
        let domain = UserDefaults.standard.persistentDomain(forName: AppEnvironment.productionBundleIdentifier)
        return RealDataSnapshot(files: files, defaults: domain.map { NSDictionary(dictionary: $0) })
    }
}

/// Test-bundle principal class (`NSPrincipalClass` of PrompterTests).
///
/// XCTest instantiates it when the bundle loads, before any test runs, so the
/// snapshot it takes is the state of the user's data before the suite.
@objc(PrompterTestObserver)
final class PrompterTestObserver: NSObject, XCTestObservation {

    nonisolated(unsafe) static var snapshotBeforeSuite: RealDataSnapshot?

    override init() {
        super.init()
        Self.snapshotBeforeSuite = RealDataSnapshot.capture()
        XCTestObservationCenter.shared.addTestObserver(self)
    }

    func testBundleDidFinish(_ testBundle: Bundle) {
        guard let before = Self.snapshotBeforeSuite else { return }
        let changed = RealDataSnapshot.capture() != before
        print("PrompterTests storage isolation: real Application Support/Prompter and defaults "
              + (changed ? "CHANGED during the suite" : "unchanged after the suite"))
    }
}

// MARK: - Isolation tests

/// Proves the test host and the services never write the user's data (US-25 AC2, AC3).
@MainActor
final class StorageIsolationTests: XCTestCase {

    private var rootURL: URL!

    override func setUp() async throws {
        try await super.setUp()
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PrompterTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() async throws {
        if let rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
        rootURL = nil
        try await super.tearDown()
    }

    func testSharedStorageIsOutsideApplicationSupport() {
        let appSupport = StoragePaths.applicationSupportDirectory.standardizedFileURL.path
        XCTAssertFalse(StoragePaths.current.root.standardizedFileURL.path.hasPrefix(appSupport))
        XCTAssertTrue(StoragePaths.current.root.path.hasPrefix(FileManager.default.temporaryDirectory.path))
    }

    func testTestHostLaunchStoppedAfterActivationPolicy() {
        // AC3: the hosted launch set the accessory policy and returned
        XCTAssertEqual(NSApp.activationPolicy(), .accessory)
        XCTAssertFalse(AppEnvironment.current.runsFullLaunch)
    }

    func testPersistenceWritesOnlyUnderInjectedRoot() throws {
        let service = PersistenceService(rootURL: rootURL)
        let deck = Deck(title: "Isolation")
        service.saveDeckSync(deck)
        service.saveSettingsSync(.default)

        let paths = StoragePaths(root: rootURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: paths.settings.path))
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: paths.decks.appendingPathComponent("\(deck.id.uuidString).json").path
        ))
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: RealDataSnapshot.productionRoot
                .appendingPathComponent("Decks/\(deck.id.uuidString).json").path
        ))
    }

    func testAssetManagerWritesOnlyUnderInjectedRoot() throws {
        let manager = AssetManager(paths: StoragePaths(root: rootURL))
        let ref = try XCTUnwrap(manager.importImage(data: Data([0x89, 0x50, 0x4E, 0x47]), extension: "png"))

        let expected = StoragePaths(root: rootURL).assets.appendingPathComponent(ref.filename)
        XCTAssertEqual(manager.fileURL(for: ref), expected)
        XCTAssertTrue(FileManager.default.fileExists(atPath: expected.path))
    }

    func testResetAndSeedReplacesRootWithSeed() throws {
        let fileManager = FileManager.default
        let paths = StoragePaths(root: rootURL.appendingPathComponent("Prompter-Hunt", isDirectory: true))
        try fileManager.createDirectory(at: paths.decks, withIntermediateDirectories: true)
        try Data("stale".utf8).write(to: paths.decks.appendingPathComponent("stale.json"))

        let seed = rootURL.appendingPathComponent("HuntSeed", isDirectory: true)
        let seedDecks = seed.appendingPathComponent("Decks", isDirectory: true)
        try fileManager.createDirectory(at: seedDecks, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: seedDecks.appendingPathComponent("seed.json"))

        paths.resetAndSeed(from: seed)

        XCTAssertFalse(fileManager.fileExists(atPath: paths.decks.appendingPathComponent("stale.json").path))
        XCTAssertTrue(fileManager.fileExists(atPath: paths.decks.appendingPathComponent("seed.json").path))
        XCTAssertTrue(fileManager.fileExists(atPath: paths.assets.path))
    }

    func testResetWithoutSeedLeavesEmptyFolders() throws {
        let fileManager = FileManager.default
        let paths = StoragePaths(root: rootURL.appendingPathComponent("Prompter-Hunt", isDirectory: true))
        try fileManager.createDirectory(at: paths.decks, withIntermediateDirectories: true)
        try Data("stale".utf8).write(to: paths.settings)

        paths.resetAndSeed(from: nil)

        XCTAssertFalse(fileManager.fileExists(atPath: paths.settings.path))
        XCTAssertEqual(try fileManager.contentsOfDirectory(atPath: paths.decks.path), [])
    }
}

/// Runs last (XCTest orders classes by name): the user's real data must be
/// exactly as it was when the bundle loaded.
@MainActor
final class ZZRealDataUntouchedTests: XCTestCase {

    func testRealApplicationSupportAndDefaultsUnchangedBySuite() throws {
        let before = try XCTUnwrap(PrompterTestObserver.snapshotBeforeSuite, "observer did not run")
        let after = RealDataSnapshot.capture()
        XCTAssertEqual(after.files, before.files, "Files under Application Support/Prompter changed")
        XCTAssertEqual(after.defaults, before.defaults, "The com.tookes.Prompter defaults domain changed")
    }
}
