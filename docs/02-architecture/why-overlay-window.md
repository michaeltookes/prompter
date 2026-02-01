# Why an Overlay Window?

## The Decision

We chose to display notes in a **floating overlay window** that can be hidden from screen capture, rather than other approaches.

## What Makes Our Overlay Special

Our overlay window has several unusual properties:

1. **Borderless**: No title bar, close buttons, or window chrome
2. **Transparent background**: The frosted glass effect shows through
3. **Always on top**: Floats above all other windows, including full-screen apps
4. **Visible on all Spaces**: Follows you across virtual desktops
5. **Click-through capable**: Mouse clicks can pass through to apps underneath
6. **Capture-protected**: Can be excluded from screen recording (best-effort)

## Why These Properties Matter

### Borderless + Transparent
**Why**: A standard window with a title bar would look out of place floating over your demo. The borderless, frosted-glass look feels like a natural part of the interface, not an intrusion.

### Always on Top
**Why**: If the overlay went behind your demo app, it would be useless. It must stay visible at all times, even when presenting full-screen content.

### All Spaces
**Why**: macOS has virtual desktops called "Spaces." If the overlay only appeared on one Space, you'd lose your notes when switching. We make it follow you everywhere.

### Click-Through
**Why**: During a demo, you need to click on things. If every click hit the overlay instead of your app, you'd have to constantly move it. Click-through mode lets clicks pass right through.

### Capture Protection
**Why**: This is the core feature - hiding notes from screen sharing. We use macOS's `sharingType = .none` property to request the window be excluded from capture.

## What We Considered Instead

### Approach 1: Second Window on a Hidden Monitor
**Idea**: Put notes on a second display that isn't being shared
**Pros**: Guaranteed not captured
**Cons**: Requires second monitor, notes not visible in your main field of view, eye movement noticeable
**Why we didn't choose it**: Not everyone has two monitors; we wanted an all-in-one solution

### Approach 2: Picture-in-Picture Style
**Idea**: Use macOS's built-in PiP feature
**Pros**: Well-known pattern, system-supported
**Cons**: PiP is designed for video, limited customization, still captured in screen shares
**Why we didn't choose it**: Doesn't solve the capture problem

### Approach 3: Native Presenter Notes Integration
**Idea**: Integrate with Keynote/PowerPoint presenter notes
**Pros**: Uses existing tools, familiar interface
**Cons**: Only works when presenting slides, not during live demos
**Why we didn't choose it**: Our whole point is to work during demos, not slides

### Approach 4: Mobile Companion App
**Idea**: Show notes on your phone/tablet
**Pros**: Completely separate from your Mac, guaranteed not captured
**Cons**: Have to look away from screen, context switching
**Why we didn't choose it**: The glance-away is exactly what we're trying to avoid

### Approach 5: Browser Extension
**Idea**: Inject notes into the browser
**Pros**: No separate app needed
**Cons**: Only works in browser, demos often use native apps
**Why we didn't choose it**: Too limiting for real demo scenarios

## The Tradeoff: Capture Protection Isn't Perfect

The `sharingType = .none` property is a **request**, not a guarantee. macOS tells screen capture tools to skip this window, but:

- Some capture tools ignore this flag
- Third-party screen recorders may not respect it
- Future macOS updates could change behavior

We're upfront about this limitation and provide a Test Capture feature so users can verify protection before important presentations.

## Why Accept This Tradeoff?

The alternatives (second monitor, phone app) are 100% reliable but create other problems:
- Require extra hardware
- Force you to look away from camera
- Break the flow of your presentation

Our approach works seamlessly when it works, and fails gracefully when it doesn't (the audience just sees your notes - not ideal, but not catastrophic).

---

Next: [Component Diagram](component-diagram.md)
