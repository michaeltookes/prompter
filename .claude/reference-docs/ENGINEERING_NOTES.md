# Engineering Notes

## Tech Stack
- Swift
- SwiftUI
- AppKit (NSWindow for overlay control)
- NSStatusItem for menu bar

## Overlay Window Requirements
- Borderless + transparent
- Floating above other apps
- Can be moved/resized
- Can ignore mouse events in click-through mode
- Protected mode should apply capture exclusion settings

## Rendering Strategy
- Overlay view binds to current card state
- Cards are rendered by a layout renderer that chooses a SwiftUI view based on layout type

## Deck Editor Strategy
- Sidebar list controls ordering and selection
- Editor area shows a template view with drop zones
- Dropping an image sets the corresponding slot

## Testing
- Ensure hotkeys work system-wide
- Confirm overlay stays on top during fullscreen presentations
- Validate settings persistence across restarts

