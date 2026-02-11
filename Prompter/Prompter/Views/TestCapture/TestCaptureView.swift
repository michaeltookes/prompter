import SwiftUI

/// A view that helps users test whether Protected Mode is working.
///
/// This view displays instructions and provides a way to verify
/// that the overlay is excluded from screen recordings and shares.
struct TestCaptureView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "eye.slash.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.accent)
                    .accessibilityHidden(true)

                Text("Test Protected Mode")
                    .font(.system(size: Theme.titleFontSize, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
            }

            Divider()
                .background(Theme.divider)

            // Status
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: appState.isProtectedModeEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(appState.isProtectedModeEnabled ? .green : .red)
                        .accessibilityHidden(true)
                    Text("Protected Mode: \(appState.isProtectedModeEnabled ? "Enabled" : "Disabled")")
                        .font(.system(size: Theme.notesFontSize, weight: .medium))
                }
                .accessibilityElement(children: .combine)

                HStack {
                    Image(systemName: appState.isOverlayVisible ? "checkmark.circle.fill" : "minus.circle.fill")
                        .foregroundColor(appState.isOverlayVisible ? .green : .orange)
                        .accessibilityHidden(true)
                    Text("Overlay: \(appState.isOverlayVisible ? "Visible" : "Hidden")")
                        .font(.system(size: Theme.notesFontSize, weight: .medium))
                }
                .accessibilityElement(children: .combine)
            }
            .foregroundColor(Theme.textPrimary)

            Divider()
                .background(Theme.divider)

            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                Text("How to Test")
                    .font(.system(size: Theme.captionFontSize, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    instructionRow(number: 1, text: "Show the overlay window (Cmd+Shift+O)")
                    instructionRow(number: 2, text: "Start a screen recording or screen share")
                    instructionRow(number: 3, text: "The overlay should NOT appear in the recording")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(Theme.divider)

            // Actions
            VStack(spacing: 12) {
                Button(action: {
                    if !appState.isOverlayVisible {
                        appState.toggleOverlay()
                    }
                }) {
                    HStack {
                        Image(systemName: "eye")
                        Text("Show Overlay")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(appState.isOverlayVisible)

                Button(action: {
                    appState.toggleProtectedMode()
                }) {
                    HStack {
                        Image(systemName: appState.isProtectedModeEnabled ? "eye" : "eye.slash")
                        Text(appState.isProtectedModeEnabled ? "Disable Protected Mode" : "Enable Protected Mode")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            // Note
            Text("Note: Protected Mode uses NSWindow.sharingType = .none which works with most screen recording software. Results may vary with some applications.")
                .font(.system(size: Theme.footerFontSize))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(width: 400, height: 500)
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: Theme.footerFontSize, weight: .bold))
                .foregroundColor(Theme.accent)
                .frame(width: 20, height: 20)
                .background(Theme.accent.opacity(0.2))
                .clipShape(Circle())
                .accessibilityLabel("Step \(number)")

            Text(text)
                .font(.system(size: Theme.captionFontSize))
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    TestCaptureView()
        .environmentObject(AppState())
}
