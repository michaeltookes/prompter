# How Prompter Works

This document explains the app's architecture in plain English. No programming knowledge required.

## The Big Picture

Prompter has four main parts that work together:

```
┌─────────────────────────────────────────────────────────┐
│                    Your Mac Screen                       │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────┐                                    │
│  │  Menu Bar Icon  │ ← Control center (always visible)  │
│  └─────────────────┘                                    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                                                  │   │
│  │              Your Demo / App                     │   │
│  │                                                  │   │
│  │     ┌─────────────────────┐                     │   │
│  │     │                     │                     │   │
│  │     │   Overlay Window    │ ← Your notes        │   │
│  │     │   (floating above)  │   (only you see)    │   │
│  │     │                     │                     │   │
│  │     └─────────────────────┘                     │   │
│  │                                                  │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Deck Editor Window                  │   │ ← Where you
│  │  (only open when creating/editing notes)         │   │   create notes
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## The Four Parts

### 1. Menu Bar Icon
**What it is**: A small icon in your menu bar (top-right of screen)

**What it does**:
- Click to see options (show overlay, open editor, etc.)
- Provides quick access without cluttering your dock
- Shows the app is running

**Why it's there**: During demos, you want minimal distractions. A menu bar app stays out of the way but is always accessible.

### 2. Overlay Window
**What it is**: A special floating window that displays your notes

**What makes it special**:
- Floats above all other windows (even full-screen apps)
- Transparent background with frosted glass effect
- Can be set to ignore mouse clicks (click-through mode)
- Can be hidden from screen capture (Protected Mode)

**How you interact with it**:
- Keyboard shortcuts to show/hide and navigate
- Drag to reposition
- Resize by dragging edges

### 3. Deck Editor
**What it is**: A standard window where you create and edit your notes

**What it does**:
- Create new decks (collections of cards)
- Add, edit, delete, and reorder cards
- Choose layouts for each card
- Drag-and-drop images into cards

**When you use it**: Before your presentation, not during.

### 4. Background Brain (App State)
**What it is**: The invisible coordinator that keeps everything in sync

**What it does**:
- Remembers which deck is open
- Tracks which card you're on
- Saves your work automatically
- Responds to keyboard shortcuts

**You never see it**: But it's the reason everything "just works."

## How Information Flows

```
You press Cmd+Shift+→ (Next Card)
        ↓
Keyboard Shortcut System catches it
        ↓
App State updates: "Now on card 3"
        ↓
Overlay Window redraws to show card 3
```

Everything is reactive - when something changes, all the parts that need to know get updated automatically.

## Where Your Data Lives

Your decks and settings are stored on your Mac:

```
~/Library/Application Support/Prompter/
├── Decks/
│   └── your-deck-id.json    ← Your cards and content
├── Assets/
│   └── image-files.png      ← Images you've added
└── Settings.json            ← Your preferences
```

This means:
- Your data stays on your computer (not in the cloud)
- You can back it up with normal file backups
- Uninstalling the app doesn't automatically delete your decks

---

Next: [Why a Menu Bar App?](why-menu-bar-app.md)
