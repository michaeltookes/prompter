import Foundation

/// Application settings that persist across app restarts.
///
/// Settings are saved to Settings.json in the app's
/// Application Support folder.
struct Settings: Codable, Equatable {
    /// Overlay window opacity (0.0 to 1.0)
    var overlayOpacity: Double

    /// Font scale multiplier for overlay text (0.5 to 2.0)
    var overlayFontScale: Double

    /// Saved overlay window frame (position and size)
    var overlayFrame: OverlayFrame

    /// Whether click-through mode is enabled
    var clickThroughEnabled: Bool

    /// Whether Protected Mode is enabled
    var protectedModeEnabled: Bool

    /// ID of the last opened deck (to restore on launch)
    var lastOpenedDeckId: UUID?

    // MARK: - Defaults

    /// Default settings for new installations
    static let `default` = Settings(
        overlayOpacity: 0.85,
        overlayFontScale: 1.0,
        overlayFrame: .default,
        clickThroughEnabled: false,
        protectedModeEnabled: true,
        lastOpenedDeckId: nil
    )

    // MARK: - Validation

    /// Returns a copy with values clamped to valid ranges
    func validated() -> Settings {
        var copy = self
        copy.overlayOpacity = max(0.3, min(1.0, overlayOpacity))
        copy.overlayFontScale = max(0.5, min(2.0, overlayFontScale))
        return copy
    }
}

/// Represents the overlay window's frame (position and size).
///
/// Stored separately so we can persist window geometry
/// across app restarts.
struct OverlayFrame: Codable, Equatable {
    /// X position (from left of screen)
    var x: Double

    /// Y position (from bottom of screen, macOS coordinate system)
    var y: Double

    /// Window width
    var width: Double

    /// Window height
    var height: Double

    // MARK: - Defaults

    /// Default frame for new installations
    static let `default` = OverlayFrame(
        x: 100,
        y: 100,
        width: 400,
        height: 500
    )

    // MARK: - Initialization

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    // MARK: - Conversion

    /// Converts to NSRect for use with AppKit
    func toNSRect() -> CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    /// Creates from an NSRect
    static func from(_ rect: CGRect) -> OverlayFrame {
        OverlayFrame(
            x: rect.origin.x,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height
        )
    }
}
