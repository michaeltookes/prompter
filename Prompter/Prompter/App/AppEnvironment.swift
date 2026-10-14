import Foundation

/// The build flavor the running process belongs to.
///
/// Each flavor keeps its own data so that tests, PR hunts and QA builds can
/// never touch a presenter's decks or settings (design section 3.2).
enum AppFlavor: String, CaseIterable, Sendable {
    /// The released app. Data in `Application Support/Prompter/`.
    case production
    /// Pre-PR QA build (`com.tookes.Prompter.qa`). Data in `Prompter-QA/`, no Sparkle.
    case qa
    /// Prowl hunt build (`com.tookes.Prompter.hunt`). Data in `Prompter-Hunt/`,
    /// wiped and re-seeded on every launch, no event tap, no Sparkle.
    case hunt
    /// The app is hosting the unit tests. Launch stops right after the
    /// activation policy is set; nothing touches the user's data.
    case unitTest
}

/// Launch-time environment: which flavor is running and what it is allowed to do.
///
/// Resolved once, before anything touches disk. The resolution itself is a
/// pure function of its inputs so the table can be unit tested.
struct AppEnvironment: Equatable, Sendable {

    /// `Info.plist` key carrying `$(PROMPTER_FLAVOR)`.
    static let flavorInfoKey = "PrompterFlavor"

    /// Environment variable that selects the hunt flavor in Debug builds only.
    static let huntModeEnvironmentKey = "PROMPTER_HUNT_MODE"

    /// Set by XCTest in every hosted test process.
    static let xcTestEnvironmentKey = "XCTestConfigurationFilePath"

    /// Bundle path fragment of Prowl's hunt builds (ContainerBar parity).
    static let prowlDerivedDataPathFragment = "/.prowl/DerivedData/"

    /// Bundle id of the released app; its defaults domain is never wiped.
    static let productionBundleIdentifier = "com.tookes.Prompter"

    let flavor: AppFlavor

    // MARK: - Current

    /// The environment of this process.
    static let current = AppEnvironment(flavor: resolveFlavor(
        infoDictionary: Bundle.main.infoDictionary ?? [:],
        environment: ProcessInfo.processInfo.environment,
        bundlePath: Bundle.main.bundlePath,
        allowsHuntModeOverride: isDebugBuild
    ))

    /// True when compiled with the DEBUG condition. `PROMPTER_HUNT_MODE` is
    /// honored only then, so no environment variable can redirect a released
    /// app's data.
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - Resolution

    /// Resolves the flavor from the process's inputs.
    ///
    /// Order: hosted unit tests win; then an explicit `PrompterFlavor` of `qa`
    /// or `hunt`; then the Debug-only `PROMPTER_HUNT_MODE=1`; then a bundle
    /// built under `.prowl/DerivedData/`; otherwise `production`.
    static func resolveFlavor(
        infoDictionary: [String: Any],
        environment: [String: String],
        bundlePath: String,
        allowsHuntModeOverride: Bool
    ) -> AppFlavor {
        if environment[xcTestEnvironmentKey] != nil {
            return .unitTest
        }

        let declared = (infoDictionary[flavorInfoKey] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch declared {
        case AppFlavor.qa.rawValue:
            return .qa
        case AppFlavor.hunt.rawValue:
            return .hunt
        default:
            break
        }

        if allowsHuntModeOverride, environment[huntModeEnvironmentKey] == "1" {
            return .hunt
        }

        if bundlePath.contains(prowlDerivedDataPathFragment) {
            return .hunt
        }

        return .production
    }

    // MARK: - Capabilities

    /// Folder name under `~/Library/Application Support/`, or nil when the
    /// flavor must not touch the user's Application Support at all.
    var dataFolderName: String? {
        switch flavor {
        case .production: return "Prompter"
        case .qa: return "Prompter-QA"
        case .hunt: return "Prompter-Hunt"
        case .unitTest: return nil
        }
    }

    /// Whether launch continues past the activation policy.
    var runsFullLaunch: Bool { flavor != .unitTest }

    /// Whether the Sparkle updater may be created and started.
    var startsUpdater: Bool { flavor == .production }

    /// Whether the global hotkey event tap is installed.
    var installsEventTap: Bool { flavor == .production || flavor == .qa }

    /// Whether the legacy `PresenterOverlay` data migration may run.
    var migratesLegacyData: Bool { flavor == .production }

    /// Whether the data root is deleted and re-seeded on every launch.
    var resetsDataOnLaunch: Bool { flavor == .hunt }

    /// Accessibility label of the status item, naming non-release flavors so a
    /// screenshot can never be mistaken for the release.
    var statusItemLabel: String {
        switch flavor {
        case .production, .unitTest: return "Prompter"
        case .qa: return "Prompter QA"
        case .hunt: return "Prompter Hunt"
        }
    }

    // MARK: - Storage

    /// Storage paths for this flavor.
    ///
    /// - Parameters:
    ///   - applicationSupport: The user's Application Support folder.
    ///   - temporaryDirectory: Used by `unitTest`, which gets a per-process
    ///     scratch root so a stray `shared` access can never reach the user's data.
    func storagePaths(
        applicationSupport: URL,
        temporaryDirectory: URL = FileManager.default.temporaryDirectory
    ) -> StoragePaths {
        guard let folder = dataFolderName else {
            let scratch = "PrompterTests-shared-\(ProcessInfo.processInfo.processIdentifier)"
            return StoragePaths(root: temporaryDirectory.appendingPathComponent(scratch, isDirectory: true))
        }
        return StoragePaths(root: applicationSupport.appendingPathComponent(folder, isDirectory: true))
    }
}
