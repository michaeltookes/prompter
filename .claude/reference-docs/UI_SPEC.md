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

---

### Main Editor Canvas

Card appears centered with drop zones.

Top Toolbar:
- Layout Selector (dropdown)
- Insert Image
- Paste Image
- Move Card Up/Down

---

## 5 Layout Templates (Editor View)

### 1) Title + Notes
[ Title Field ]
[ Notes Field (multi-line) ]

### 2) Image Top + Notes Bottom
[ Image Drop Zone ]
[ Notes Field ]

### 3) Two Images + Notes
[ Image Slot ] [ Image Slot ]
[ Notes Field ]

### 4) 2x2 Image Grid + Caption
[ Img ][ Img ]
[ Img ][ Img ]
[ Caption Field ]

### 5) Full Image + 3 Bullets
[ Large Image Slot ]
• Bullet 1
• Bullet 2
• Bullet 3

All image slots:
- Dashed glowing border when empty
- Drag highlight when hovering file

