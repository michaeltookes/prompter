import AppKit
import SwiftUI

/// Manages the menu bar icon and dropdown menu.
///
/// The menu bar is the primary access point for the application.
/// It provides quick access to all features without taking up dock space.
@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {

    // MARK: - Properties

    /// The status item (menu bar icon)
    private var statusItem: NSStatusItem!

    /// Reference to the app state
    private var appState: AppState

    /// Reference to the overlay window controller
    private var overlayController: OverlayWindowController

    /// The deck editor window (created lazily)
    private var editorWindow: NSWindow?

    /// The test capture window (created lazily)
    private var testCaptureWindow: NSWindow?

    /// Observer for editor window close
    private var editorCloseObserver: NSObjectProtocol?

    // MARK: - Initialization

    init(appState: AppState, overlayController: OverlayWindowController) {
        self.appState = appState
        self.overlayController = overlayController
        super.init()
        setupStatusItem()
    }

    deinit {
        if let observer = editorCloseObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Setup

    /// Creates and configures the menu bar icon
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            // Use SF Symbol for the menu bar icon
            button.image = NSImage(
                systemSymbolName: "text.bubble",
                accessibilityDescription: "Presenter Overlay"
            )
            button.image?.isTemplate = true  // Adapts to light/dark menu bar
        }

        // Build and attach the menu with delegate for dynamic refresh
        let menu = buildMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - NSMenuDelegate

    /// Called when the menu is about to be displayed - refreshes menu state
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        for item in buildMenuItems() {
            menu.addItem(item)
        }
    }

    /// Builds the dropdown menu items
    private func buildMenuItems() -> [NSMenuItem] {
        var items: [NSMenuItem] = []

        // Show/Hide Overlay
        let overlayTitle = appState.isOverlayVisible ? "Hide Overlay" : "Show Overlay"
        let overlayItem = NSMenuItem(
            title: overlayTitle,
            action: #selector(toggleOverlay),
            keyEquivalent: ""
        )
        overlayItem.target = self
        items.append(overlayItem)

        // Open Deck Editor
        let editorItem = NSMenuItem(
            title: "Open Deck Editor…",
            action: #selector(openDeckEditor),
            keyEquivalent: ""
        )
        editorItem.target = self
        items.append(editorItem)

        items.append(NSMenuItem.separator())

        // Protected Mode toggle
        let protectedItem = NSMenuItem(
            title: "Protected Mode",
            action: #selector(toggleProtectedMode),
            keyEquivalent: ""
        )
        protectedItem.target = self
        protectedItem.state = appState.isProtectedModeEnabled ? .on : .off
        items.append(protectedItem)

        // Click-through toggle
        let clickThroughItem = NSMenuItem(
            title: "Click-through Overlay",
            action: #selector(toggleClickThrough),
            keyEquivalent: ""
        )
        clickThroughItem.target = self
        clickThroughItem.state = appState.isClickThroughEnabled ? .on : .off
        items.append(clickThroughItem)

        items.append(NSMenuItem.separator())

        // Test Capture Setup
        let testItem = NSMenuItem(
            title: "Test Capture Setup…",
            action: #selector(openTestCapture),
            keyEquivalent: ""
        )
        testItem.target = self
        items.append(testItem)

        items.append(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Presenter Overlay",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        items.append(quitItem)

        return items
    }

    /// Builds the dropdown menu
    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        for item in buildMenuItems() {
            menu.addItem(item)
        }
        return menu
    }

    // MARK: - Menu Actions

    @objc private func toggleOverlay() {
        appState.toggleOverlay()
    }

    @objc private func toggleProtectedMode() {
        appState.toggleProtectedMode()
    }

    @objc private func toggleClickThrough() {
        appState.toggleClickThrough()
    }

    @objc private func openDeckEditor() {
        if editorWindow == nil {
            // Create the editor window with SwiftUI content
            let editorView = DeckEditorPlaceholderView()
                .environmentObject(appState)

            editorWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            editorWindow?.title = "Deck Editor"
            editorWindow?.contentView = NSHostingView(rootView: editorView)
            editorWindow?.center()
            editorWindow?.minSize = NSSize(width: 800, height: 500)

            // Observe window close to update app state
            editorCloseObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: editorWindow,
                queue: .main
            ) { [weak self] _ in
                self?.handleEditorWindowClose()
            }
        }

        editorWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        appState.isEditorOpen = true
    }

    /// Handles editor window close - resets state and cleans up observer
    private func handleEditorWindowClose() {
        appState.isEditorOpen = false
        editorWindow = nil
        if let observer = editorCloseObserver {
            NotificationCenter.default.removeObserver(observer)
            editorCloseObserver = nil
        }
    }

    @objc private func openTestCapture() {
        if testCaptureWindow == nil {
            // Create the test capture window with SwiftUI content
            let testView = TestCapturePlaceholderView()

            testCaptureWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            testCaptureWindow?.title = "Test Capture Setup"
            testCaptureWindow?.contentView = NSHostingView(rootView: testView)
            testCaptureWindow?.center()
        }

        testCaptureWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Placeholder Views

/// Placeholder view for the deck editor (to be replaced in Phase 2)
struct DeckEditorPlaceholderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("Deck Editor")
                .font(.title)

            Text("Coming in Phase 2")
                .foregroundColor(.secondary)

            if let deck = appState.currentDeck {
                Text("Current deck: \(deck.title)")
                Text("Cards: \(deck.cards.count)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Placeholder view for test capture instructions (to be replaced in Phase 3)
struct TestCapturePlaceholderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test Capture Setup")
                .font(.title)

            Text("To test if Protected Mode hides the overlay:")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Label("1. Open Google Meet or Microsoft Teams", systemImage: "1.circle")
                Label("2. Start a test call (you can call yourself)", systemImage: "2.circle")
                Label("3. Share your entire screen", systemImage: "3.circle")
                Label("4. Check if the overlay is visible in the shared view", systemImage: "4.circle")
            }
            .padding(.leading)

            Divider()

            Text("If the overlay IS visible:")
                .font(.headline)

            Text("Try sharing a specific window or browser tab instead of your entire screen.")
                .foregroundColor(.secondary)

            Spacer()

            Text("Note: Protected Mode is best-effort. Always test before important presentations.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
