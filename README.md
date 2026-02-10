# Prompter (macOS) — Deck Mode MVP (5 Layouts)

A macOS menu bar app that shows a **presenter-only overlay** (teleprompter + slide-notes deck).
Designed for presenters using **Google Meet** and sometimes **Microsoft Teams**, typically sharing **entire screen**.

The overlay is intended to be visible only to the presenter. The app includes **Protected Mode** to attempt to hide the overlay from screen capture/screen sharing (best effort) and a built-in **Test Capture Setup** screen.

## Installation

### Homebrew (Recommended)

```bash
brew tap michaeltookes/prompter
brew install --cask prompter
```

### Direct Download

Download the latest release from [GitHub Releases](https://github.com/michaeltookes/prompter/releases):
- **Prompter.dmg** — Drag-to-Applications installer
- **Prompter.zip** — Direct app bundle

The app is signed and notarized by Apple for Gatekeeper approval.

## Key Features
- Menu bar app (NSStatusItem)
- Deck editor (cards)
- 5 layout templates per card (PowerPoint-like)
- Drag & drop images into template slots
- Optional image callouts (per-card)
- Always-on-top overlay window
- Protected Mode (attempt hide from capture)
- Click-through overlay mode
- Presentation timer with per-card countdown and configurable modes
- Global hotkeys (works while presenting)
- Automatic updates via Sparkle
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
- Cmd+Shift+T: Start / Pause / Resume Timer

## Run

After installation, launch **Prompter** from your Applications folder. The app runs in the menu bar.

### Building from Source

```bash
git clone https://github.com/michaeltookes/prompter.git
cd prompter/Prompter
open Prompter.xcodeproj
```

Then build and run the macOS target in Xcode.

## License

This project is licensed under the [MIT License](LICENSE).

## Disclaimer
Capture protection is best-effort. Some capture tools or capture methods may still display the overlay.
Always verify with the built-in "Test Capture Setup" screen before a live presentation.

