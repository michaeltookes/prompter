# Changelog

All notable changes to Prompter will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- Sparkle auto-update framework (code integration with placeholder appcast URL and EdDSA key)
- "Check for Updates..." menu item in the menu bar dropdown
- Unit tests for timer logic (33 tests covering configuration, state machine, toggle cycle, card navigation, real-time tick)
- Themed NSPanel dialogs for timer configuration (TimeInputPanelView, DeckPickerPanelView)
- ThemedPanelWindow reusable NSPanel subclass for utility dialogs
- Presentation timer with per-card countdown displayed in the overlay footer
- Play/pause button in overlay to start timer inline
- Timer auto-starts when navigating from card 1 to card 2
- Warning pulse animation (orange) when timer reaches last 20% of per-card time
- Two timer modes: deck total time (divided by cards) or fixed per-card time
- Timer configuration submenu in menu bar (mode, duration, pause button, deck scope)
- Global hotkey Cmd+Shift+T for timer start/pause/resume
- Traffic light close button (top-left of overlay) to hide overlay without menu bar
- Confirmation prompt before deleting a deck

### Changed
- Migrated global hotkeys from deprecated Carbon Event Manager to CGEvent tap
- Replaced NSAlert-based timer dialogs with custom themed NSPanel windows
- Hotkey registration now prompts for Accessibility permission with automatic retry
- Increased maximum deck limit from 5 to 10
- Moved "Delete Deck" button to bottom of sidebar to prevent accidental deletions

### Fixed
- Swift strict concurrency warnings in notification observer closures
- Editor window crash on close caused by double-release (missing `isReleasedWhenClosed`)

## [1.0.0] - 2026-02-08

### Added
- Menu bar application with system-wide global hotkeys (Cmd+Shift combos)
- Overlay window visible across all Spaces and fullscreen applications
- Click-through mode for mouse event passthrough
- Protected Mode for screen capture exclusion
- 5 card layout templates: Title + Bullets, Image + Notes, Two Images + Notes, 2x2 Grid + Caption, Full Bleed + 3 Bullets
- Deck editor with drag-to-reorder cards, layout picker, and image drag-and-drop
- JSON persistence with auto-save (debounced) to ~/Library/Application Support/Prompter/
- Asset management with UUID-based image storage and caching
- Window frame persistence across app restarts
- Overlay opacity and font size controls
- Test Protected Mode window with step-by-step instructions
