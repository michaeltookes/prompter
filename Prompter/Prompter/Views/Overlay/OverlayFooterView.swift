import SwiftUI

/// Footer view for the overlay showing card position, timer, and status indicators.
struct OverlayFooterView: View {
    @EnvironmentObject var appState: AppState
    @State private var warningPulse = false

    var body: some View {
        HStack {
            // Card position
            Text("Card \(appState.currentCardIndex + 1) / \(appState.totalCards)")
                .font(.system(size: Theme.footerFontSize, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .accessibilityLabel("Card \(appState.currentCardIndex + 1) of \(appState.totalCards)")

            // Timer display
            if appState.isTimerActiveForCurrentDeck {
                Text("|")
                    .font(.system(size: Theme.footerFontSize))
                    .foregroundColor(Theme.textSecondary.opacity(0.3))

                // Play/Pause button
                Button(action: { appState.toggleTimerStartPause() }) {
                    Image(systemName: timerButtonIcon)
                        .font(.system(size: Theme.footerFontSize))
                        .foregroundColor(Theme.accent)
                }
                .buttonStyle(.plain)
                .help(timerButtonHelp)
                .accessibilityLabel(timerButtonHelp)

                // Countdown display
                Text(appState.isTimerRunning || appState.timerSecondsRemaining > 0
                     ? appState.timerDisplayText
                     : formatTime(appState.effectivePerCardSeconds))
                    .font(.system(size: Theme.footerFontSize, weight: .medium, design: .monospaced))
                    .foregroundColor(appState.isTimerWarning ? Theme.timerWarning : Theme.textSecondary)
                    .accessibilityLabel("Timer: \(appState.isTimerRunning || appState.timerSecondsRemaining > 0 ? appState.timerDisplayText : formatTime(appState.effectivePerCardSeconds))")
                    .opacity(appState.isTimerWarning ? (warningPulse ? 0.4 : 1.0) : 1.0)
                    .animation(
                        appState.isTimerWarning
                            ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                            : .default,
                        value: warningPulse
                    )
                    .onChange(of: appState.isTimerWarning) { _, isWarning in
                        warningPulse = isWarning
                    }

                if appState.isTimerPaused {
                    Text("PAUSED")
                        .font(Theme.smallSemibold)
                        .foregroundColor(Theme.accent.opacity(0.7))
                }
            }

            Spacer()

            // Opacity slider
            HStack(spacing: 6) {
                Image(systemName: "circle.lefthalf.filled")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary.opacity(0.7))
                    .accessibilityHidden(true)

                Slider(value: $appState.overlayOpacity, in: 0.3...1.0, step: 0.05)
                    .frame(width: 60)
                    .controlSize(.mini)
                    .accessibilityLabel("Overlay opacity")
                    .accessibilityValue("\(Int(appState.overlayOpacity * 100)) percent")

                Text("\(Int(appState.overlayOpacity * 100))%")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Theme.textSecondary.opacity(0.7))
                    .frame(width: 28, alignment: .trailing)
                    .accessibilityHidden(true)
            }
            .help("Adjust overlay transparency")

            Spacer()

            // Status indicators
            HStack(spacing: 8) {
                if appState.isProtectedModeEnabled {
                    StatusIndicator(
                        iconName: "shield.fill",
                        label: "Protected",
                        color: Theme.accent
                    )
                } else {
                    // Warning when Protected Mode is off
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                            .accessibilityHidden(true)
                        Text("Visible to capture")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                    .help("Protected Mode is off. Enable it before sharing your screen.")
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Warning: Visible to capture. Protected Mode is off.")
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

    // MARK: - Timer Helpers

    private var timerButtonIcon: String {
        if !appState.isTimerRunning {
            return "play.fill"
        } else if appState.isTimerPaused {
            return "play.fill"
        } else if appState.timerShowPauseButton {
            return "pause.fill"
        } else {
            return "stop.fill"
        }
    }

    private var timerButtonHelp: String {
        if !appState.isTimerRunning {
            return "Start timer (⌘⇧T)"
        } else if appState.isTimerPaused {
            return "Resume timer (⌘⇧T)"
        } else if appState.timerShowPauseButton {
            return "Pause timer (⌘⇧T)"
        } else {
            return "Stop timer (⌘⇧T)"
        }
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
            .accessibilityLabel(label)
    }
}

#Preview {
    OverlayFooterView()
        .environmentObject(AppState())
        .padding()
        .background(Theme.surfaceBackground)
}
