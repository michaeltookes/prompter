# Prompter Agent Guide

## Purpose
This file is the shared grounding doc for anyone working in this repo.
Read this before making changes.

## Quick Start
1. Read the relevant spec in `.claude/reference-docs/` before implementing.
2. Follow the SwiftUI + AppKit hybrid architecture.
3. Use Theme constants and dynamic values/tokens where available; avoid hardcoded literals (colors, sizes, timings, limits) when values can be derived from app state, system APIs, or shared config.
4. Validate global hotkeys work system-wide (not just app-focused).
5. Verify overlay behavior in fullscreen and across Spaces.
6. Check the **backlog** document (maintained separately, not in repo) for prioritized planned work — ask the user for the file path when needed.

## Tech Stack
- Language: Swift 5.9+
- UI: SwiftUI (views) + AppKit (window management)
- Target: macOS 14.0+
- App type: Menu bar only (LSUIElement = YES)
- Persistence: JSON in `~/Library/Application Support/Prompter/`

## Core Architecture
Prompter/
- App/        app lifecycle, state, menu bar
- Windows/    NSWindow controllers
- Views/      SwiftUI views (DeckEditor, Overlay, Shared)
- Models/     Deck, Card, Settings
- Services/   persistence, hotkeys, assets
- Extensions/ theme definitions
- Resources/  assets, Info.plist

## Key Concepts
- Deck: collection of cards with metadata.
- Card: single presenter content unit with layout.
- LayoutType: six templates (TITLE_BULLETS, TITLE_NOTES, IMAGE_TOP_NOTES, TWO_IMAGES_NOTES,
  GRID_2X2_CAPTION, FULL_BLEED_IMAGE_3_BULLETS).
- AssetRef: reference to images stored in Assets folder.
- Overlay window: borderless, floating, all Spaces, click-through, Protected Mode.

## Global Hotkeys (Cmd+Shift)
- O: toggle overlay
- Left/Right: previous/next card
- = / -: increase/decrease font size
- Up/Down: scroll overlay content
- C: toggle click-through
- P: toggle Protected Mode
- ] / [: increase/decrease overlay opacity
- T: start/pause/resume timer

## Storage Layout
~/Library/Application Support/Prompter/
- Decks/<deckId>.json
- Assets/<assetUuid>.<ext>
- Settings.json

## Reference Specs
All reference docs live in `.claude/reference-docs/`:
- PRODUCT_REQUIREMENTS.md
- PROJECT_STRUCTURE.md
- DATA_MODEL.md
- UI_UX_STYLE_GUIDE.md
- HOTKEYS_SPEC.md
- OVERLAY_WINDOW_SPEC.md
- OVERLAY_UI_SPEC.md
- UI_SPEC.md
- PERSISTENCE_SPEC.md
- CAPTURE_PROTECTION.md
- STATE_MANAGEMENT.md
- IMAGE_HANDLING.md
- ENGINEERING_NOTES.md

## Testing Checklist
- Menu bar only (no dock icon)
- Hotkeys work globally
- Overlay floats above all windows including fullscreen
- Click-through ignores mouse events
- Protected Mode excludes overlay from capture
- Decks persist across app restarts
- Images render in all layouts

## Important Notes
1. Protected Mode is best-effort. Test before presentations.
2. Global hotkeys use a CGEvent tap (requires Accessibility permissions, prompted on first launch).
3. LSUIElement must remain YES in Info.plist.
4. Accessibility permissions are required for hotkeys. The app auto-prompts and retries after 5 seconds.
5. Auto-save uses a 0.5s debouncer.
6. Sparkle auto-update is configured. Keep SUEnableAutomaticChecks aligned with valid SUFeedURL/SUPublicEDKey values (disable only when placeholders are used).
7. Prefer dynamic values over hardcoded constants whenever possible (theme tokens, system colors, derived counts, and centralized config values).
