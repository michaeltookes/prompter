import SwiftUI

/// Main entry point for Presenter Overlay
/// This is a menu bar application (LSUIElement = YES in Info.plist)
/// that provides a floating overlay for presenter notes during demos.
@main
struct PresenterOverlayApp: App {
    /// AppDelegate handles NSApplication lifecycle and window management
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar apps don't need a main window scene
        // All UI is managed through the AppDelegate
        // Using an empty WindowGroup that we never show
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
    }
}
