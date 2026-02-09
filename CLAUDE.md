# Prompter - Claude Agent Grounding Document

## Project Overview

**Prompter** is a macOS 14+ menu bar application designed for sales representatives and solution architects to display hidden speaker notes during technical demonstrations. The overlay window remains visible only to the presenter while screen-sharing in Google Meet or Microsoft Teams.

## Quick Start for Agents

When working on this project:
1. Read the relevant spec file in `.claude/reference-docs/` before implementing a feature
2. Follow the SwiftUI/AppKit hybrid architecture pattern
3. Use the established Theme constants for all UI styling
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
- **LayoutType**: One of 5 templates (TITLE_BULLETS, IMAGE_TOP_NOTES, TWO_IMAGES_NOTES, GRID_2X2_CAPTION, FULL_BLEED_IMAGE_3_BULLETS)
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
    var title: String?        // For TITLE_BULLETS
    var notes: String?        // For notes layouts
    var bullets: [String]?    // For bullet layouts
    var caption: String?      // For GRID_2X2_CAPTION
    var imageSlots: [AssetRef?]  // Size depends on layout
}

// 5 Layout Types with image slot counts
enum LayoutType: String, Codable {
    case titleBullets = "TITLE_BULLETS"           // 0 images
    case imageTopNotes = "IMAGE_TOP_NOTES"        // 1 image
    case twoImagesNotes = "TWO_IMAGES_NOTES"      // 2 images
    case grid2x2Caption = "GRID_2X2_CAPTION"      // 4 images
    case fullBleedBullets = "FULL_BLEED_IMAGE_3_BULLETS"  // 1 image
}
```

## UI Theme (from .claude/reference-docs/UI_UX_STYLE_GUIDE.md)

```swift
// Color Palette
let surfaceBackground = Color(rgba: 25, 27, 32, 0.85)  // Frosted dark glass
let accent = Color(hex: "5DA9FF")                       // Soft electric blue
let secondaryAccent = Color(hex: "7A86FF")              // Muted indigo
let textPrimary = Color(hex: "F5F7FA")
let textSecondary = Color(hex: "B8C1CC")
let divider = Color.white.opacity(0.08)
let accentGlow = Color(hex: "5DA9FF").opacity(0.35)

// Typography (SF Pro)
let titleSize = 26-32pt Semibold
let notesSize = 18-22pt Regular
let captionSize = 16pt Regular
let footerSize = 13pt Medium

// Corner Radii
let overlayWindow = 18px
let cards = 16px
let imageSlots = 14px
let buttons = 10px
```

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
- All 5 layout editor views
- All 5 layout overlay renderers
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

## Testing Checklist

- [ ] App launches as menu bar only (no dock icon)
- [ ] Hotkeys work system-wide during presentations
- [ ] Overlay floats above all windows including fullscreen
- [ ] Click-through mode ignores mouse events
- [ ] Protected Mode excludes overlay from screen capture
- [ ] Decks persist across app restarts
- [ ] Images render correctly in all layouts

## Important Notes

1. **Protected Mode is Best-Effort**: `NSWindow.sharingType = .none` may not work with all capture tools. Always include a disclaimer and test instructions.

2. **CGEvent Tap Hotkeys**: Global hotkeys use a CGEvent tap (migrated from deprecated Carbon Event Manager). Requires Accessibility permissions — the app prompts automatically on first launch via `AXIsProcessTrustedWithOptions` with a 5-second retry.

3. **Sparkle Auto-Update**: Sparkle 2.x is integrated via SPM. `Info.plist` contains placeholder values for `SUFeedURL` and `SUPublicEDKey` that must be replaced before shipping. Generate an EdDSA keypair with Sparkle's `generate_keys` tool and host an `appcast.xml` alongside GitHub Releases.

4. **LSUIElement**: Must be set to YES in Info.plist for menu bar-only behavior.

5. **Accessibility Permissions**: Required for global hotkeys (CGEvent tap). The app prompts the user on first launch and retries registration after 5 seconds.

6. **Auto-Save**: Use 0.5s debouncer to avoid excessive disk writes during editing.
