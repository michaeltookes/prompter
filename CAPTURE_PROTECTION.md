# Capture Protection (macOS)

## Protected Mode (Best Effort)
When ON:
- Attempt to exclude overlay window from screen capture/screen sharing
- Apply capture protection flags to overlay NSWindow
- Show an indicator in UI that Protected Mode is enabled

Implementation requirement:
- Use AppKit window controls to make the overlay "not shareable"
  Example direction: NSWindow sharing/capture exclusion settings (e.g., sharingType = .none)
- Provide fallback messaging if OS/capture pipeline still shows overlay.

## Test Capture Setup Window
A simple instruction window:

1) Open Google Meet or Microsoft Teams
2) Start a test call alone (or join from phone as second participant)
3) Share your entire screen
4) Confirm overlay is not visible
5) If visible:
   - Switch to sharing a Chrome tab or window
   - Or disable overlay and use Presenter Notes in another device

Disclaimer:
- Some capture tools may bypass protection
- Always test before important presentations

