# Phase 1: Core Infrastructure

**Status**: In Progress
**Started**: January 2026

## What We're Building

The foundation of Presenter Overlay:
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
| PresenterOverlayApp.swift | App entry point |
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
**Date**: [Current]

Created the docs/ folder structure with:
- Overview documentation (what, who, features)
- Architecture documentation (how it works, component diagram)
- Decision log with rationale for key choices
- Glossary for non-technical readers

**Why documentation first?**: We want to explain decisions as we make them, not try to remember later. Also, writing documentation helps clarify our thinking.

---

*More entries will be added as we progress through Phase 1.*

## Challenges Encountered

*This section documents problems we ran into and how we solved them.*

(No challenges logged yet - Phase 1 in progress)

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
