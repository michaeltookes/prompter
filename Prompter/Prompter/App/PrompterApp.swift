import SwiftUI

/// Entry point: picks the scene set for the running flavor.
///
/// The unit-test host, and a hunt launch running under the released app's
/// bundle id, get an app with no window scene, so AppKit never autosaves a
/// window frame into the `com.tookes.Prompter` defaults domain (US-25 AC2).
@main
enum PrompterMain {
    static func main() {
        if AppEnvironment.current.opensWindowScene(bundleIdentifier: Bundle.main.bundleIdentifier) {
            PrompterApp.main()
        } else {
            PrompterHeadlessApp.main()
        }
    }
}

/// Main app for Prompter
/// This is a menu bar application (LSUIElement = YES in Info.plist)
/// that provides a floating overlay for presenter notes during demos.
struct PrompterApp: App {
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

/// App with no window scene: used by the unit-test host (AppDelegate returns
/// right after the activation policy) and by a hunt launch that shares the
/// released app's defaults domain. A Settings scene opens no window at launch.
struct PrompterHeadlessApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        SwiftUI.Settings {
            EmptyView()
        }
    }
}
