# Backlog

Prioritized list of planned features, improvements, and technical debt.

**Latest release: v1.2.0** (Feb 11, 2026) — Full accessibility support (VoiceOver, keyboard navigation, Dynamic Type), "Presenter Overlay" → "Prompter" rename throughout UI.

## High Priority

1. ~~**Add Sparkle auto-update framework**~~  **DONE**
   Integrated Sparkle 2.x via SPM. UpdateManager service, "Check for Updates..." menu item, Info.plist placeholders for appcast URL and EdDSA key. Release infrastructure (key generation, appcast hosting) still needed before first shipped update.

{PRMT-001} **Adopt macOS 26 Liquid Glass design**
   Apply Apple's Liquid Glass material to the overlay and editor UI using `.glassEffect()` (SwiftUI) and `NSGlassEffectView` (AppKit). Must use `#available(macOS 26.0, *)` checks to keep macOS 14 as minimum target. Key areas: overlay background (replace `.ultraThinMaterial`), traffic light buttons, footer controls, deck editor toolbar. Note: standard components (toolbars, sidebars, sheets) get Liquid Glass automatically when compiled with Xcode 26 — custom views need explicit adoption. Limit to 5-10 glass views for performance. Use `GlassEffectContainer` when grouping multiple glass elements.

{PRMT-006} **Add Mission Control backlog sync workflow**
   Add `.github/workflows/sync-backlog.yml` so this repo's `docs/backlog.md` syncs to Mission Control on every push to `main` (and via manual `workflow_dispatch`). Copy the canonical template and instructions from the Mission Control repo at `docs/backlog-sync-workflow.md`. Set `PROJECT_SLUG` to this repo's project slug in Mission Control and add the `INGEST_API_KEY` repo secret (key will be provided separately).

3. ~~**Replace NSAlert dialogs with custom NSPanel**~~  **DONE**
   Replaced NSAlert with ThemedPanelWindow (NSPanel subclass) + SwiftUI views (TimeInputPanelView, DeckPickerPanelView) for consistent themed styling.

4. ~~**Migrate from Carbon hotkeys to CGEvent tap**~~  **DONE**
   Replaced Carbon Event Manager with CGEvent tap. Added AXIsProcessTrustedWithOptions for accessibility permission prompting and auto-retry on first launch.

## Medium Priority

5. ~~**Add unit tests for timer logic**~~  **DONE**
   Added 33 tests in TimerTests.swift covering configuration, state machine, toggle cycle, card navigation, and real-time tick behavior.

6. ~~**Accessibility audit**~~  **DONE**
   Full audit completed Feb 2026. All four implementation phases completed:

   ~~**Phase 1 — Accessibility announcements (Critical)**~~ **DONE**
   Added `postAccessibilityAnnouncement()` helper to AppState. All hotkey-driven state changes announced. Window accessibility roles/titles added to OverlayWindow, EditorWindow, ThemedPanelWindow, and TestCaptureWindow.

   ~~**Phase 2 — VoiceOver labels (High)**~~ **DONE**
   Added `.accessibilityLabel()` and `.accessibilityHint()` to all icon buttons, image drop zones, sliders, toggles, and text fields across all editor and overlay views. Added `accessibilityDescription` to `LayoutType` and `accessibilitySummary` to `Card`. Labeled menu items with `.accessibilityHelp()`.

   ~~**Phase 3 — Keyboard navigation (Medium)**~~ **DONE**
   Added Browse button (fileImporter) to ImageDropZone, Move Up/Down context menu items for card reordering, bullet move buttons replacing drag handles in TitleBulletsEditorView, and @FocusState auto-focus for new bullet fields.

   ~~**Phase 4 — Dynamic Type (Medium)**~~ **DONE**
   Replaced hardcoded font sizes in CardListSidebar and OverlayFooterView with Dynamic Type equivalents (`.caption2`, `.footnote`, `.callout`, etc.). Overlay renderers kept as-is with `fontScale` multiplier.

{PRMT-002} **Export/import decks**
   Allow users to share decks as `.prompter` files (JSON + bundled assets).

## Low Priority

{PRMT-003} **Keyboard shortcut customization**
   Let users rebind global hotkeys from a settings panel.

{PRMT-004} **Deck templates**
   Pre-built deck templates for common presentation scenarios.

{PRMT-005} **Overlay position presets**
    Quick-select overlay positions (top-right, bottom-left, etc.) instead of manual drag.
