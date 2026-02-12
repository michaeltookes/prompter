# UI / UX Style Guide — Prompter

## Design Principles
The UI should feel:
- Modern macOS native
- Clean and distraction-free
- Lightweight, elegant, and minimal
- Designed for presenters under pressure

Visual tone:
- Thin strokes
- Soft glow highlights
- Subtle drop shadows
- Gentle translucency
- No heavy borders or skeuomorphic elements

---

## Color Palette

Primary Accent: Soft Electric Blue
Secondary Accent: Muted Indigo
Surface: Frosted dark glass
Text: Soft white with hierarchy contrast

| Element | Color |
|--------|------|
| Background panels | rgba(25, 27, 32, 0.85) |
| Accent highlight | #5DA9FF |
| Secondary accent | #7A86FF |
| Text Primary | #F5F7FA |
| Text Secondary | #B8C1CC |
| Divider lines | rgba(255,255,255,0.08) |
| Glow shadow | rgba(93,169,255,0.35) |
| Traffic light close | #FF5F56 |

---

## Typography

Primary Font: SF Pro (system)
Fallback: Helvetica Neue

| Usage | Style | Dynamic Type? |
|------|------|--------------|
| Card Title | 26–32pt Semibold | No (uses fontScale) |
| Notes Text | 18–22pt Regular | No (uses fontScale) |
| Caption | 16pt Regular | No (uses fontScale) |
| Overlay Footer | 13pt Medium | Yes (`.footnote`) |
| Editor Sidebar | 11–16pt varies | Yes (`.caption2`, `.footnote`, `.callout`) |

**Dynamic Type**: Editor sidebar and overlay footer use SwiftUI text styles that scale with system accessibility settings. Overlay renderers keep hardcoded sizes with the `fontScale` multiplier for presenter-controlled scaling.

Line spacing should be generous for readability at a distance.

---

## Elevation & Shadows

Use layered shadows to create subtle floating depth:

Overlay Window:
- Shadow radius: 30
- Opacity: 0.25
- Color: Accent glow mix

Cards:
- Soft inner glow at edges
- Slight blur background

---

## Corners & Shape

| Element | Radius |
|--------|-------|
| Overlay Window | 18px |
| Cards | 16px |
| Image Slots | 14px |
| Buttons | 10px |

---

## Icon Style

Icons should be:
- Thin line (1.5–2pt)
- Monochrome
- Subtle hover glow
- Based on SF Symbols style

Common icons:
- Eye (overlay visibility)
- Shield (Protected Mode)
- Cursor (Click-through)
- Chevron arrows (Next/Prev card)
- Image icon (media slot)
