# Presenter Overlay (macOS) — Deck Mode MVP (5 Layouts)

A macOS menu bar app that shows a **presenter-only overlay** (teleprompter + slide-notes deck).
Designed for presenters using **Google Meet** and sometimes **Microsoft Teams**, typically sharing **entire screen**.

The overlay is intended to be visible only to the presenter. The app includes **Protected Mode** to attempt to hide the overlay from screen capture/screen sharing (best effort) and a built-in **Test Capture Setup** screen.

## Key Features
- Menu bar app (NSStatusItem)
- Deck editor (cards)
- 5 layout templates per card (PowerPoint-like)
- Drag & drop images into template slots
- Optional image callouts (per-card)
- Always-on-top overlay window
- Protected Mode (attempt hide from capture)
- Click-through overlay mode
- Global hotkeys (works while presenting)
- Persistence (deck, assets, settings)

## Layout Templates (5)
1. Title + Bullets
2. Image Top + Notes Bottom
3. Two Images Side-by-Side + Notes
4. 2x2 Image Grid + Caption
5. Full-Bleed Image + 3 Key Bullets (overlay-friendly)

## Hotkeys
- Cmd+Shift+O: Toggle Overlay
- Cmd+Shift+← / Cmd+Shift+→: Previous / Next Card
- Cmd+Shift+= / Cmd+Shift+-: Font Size Up / Down
- Cmd+Shift+Up / Cmd+Shift+Down: Scroll within card notes (if overflow)
- Cmd+Shift+C: Toggle Click-through Overlay
- Cmd+Shift+P: Toggle Protected Mode

## Run
Open the Xcode project and run the macOS target.

## Disclaimer
Capture protection is best-effort. Some capture tools or capture methods may still display the overlay.
Always verify with the built-in "Test Capture Setup" screen before a live presentation.

