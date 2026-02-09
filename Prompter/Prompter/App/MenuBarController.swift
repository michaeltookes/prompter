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

    /// Observer for test capture window close
    private var testCaptureWindowObserver: NSObjectProtocol?

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
        if let observer = testCaptureWindowObserver {
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

        // Presentation Timer submenu
        items.append(buildTimerSubmenuItem())

        items.append(NSMenuItem.separator())

        // Test Protected Mode
        let testItem = NSMenuItem(
            title: "Test Protected Mode…",
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
            let editorView = DeckEditorView()
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
            editorWindow?.isReleasedWhenClosed = false

            // Observe window close to update app state
            editorCloseObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: editorWindow,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handleEditorWindowClose()
                }
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
            let testView = TestCaptureView()
                .environmentObject(appState)

            testCaptureWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            testCaptureWindow?.title = "Test Protected Mode"
            testCaptureWindow?.contentView = NSHostingView(rootView: testView)
            testCaptureWindow?.center()
            testCaptureWindow?.isReleasedWhenClosed = false

            // Observe window close to clean up reference
            testCaptureWindowObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: testCaptureWindow,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    if let observer = self?.testCaptureWindowObserver {
                        NotificationCenter.default.removeObserver(observer)
                        self?.testCaptureWindowObserver = nil
                    }
                    self?.testCaptureWindow = nil
                }
            }
        }

        testCaptureWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Timer Submenu

    /// Builds the Presentation Timer submenu item
    private func buildTimerSubmenuItem() -> NSMenuItem {
        let timerMenuItem = NSMenuItem(title: "Presentation Timer", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Presentation Timer")

        // Start/Stop Timer
        let startStopTitle = appState.isTimerRunning ? "Stop Timer" : "Start Timer"
        let startStopItem = NSMenuItem(title: startStopTitle, action: #selector(toggleTimer), keyEquivalent: "")
        startStopItem.target = self
        submenu.addItem(startStopItem)

        submenu.addItem(NSMenuItem.separator())

        // Deck Timer mode (radio)
        let deckTimerItem = NSMenuItem(
            title: "Deck Timer (\(formatTime(appState.timerTotalSeconds)))",
            action: #selector(setDeckTimerMode),
            keyEquivalent: ""
        )
        deckTimerItem.target = self
        deckTimerItem.state = appState.timerMode == "deck" ? .on : .off
        submenu.addItem(deckTimerItem)

        // Per-Card Timer mode (radio)
        let perCardItem = NSMenuItem(
            title: "Per-Card Timer (\(formatTime(appState.timerPerCardSeconds)))",
            action: #selector(setPerCardTimerMode),
            keyEquivalent: ""
        )
        perCardItem.target = self
        perCardItem.state = appState.timerMode == "perCard" ? .on : .off
        submenu.addItem(perCardItem)

        submenu.addItem(NSMenuItem.separator())

        // Set Deck Time...
        let setDeckTimeItem = NSMenuItem(title: "Set Deck Time\u{2026}", action: #selector(showSetDeckTime), keyEquivalent: "")
        setDeckTimeItem.target = self
        submenu.addItem(setDeckTimeItem)

        // Set Per-Card Time...
        let setPerCardTimeItem = NSMenuItem(title: "Set Per-Card Time\u{2026}", action: #selector(showSetPerCardTime), keyEquivalent: "")
        setPerCardTimeItem.target = self
        submenu.addItem(setPerCardTimeItem)

        submenu.addItem(NSMenuItem.separator())

        // Show Pause Button toggle
        let pauseItem = NSMenuItem(title: "Show Pause Button", action: #selector(togglePauseButton), keyEquivalent: "")
        pauseItem.target = self
        pauseItem.state = appState.timerShowPauseButton ? .on : .off
        submenu.addItem(pauseItem)

        submenu.addItem(NSMenuItem.separator())

        // Apply To sub-submenu
        let applyToItem = NSMenuItem(title: "Apply To", action: nil, keyEquivalent: "")
        let applyToSubmenu = NSMenu(title: "Apply To")

        let allDecksItem = NSMenuItem(title: "All Decks", action: #selector(setApplyToAll), keyEquivalent: "")
        allDecksItem.target = self
        allDecksItem.state = appState.timerApplyMode == "all" ? .on : .off
        applyToSubmenu.addItem(allDecksItem)

        let selectedDecksItem = NSMenuItem(title: "Selected Decks\u{2026}", action: #selector(showDeckPicker), keyEquivalent: "")
        selectedDecksItem.target = self
        selectedDecksItem.state = appState.timerApplyMode == "selected" ? .on : .off
        applyToSubmenu.addItem(selectedDecksItem)

        applyToItem.submenu = applyToSubmenu
        submenu.addItem(applyToItem)

        timerMenuItem.submenu = submenu
        return timerMenuItem
    }

    @objc private func toggleTimer() {
        appState.toggleTimerStartPause()
    }

    @objc private func setDeckTimerMode() {
        appState.timerMode = "deck"
    }

    @objc private func setPerCardTimerMode() {
        appState.timerMode = "perCard"
    }

    @objc private func togglePauseButton() {
        appState.timerShowPauseButton.toggle()
    }

    @objc private func setApplyToAll() {
        appState.timerApplyMode = "all"
    }

    @objc private func showSetDeckTime() {
        showTimeInputDialog(
            title: "Set Deck Time",
            message: "Enter the total time for the entire deck (MM:SS):",
            currentSeconds: appState.timerTotalSeconds
        ) { [weak self] seconds in
            self?.appState.timerTotalSeconds = seconds
        }
    }

    @objc private func showSetPerCardTime() {
        showTimeInputDialog(
            title: "Set Per-Card Time",
            message: "Enter the time allotted per card (MM:SS):",
            currentSeconds: appState.timerPerCardSeconds
        ) { [weak self] seconds in
            self?.appState.timerPerCardSeconds = seconds
        }
    }

    @objc private func showDeckPicker() {
        let alert = NSAlert()
        alert.messageText = "Select Decks for Timer"
        alert.informativeText = "Choose which decks should use the presentation timer:"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Apply")
        alert.addButton(withTitle: "Cancel")

        // Create scrollable checkbox list
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder

        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false

        var checkboxes: [(NSButton, UUID)] = []

        for deck in appState.decks {
            let checkbox = NSButton(checkboxWithTitle: deck.title, target: nil, action: nil)
            checkbox.state = appState.timerSelectedDeckIds.contains(deck.id) ? .on : .off
            stackView.addArrangedSubview(checkbox)
            checkboxes.append((checkbox, deck.id))
        }

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor, constant: -8)
        ])

        scrollView.documentView = documentView
        documentView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor).isActive = true

        alert.accessoryView = scrollView

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let selectedIds = checkboxes
                .filter { $0.0.state == .on }
                .map { $0.1 }
            appState.timerSelectedDeckIds = selectedIds
            appState.timerApplyMode = "selected"
        }
    }

    /// Shows a time input dialog and calls the completion with the parsed seconds
    private func showTimeInputDialog(title: String, message: String, currentSeconds: Int, completion: @escaping (Int) -> Void) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Set")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 120, height: 24))
        textField.stringValue = formatTime(currentSeconds)
        textField.placeholderString = "MM:SS"
        alert.accessoryView = textField

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let input = textField.stringValue.trimmingCharacters(in: .whitespaces)
            if let seconds = parseTime(input) {
                completion(seconds)
            }
        }
    }

    /// Formats seconds as MM:SS
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Parses MM:SS or M:SS string to total seconds
    private func parseTime(_ input: String) -> Int? {
        let parts = input.split(separator: ":")
        if parts.count == 2,
           let minutes = Int(parts[0]),
           let seconds = Int(parts[1]),
           minutes >= 0, seconds >= 0, seconds < 60 {
            return minutes * 60 + seconds
        }
        // Try parsing as plain number of minutes
        if let minutes = Int(input), minutes > 0 {
            return minutes * 60
        }
        return nil
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
