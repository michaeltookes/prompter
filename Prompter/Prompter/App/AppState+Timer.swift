import Combine
import Foundation

// MARK: - Timer

extension AppState {

    /// Formatted timer display (MM:SS)
    var timerDisplayText: String {
        let minutes = timerSecondsRemaining / 60
        let seconds = timerSecondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Effective per-card time based on current mode
    var effectivePerCardSeconds: Int {
        if timerMode == "deck" {
            guard totalCards > 0 else { return 0 }
            return timerTotalSeconds / totalCards
        } else {
            return timerPerCardSeconds
        }
    }

    /// Whether the timer is active for the current deck
    var isTimerActiveForCurrentDeck: Bool {
        guard isTimerEnabled else { return false }
        guard totalCards > 0 else { return false }
        if timerApplyMode == "all" { return true }
        guard let deckId = currentDeck?.id else { return false }
        return timerSelectedDeckIds.contains(deckId)
    }

    /// Starts the timer for the current card
    func startTimer() {
        guard isTimerActiveForCurrentDeck else { return }
        let seconds = effectivePerCardSeconds
        guard seconds > 0 else { return }

        timerSecondsRemaining = seconds
        isTimerRunning = true
        isTimerPaused = false
        isTimerWarning = false
        startTimerTick()
    }

    /// Stops the timer and resets all runtime state
    func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
        isTimerRunning = false
        isTimerPaused = false
        isTimerWarning = false
        timerSecondsRemaining = 0
    }

    /// Pauses the timer
    func pauseTimer() {
        guard isTimerRunning, !isTimerPaused else { return }
        isTimerPaused = true
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    /// Resumes the timer from paused state
    func resumeTimer() {
        guard isTimerRunning, isTimerPaused else { return }
        isTimerPaused = false
        startTimerTick()
    }

    /// Cycles through timer states: stopped → running → paused → running
    func toggleTimerStartPause() {
        if !isTimerRunning {
            startTimer()
            postAccessibilityAnnouncement("Timer started")
        } else if isTimerPaused {
            resumeTimer()
            postAccessibilityAnnouncement("Timer resumed")
        } else if timerShowPauseButton {
            pauseTimer()
            postAccessibilityAnnouncement("Timer paused at \(timerDisplayText)")
        } else {
            stopTimer()
            postAccessibilityAnnouncement("Timer stopped")
        }
    }

    /// Resets the card timer (called on card navigation)
    func resetCardTimer() {
        guard isTimerRunning else { return }
        timerCancellable?.cancel()

        let seconds = effectivePerCardSeconds
        guard seconds > 0 else {
            stopTimer()
            return
        }

        timerSecondsRemaining = seconds
        isTimerWarning = false
        if !isTimerPaused {
            startTimerTick()
        }
    }

    /// Starts the 1-second tick publisher
    private func startTimerTick() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.timerTick()
            }
    }

    /// Processes one timer tick
    private func timerTick() {
        guard timerSecondsRemaining > 0 else {
            timerCancellable?.cancel()
            timerCancellable = nil
            isTimerRunning = false
            isTimerPaused = false
            timerSecondsRemaining = 0
            isTimerWarning = true
            postAccessibilityAnnouncement("Card time expired")
            return
        }
        timerSecondsRemaining -= 1

        if timerSecondsRemaining == 0 {
            timerCancellable?.cancel()
            timerCancellable = nil
            isTimerRunning = false
            isTimerPaused = false
            isTimerWarning = true
            postAccessibilityAnnouncement("Card time expired")
            return
        }

        // Warning at last 20% of per-card time
        let threshold = Int(Double(effectivePerCardSeconds) * 0.2)
        let wasWarning = isTimerWarning
        isTimerWarning = timerSecondsRemaining <= threshold
        if isTimerWarning && !wasWarning {
            postAccessibilityAnnouncement("Warning: \(timerDisplayText) remaining")
        }
    }
}
