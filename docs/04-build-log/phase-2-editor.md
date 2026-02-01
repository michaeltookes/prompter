# Phase 2: Deck Editor & Layouts

**Status**: Complete
**Completed**: January 2026

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

### Entry 1: Shared Components
**Date**: January 2026

Created the reusable UI components for Phase 2:
- **ImageDropZone.swift**: Drag-and-drop handler for image files. Supports common formats (PNG, JPEG, HEIC). Shows visual feedback during drag hover.
- **FrostedPanelView.swift**: Reusable frosted glass panel with customizable corner radius and opacity.
- **IconButton.swift**: Standardized icon button with hover/press states and animations.

---

### Entry 2: Asset Management
**Date**: January 2026

Implemented the AssetManager service for image storage:
- Stores images in `~/Library/Application Support/PresenterOverlay/Assets/`
- Uses UUID-based filenames for uniqueness
- Includes in-memory LRU cache (50 images max)
- Provides import from file URL or raw data
- Cleanup method for removing unused assets

---

### Entry 3: Deck Editor View
**Date**: January 2026

Built the main deck editor UI:
- **DeckEditorView**: HSplitView with sidebar and canvas
- **CardListSidebar**: Card list with layout icons, context menus for duplicate/delete, drag-to-reorder support
- **CardCanvasView**: Layout picker and dynamic layout editor switching

Key features:
- Add cards with layout selection menu
- Delete/duplicate via context menu
- Layout type picker in header
- Automatic scroll to selected card

---

### Entry 4: Layout Editors (5 Views)
**Date**: January 2026

Created editing interfaces for all 5 layouts:
1. **TitleBulletsEditorView**: Title field + dynamic bullet list (add/remove)
2. **ImageTopNotesEditorView**: Single image drop zone + text editor
3. **TwoImagesNotesEditorView**: Side-by-side image zones + notes
4. **Grid2x2CaptionEditorView**: 2x2 grid of drop zones + caption
5. **FullBleedBulletsEditorView**: Hero image + exactly 3 numbered bullets

Each editor uses bindings to update the Card model in real-time.

---

### Entry 5: Layout Renderers (5 Views)
**Date**: January 2026

Created overlay renderers for all 5 layouts:
1. **TitleBulletsRenderer**: Title + bullet list with accent dots
2. **ImageTopNotesRenderer**: Image display + notes text
3. **TwoImagesNotesRenderer**: Side-by-side images + notes
4. **Grid2x2CaptionRenderer**: 2x2 image grid + centered caption
5. **FullBleedBulletsRenderer**: Large hero image + numbered bullets

Each renderer respects the fontScale setting for accessibility.

---

### Entry 6: Overlay Integration
**Date**: January 2026

Updated the overlay window to use the new renderers:
- **OverlayCardRenderer**: Switches to correct renderer based on card layout
- **OverlayFooterView**: Extracted footer with card counter and status icons
- Added transition animations between cards

Card model extended with `images` computed property (alias for `imageSlots`) for cleaner code.

---

### Entry 7: AppState Extensions
**Date**: January 2026

Added methods to AppState for editor operations:
- `loadDeck(_:)` - Load a deck
- `navigateToCard(_:)` - Navigate to card by index
- `addCard(_:)` - Add existing Card object
- `insertCard(_:at:)` - Insert at specific position
- `updateCard(_:at:)` - Update card at index
- `moveCard(from:to:)` - Reorder with Int parameters

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
