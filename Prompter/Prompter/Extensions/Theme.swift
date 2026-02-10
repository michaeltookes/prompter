import SwiftUI

/// Theme constants for Presenter Overlay.
///
/// These values come from the UI/UX Style Guide and should be used
/// throughout the app for consistent styling. Never hardcode colors
/// or dimensions - always use these constants.
///
/// Reference: .claude/reference-docs/UI_UX_STYLE_GUIDE.md and CLAUDE.md
enum Theme {

    // MARK: - Colors

    /// Primary accent color - Soft Electric Blue (#5DA9FF)
    static let accent = Color(red: 93/255, green: 169/255, blue: 255/255)

    /// Secondary accent color - Muted Indigo (#7A86FF)
    static let secondaryAccent = Color(red: 122/255, green: 134/255, blue: 255/255)

    /// Primary text color - Soft white (#F5F7FA)
    static let textPrimary = Color(red: 245/255, green: 247/255, blue: 250/255)

    /// Secondary text color - Muted gray (#B8C1CC)
    static let textSecondary = Color(red: 184/255, green: 193/255, blue: 204/255)

    /// Surface background - Frosted dark glass
    /// rgba(25, 27, 32, 0.85)
    static let surfaceBackground = Color(red: 25/255, green: 27/255, blue: 32/255)

    /// Default surface opacity
    static let surfaceOpacity: Double = 0.85

    /// Divider line color
    static let divider = Color.white.opacity(0.08)

    /// Accent glow for shadows
    /// rgba(93, 169, 255, 0.35)
    static let accentGlow = Color(red: 93/255, green: 169/255, blue: 255/255).opacity(0.35)

    /// Timer warning color (matches changelog/UX expectation)
    static let timerWarning = Color.orange

    /// Error text color (mapped to approved palette token)
    static let errorColor = secondaryAccent

    /// Traffic light close button color (macOS traffic red)
    static let trafficLightRed = Color(red: 255/255, green: 95/255, blue: 86/255)

    /// Traffic light disabled fill color (mapped to approved palette token)
    static let trafficLightDisabled = textSecondary.opacity(0.35)

    /// Traffic light icon color (macOS close glyph)
    static let trafficLightIcon = Color.black.opacity(0.7)

    /// Background for drop zones
    static let dropZoneBackground = Color.gray.opacity(0.1)

    /// Sidebar background (system)
    static let sidebarBackground = Color(nsColor: .controlBackgroundColor)

    /// Canvas background (system)
    static let canvasBackground = Color(nsColor: .windowBackgroundColor)

    /// Card background (system)
    static let cardBackground = Color(nsColor: .controlBackgroundColor)

    // MARK: - Corner Radii

    /// Overlay window corner radius
    static let overlayCornerRadius: CGFloat = 18

    /// Card corner radius
    static let cardCornerRadius: CGFloat = 16

    /// Image slot corner radius
    static let imageCornerRadius: CGFloat = 14

    /// Button corner radius
    static let buttonCornerRadius: CGFloat = 10

    // MARK: - Typography

    /// Title font size range (26-32pt)
    static let titleFontSize: CGFloat = 28

    /// Notes font size range (18-22pt)
    static let notesFontSize: CGFloat = 20

    /// Alias for note text size (18-22pt)
    static let noteFontSize: CGFloat = notesFontSize

    /// Caption font size (16pt)
    static let captionFontSize: CGFloat = 16

    /// Footer font size (13pt)
    static let footerFontSize: CGFloat = 13

    // MARK: - Typography Helpers

    static let titleSemibold = Font.system(size: titleFontSize, weight: .semibold, design: .default)
    static let note = Font.system(size: noteFontSize, weight: .regular, design: .default)
    static let caption = Font.system(size: captionFontSize, weight: .regular, design: .default)
    static let footerMedium = Font.system(size: footerFontSize, weight: .medium, design: .default)
    static let smallSemibold = Font.system(size: footerFontSize, weight: .semibold, design: .default)

    // MARK: - Shadows

    /// Overlay shadow radius
    static let overlayShadowRadius: CGFloat = 30

    /// Overlay shadow opacity
    static let overlayShadowOpacity: Double = 0.25

    // MARK: - Animation

    /// Card transition duration
    static let cardTransitionDuration: Double = 0.15
}

// MARK: - Color Extension

extension Color {
    /// Creates a Color from a hex string (e.g., "5DA9FF" or "#5DA9FF")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let red, green, blue: UInt64
        (red, green, blue) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        self.init(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255
        )
    }
}

// MARK: - NSColor Convenience

extension Color {
    /// Creates a SwiftUI Color from an NSColor
    init(nsColor: NSColor) {
        self.init(nsColor)
    }
}
