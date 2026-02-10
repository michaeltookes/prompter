# Global Hotkeys Spec

Global (system-wide) hotkeys must work while presenting.

## Required Hotkeys
Cmd+Shift+O  -> Toggle Overlay visibility
Cmd+Shift+←  -> Previous card
Cmd+Shift+→  -> Next card
Cmd+Shift+=  -> Increase overlay font size
Cmd+Shift+-  -> Decrease overlay font size
Cmd+Shift+Up -> Scroll overlay up (if overflow)
Cmd+Shift+Down -> Scroll overlay down (if overflow)
Cmd+Shift+C  -> Toggle click-through mode
Cmd+Shift+P  -> Toggle Protected Mode
Cmd+Shift+]  -> Increase overlay opacity
Cmd+Shift+[  -> Decrease overlay opacity
Cmd+Shift+T  -> Toggle timer (start/pause/resume/stop based on timer mode)

## Notes
- Hotkeys must not require the app to be focused.
- Implementation uses a CGEvent tap (`CGEvent.tapCreate`) for system-wide hotkey interception. Requires Accessibility permissions (prompted automatically on first launch).
- Provide UI showing current hotkeys (Help screen or footer).
