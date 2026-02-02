# Phase 3: Persistence & Polish

**Status**: Not Started
**Depends on**: Phase 2 completion

## What We're Building

The finishing touches that make the app feel complete:
- Automatic saving of decks
- Settings that persist across restarts
- Test Capture instructions window
- UI polish and edge case handling

## Goals

By the end of Phase 3, we should have:
1. Decks automatically saved as you edit
2. Settings persisting across app restarts
3. Overlay position/size remembered
4. Last opened deck loaded on launch
5. Test Capture window with instructions
6. Polished UI matching the style guide
7. Graceful handling of edge cases

## Components Being Built

### 1. Persistence Service
| File | Purpose |
|------|---------|
| PersistenceService.swift | JSON read/write operations |
| Debouncer.swift | Prevents excessive saves |

### 2. Test Capture Window
| File | Purpose |
|------|---------|
| TestCaptureWindowController.swift | Window management |
| TestCaptureView.swift | Instructions UI |

### 3. Additional Models
| File | Purpose |
|------|---------|
| OverlayFrame.swift | Window position/size |

### 4. UI Polish
- Card transition animations (fade + slide)
- Hover-reveal control strip on overlay
- Glow effects and shadows per style guide
- Footer with card counter and mode indicators

## Build Log

*This section will be updated as we build Phase 3.*

(Phase 3 not yet started)

## Persistence Design

### Auto-Save
- Changes save automatically (no manual save button)
- We use a "debouncer" to wait until typing stops
- This prevents saving on every keystroke

### File Structure
```
~/Library/Application Support/Prompter/
├── Decks/
│   └── {deck-id}.json     # Each deck in its own file
├── Assets/
│   └── {asset-id}.png     # Images copied here
└── Settings.json          # User preferences
```

### What Gets Saved
**In each deck file:**
- Deck title
- All cards (content, layout, image references)
- Created/updated timestamps

**In Settings.json:**
- Overlay opacity
- Overlay font scale
- Overlay position and size
- Click-through mode state
- Protected mode state
- Last opened deck ID

## Edge Cases to Handle

| Situation | How We Handle It |
|-----------|------------------|
| No decks exist | Create a default deck with sample card |
| Referenced image deleted | Show placeholder, don't crash |
| Settings file corrupted | Use defaults, log warning |
| App force-quit | Auto-save should have captured recent changes |
| Very old deck format | Migration (future consideration) |

## UI Polish Details

### Card Transitions
- Animation: Fade + slight horizontal slide
- Duration: 150-200ms
- Easing: ease-in-out
- Should feel snappy, not sluggish

### Overlay Footer
Shows:
- Current card number (e.g., "3 / 12")
- Protected mode indicator (shield icon)
- Click-through indicator (cursor icon)

### Control Strip
- Appears when hovering over overlay
- Font size +/- buttons
- Opacity slider
- Fades out when not hovering

### Visual Refinements
- Frosted glass background (per style guide)
- Subtle glow/shadow on overlay window
- Consistent corner radii throughout
- Proper spacing and typography

## Verification Checklist

Once Phase 3 is complete, we'll verify:

- [ ] Create deck, quit app, relaunch - deck is there
- [ ] Change settings, restart - settings preserved
- [ ] Move/resize overlay, restart - position remembered
- [ ] Last opened deck loads automatically
- [ ] Auto-save works (edit, force quit, verify saved)
- [ ] Test Capture window opens and displays instructions
- [ ] Empty state looks good (no decks)
- [ ] Missing image shows placeholder
- [ ] Card transitions are smooth
- [ ] Footer shows correct information
- [ ] Control strip appears on hover
- [ ] All UI matches style guide

## After Phase 3

With Phase 3 complete, we'll have a **fully functional MVP**:
- Complete feature set as specified
- Polished user experience
- Reliable data persistence

Future work might include:
- Export/import of decks
- Additional layout templates
- Cloud sync (iCloud)
- Team sharing features
- Integration with presentation tools
