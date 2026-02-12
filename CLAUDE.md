# Prompter - Claude Agent Grounding Document

## Project Overview

**Prompter** is a macOS 14+ menu bar application designed for sales representatives and solution architects to display hidden speaker notes during technical demonstrations. The overlay window remains visible only to the presenter while screen-sharing in Google Meet or Microsoft Teams.

## Quick Start for Agents

When working on this project:
1. Read the relevant spec file in `.claude/reference-docs/` before implementing a feature
2. Follow the SwiftUI/AppKit hybrid architecture pattern
3. Use established Theme constants and dynamic values/tokens where possible; avoid hardcoded literals when values can be derived from state, system APIs, or shared config
4. Test hotkeys work system-wide (not just when app is focused)
5. Verify overlay behavior in fullscreen and across Spaces
6. Check the **backlog** document (maintained separately, not in repo) for prioritized planned work — ask the user for the file path if you don't already have it in context.
7. Keep the backlog up to date: when completing backlog items during a session, mark them as done with a brief summary of what was implemented. When asked to update the backlog, ask the user for the file path if not already known.

## Tech Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (views) + AppKit (window management)
- **Minimum Target**: macOS 14.0 Sonoma
- **App Type**: Menu bar only (LSUIElement = YES)
- **Persistence**: JSON files in ~/Library/Application Support/Prompter/

## Core Architecture

```
Prompter/
├── App/                    # App lifecycle, state, menu bar
├── Windows/                # NSWindow controllers for overlay, editor
├── Views/                  # SwiftUI views organized by feature
│   ├── DeckEditor/         # Card editing UI
│   ├── Overlay/            # Presenter overlay rendering
│   └── Shared/             # Reusable components
├── Models/                 # Data types (Deck, Card, Settings)
├── Services/               # Business logic (persistence, hotkeys, assets)
├── Extensions/             # Swift extensions and theme definitions
└── Resources/              # Assets and configuration
```

## Key Concepts

### Deck & Card System
- **Deck**: Collection of presenter cards with metadata
- **Card**: Single presenter content unit with a specific layout
- **LayoutType**: One of 6 templates (TITLE_BULLETS, TITLE_NOTES, IMAGE_TOP_NOTES, TWO_IMAGES_NOTES, GRID_2X2_CAPTION, FULL_BLEED_IMAGE_3_BULLETS)
- **AssetRef**: Reference to image file stored in Assets folder

### Overlay Window
- Borderless, transparent NSWindow floating above all apps
- Visible on all Spaces including fullscreen applications
- Supports click-through mode (ignores mouse events)
- Supports Protected Mode (attempts capture exclusion via `sharingType = .none`)

