import AppKit
import os
import Sparkle

private let logger = Logger(subsystem: "com.tookes.Prompter", category: "Updates")

/// Manages application updates using the Sparkle framework.
///
/// Wraps SPUStandardUpdaterController to provide a simple interface
/// for checking and installing updates. The controller is only created
/// when a valid configuration is detected (prevents Sparkle from
/// touching placeholder URLs at init time).
@MainActor
final class UpdateManager {

    /// The Sparkle updater controller (nil when unconfigured)
    private var updaterController: SPUStandardUpdaterController?

    /// Whether Sparkle is configured with a valid appcast URL and public key.
    private(set) var isConfigured: Bool = false

    /// Why update checks are unavailable (used for menu tooltips/logging).
    private(set) var unavailableReason: String?

    /// Whether we've attempted to start the updater.
    private var hasStartedUpdater = false

    init() {
        validateConfiguration()
    }

    /// Starts the updater. Call after app launch is complete.
    func startUpdater() {
        guard isConfigured, let controller = updaterController else {
            logger.info("Sparkle disabled (\(self.unavailableReason ?? "not configured"))")
            return
        }
        guard !hasStartedUpdater else { return }
        controller.startUpdater()
        hasStartedUpdater = true
    }

    /// Manually checks for updates (user-initiated).
    func checkForUpdates() {
        guard isConfigured, let controller = updaterController else {
            logger.info("Check skipped (\(self.unavailableReason ?? "not configured"))")
            return
        }
        guard canCheckForUpdates else {
            logger.info("Check skipped (updater not ready)")
            return
        }
        controller.checkForUpdates(nil)
    }

    /// Whether the updater can currently check for updates.
    var canCheckForUpdates: Bool {
        updaterController?.updater.canCheckForUpdates ?? false
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

        guard let parsedURL = URL(string: feedURL), parsedURL.scheme == "https" else {
            isConfigured = false
            unavailableReason = "Update feed URL must be a valid HTTPS URL."
            return
        }

        // Only create the Sparkle controller when configuration is valid
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        isConfigured = true
        unavailableReason = nil

        // Note: When replacing placeholders with real values, also set
        // SUEnableAutomaticChecks to true in Info.plist.
    }
}
