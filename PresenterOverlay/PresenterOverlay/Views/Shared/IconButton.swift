import SwiftUI

/// A standardized icon button with consistent styling.
///
/// Provides hover and press states with smooth animations.
/// Used throughout the editor UI for toolbar actions.
struct IconButton: View {
    /// SF Symbol name
    let iconName: String

    /// Button label (for accessibility)
    let label: String

    /// Action to perform when tapped
    let action: () -> Void

    /// Icon size
    var size: CGFloat = 16

    /// Whether the button is disabled
    var isDisabled: Bool = false

    /// Whether the button shows a "selected" state
    var isSelected: Bool = false

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size + 16, height: size + 16)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .help(label)
        .accessibilityLabel(label)
    }

    private var foregroundColor: Color {
        if isDisabled {
            return Theme.textSecondary.opacity(0.5)
        }
        if isSelected || isPressed {
            return Theme.accent
        }
        if isHovered {
            return Theme.textPrimary
        }
        return Theme.textSecondary
    }

    private var backgroundColor: Color {
        if isSelected {
            return Theme.accent.opacity(0.2)
        }
        if isPressed {
            return Theme.accent.opacity(0.1)
        }
        if isHovered {
            return Color.white.opacity(0.1)
        }
        return .clear
    }
}

/// A group of icon buttons in a horizontal toolbar style
struct IconButtonGroup: View {
    let buttons: [(iconName: String, label: String, action: () -> Void)]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(buttons.enumerated()), id: \.offset) { _, button in
                IconButton(
                    iconName: button.iconName,
                    label: button.label,
                    action: button.action
                )
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius + 2))
    }
}

#Preview {
    HStack(spacing: 20) {
        IconButton(iconName: "plus", label: "Add", action: {})
        IconButton(iconName: "trash", label: "Delete", action: {})
        IconButton(iconName: "square.on.square", label: "Duplicate", action: {})
        IconButton(iconName: "star.fill", label: "Selected", action: {}, isSelected: true)
        IconButton(iconName: "xmark", label: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
    .background(Color.gray)
}