### Global Hotkeys
All hotkeys use Cmd+Shift modifier and must work system-wide:
| Hotkey | Action |
|--------|--------|
| Cmd+Shift+O | Toggle overlay visibility |
| Cmd+Shift+← / → | Previous/Next card |
| Cmd+Shift+= / - | Increase/Decrease font size |
| Cmd+Shift+↑ / ↓ | Scroll overlay content |
| Cmd+Shift+C | Toggle click-through mode |
| Cmd+Shift+P | Toggle Protected Mode |
| Cmd+Shift+] | Increase overlay opacity |
| Cmd+Shift+[ | Decrease overlay opacity |
| Cmd+Shift+T | Start/Pause/Resume timer |

## Data Models (from .claude/reference-docs/DATA_MODEL.md)

```swift
// Deck: Collection of cards
struct Deck: Identifiable, Codable {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var cards: [Card]
    var currentCardIndex: Int
}

// Card: Single presenter content
struct Card: Identifiable, Codable {
    var id: UUID
    var layout: LayoutType
    var title: String?        // For TITLE_BULLETS and TITLE_NOTES
    var notes: String?        // For notes layouts
    var bullets: [String]?    // For bullet layouts
    var caption: String?      // For GRID_2X2_CAPTION
    var imageSlots: [AssetRef?]  // Size depends on layout
}

// 6 Layout Types with image slot counts
enum LayoutType: String, Codable {
    case titleBullets = "TITLE_BULLETS"           // 0 images
    case titleNotes = "TITLE_NOTES"               // 0 images
    case imageTopNotes = "IMAGE_TOP_NOTES"        // 1 image
    case twoImagesNotes = "TWO_IMAGES_NOTES"      // 2 images
    case grid2x2Caption = "GRID_2X2_CAPTION"      // 4 images
    case fullBleedBullets = "FULL_BLEED_IMAGE_3_BULLETS"  // 1 image
}
```

## UI Theme (from .claude/reference-docs/UI_UX_STYLE_GUIDE.md)

```swift
// Color Palette — OVERLAY ONLY (dark frosted glass surface)
let surfaceBackground = Color(rgba: 25, 27, 32, 0.85)  // Frosted dark glass
let accent = Color(hex: "5DA9FF")                       // Soft electric blue
let secondaryAccent = Color(hex: "7A86FF")              // Muted indigo
let textPrimary = Color(hex: "F5F7FA")                  // ⚠️ OVERLAY ONLY
let textSecondary = Color(hex: "B8C1CC")                // ⚠️ OVERLAY ONLY
let divider = Color.white.opacity(0.08)                 // ⚠️ OVERLAY ONLY
let accentGlow = Color(hex: "5DA9FF").opacity(0.35)

// Typography (SF Pro)
// Overlay renderers use hardcoded sizes with fontScale multiplier — keep as-is
let titleSize = 26-32pt Semibold
let notesSize = 18-22pt Regular
let captionSize = 16pt Regular
let footerSize = 13pt Medium

// Editor sidebar & overlay footer use Dynamic Type (v1.2.0+)
// .caption2 (11pt), .footnote (13pt), .callout (16pt), etc.
// These scale with user accessibility settings

// Corner Radii
let overlayWindow = 18px
let cards = 16px
let imageSlots = 14px
let buttons = 10px
```

### Light Mode / Dark Mode Color Rules

The app has **two color contexts** that must not be mixed:

| Context | Text Color | Secondary Text | Border | Used In |
|---------|-----------|---------------|--------|---------|
| **Overlay** (dark glass) | `Theme.textPrimary` (#F5F7FA) | `Theme.textSecondary` (#B8C1CC) | `Theme.divider` | `Views/Overlay/`, `ThemedPanelWindow` panels |
| **Editor** (system bg) | `Theme.editorTextPrimary` | `Theme.editorTextSecondary` | `Theme.editorBorder` | `Views/DeckEditor/`, sidebar, canvas |

The editor tokens use `NSColor.labelColor`, `NSColor.secondaryLabelColor`, and `NSColor.separatorColor` which automatically adapt to Light/Dark Mode (black text in Light Mode, white text in Dark Mode).

**Never use `Theme.textPrimary`, `Theme.textSecondary`, or `Theme.divider` in editor views** — they are hardcoded white-on-dark values that become invisible on light backgrounds.

## File Storage (from .claude/reference-docs/PERSISTENCE_SPEC.md)

```
~/Library/Application Support/Prompter/
├── Decks/
│   └── <deckId>.json       # Individual deck files
├── Assets/
│   └── <assetUuid>.<ext>   # Imported images (renamed to UUID)
└── Settings.json           # App settings
```

## Implementation Phases

### Phase 1: Core Infrastructure
- Xcode project setup with LSUIElement
- AppState central state container
- Menu bar with dropdown (NSStatusItem)
- Overlay window with capture protection
- Global hotkey registration (CGEvent tap)
- Basic card navigation

### Phase 2: Deck Editor & Layouts
- Deck editor window (split view)
- Card list sidebar with thumbnails
- All 6 layout editor views
- All 6 layout overlay renderers
- Image drag-and-drop handling
- Asset management service

### Phase 3: Persistence & Polish
- JSON persistence (auto-save with debounce)
- Settings persistence
- Window frame persistence
- Test Capture instructions window
- UI polish and animations
- Error handling

## Specification Files Reference

All reference specs live in `.claude/reference-docs/`.

| File | Purpose |
|------|---------|
| .claude/reference-docs/PRODUCT_REQUIREMENTS.md | Core problem, MVP outcomes, acceptance criteria |
| .claude/reference-docs/PROJECT_STRUCTURE.md | File/folder architecture |
| .claude/reference-docs/DATA_MODEL.md | All data structures |
| .claude/reference-docs/UI_UX_STYLE_GUIDE.md | Colors, typography, design tokens |
| .claude/reference-docs/HOTKEYS_SPEC.md | Global hotkey definitions |
| .claude/reference-docs/OVERLAY_WINDOW_SPEC.md | Overlay technical requirements |
| .claude/reference-docs/OVERLAY_UI_SPEC.md | Overlay visual design |
| .claude/reference-docs/UI_SPEC.md | Menu bar and editor UI specs |
| .claude/reference-docs/PERSISTENCE_SPEC.md | File storage structure |
| .claude/reference-docs/CAPTURE_PROTECTION.md | Protected Mode implementation |
| .claude/reference-docs/STATE_MANAGEMENT.md | AppState architecture |
| .claude/reference-docs/IMAGE_HANDLING.md | Asset import workflow |
| .claude/reference-docs/ENGINEERING_NOTES.md | Tech stack and strategies |

## Accessibility (v1.2.0+)

The app has full accessibility support across four areas:

1. **VoiceOver Announcements**: All hotkey-driven state changes (overlay toggle, card navigation, timer, font size, opacity, click-through, Protected Mode) are announced via `postAccessibilityAnnouncement()` in AppState.
2. **VoiceOver Labels**: All interactive controls have `.accessibilityLabel()` and `.accessibilityHint()`. `LayoutType` has `accessibilityDescription`, `Card` has `accessibilitySummary`.
3. **Keyboard Navigation**: Image drop zones have a "Browse" button (fileImporter). Cards have "Move Up/Down" context menu items. Bullets have reorder buttons. New bullets auto-focus via `@FocusState`.
4. **Dynamic Type**: Editor sidebar (`CardListSidebar`) and overlay footer (`OverlayFooterView`) use SwiftUI Dynamic Type text styles (`.caption2`, `.footnote`, `.callout`). Overlay renderers keep hardcoded sizes with `fontScale` multiplier.

## Testing Checklist

- [ ] App launches as menu bar only (no dock icon)
- [ ] Hotkeys work system-wide during presentations
- [ ] Overlay floats above all windows including fullscreen
- [ ] Click-through mode ignores mouse events
- [ ] Protected Mode excludes overlay from screen capture
- [ ] Decks persist across app restarts
- [ ] Images render correctly in all layouts
- [ ] VoiceOver reads all controls correctly
- [ ] Browse button opens file picker in empty image drop zones
- [ ] Move Up/Down works in card context menu and bullet reorder buttons

## Release Configuration

Referenced by the `/release-prep` skill:

| Key | Value |
|-----|-------|
| Release branch | `main` |
| Version file | `Prompter/Prompter/Resources/Info.plist` |
| Version keys | `CFBundleShortVersionString`, `CFBundleVersion` |
| Additional version file | `Prompter/Prompter.xcodeproj/project.pbxproj` — update `MARKETING_VERSION` (4 occurrences) and `CURRENT_PROJECT_VERSION` (4 occurrences) to match Info.plist |
| Changelog | `CHANGELOG.md` (Keep a Changelog format) |
| Build script | `cd Prompter && ./scripts/build-release.sh` |
| Notarize script | `cd Prompter && ./scripts/notarize.sh` |
| DMG script | `cd Prompter && ./scripts/create-dmg.sh` |
| Publish script | `cd Prompter && ./scripts/publish-release.sh` (signs zip with EdDSA, updates appcast, commits/pushes, creates GitHub Release) |
| Release artifacts | `Prompter/dist/Prompter.zip`, `Prompter/dist/Prompter.dmg` |
| Tag format | `v{VERSION}` |
| Asset naming | `Prompter.zip`, `Prompter.dmg` (no version in filename) |
| GitHub repo | `michaeltookes/prompter` |
| Sparkle appcast script | Handled by `publish-release.sh` |
| Sparkle appcast URL | `https://michaeltookes.github.io/prompter/appcast.xml` |
| Sparkle appcast file | `appcast.xml` (repo root, served by GitHub Pages from `main`) |
| Homebrew tap location | `~/Desktop/homebrew-prompter/` |
| Homebrew cask file | `Casks/prompter.rb` |
| Homebrew cask URL template | `https://github.com/michaeltookes/prompter/releases/download/v{VERSION}/Prompter.dmg` |
| Notarization keychain profile | `Prompter-Notarize` (hardcoded in `notarize.sh`) |
| Validation script | *Not yet implemented* |

## Important Notes

1. **Protected Mode is Best-Effort**: `NSWindow.sharingType = .none` may not work with all capture tools. Always include a disclaimer and test instructions.

2. **CGEvent Tap Hotkeys**: Global hotkeys use a CGEvent tap (migrated from deprecated Carbon Event Manager). Requires Accessibility permissions — the app prompts automatically on first launch via `AXIsProcessTrustedWithOptions` with a 5-second retry.

3. **Sparkle Auto-Update**: Sparkle 2.x is integrated via SPM. The appcast is hosted via GitHub Pages at `https://michaeltookes.github.io/prompter/appcast.xml`. The `SUFeedURL` and `SUPublicEDKey` in `Info.plist` are configured for production. Generate an EdDSA keypair with Sparkle's `generate_keys` tool. The appcast XML lives in the repo root on `main` and is served by GitHub Pages.

4. **LSUIElement**: Must be set to YES in Info.plist for menu bar-only behavior.

5. **Accessibility Permissions**: Required for global hotkeys (CGEvent tap). The app prompts the user on first launch and retries registration after 5 seconds.

6. **Auto-Save**: Use 0.5s debouncer to avoid excessive disk writes during editing.

7. **No Hardcoded Values**: Never hardcode values when a dynamic or system-provided alternative exists. Use Dynamic Type text styles (`.footnote`, `.caption2`, etc.) instead of `.system(size: N)` in editor and footer views. Use `NSColor.labelColor` / `NSColor.secondaryLabelColor` instead of hardcoded color hex values for system-context views. Use system-provided constants, enum cases, and configuration values rather than magic numbers or string literals. The only exception is overlay renderers, which intentionally use hardcoded sizes scaled by the `fontScale` multiplier.
