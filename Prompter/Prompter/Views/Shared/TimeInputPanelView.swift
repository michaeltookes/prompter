import SwiftUI

/// SwiftUI view for entering a time duration in MM:SS format.
///
/// Used for "Set Deck Time" and "Set Per-Card Time" dialogs.
/// Reports the result via a closure: Int (parsed seconds) on Set, nil on Cancel.
struct TimeInputPanelView: View {
    let title: String
    let message: String
    let currentSeconds: Int
    let onComplete: (Int?) -> Void

    @State private var timeText: String = ""
    @State private var isInvalid: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            // Description
            Text(message)
                .font(.system(size: Theme.captionFontSize))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            // Time input
            VStack(spacing: 6) {
                TextField("MM:SS", text: $timeText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 120)
                    .onChange(of: timeText) { _, _ in
                        isInvalid = false
                    }

                if isInvalid {
                    Text("Enter a valid time (e.g. 5:00)")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.8))
                }
            }

            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    onComplete(nil)
                }
                .keyboardShortcut(.cancelAction)

                Button("Set") {
                    if let seconds = parseTime(timeText) {
                        onComplete(seconds)
                    } else {
                        isInvalid = true
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
            }
        }
        .padding(24)
        .frame(width: 280)
        .onAppear {
            timeText = formatTime(currentSeconds)
        }
    }

    // MARK: - Helpers

    /// Formats seconds as M:SS
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Parses MM:SS or plain minutes to total seconds
    private func parseTime(_ input: String) -> Int? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        let parts = trimmed.split(separator: ":")
        if parts.count == 2,
           let minutes = Int(parts[0]),
           let seconds = Int(parts[1]),
           minutes >= 0, seconds >= 0, seconds < 60 {
            return minutes * 60 + seconds
        }
        if let minutes = Int(trimmed), minutes > 0 {
            return minutes * 60
        }
        return nil
    }
}

#Preview {
    TimeInputPanelView(
        title: "Set Deck Time",
        message: "Enter the total time for the entire deck (MM:SS):",
        currentSeconds: 300
    ) { result in
        print("Result: \(String(describing: result))")
    }
}
