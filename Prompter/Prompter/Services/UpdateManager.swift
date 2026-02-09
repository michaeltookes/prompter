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

    init() {
        // Initialize with startingUpdater: false so we can start it manually
        // after the app has fully launched
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    /// Starts the updater. Call after app launch is complete.
    func startUpdater() {
        updaterController.startUpdater()
    }

    /// Manually checks for updates (user-initiated).
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    /// Whether the updater can currently check for updates.
    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }
}
