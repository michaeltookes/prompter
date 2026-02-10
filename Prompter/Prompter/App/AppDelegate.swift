import AppKit
import os
import SwiftUI

private let logger = Logger(subsystem: "com.tookes.Prompter", category: "AppDelegate")

/// AppDelegate manages the application lifecycle and coordinates all major components.
///
/// Responsibilities:
/// - Initialize the menu bar controller
/// - Set up the overlay window controller
/// - Register global hotkeys
/// - Load persisted data on launch
/// - Save data on termination
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    /// Central state container for the application
    private var appState: AppState!

    /// Manages the menu bar icon and dropdown menu
    private var menuBarController: MenuBarController!

    /// Manages the floating overlay window
    private var overlayWindowController: OverlayWindowController!

    /// Handles global keyboard shortcuts
    private var hotkeyManager: HotkeyManager!

    /// Manages application updates via Sparkle
    private var updateManager: UpdateManager!

    /// Pending retry task for hotkey registration
    private var hotkeyRetryWorkItem: DispatchWorkItem?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - this is a menu bar only app
        // LSUIElement in Info.plist handles this, but we ensure it here
        NSApp.setActivationPolicy(.accessory)

        // Initialize the central state container
        appState = AppState()

        // Initialize the overlay window controller
        overlayWindowController = OverlayWindowController(appState: appState)

        // Initialize the update manager
        updateManager = UpdateManager()

        // Initialize the menu bar
        menuBarController = MenuBarController(
            appState: appState,
            overlayController: overlayWindowController,
            updateManager: updateManager
        )

        // Set up global hotkeys
        hotkeyManager = HotkeyManager.shared
        hotkeyManager.bindToAppState(appState)
        hotkeyManager.registerAllHotkeys(promptIfNeeded: true)
        scheduleHotkeyRegistrationRetryIfNeeded()

        // Load persisted data (deck, settings)
        appState.loadLastOpenedDeck()

        // Create the overlay window (hidden initially)
        overlayWindowController.createWindow()

        // Start the Sparkle updater
        updateManager.startUpdater()

        logger.info("Prompter launched successfully")
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyRetryWorkItem?.cancel()
        hotkeyRetryWorkItem = nil

        // Save settings and current deck synchronously before quitting
        appState.saveDeckSync()
        appState.saveSettingsSync()
        hotkeyManager.unregisterAllHotkeys()

        logger.info("Prompter terminating")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - Hotkey Retry

    /// Retries hotkey registration silently while the user grants permissions.
    private func scheduleHotkeyRegistrationRetryIfNeeded(
        maxAttempts: Int = 12,
        interval: TimeInterval = 5,
        attempt: Int = 1
    ) {
        guard !hotkeyManager.isRegistered, attempt <= maxAttempts else { return }

        hotkeyRetryWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.hotkeyManager.isRegistered else { return }
            self.hotkeyManager.registerAllHotkeys(promptIfNeeded: false)
            self.scheduleHotkeyRegistrationRetryIfNeeded(
                maxAttempts: maxAttempts,
                interval: interval,
                attempt: attempt + 1
            )
        }
        hotkeyRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: workItem)
    }
}
