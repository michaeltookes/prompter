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

## Accessibility
- All hotkey-driven state changes announced via `AppState.postAccessibilityAnnouncement()`
- All interactive controls have `.accessibilityLabel()` and `.accessibilityHint()`
- `LayoutType.accessibilityDescription` and `Card.accessibilitySummary` provide VoiceOver context
- Window roles/titles set on OverlayWindow, EditorWindow, ThemedPanelWindow, TestCaptureWindow
- Image drop zones have "Browse" button (fileImporter) for keyboard-only users
- Cards support "Move Up/Down" via context menu; bullets have reorder buttons
- New bullet fields auto-focus via `@FocusState`
- Editor sidebar and overlay footer use Dynamic Type (`.caption2`, `.footnote`, `.callout`)
- Overlay renderers keep hardcoded sizes with `fontScale` multiplier

## Coding Conventions
- **No hardcoded values** when a dynamic or system-provided alternative exists
  - Use Dynamic Type text styles (`.footnote`, `.caption2`) instead of `.system(size: N)` in editor/footer views
  - Use `NSColor.labelColor` / `NSColor.secondaryLabelColor` instead of hardcoded hex colors for system-context views
  - Use system constants and enum cases over magic numbers or string literals
  - Exception: overlay renderers intentionally use hardcoded sizes scaled by `fontScale`

## Testing
- Ensure hotkeys work system-wide
- Confirm overlay stays on top during fullscreen presentations
- Validate settings persistence across restarts
- Verify VoiceOver reads all controls correctly
- Test Browse button opens file picker in empty image drop zones
- Test Move Up/Down in card context menu and bullet reorder buttons

