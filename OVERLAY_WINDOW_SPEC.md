# Overlay Window Technical Spec

Overlay window must:
- Be borderless
- Transparent background
- Floating above other apps
- Visible on all Spaces (including full-screen apps)
- Support click-through (ignore mouse events)
- Support Protected Mode (attempt to exclude from capture)

Overlay contains SwiftUI view bound to current card.

