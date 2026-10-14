import SwiftUI

/// Entry point: picks the scene set for the running flavor.
///
/// The unit-test host gets an app with no window scene, so launching it under
/// XCTest opens no window and AppKit never autosaves a window frame into the
/// `com.tookes.Prompter` defaults domain (US-25 AC2).
@main
enum PrompterMain {
    static func main() {
        if AppEnvironment.current.runsFullLaunch {
            PrompterApp.main()
        } else {
            PrompterTestHostApp.main()
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

/// App used when the process hosts the unit tests. A Settings scene opens no
/// window at launch; AppDelegate returns right after the activation policy.
struct PrompterTestHostApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        SwiftUI.Settings {
            EmptyView()
        }
    }
}
