# Phase 1: Core Infrastructure

**Status**: In Progress
**Started**: January 2026

## What We're Building

The foundation of Prompter:
- Menu bar app that runs without a dock icon
- Floating overlay window with capture protection
- Global keyboard shortcuts
- Basic card navigation

## Goals

By the end of Phase 1, we should have:
1. A menu bar icon that shows a dropdown menu
2. An overlay window that floats above everything
3. Protected Mode working (overlay hidden from screen capture)
4. Click-through mode working (mouse passes through overlay)
5. Keyboard shortcuts working system-wide
6. Basic hardcoded cards to test with

## Components Being Built

### 1. Project Setup
- Xcode project with proper folder structure
- Info.plist configured for menu bar app (LSUIElement = YES)
- macOS 14.0 minimum deployment target
- Entitlements for accessibility (hotkeys)

### 2. App Foundation
| File | Purpose |
|------|---------|
| PrompterApp.swift | App entry point |
| AppDelegate.swift | Handles app lifecycle events |
| AppState.swift | Central state container |
| MenuBarController.swift | Menu bar icon and dropdown |

### 3. Overlay Window
| File | Purpose |
|------|---------|
| OverlayWindow.swift | Custom window with special behaviors |
| OverlayWindowController.swift | Manages window lifecycle |
| OverlayContentView.swift | The actual content shown |

### 4. Hotkey System
| File | Purpose |
|------|---------|
| HotkeyManager.swift | Registers and handles global shortcuts |

### 5. Data Models
| File | Purpose |
|------|---------|
| Deck.swift | Collection of cards |
| Card.swift | Single presenter note |
| LayoutType.swift | The 5 layout templates |
| Settings.swift | User preferences |

## Build Log

*This section is updated as we build.*

### Entry 1: Documentation Setup
**Date**: January 2026

Created the docs/ folder structure with:
- Overview documentation (what, who, features)
- Architecture documentation (how it works, component diagram)
- Decision log with rationale for key choices
- Glossary for non-technical readers

**Why documentation first?**: We want to explain decisions as we make them, not try to remember later. Also, writing documentation helps clarify our thinking.

---

### Entry 2: Xcode Project Setup
**Date**: January 2026

Created the Prompter Xcode project with:
- Folder structure matching our architecture plan
- Info.plist with LSUIElement=YES (menu bar only app)
- macOS 14.0 deployment target
- Entitlements file (sandbox disabled for hotkey access)
- Assets.xcassets with placeholder AppIcon and AccentColor

**Key decision - LSUIElement**: Setting this to YES makes the app invisible in the Dock. It only appears in the menu bar. This keeps it unobtrusive during demos.

---

### Entry 3: Data Models
**Date**: January 2026

Implemented all core data models:
- **LayoutType**: Enum with 5 layout types, includes helper properties for image slots, bullet counts, etc.
- **AssetRef**: Simple struct for image references with UUID-based filenames
- **Card**: Core presenter note with layout-specific optional fields
- **Deck**: Collection of cards with navigation state
- **Settings**: User preferences including overlay frame

**Design choice - Optional fields in Card**: Each layout type uses different fields (title, notes, bullets, caption). We made them all optional rather than creating separate types per layout. This keeps the model simple while being flexible.

---

### Entry 4: AppState and Core App Structure
**Date**: January 2026

Built the central nervous system:
- **AppState**: ObservableObject with all app state, published properties for reactivity
- **AppDelegate**: Sets up menu bar, overlay, and hotkeys on launch
- **PrompterApp**: SwiftUI app entry point with NSApplicationDelegateAdaptor

**Why centralized state?**: All views observe AppState. When you press a hotkey to advance cards, AppState updates, and the overlay redraws automatically. No manual refresh calls needed.

---

### Entry 5: Menu Bar Controller
**Date**: January 2026

Implemented MenuBarController with:
- NSStatusItem for the menu bar icon
- Dropdown menu with all options
- Placeholder views for editor and test capture windows

**Design note**: The menu rebuilds each time it's shown to reflect current state (overlay visibility, mode toggles). Simple and reliable.

---

### Entry 6: Overlay Window System
**Date**: January 2026

Created the core overlay:
- **OverlayWindow**: Custom NSWindow with special properties
  - Borderless and transparent
  - Floating level (above all windows)
  - canJoinAllSpaces + fullScreenAuxiliary
  - sharingType=.none for capture protection
  - ignoresMouseEvents for click-through
- **OverlayWindowController**: Manages lifecycle with Combine bindings
- **OverlayContentView**: SwiftUI placeholder with frosted glass styling

**The capture protection approach**: We set `sharingType = .none` which requests the window be excluded from screen capture. This is "best effort" - it works for most cases but isn't guaranteed.

---

### Entry 7: Global Hotkeys
**Date**: January 2026

Implemented HotkeyManager using Carbon Event Manager:
- Registers 9 global hotkeys (Cmd+Shift+...)
- Works even when other apps are focused
- Callbacks bound to AppState methods

**Why Carbon?**: Despite being deprecated, it's still the standard for global hotkeys. Many popular apps (Alfred, Rectangle) use it. There's no modern replacement.

---

## Challenges Encountered

### Challenge 1: Xcode Project File Complexity
The .pbxproj file format is complex. We manually created a minimal version that Xcode can open and enhance.

**Solution**: Start with minimal configuration, let Xcode add files as we build.

### Challenge 2: Type Resolution During Development
While creating files, the IDE shows errors because dependent types don't exist yet.

**Solution**: Create files in dependency order (models first, then services, then views). Errors resolve once all files exist.

## Verification Checklist

Once Phase 1 is complete, we'll verify:

- [ ] App launches with menu bar icon
- [ ] No dock icon appears
- [ ] Menu dropdown shows all options
- [ ] Overlay toggles with Cmd+Shift+O
- [ ] Overlay floats above all windows
- [ ] Overlay visible over fullscreen apps
- [ ] Click-through mode works
- [ ] Protected Mode hides from screen recording
- [ ] All navigation hotkeys work
- [ ] Card transitions work

## What's Next

After Phase 1, we'll move to [Phase 2: Deck Editor](phase-2-editor.md), which adds:
- Full deck editing interface
- All 5 layout templates
- Image drag-and-drop support
