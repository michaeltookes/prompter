import XCTest
@testable import Prompter

/// Tests for the flavor resolution table (US-25, design section 3.2).
final class AppEnvironmentTests: XCTestCase {

    private let appSupport = URL(fileURLWithPath: "/Users/tester/Library/Application Support", isDirectory: true)
    private let temp = URL(fileURLWithPath: "/private/tmp", isDirectory: true)
    private let installedPath = "/Applications/Prompter.app"
    private let derivedDataPath = "/Users/runner/work/prompter/.prowl/DerivedData/Build/Products/Debug/Prompter.app"
    private let productionId = AppEnvironment.productionBundleIdentifier
    private let huntId = AppEnvironment.huntBundleIdentifier
    private let qaId = AppEnvironment.qaBundleIdentifier

    private func resolve(
        flavor: String? = nil,
        environment: [String: String] = [:],
        bundlePath: String? = nil,
        bundleId: String? = AppEnvironment.productionBundleIdentifier,
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
            bundleIdentifier: bundleId,
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
        XCTAssertEqual(resolve(flavor: "qa", bundleId: qaId), .qa)
        XCTAssertEqual(resolve(flavor: "hunt", bundleId: huntId), .hunt)
        XCTAssertEqual(resolve(flavor: " QA ", bundleId: qaId), .qa)
    }

    func testXCTestHostResolvesToUnitTestWhateverTheFlavor() {
        let env = [AppEnvironment.xcTestEnvironmentKey: "/tmp/config.xctestconfiguration"]
        XCTAssertEqual(resolve(environment: env), .unitTest)
        XCTAssertEqual(resolve(flavor: "qa", environment: env), .unitTest)
        XCTAssertEqual(resolve(flavor: "hunt", environment: env, debug: false), .unitTest)
    }

    func testHuntModeEnvironmentSelectsHuntInDebugOnlyUnderHuntBundleId() {
        let env = [AppEnvironment.huntModeEnvironmentKey: "1"]
        XCTAssertEqual(resolve(environment: env, bundleId: huntId, debug: true), .hunt)
        // AC5: a Release build ignores PROMPTER_HUNT_MODE
        XCTAssertEqual(resolve(environment: env, bundleId: huntId, debug: false), .production)
        XCTAssertEqual(resolve(environment: [AppEnvironment.huntModeEnvironmentKey: "0"], bundleId: huntId), .production)
    }

    func testProwlDerivedDataBundleIsHuntUnderHuntBundleId() {
        XCTAssertEqual(resolve(bundlePath: derivedDataPath, bundleId: huntId), .hunt)
        XCTAssertEqual(resolve(bundlePath: derivedDataPath, bundleId: huntId, debug: false), .hunt)
    }

    func testHuntRequestUnderOtherBundleIdRunsAsProduction() {
        // The hunt UI never runs under the released app's bundle id (and its
        // defaults domain): env or path requests fall back to production
        let env = [AppEnvironment.huntModeEnvironmentKey: "1"]
        for bundleId in [productionId, "com.example.other", nil] {
            XCTAssertEqual(resolve(environment: env, bundleId: bundleId), .production)
            XCTAssertEqual(resolve(bundlePath: derivedDataPath, bundleId: bundleId), .production)
            XCTAssertTrue(ignored(environment: env, bundleId: bundleId))
            XCTAssertTrue(ignored(bundlePath: derivedDataPath, bundleId: bundleId, debug: false))
        }
    }

    func testHuntRequestIgnoredOnlyWhenRequestedAndNotHuntId() {
        let env = [AppEnvironment.huntModeEnvironmentKey: "1"]
        XCTAssertFalse(ignored(environment: env, bundleId: huntId))
        XCTAssertFalse(ignored(bundleId: productionId))
        // Release builds never honor the variable, so there is nothing to ignore
        XCTAssertFalse(ignored(environment: env, bundleId: productionId, debug: false))
        // The test host is unitTest regardless
        var hosted = env
        hosted[AppEnvironment.xcTestEnvironmentKey] = "/tmp/config.xctestconfiguration"
        XCTAssertFalse(ignored(flavor: "qa", environment: hosted, bundleId: productionId))
    }

    func testDeclaredFlavorUnderWrongBundleIdRunsAsProduction() {
        // A build with only PROMPTER_FLAVOR=qa/hunt keeps com.tookes.Prompter:
        // it must not run QA or hunt startup in the released app's defaults
        for bundleId in [productionId, "com.example.other", nil] {
            XCTAssertEqual(resolve(flavor: "qa", bundleId: bundleId), .production)
            XCTAssertEqual(resolve(flavor: "hunt", bundleId: bundleId), .production)
            XCTAssertTrue(ignored(flavor: "qa", bundleId: bundleId))
            XCTAssertTrue(ignored(flavor: "hunt", bundleId: bundleId))
        }
        // Crossed ids are refused too
        XCTAssertEqual(resolve(flavor: "qa", bundleId: huntId), .production)
        XCTAssertEqual(resolve(flavor: "hunt", bundleId: qaId), .production)
        XCTAssertTrue(ignored(flavor: "qa", bundleId: huntId))
        // Matching ids are honored and not reported
        XCTAssertFalse(ignored(flavor: "qa", bundleId: qaId))
        XCTAssertFalse(ignored(flavor: "hunt", bundleId: huntId))
        XCTAssertFalse(ignored(flavor: "production", bundleId: productionId))
    }

    private func ignored(
        flavor: String? = nil,
        environment: [String: String] = [:],
        bundlePath: String? = nil,
        bundleId: String?,
        debug: Bool = true
    ) -> Bool {
        var info: [String: Any] = [:]
        if let flavor {
            info[AppEnvironment.flavorInfoKey] = flavor
        }
        return AppEnvironment.isFlavorRequestIgnored(
            infoDictionary: info,
            environment: environment,
            bundlePath: bundlePath ?? installedPath,
            bundleIdentifier: bundleId,
            allowsHuntModeOverride: debug
        )
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

    func testVisibleFlavorMarkers() {
        XCTAssertNil(AppEnvironment(flavor: .production).statusItemBadge)
        XCTAssertEqual(AppEnvironment(flavor: .qa).statusItemBadge, "QA")
        XCTAssertEqual(AppEnvironment(flavor: .hunt).statusItemBadge, "Hunt")
        XCTAssertNil(AppEnvironment(flavor: .production).menuBuildLabel)
        XCTAssertEqual(AppEnvironment(flavor: .qa).menuBuildLabel, "Prompter QA build")
        XCTAssertEqual(AppEnvironment(flavor: .hunt).menuBuildLabel, "Prompter Hunt build")
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

    func testDeclaredHuntUnderProductionBundleIdWritesNothingToProductionDomain() {
        // Safety net: a build declaring PrompterFlavor=hunt without the hunt
        // bundle id shares the released app's defaults domain
        // (resolution already refuses it; the capabilities stay safe anyway)
        XCTAssertEqual(resolve(flavor: "hunt", bundleId: productionId), .production)
        let env = AppEnvironment(flavor: .hunt)
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

    func testWindowSceneAndDefaultsResetPerBundleId() {

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
