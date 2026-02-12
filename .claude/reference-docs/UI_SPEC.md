# UI Spec — Deck Mode Overlay (Modern macOS)

## Menu Bar Dropdown

Prompter
────────────────────
Show Overlay
Open Deck Editor…
────────────────────
✔ Protected Mode
☐ Click-through Overlay
────────────────────
Timer                 ▸
  ☐ Enable Timer
  ────────────────────
  Mode: Deck Total
  Mode: Per Card
  ────────────────────
  Set Deck Time…
  Set Per-Card Time…
  ────────────────────
  Apply To: All Decks
  Apply To: Selected Decks…
────────────────────
Test Capture Setup…
Check for Updates…
Quit

Protected Mode disclaimer:
- Protected Mode is best-effort. It uses `NSWindow.sharingType = .none`, which may not be honored by all capture tools.

Test Capture Setup:
- Open `Test Capture Setup…` from the menu bar.
- Enable Protected Mode and start a screen share/recording test.
- Expected outcome: overlay remains visible locally, but is not visible in the captured/shared output.

Menu appearance:
- Frosted dark background
- Thin separators
- Soft blue hover highlight

---

## Deck Editor Window

### Layout
Left Sidebar — Card Navigator  
Main Area — Card Canvas Editor  

---

### Sidebar (Card List)

Appearance:
- Vertical list with rounded card thumbnails
- Subtle glow around selected card
- Card number + layout icon + title

Controls at bottom:
+ Add Card
Duplicate
Delete

Context menu (right-click card):
- Move Up (disabled at top)
- Move Down (disabled at bottom)
- Duplicate
- Delete

---

### Main Editor Canvas

Card appears centered with drop zones.

Top Toolbar:
- Layout Selector (dropdown)
- Insert Image
- Paste Image
- Move Card Up/Down

---

## 6 Layout Templates (Editor View)

### 1) Title + Bullets
[ Title Field ]
[ Bullet List (add/remove/reorder via up/down buttons) ]

### 2) Title + Notes
[ Title Field ]
[ Notes Field (multi-line) ]

### 3) Image Top + Notes Bottom
[ Image Drop Zone ]
[ Notes Field ]

### 4) Two Images + Notes
[ Image Slot ] [ Image Slot ]
[ Notes Field ]

### 5) 2x2 Image Grid + Caption
`[ Img ]` `[ Img ]`
`[ Img ]` `[ Img ]`
[ Caption Field ]

### 6) Full Image + 3 Bullets
[ Large Image Slot ]
• Bullet 1
• Bullet 2
• Bullet 3

All image slots:
- Dashed glowing border when empty
- Drag highlight when hovering file
- "Browse" button in empty state opens file picker (fileImporter)
- Remove button (x) overlay on existing images
