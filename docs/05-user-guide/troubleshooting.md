# Troubleshooting

Solutions to common problems with Prompter.

## Overlay Issues

### Overlay isn't appearing

**Check if the app is running:**
- Look for the icon in your menu bar (top-right of screen)
- If not there, open Prompter from Applications

**Try toggling it:**
- Press Cmd+Shift+O
- Or click the menu bar icon and select "Show Overlay"

**Check other Spaces:**
- The overlay might be on a different virtual desktop
- Use Mission Control to check all Spaces

### Overlay is appearing on screen share

**Verify Protected Mode is enabled:**
- Click the menu bar icon
- Make sure "Protected Mode" is checked

**Try sharing differently:**
Instead of sharing your entire screen, try:
- Share a specific window
- Share a browser tab (in Chrome/Edge)
- Share only the application you're demoing

**Test with a fresh call:**
- End and rejoin the meeting
- Enable Protected Mode before sharing

**Different video app:**
Protected Mode works differently across apps:
- Google Meet: Usually works with "Entire Screen"
- Microsoft Teams: Usually works
- Zoom: May vary depending on settings

### Overlay is in the way

**Enable click-through:**
- Press Cmd+Shift+C
- Clicks will pass through to apps underneath
- Press Cmd+Shift+C again to disable

**Resize the overlay:**
- Drag the edges to make it smaller
- Position it in a corner

**Move it:**
- Drag the overlay to a new position
- (Make sure click-through is disabled to drag it)

### Overlay isn't staying on top

The overlay should float above all windows. If it's not:

**Check if it's behind a fullscreen app:**
- The overlay should work in fullscreen
- Try exiting and re-entering fullscreen

**Restart the app:**
- Quit Prompter
- Reopen it
- Show the overlay again

## Hotkey Issues

### Hotkeys aren't working

**Check if another app is using the same shortcut:**
- Some apps register global hotkeys
- Try quitting other apps and testing again

**Grant Accessibility permissions:**
1. Open System Settings (or System Preferences)
2. Go to Privacy & Security → Accessibility
3. Make sure Prompter is listed and enabled
4. If not, add it by clicking the + button

**Restart after permission change:**
- Quit and reopen Prompter
- Permissions often require a restart to take effect

### Some hotkeys work, others don't

If certain shortcuts work but not others, another app might be using those specific shortcuts. Check:
- Alfred
- Raycast
- Rectangle
- Other productivity apps

### Want different hotkeys?

Currently, hotkeys are fixed. Custom hotkey configuration may be added in a future update.

## Editor Issues

### Can't open the editor

**Click the menu bar icon:**
- Select "Open Deck Editor..."
- A window should appear

**If nothing happens:**
- Try quitting and reopening the app
- Check if the window opened behind other windows

### Changes aren't saving

Changes should save automatically. If they're not:

**Check for error messages:**
- Look for any alerts or notifications

**Verify file permissions:**
- Prompter saves to:
  `~/Library/Application Support/Prompter/`
- Make sure this folder is writable

**Force a save:**
- Make a small change (add a space)
- Wait a moment
- Quit the app (forces save)
- Reopen and check

### Images won't drag into cards

**Check the image format:**
- Supported: PNG, JPEG, GIF
- Try a different image to test

**Try copy-paste:**
- Copy the image (Cmd+C)
- Click in the image zone
- Paste (Cmd+V)

**Restart the editor:**
- Close and reopen the deck editor

## Performance Issues

### App is slow

Prompter should be very fast. If it's not:

**Check image sizes:**
- Very large images (>5MB) might slow things down
- Try using smaller images

**Restart the app:**
- Quit and reopen
- This clears any accumulated state

### High CPU usage

The app should use minimal CPU. If it's using a lot:

**Check Activity Monitor:**
- Open Activity Monitor
- Find "Prompter"
- Note the CPU percentage

**Report the issue:**
- High CPU is likely a bug
- Note what you were doing when it happened

## Data Issues

### Where are my decks stored?

Your data is stored at:
```
~/Library/Application Support/Prompter/
├── Decks/        # Your deck files
├── Assets/       # Images you've added
└── Settings.json # Your preferences
```

To find this folder:
1. Open Finder
2. Press Cmd+Shift+G
3. Paste: `~/Library/Application Support/Prompter/`

### How do I back up my decks?

Copy the entire folder mentioned above. It contains everything:
- All decks
- All images
- Your settings

### Can I transfer decks to another Mac?

Yes! Copy the `Prompter` folder to the same location on the other Mac.

### My deck disappeared

**Check the folder:**
- Go to the location above
- Look in the Decks folder for JSON files

**Check for backups:**
- If you use Time Machine, you can restore previous versions

## Getting More Help

### Check for updates

Make sure you're running the latest version of the app.

### Report an issue

If you encounter a bug:
1. Note exactly what happened
2. Note what you were doing when it happened
3. Check if you can reproduce it
4. Report at: [GitHub Issues link]

### Community

For tips from other users, check:
- [Community forum link]
- [Discussion board link]

---

*If your issue isn't listed here, please reach out so we can help and improve this guide!*
