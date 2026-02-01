# User Guide

## The Overlay Window

The overlay is a floating window that displays your speaker notes. It stays visible on top of all other windows, including fullscreen apps.

### Moving and Resizing

- **Move**: Drag anywhere on the overlay background, or use the drag handle at the top
- **Resize**: Drag the edges or corners of the window
- **Note**: Click-through mode must be OFF to interact with the overlay

### Footer Status Indicators

The bottom of the overlay shows your current card position and status indicators:

#### Protected Mode Enabled (Safe for Sharing)
- **Blue shield icon** - Your overlay is hidden from screen capture
- Safe to share your screen

#### Protected Mode Disabled (Warning)
- **Yellow warning triangle** with "Visible to capture" message
- Your overlay WILL appear in screen recordings and shares
- Enable Protected Mode before presenting (`Cmd+Shift+P`)

#### Click-through Mode
- **Cursor icon** - Mouse events pass through the overlay
- Useful when you need to interact with windows underneath

## Protected Mode

Protected Mode uses macOS's `NSWindow.sharingType = .none` to exclude the overlay from screen capture. This works with most screen recording and sharing software.

### How to Enable/Disable

- **Menu bar**: Click icon → check/uncheck "Protected Mode"
- **Hotkey**: `Cmd+Shift+P`

### Testing Protected Mode

1. Menu bar → "Test Protected Mode..."
2. Follow the on-screen instructions
3. Start a screen recording or share
4. Verify the overlay is not visible in the capture

### Important Notes

- Always test before important presentations
- Results may vary with some capture software
- The yellow warning appears when Protected Mode is off as a reminder

## Click-through Mode

When enabled, all mouse clicks pass through the overlay to windows underneath. This is useful when you need to interact with your presentation but still see your notes.

### How to Enable/Disable

- **Menu bar**: Click icon → check/uncheck "Click-through Overlay"
- **Hotkey**: `Cmd+Shift+C`

### Note

When click-through is enabled, you cannot move or resize the overlay. Disable it first if you need to reposition the window.

## Creating Decks

### Opening the Deck Editor

- **Menu bar**: Click icon → "Open Deck Editor..."
- The editor window opens with a sidebar (card list) and main canvas (card editor)

### Card Layouts

Choose from 5 layout templates:

1. **Title + Bullets** - A title with bullet points below
2. **Image Top + Notes** - One image with notes underneath
3. **Two Images + Notes** - Two images side by side with notes
4. **2x2 Grid + Caption** - Four images in a grid with a caption
5. **Full Bleed + 3 Bullets** - Large background image with 3 bullet points

### Managing Cards

- **Add card**: Click "+" button, choose a layout
- **Delete card**: Select card, click trash icon or press Delete
- **Duplicate card**: Right-click → Duplicate
- **Reorder cards**: Drag cards in the sidebar

### Adding Images

- Drag and drop images onto the drop zones
- Click the drop zone to open a file picker
- Supported formats: PNG, JPEG, GIF, HEIC

## Presenting

### Basic Navigation

- **Next card**: `Cmd+Shift+→` (Right Arrow)
- **Previous card**: `Cmd+Shift+←` (Left Arrow)
- **Show/hide overlay**: `Cmd+Shift+O`

### Font Size

Adjust text size for readability:

- **Increase**: `Cmd+Shift+=`
- **Decrease**: `Cmd+Shift+-`

### Recommended Workflow

1. Create your deck in the editor
2. Position the overlay where you want it
3. Enable Protected Mode (check for blue shield)
4. Start your screen share
5. Use hotkeys to navigate (they work even when Meet/Teams is focused)

## Data Storage

Your data is automatically saved to:

```
~/Library/Application Support/PresenterOverlay/
├── Decks/          # Your deck files (JSON)
├── Assets/         # Imported images
└── Settings.json   # App preferences
```

Settings saved include:
- Overlay position and size
- Font scale
- Protected Mode state
- Click-through state
- Last opened deck
