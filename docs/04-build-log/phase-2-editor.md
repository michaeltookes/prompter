# Phase 2: Deck Editor & Layouts

**Status**: Not Started
**Depends on**: Phase 1 completion

## What We're Building

The deck editor - where users create and organize their presenter cards:
- Split-view editor (sidebar + main canvas)
- All 5 layout templates for editing
- All 5 layout templates for overlay rendering
- Image drag-and-drop support
- Card management (add, delete, duplicate, reorder)

## Goals

By the end of Phase 2, we should have:
1. A deck editor window accessible from the menu
2. Sidebar showing all cards with thumbnails
3. Main editing area for the selected card
4. Working layout selector
5. Image drop zones that accept dragged images
6. All layouts rendering correctly in the overlay
7. Smooth card transition animations

## Components Being Built

### 1. Editor Window
| File | Purpose |
|------|---------|
| DeckEditorWindowController.swift | Editor window management |
| DeckEditorView.swift | Main editor container (split view) |
| CardListSidebar.swift | Left sidebar with card list |
| CardCanvasView.swift | Main editing area |

### 2. Layout Editors (5 files)
Each layout needs an editing interface:
| Layout | Editor File |
|--------|-------------|
| Title + Bullets | TitleBulletsEditorView.swift |
| Image + Notes | ImageTopNotesEditorView.swift |
| Two Images + Notes | TwoImagesNotesEditorView.swift |
| 2x2 Grid + Caption | Grid2x2CaptionEditorView.swift |
| Full Image + Bullets | FullBleedBulletsEditorView.swift |

### 3. Layout Renderers (5 files)
Each layout needs a display version for the overlay:
| Layout | Renderer File |
|--------|---------------|
| Title + Bullets | TitleBulletsRenderer.swift |
| Image + Notes | ImageTopNotesRenderer.swift |
| Two Images + Notes | TwoImagesNotesRenderer.swift |
| 2x2 Grid + Caption | Grid2x2CaptionRenderer.swift |
| Full Image + Bullets | FullBleedBulletsRenderer.swift |

### 4. Shared Components
| File | Purpose |
|------|---------|
| ImageDropZone.swift | Drag-and-drop image handling |
| FrostedPanelView.swift | Frosted glass effect |
| IconButton.swift | Consistent button styling |
| OverlayCardRenderer.swift | Dispatches to correct layout |
| OverlayFooterView.swift | Card counter and status |

### 5. Services
| File | Purpose |
|------|---------|
| AssetManager.swift | Image import and storage |
| ImageCacheService.swift | Thumbnail caching |

### 6. Additional Models
| File | Purpose |
|------|---------|
| AssetRef.swift | Image reference model |

## Build Log

*This section will be updated as we build Phase 2.*

(Phase 2 not yet started)

## Design Decisions

### Editor Layout
We chose a split-view design:
- Left sidebar: Card list with thumbnails
- Right area: Current card editor

This mirrors apps like Keynote and PowerPoint, which users already understand.

### Template-Based Editing
Rather than freeform placement, each layout has fixed zones:
- Text fields where text goes
- Image slots where images go
- No manual positioning

This ensures consistent, readable results.

### Image Handling
When users drag an image:
1. We copy it to our Assets folder
2. We generate a thumbnail for the sidebar
3. We reference it by ID (not file path)

This means decks are self-contained and won't break if the original image moves.

## Challenges Anticipated

- SwiftUI drag-and-drop can be tricky for image handling
- Ensuring smooth animations during card transitions
- Keeping editor and overlay in sync during live editing

## Verification Checklist

Once Phase 2 is complete, we'll verify:

- [ ] Editor opens from menu bar
- [ ] Cards can be created with each layout type
- [ ] Cards can be deleted
- [ ] Cards can be duplicated
- [ ] Cards can be reordered (drag in sidebar)
- [ ] Images can be dragged into slots
- [ ] Images can be removed from slots
- [ ] All layouts look correct in editor
- [ ] All layouts look correct in overlay
- [ ] Card transitions animate smoothly
- [ ] Font size controls work

## What's Next

After Phase 2, we'll move to [Phase 3: Polish](phase-3-polish.md), which adds:
- Persistent storage (decks save to disk)
- Settings persistence
- Test Capture instructions window
- UI polish and edge cases
