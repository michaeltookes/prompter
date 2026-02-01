import SwiftUI

/// Footer view for the overlay showing card position and status indicators.
struct OverlayFooterView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            // Card position
            Text("Card \(appState.currentCardIndex + 1) / \(appState.totalCards)")
                .font(.system(size: Theme.footerFontSize, weight: .medium))
                .foregroundColor(Theme.textSecondary)

            Spacer()

            // Status indicators
            HStack(spacing: 8) {
                if appState.isProtectedModeEnabled {
                    StatusIndicator(
                        iconName: "shield.fill",
                        label: "Protected",
                        color: Theme.accent
                    )
                }

                if appState.isClickThroughEnabled {
                    StatusIndicator(
                        iconName: "cursorarrow.click.badge.clock",
                        label: "Click-through",
                        color: Theme.accent
                    )
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(0.8)
    }
}

/// A small status indicator with icon
struct StatusIndicator: View {
    let iconName: String
    let label: String
    let color: Color

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 12))
            .foregroundColor(color)
            .help(label)
    }
}

#Preview {
    OverlayFooterView()
        .environmentObject(AppState())
        .padding()
        .background(Theme.surfaceBackground)
}
