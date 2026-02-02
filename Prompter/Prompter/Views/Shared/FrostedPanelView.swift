import SwiftUI

/// A frosted glass panel with consistent styling.
///
/// Used for overlay backgrounds and editor panels to provide
/// a semi-transparent, blurred background effect.
struct FrostedPanelView<Content: View>: View {
    /// The content to display inside the panel
    let content: Content

    /// Corner radius (defaults to Theme.cardCornerRadius)
    var cornerRadius: CGFloat = Theme.cardCornerRadius

    /// Whether to show a border
    var showBorder: Bool = true

    /// Background opacity multiplier
    var opacity: Double = 0.75

    init(
        cornerRadius: CGFloat = Theme.cardCornerRadius,
        showBorder: Bool = true,
        opacity: Double = 0.75,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.showBorder = showBorder
        self.opacity = opacity
        self.content = content()
    }

    var body: some View {
        content
            .background(
                ZStack {
                    // Frosted glass effect
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)

                    // Tinted overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Theme.surfaceBackground.opacity(opacity))
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(showBorder ? Theme.divider : .clear, lineWidth: 1)
            )
    }
}

#Preview {
    FrostedPanelView {
        VStack {
            Text("Frosted Panel")
                .font(.title)
            Text("With blur effect")
                .foregroundColor(.secondary)
        }
        .padding(24)
    }
    .padding()
    .background(Color.blue.gradient)
}
