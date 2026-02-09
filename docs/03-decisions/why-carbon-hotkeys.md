# Global Hotkeys: From Carbon to CGEvent Tap

## The Decision

We use a **CGEvent tap** to register global keyboard shortcuts (hotkeys) that work even when other applications are focused. This replaced the original Carbon Event Manager implementation.

## What's a Global Hotkey?

A **global hotkey** is a keyboard shortcut that works across your entire system, not just within one app.

**Example**:
- **Local shortcut**: Cmd+C copies text, but only when you're in an app that supports it
- **Global hotkey**: Cmd+Shift+O toggles the Prompter, no matter what app you're using

Global hotkeys are essential because during a demo, you're focused on *your demo app*, not Prompter. You need shortcuts that work from anywhere.

## History

### Phase 1: Carbon Event Manager (January 2026)

The initial implementation used Apple's **Carbon Event Manager**, an older API dating back to Mac OS 9. It was chosen because:
- It was the established method for global hotkeys
- Many popular apps used it (Alfred, Spectacle, etc.)
- Simpler to implement than alternatives

### Pre-Release Migration: CGEvent Tap (February 2026)

Before the first release, we migrated to **CGEvent tap** because:
- Carbon Event Manager is deprecated with no guarantee of future macOS support
- CGEvent tap is a modern, actively supported API
- It provides finer control over event handling (consuming events to prevent propagation)
- Long-term maintainability outweighs the slight increase in complexity

## How CGEvent Tap Works

```
1. App starts up

2. We check for Accessibility permissions
   └─→ If not granted, macOS prompts the user
   └─→ App retries after 5 seconds

3. We create a CGEvent tap listening for keyDown events
   └─→ Tap is added to the main run loop

4. User presses Cmd+Shift+O (while in any app)

5. macOS routes the event through our tap
   └─→ We check: is it Cmd+Shift + a registered key?
   └─→ If yes: consume the event (return nil) and dispatch the action
   └─→ If no: pass the event through (return the event)
```

This all happens in milliseconds, so the overlay responds instantly.

## What We Considered

### Carbon Event Manager (Original Choice, Now Replaced)

**Pros**:
- Simple to implement
- Well-documented with many examples
- No Accessibility permissions required

**Cons**:
- Deprecated by Apple
- No guarantee of future macOS support
- Less control over event propagation

### Third-Party Libraries

**Examples**: HotKey (Swift library), MASShortcut (Objective-C library)

**Pros**:
- Higher-level API (easier to use)
- Some offer UI for shortcut recording

**Cons**:
- Another dependency to maintain
- May not be updated for future macOS versions

**Why we didn't choose it**: CGEvent tap is well-contained in a single file and we prefer owning the code.

### Listening Only When App is Active

**Idea**: Just use regular keyboard shortcuts that work when the app is focused.

**Why we didn't choose it**: This would make the app unusable during demos — the entire point is hands-free control from any app.

## Tradeoffs We Accept

### 1. Accessibility Permissions Required

CGEvent tap requires the user to grant Accessibility permissions. We handle this gracefully:
- `AXIsProcessTrustedWithOptions` prompts the user automatically on first launch
- AppDelegate retries registration after 5 seconds (gives the user time to approve)
- If denied, the app still works — just without global hotkeys

### 2. Tap Can Be Disabled by the System

macOS may disable our event tap if it takes too long to process events or if the user's input gets blocked. We handle `tapDisabledByTimeout` and `tapDisabledByUserInput` events by re-enabling the tap automatically.

### 3. Carbon.HIToolbox Still Imported

We still import `Carbon.HIToolbox` for virtual key code constants (`kVK_ANSI_O`, `kVK_RightArrow`, etc.). These are stable constants, not deprecated API calls.
