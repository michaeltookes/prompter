import AppKit

/// Custom NSWindow subclass for the overlay.
///
/// This window has special properties:
/// - Borderless (no title bar)
/// - Transparent background
/// - Floats above all other windows
/// - Visible on all Spaces (virtual desktops)
/// - Can be excluded from screen capture (Protected Mode)
/// - Can ignore mouse events (click-through mode)
final class OverlayWindow: NSWindow {

    // MARK: - Initialization

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: style,
            backing: backingStoreType,
            defer: flag
        )
        configureWindow()
    }

    // MARK: - Configuration

    /// Configures the window with overlay-specific properties
    private func configureWindow() {
        // Borderless, transparent window
        self.styleMask = [.borderless, .resizable]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true

        // Floating above other windows
        self.level = .floating

        // Collection behavior for overlay
        self.collectionBehavior = [
            .canJoinAllSpaces,      // Visible on all Spaces
            .fullScreenAuxiliary,   // Visible in fullscreen apps
            .stationary             // Doesn't move with space switching
        ]

        // Allow movement by dragging anywhere on the window
        self.isMovableByWindowBackground = true

        // Title bar configuration (hidden but allows resize)
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden

        // Default Protected Mode (attempt to hide from capture)
        self.sharingType = .none
    }

    // MARK: - Public API

    /// Enables or disables click-through mode.
    /// When enabled, mouse events pass through to windows underneath.
    /// - Parameter enabled: Whether to enable click-through
    func setClickThrough(_ enabled: Bool) {
        self.ignoresMouseEvents = enabled
    }

    /// Enables or disables Protected Mode.
    /// When enabled, attempts to exclude window from screen capture.
    /// - Parameter enabled: Whether to enable protected mode
    func setProtectedMode(_ enabled: Bool) {
        if enabled {
            self.sharingType = .none
        } else {
            self.sharingType = .readOnly
        }
    }

    // MARK: - Window Behavior Overrides

    /// Allows the window to become key only when not in click-through mode
    override var canBecomeKey: Bool {
        return !ignoresMouseEvents
    }

    /// Prevents this window from becoming the main window
    override var canBecomeMain: Bool {
        return false
    }
}
