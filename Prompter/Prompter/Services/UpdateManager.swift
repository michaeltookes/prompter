import AppKit
import Sparkle

/// Manages application updates using the Sparkle framework.
///
/// Wraps SPUStandardUpdaterController to provide a simple interface
/// for checking and installing updates.
@MainActor
final class UpdateManager: ObservableObject {

    /// The Sparkle updater controller
    private let updaterController: SPUStandardUpdaterController

    /// Whether Sparkle is configured with a valid appcast URL and public key.
    private(set) var isConfigured: Bool = false

    /// Why update checks are unavailable (used for menu tooltips/logging).
    private(set) var unavailableReason: String?

    /// Whether we've attempted to start the updater.
    private var hasStartedUpdater = false

    init() {
        // Initialize with startingUpdater: false so we can start it manually
        // after the app has fully launched
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        validateConfiguration()
    }

    /// Starts the updater. Call after app launch is complete.
    func startUpdater() {
        guard isConfigured else {
            print("UpdateManager: Sparkle disabled (\(unavailableReason ?? "not configured"))")
            return
        }
        guard !hasStartedUpdater else { return }
        updaterController.startUpdater()
        hasStartedUpdater = true
    }

    /// Manually checks for updates (user-initiated).
    func checkForUpdates() {
        guard isConfigured else {
            print("UpdateManager: Check skipped (\(unavailableReason ?? "not configured"))")
            return
        }
        guard canCheckForUpdates else {
            print("UpdateManager: Check skipped (updater not ready)")
            return
        }
        updaterController.checkForUpdates(nil)
    }

    /// Whether the updater can currently check for updates.
    var canCheckForUpdates: Bool {
        isConfigured && updaterController.updater.canCheckForUpdates
    }

    // MARK: - Configuration

    private func validateConfiguration() {
        let info = Bundle.main.infoDictionary ?? [:]
        let feedURL = (info["SUFeedURL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let publicKey = (info["SUPublicEDKey"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !feedURL.isEmpty, !publicKey.isEmpty else {
            isConfigured = false
            unavailableReason = "Updates are not configured yet."
            return
        }

        if feedURL.contains("PLACEHOLDER") || publicKey.contains("PLACEHOLDER") {
            isConfigured = false
            unavailableReason = "Updates are disabled until appcast and signing key are configured."
            return
        }

        guard let parsedURL = URL(string: feedURL), parsedURL.scheme?.isEmpty == false else {
            isConfigured = false
            unavailableReason = "Update feed URL is invalid."
            return
        }

        isConfigured = true
        unavailableReason = nil
    }
}
