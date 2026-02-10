import AppKit

/// A reusable themed NSPanel for utility dialogs.
///
/// Provides consistent styling matching the app's dark frosted aesthetic.
/// Use for transient dialogs like time input, deck picker, etc.
final class ThemedPanelWindow: NSPanel {

    /// Creates a themed utility panel.
    /// - Parameters:
    ///   - contentRect: The panel's frame rectangle
    ///   - title: The window title
    init(contentRect: NSRect, title: String) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        self.title = title
        self.isFloatingPanel = true
        self.becomesKeyOnlyIfNeeded = false
        self.isReleasedWhenClosed = false
        self.titlebarAppearsTransparent = true
        self.center()
    }

    /// Applies dark appearance to content without affecting window chrome (keeps close button red).
    override var contentView: NSView? {
        didSet {
            contentView?.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
