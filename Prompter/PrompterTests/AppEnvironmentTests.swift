import XCTest
@testable import Prompter

/// Tests for the flavor resolution table (US-25, design section 3.2).
final class AppEnvironmentTests: XCTestCase {

    private let appSupport = URL(fileURLWithPath: "/Users/tester/Library/Application Support", isDirectory: true)
    private let temp = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
    private let installedPath = "/Applications/Prompter.app"

    private func resolve(
        flavor: String? = nil,
        environment: [String: String] = [:],
        bundlePath: String? = nil,
        debug: Bool = true
    ) -> AppFlavor {
        var info: [String: Any] = [:]
        if let flavor {
            info[AppEnvironment.flavorInfoKey] = flavor
        }
        return AppEnvironment.resolveFlavor(
            infoDictionary: info,
            environment: environment,
            bundlePath: bundlePath ?? installedPath,
            allowsHuntModeOverride: debug
        )
    }

    // MARK: - Resolution

    func testDefaultIsProduction() {
        XCTAssertEqual(resolve(), .production)
        XCTAssertEqual(resolve(flavor: "production"), .production)
    }

    func testUnexpandedOrUnknownFlavorFallsBackToProduction() {
        XCTAssertEqual(resolve(flavor: ""), .production)
        XCTAssertEqual(resolve(flavor: "$(PROMPTER_FLAVOR)"), .production)
        XCTAssertEqual(resolve(flavor: "staging"), .production)
    }

    func testInfoPlistSelectsQAAndHunt() {
        XCTAssertEqual(resolve(flavor: "qa"), .qa)
        XCTAssertEqual(resolve(flavor: "hunt"), .hunt)
        XCTAssertEqual(resolve(flavor: " QA "), .qa)
    }

    func testXCTestHostResolvesToUnitTestWhateverTheFlavor() {
        let env = [AppEnvironment.xcTestEnvironmentKey: "/tmp/config.xctestconfiguration"]
        XCTAssertEqual(resolve(environment: env), .unitTest)
        XCTAssertEqual(resolve(flavor: "qa", environment: env), .unitTest)
        XCTAssertEqual(resolve(flavor: "hunt", environment: env, debug: false), .unitTest)
    }

    func testHuntModeEnvironmentSelectsHuntInDebugOnly() {
        let env = [AppEnvironment.huntModeEnvironmentKey: "1"]
        XCTAssertEqual(resolve(environment: env, debug: true), .hunt)
        // AC5: a Release build ignores PROMPTER_HUNT_MODE
        XCTAssertEqual(resolve(environment: env, debug: false), .production)
        XCTAssertEqual(resolve(environment: [AppEnvironment.huntModeEnvironmentKey: "0"]), .production)
    }

    func testProwlDerivedDataBundleIsHunt() {
        let path = "/Users/runner/work/prompter/.prowl/DerivedData/Build/Products/Debug/Prompter.app"
        XCTAssertEqual(resolve(bundlePath: path), .hunt)
        XCTAssertEqual(resolve(bundlePath: path, debug: false), .hunt)
    }

    func testQAFlavorIsNotOverriddenByHuntMode() {
        let env = [AppEnvironment.huntModeEnvironmentKey: "1"]
        XCTAssertEqual(resolve(flavor: "qa", environment: env), .qa)
    }

    // MARK: - Table

    func testDataRootPerFlavor() {
        let expected: [AppFlavor: String] = [
            .production: "/Users/tester/Library/Application Support/Prompter",
            .qa: "/Users/tester/Library/Application Support/Prompter-QA",
            .hunt: "/Users/tester/Library/Application Support/Prompter-Hunt"
        ]
        for (flavor, path) in expected {
            let paths = AppEnvironment(flavor: flavor).storagePaths(applicationSupport: appSupport, temporaryDirectory: temp)
            XCTAssertEqual(paths.root.path, path, "\(flavor)")
        }
    }

    func testUnitTestFlavorNeverUsesApplicationSupport() {
        let env = AppEnvironment(flavor: .unitTest)
        XCTAssertNil(env.dataFolderName)
        let paths = env.storagePaths(applicationSupport: appSupport, temporaryDirectory: temp)
        XCTAssertTrue(paths.root.path.hasPrefix(temp.path))
        XCTAssertFalse(paths.root.path.hasPrefix(appSupport.path))
    }

    func testCapabilitiesPerFlavor() {
        let production = AppEnvironment(flavor: .production)
        let qa = AppEnvironment(flavor: .qa)
        let hunt = AppEnvironment(flavor: .hunt)
        let unitTest = AppEnvironment(flavor: .unitTest)

        XCTAssertEqual([production, qa, hunt, unitTest].map(\.runsFullLaunch), [true, true, true, false])
        XCTAssertEqual([production, qa, hunt, unitTest].map(\.startsUpdater), [true, false, false, false])
        XCTAssertEqual([production, qa, hunt, unitTest].map(\.installsEventTap), [true, true, false, false])
        XCTAssertEqual([production, qa, hunt, unitTest].map(\.migratesLegacyData), [true, false, false, false])
        XCTAssertEqual([production, qa, hunt, unitTest].map(\.resetsDataOnLaunch), [false, false, true, false])
    }

