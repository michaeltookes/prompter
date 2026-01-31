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

## Notes
- Hotkeys must not require the app to be focused.
- Use a reliable macOS global hotkey mechanism (Carbon hotkeys or a trusted wrapper).
- Provide UI showing current hotkeys (Help screen or footer).

