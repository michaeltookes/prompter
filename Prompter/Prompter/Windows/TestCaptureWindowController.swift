import AppKit
import SwiftUI

/// Controls the Test Capture window.
///
/// This window allows users to verify that Protected Mode
/// is working correctly by testing screen capture behavior.
@MainActor
final class TestCaptureWindowController {

    // MARK: - Properties

    /// The test capture window
    private var window: NSWindow?

    /// Reference to app state
    private let appState: AppState

    // MARK: - Initialization

    init(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Window Management

    /// Shows the test capture window
    func showWindow() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create the SwiftUI view
        let contentView = TestCaptureView()
            .environmentObject(appState)

        // Create and configure the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Test Protected Mode"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.isReleasedWhenClosed = false

        // Set up close handler
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.window = nil
            }
        }

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Closes the test capture window
    func closeWindow() {
        window?.close()
        window = nil
    }

    /// Returns whether the window is currently visible
    var isVisible: Bool {
        window?.isVisible ?? false
    }
}
