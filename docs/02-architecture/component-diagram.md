# Component Diagram

This diagram shows how the parts of Presenter Overlay connect to each other.

## Visual Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PRESENTER OVERLAY                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                        USER INTERFACE                         │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │                                                               │   │
│  │   ┌─────────────┐   ┌─────────────┐   ┌─────────────────┐   │   │
│  │   │  Menu Bar   │   │   Overlay   │   │   Deck Editor   │   │   │
│  │   │   (icon +   │   │   Window    │   │    Window       │   │   │
│  │   │   dropdown) │   │             │   │                 │   │   │
│  │   └──────┬──────┘   └──────┬──────┘   └────────┬────────┘   │   │
│  │          │                 │                    │            │   │
│  └──────────┼─────────────────┼────────────────────┼────────────┘   │
│             │                 │                    │                 │
│             └────────────┬────┴────────────────────┘                 │
│                          │                                           │
│                          ▼                                           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                         APP STATE                             │   │
│  │                    (Central Coordinator)                      │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │  • Current deck              • Overlay visibility             │   │
│  │  • Current card index        • Click-through mode             │   │
│  │  • Font size                 • Protected mode                 │   │
│  └──────────────────────────────────────────────────────────────┘   │
│             │                          │                             │
│             ▼                          ▼                             │
│  ┌────────────────────┐    ┌────────────────────┐                   │
│  │   HOTKEY MANAGER   │    │ PERSISTENCE SERVICE│                   │
│  │                    │    │                    │                   │
│  │ Listens for global │    │ Saves/loads decks  │                   │
│  │ keyboard shortcuts │    │ and settings       │                   │
│  └────────────────────┘    └─────────┬──────────┘                   │
│                                      │                               │
│                                      ▼                               │
│                          ┌────────────────────┐                     │
│                          │    FILE SYSTEM     │                     │
│                          │                    │                     │
│                          │ ~/Library/App.../  │                     │
│                          │  ├── Decks/        │                     │
│                          │  ├── Assets/       │                     │
│                          │  └── Settings.json │                     │
│                          └────────────────────┘                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Component Descriptions

### User Interface Layer

| Component | Purpose | When You See It |
|-----------|---------|-----------------|
| **Menu Bar** | Quick access to all app features | Always (when app is running) |
| **Overlay Window** | Displays your notes during presentations | When toggled on |
| **Deck Editor** | Create and edit your card decks | When editing notes |

### App State (The Brain)

The App State is the central coordinator. It knows:
- Which deck is currently open
- Which card you're viewing
- All your current settings (font size, modes, etc.)

When you press a hotkey or click a menu item, the App State updates, and all the windows automatically reflect the change.

### Services Layer

| Service | Purpose |
|---------|---------|
| **Hotkey Manager** | Listens for keyboard shortcuts even when app isn't focused |
| **Persistence Service** | Saves your work to disk; loads it when app starts |
| **Asset Manager** | Handles images you drag into cards |

### File System

Your data is stored in a folder on your Mac:
- **Decks/**: JSON files containing your cards
- **Assets/**: Images you've added to cards
- **Settings.json**: Your preferences

## How Data Flows

### Example: You Press "Next Card"

```
1. You press Cmd+Shift+→

2. Hotkey Manager detects the keypress
   └─→ Tells App State: "User wants next card"

3. App State updates
   └─→ currentCardIndex: 2 → 3

4. Overlay Window sees the change
   └─→ Redraws to show card #3

5. (Sidebar in Editor also updates if open)
   └─→ Selection moves to card #3
```

### Example: You Add an Image

```
1. You drag an image onto a card in the Editor

2. Asset Manager catches the drop
   └─→ Copies image to Assets/ folder
   └─→ Generates a reference ID

3. App State updates
   └─→ Card now references the new image

4. Editor shows the image in the card

5. Persistence Service saves
   └─→ Deck JSON updated with image reference
```

## Why This Architecture?

### Centralized State
All data flows through App State. This means:
- One source of truth (no conflicting information)
- Easy to understand what's happening
- Changes automatically propagate everywhere

### Separation of Concerns
Each component has one job:
- UI components just display things
- Services just do their specific task
- App State just coordinates

This makes the app easier to understand, test, and modify.

---

Next: [Decision Log](../03-decisions/decision-log.md)