    func testStatusItemLabelNamesFlavor() {
        XCTAssertEqual(AppEnvironment(flavor: .production).statusItemLabel, "Prompter")
        XCTAssertEqual(AppEnvironment(flavor: .qa).statusItemLabel, "Prompter QA")
        XCTAssertEqual(AppEnvironment(flavor: .hunt).statusItemLabel, "Prompter Hunt")
    }

    func testStoragePathsLayout() {
        let paths = StoragePaths(root: URL(fileURLWithPath: "/data/Prompter", isDirectory: true))
        XCTAssertEqual(paths.decks.path, "/data/Prompter/Decks")
        XCTAssertEqual(paths.decksUnreadable.path, "/data/Prompter/Decks/Unreadable")
        XCTAssertEqual(paths.assets.path, "/data/Prompter/Assets")
        XCTAssertEqual(paths.assetsTrash.path, "/data/Prompter/Assets/.Trash")
        XCTAssertEqual(paths.settings.path, "/data/Prompter/Settings.json")
    }

    // MARK: - Defaults identity

    func testHuntUnderProductionBundleIdWritesNothingToProductionDomain() {
        // A Debug build of com.tookes.Prompter selected as hunt by
        // PROMPTER_HUNT_MODE=1 or the .prowl/DerivedData path
        let viaEnv = resolve(environment: [AppEnvironment.huntModeEnvironmentKey: "1"], debug: true)
        let viaPath = resolve(bundlePath: "/r/.prowl/DerivedData/Build/Products/Debug/Prompter.app")
        let productionId = AppEnvironment.productionBundleIdentifier

        for flavor in [viaEnv, viaPath] {
            XCTAssertEqual(flavor, .hunt)
            let env = AppEnvironment(flavor: flavor)
            XCTAssertTrue(env.sharesProductionDefaults(bundleIdentifier: productionId))
            // No placeholder window, so no frame autosave into com.tookes.Prompter
            XCTAssertFalse(env.opensWindowScene(bundleIdentifier: productionId))
            // The released app's domain is never wiped
            XCTAssertNil(env.huntDefaultsDomainToReset(bundleIdentifier: productionId))
            // No other defaults writer runs: event tap (prompt timestamp),
            // Sparkle, and the legacy migration flag are all off
            XCTAssertFalse(env.installsEventTap)
            XCTAssertFalse(env.startsUpdater)
            XCTAssertFalse(env.migratesLegacyData)
        }
    }

    func testWindowSceneAndDefaultsResetPerBundleId() {
        let huntId = "com.tookes.Prompter.hunt"
        let productionId = AppEnvironment.productionBundleIdentifier

        XCTAssertTrue(AppEnvironment(flavor: .production).opensWindowScene(bundleIdentifier: productionId))
        XCTAssertFalse(AppEnvironment(flavor: .production).sharesProductionDefaults(bundleIdentifier: productionId))
        XCTAssertTrue(AppEnvironment(flavor: .qa).opensWindowScene(bundleIdentifier: "com.tookes.Prompter.qa"))
        XCTAssertTrue(AppEnvironment(flavor: .hunt).opensWindowScene(bundleIdentifier: huntId))
        XCTAssertFalse(AppEnvironment(flavor: .unitTest).opensWindowScene(bundleIdentifier: productionId))

        XCTAssertEqual(AppEnvironment(flavor: .hunt).huntDefaultsDomainToReset(bundleIdentifier: huntId), huntId)
        XCTAssertNil(AppEnvironment(flavor: .hunt).huntDefaultsDomainToReset(bundleIdentifier: nil))
        XCTAssertNil(AppEnvironment(flavor: .qa).huntDefaultsDomainToReset(bundleIdentifier: "com.tookes.Prompter.qa"))
        XCTAssertNil(AppEnvironment(flavor: .production).huntDefaultsDomainToReset(bundleIdentifier: productionId))
    }

    // MARK: - This process

    func testTestHostRunsAsUnitTestFlavor() {
        XCTAssertEqual(AppEnvironment.current.flavor, .unitTest)
    }

    @MainActor
    func testUpdaterIsNotConfiguredWhenDisabled() {
        let manager = UpdateManager(enabled: false)
        XCTAssertFalse(manager.isConfigured)
        XCTAssertFalse(manager.canCheckForUpdates)
        XCTAssertNotNil(manager.unavailableReason)
    }
}
