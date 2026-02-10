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

    // MARK: - Timer Settings

    /// Whether the timer UI is visible in the overlay footer
    var timerEnabled: Bool

    /// Timer mode: "deck" (total time divided by cards) or "perCard" (fixed per card)
    var timerMode: String

    /// Total deck time in seconds (used when timerMode == "deck")
    var timerTotalSeconds: Int

    /// Per-card time in seconds (used when timerMode == "perCard")
    var timerPerCardSeconds: Int

    /// Whether to show a pause button in the overlay footer
    var timerShowPauseButton: Bool

    /// Timer scope: "all" (all decks) or "selected" (specific decks only)
    var timerApplyMode: String

    /// Deck IDs the timer applies to (used when timerApplyMode == "selected")
    var timerSelectedDeckIds: [UUID]

    // MARK: - Defaults

    /// Default settings for new installations
    static let `default` = Settings(
        overlayOpacity: 0.85,
        overlayFontScale: 1.0,
        overlayFrame: .default,
        clickThroughEnabled: false,
        protectedModeEnabled: true,
        lastOpenedDeckId: nil,
        timerEnabled: true,
        timerMode: "deck",
        timerTotalSeconds: 300,
        timerPerCardSeconds: 60,
        timerShowPauseButton: false,
        timerApplyMode: "all",
        timerSelectedDeckIds: []
    )

    // MARK: - Memberwise Init

    init(
        overlayOpacity: Double,
        overlayFontScale: Double,
        overlayFrame: OverlayFrame,
        clickThroughEnabled: Bool,
        protectedModeEnabled: Bool,
        lastOpenedDeckId: UUID?,
        timerEnabled: Bool = true,
        timerMode: String = "deck",
        timerTotalSeconds: Int = 300,
        timerPerCardSeconds: Int = 60,
        timerShowPauseButton: Bool = false,
        timerApplyMode: String = "all",
        timerSelectedDeckIds: [UUID] = []
    ) {
        self.overlayOpacity = overlayOpacity
        self.overlayFontScale = overlayFontScale
        self.overlayFrame = overlayFrame
        self.clickThroughEnabled = clickThroughEnabled
        self.protectedModeEnabled = protectedModeEnabled
        self.lastOpenedDeckId = lastOpenedDeckId
        self.timerEnabled = timerEnabled
        self.timerMode = timerMode
        self.timerTotalSeconds = timerTotalSeconds
        self.timerPerCardSeconds = timerPerCardSeconds
        self.timerShowPauseButton = timerShowPauseButton
        self.timerApplyMode = timerApplyMode
        self.timerSelectedDeckIds = timerSelectedDeckIds
    }

    // MARK: - Codable (backward compatibility for new timer fields)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overlayOpacity = try container.decode(Double.self, forKey: .overlayOpacity)
        overlayFontScale = try container.decode(Double.self, forKey: .overlayFontScale)
        overlayFrame = try container.decode(OverlayFrame.self, forKey: .overlayFrame)
        clickThroughEnabled = try container.decode(Bool.self, forKey: .clickThroughEnabled)
        protectedModeEnabled = try container.decode(Bool.self, forKey: .protectedModeEnabled)
        lastOpenedDeckId = try container.decodeIfPresent(UUID.self, forKey: .lastOpenedDeckId)
        timerEnabled = try container.decodeIfPresent(Bool.self, forKey: .timerEnabled) ?? true
        timerMode = try container.decodeIfPresent(String.self, forKey: .timerMode) ?? "deck"
        timerTotalSeconds = try container.decodeIfPresent(Int.self, forKey: .timerTotalSeconds) ?? 300
        timerPerCardSeconds = try container.decodeIfPresent(Int.self, forKey: .timerPerCardSeconds) ?? 60
        timerShowPauseButton = try container.decodeIfPresent(Bool.self, forKey: .timerShowPauseButton) ?? false
        timerApplyMode = try container.decodeIfPresent(String.self, forKey: .timerApplyMode) ?? "all"
        timerSelectedDeckIds = try container.decodeIfPresent([UUID].self, forKey: .timerSelectedDeckIds) ?? []
    }

    // MARK: - Validation

    /// Returns a copy with values clamped to valid ranges
    func validated() -> Settings {
        var copy = self
        copy.overlayOpacity = max(0.3, min(1.0, overlayOpacity))
        copy.overlayFontScale = max(0.5, min(2.0, overlayFontScale))
        copy.timerTotalSeconds = max(10, timerTotalSeconds)
        copy.timerPerCardSeconds = max(5, timerPerCardSeconds)
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
