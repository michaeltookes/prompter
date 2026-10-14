import Combine
import Foundation

// MARK: - Auto-save

extension AppState {

    /// Sets up auto-save on settings changes
    func setupAutoSave() {
        // Auto-save settings when overlay properties change
        $overlayOpacity
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $overlayFontScale
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $overlayFrame
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $isClickThroughEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $isProtectedModeEnabled
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        // Auto-save when current deck changes
        $currentDeck
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        // Auto-save timer configuration changes
        $isTimerEnabled
            .dropFirst()
            .sink { [weak self] newValue in
                self?.saveSettings()
                self?.stopTimerIfCurrentDeckIneligible(isTimerEnabled: newValue)
            }
            .store(in: &cancellables)

        $timerMode
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $timerTotalSeconds
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $timerPerCardSeconds
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $timerShowPauseButton
            .dropFirst()
            .sink { [weak self] _ in self?.saveSettings() }
            .store(in: &cancellables)

        $timerApplyMode
            .dropFirst()
            .sink { [weak self] newValue in
                self?.saveSettings()
                self?.stopTimerIfCurrentDeckIneligible(timerApplyMode: newValue)
            }
            .store(in: &cancellables)

        $timerSelectedDeckIds
            .dropFirst()
            .sink { [weak self] newValue in
                self?.saveSettings()
                self?.stopTimerIfCurrentDeckIneligible(timerSelectedDeckIds: newValue)
            }
            .store(in: &cancellables)
    }

    /// Stops the running timer when config changes make the current deck ineligible.
    private func stopTimerIfCurrentDeckIneligible(
        isTimerEnabled: Bool? = nil,
        timerApplyMode: String? = nil,
        timerSelectedDeckIds: [UUID]? = nil
    ) {
        guard isTimerRunning else { return }
        guard !wouldTimerBeActiveForCurrentDeck(
            isTimerEnabled: isTimerEnabled,
            timerApplyMode: timerApplyMode,
            timerSelectedDeckIds: timerSelectedDeckIds
        ) else { return }
        stopTimer()
    }

    /// Evaluates timer eligibility using optional override values from incoming publisher updates.
    private func wouldTimerBeActiveForCurrentDeck(
        isTimerEnabled: Bool? = nil,
        timerApplyMode: String? = nil,
        timerSelectedDeckIds: [UUID]? = nil
    ) -> Bool {
        let enabled = isTimerEnabled ?? self.isTimerEnabled
        let applyMode = timerApplyMode ?? self.timerApplyMode
        let selectedDeckIds = timerSelectedDeckIds ?? self.timerSelectedDeckIds

        guard enabled else { return false }
        guard totalCards > 0 else { return false }
        if applyMode == "all" { return true }
        guard let deckId = currentDeck?.id else { return false }
        return selectedDeckIds.contains(deckId)
    }
}
