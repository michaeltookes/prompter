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

    /// Bundle id of hunt builds. `PROMPTER_HUNT_MODE` and the
    /// `.prowl/DerivedData/` path select hunt only under this id.
    static let huntBundleIdentifier = "com.tookes.Prompter.hunt"

    /// Bundle id of QA builds; `PrompterFlavor = qa` is honored only under it.
    static let qaBundleIdentifier = "com.tookes.Prompter.qa"

    let flavor: AppFlavor

    // MARK: - Current

    /// The environment of this process.
    static let current = AppEnvironment(flavor: resolveFlavor(
        infoDictionary: Bundle.main.infoDictionary ?? [:],
        environment: ProcessInfo.processInfo.environment,
        bundlePath: Bundle.main.bundlePath,
        bundleIdentifier: Bundle.main.bundleIdentifier,
        allowsHuntModeOverride: isDebugBuild
    ))

    /// True when this process asked for qa or hunt (Info.plist, environment
    /// or path) under a bundle id that does not match, so it was resolved as
    /// production instead.
    static let ignoredFlavorRequest = isFlavorRequestIgnored(
        infoDictionary: Bundle.main.infoDictionary ?? [:],
        environment: ProcessInfo.processInfo.environment,
        bundlePath: Bundle.main.bundlePath,
        bundleIdentifier: Bundle.main.bundleIdentifier,
        allowsHuntModeOverride: isDebugBuild
    )

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
    /// or `hunt`; then the Debug-only `PROMPTER_HUNT_MODE=1` or a bundle built
    /// under `.prowl/DerivedData/`. Every non-production flavor needs its own
    /// bundle id (`qa` → `com.tookes.Prompter.qa`, `hunt` →
    /// `com.tookes.Prompter.hunt`), so the QA or hunt UI never runs under the
    /// released app's bundle id and defaults domain; any other combination
    /// resolves to `production`.
    static func resolveFlavor(
        infoDictionary: [String: Any],
        environment: [String: String],
        bundlePath: String,
        bundleIdentifier: String?,
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
            return bundleIdentifier == qaBundleIdentifier ? .qa : .production
        case AppFlavor.hunt.rawValue:
            return bundleIdentifier == huntBundleIdentifier ? .hunt : .production
        default:
            break
        }

        if bundleIdentifier == huntBundleIdentifier,
           requestsHunt(environment: environment, bundlePath: bundlePath, allowsHuntModeOverride: allowsHuntModeOverride) {
            return .hunt
        }

        return .production
    }

    /// Whether `PROMPTER_HUNT_MODE=1` (Debug only) or the `.prowl/DerivedData/`
    /// path asks for the hunt flavor.
    static func requestsHunt(
        environment: [String: String],
        bundlePath: String,
        allowsHuntModeOverride: Bool
    ) -> Bool {
        (allowsHuntModeOverride && environment[huntModeEnvironmentKey] == "1")
            || bundlePath.contains(prowlDerivedDataPathFragment)
    }

    /// True when qa or hunt was asked for (Info.plist, environment or path)
    /// but the bundle id did not match, so the launch runs as production.
    static func isFlavorRequestIgnored(
        infoDictionary: [String: Any],
        environment: [String: String],
        bundlePath: String,
        bundleIdentifier: String?,
        allowsHuntModeOverride: Bool
    ) -> Bool {
        let declared = (infoDictionary[flavorInfoKey] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let requested = declared == AppFlavor.qa.rawValue
            || declared == AppFlavor.hunt.rawValue
            || requestsHunt(environment: environment, bundlePath: bundlePath, allowsHuntModeOverride: allowsHuntModeOverride)
        let resolved = resolveFlavor(
            infoDictionary: infoDictionary,
            environment: environment,
            bundlePath: bundlePath,
            bundleIdentifier: bundleIdentifier,
            allowsHuntModeOverride: allowsHuntModeOverride
        )
        return requested && resolved == .production
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

    /// Short visible marker next to the status item icon, or nil for the release.
    var statusItemBadge: String? {
        switch flavor {
        case .qa: return "QA"
        case .hunt: return "Hunt"
        case .production, .unitTest: return nil
        }
    }

    /// Disabled first item of the status menu naming a non-release build.
    var menuBuildLabel: String? {
        switch flavor {
        case .qa: return "Prompter QA build"
        case .hunt: return "Prompter Hunt build"
        case .production, .unitTest: return nil
        }
    }

    // MARK: - Defaults identity

    /// True when this flavor runs under the released app's bundle id, so
    /// `UserDefaults.standard` is the released app's `com.tookes.Prompter`
    /// domain. Only a Debug build selected as hunt by `PROMPTER_HUNT_MODE=1` or
    /// the `.prowl/DerivedData/` path can be in that state.
    func sharesProductionDefaults(bundleIdentifier: String?) -> Bool {
        flavor != .production && bundleIdentifier == Self.productionBundleIdentifier
    }

    /// Whether the app may open SwiftUI's placeholder `WindowGroup`. Its window
    /// autosaves a frame into the standard defaults domain, so it is skipped
    /// under XCTest and whenever a non-production flavor shares the released
    /// app's domain.
    func opensWindowScene(bundleIdentifier: String?) -> Bool {
        flavor != .unitTest && !sharesProductionDefaults(bundleIdentifier: bundleIdentifier)
    }

    /// The defaults domain the hunt launch wipes, or nil when there is none it
    /// may wipe (not hunt, or the domain belongs to the released app).
    func huntDefaultsDomainToReset(bundleIdentifier: String?) -> String? {
        guard flavor == .hunt, let bundleIdentifier,
              !sharesProductionDefaults(bundleIdentifier: bundleIdentifier) else {
            return nil
        }
        return bundleIdentifier
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
