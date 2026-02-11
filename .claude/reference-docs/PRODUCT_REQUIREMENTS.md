# Product Requirements

## Problem
Presenters need a teleprompter / speaker-notes overlay that remains visible to the presenter but is not visible to the audience when sharing their screen via Google Meet / Microsoft Teams.

## Core Experience
- User edits a deck of "Presenter Cards"
- Each card has a selected layout template (from 5 preset layouts)
- During presenting, overlay displays one card at a time
- User advances cards with hotkeys (Next/Prev)
- Overlay stays always-on-top and optionally click-through
- Protected Mode attempts to hide overlay from capture

## Primary User
- Presents mainly in Google Meet, sometimes Teams
- Shares "Entire Screen" often
- Wants quick "Presenter Notes" that behave like slide notes (not long scrolling)

## Key MVP Outcomes
1. Create / edit a deck with 6 layouts
2. Drag & drop images into layout zones
3. Show deck in always-on-top overlay window
4. Navigate cards with hotkeys
5. Protected Mode toggle + Test Capture instructions
6. Persist deck + assets + overlay settings

## Non-goals (for this version)
- Full Canva-style freeform canvas with resizing handles
- Collaboration / cloud sync
- Automatic integration with Google Slides / PowerPoint speaker notes (future feature)

## Acceptance Criteria
- Overlay displays properly above other apps (Keynote, Slides in Chrome, etc.)
- Overlay can be toggled instantly via hotkey
- Deck navigation is reliable, no lag
- Images are stored locally and render quickly
- "Protected Mode" toggles a capture protection flag on the overlay window (best effort)
- A help screen exists to test Meet/Teams screen sharing

