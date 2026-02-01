# Why Protected Mode?

## The Decision

We implement "Protected Mode" using macOS's `NSWindow.sharingType = .none` property to request that the overlay window be excluded from screen capture.

## What Problem Are We Solving?

When you share your screen in Google Meet or Microsoft Teams, normally **everything** on your screen is visible to your audience. This includes any notes or helper windows you have open.

Our users want to see their presenter notes, but they don't want their audience to see them. Protected Mode attempts to hide the overlay from screen sharing.

## How Protected Mode Works

### The Technical Part (Simplified)

macOS windows have a property called `sharingType` that can be set to:
- `.readOnly` - Window can be captured (default)
- `.readWrite` - Window can be captured and remotely controlled
- `.none` - Window should not be captured

When we set `sharingType = .none`, we're telling macOS: "Please exclude this window from screen capture."

### What Happens

```
1. You enable Protected Mode in the menu

2. Our app sets sharingType = .none on the overlay window

3. When you share your screen in Meet/Teams:
   - macOS tells the app which windows to capture
   - macOS (ideally) excludes our window from that list

4. Your audience sees your screen, minus the overlay
```

## Why "Best Effort"?

We call this "best effort" because it's not guaranteed to work 100% of the time.

### Why It Might Not Work

1. **Some capture tools ignore the flag**: Not all screen recording software respects `sharingType`. Some tools capture everything regardless.

2. **Platform-specific behavior**: Google Meet and Microsoft Teams use different capture methods. What works for one might not work for the other.

3. **macOS updates**: Apple could change how this feature works in future versions.

4. **Third-party recording apps**: Tools like OBS, Loom, or QuickTime may or may not respect the flag.

### What We Know Works

Based on testing and user reports from similar apps:
- Google Meet's "Entire Screen" share usually respects the flag
- Microsoft Teams usually respects the flag
- Native macOS screen recording usually respects the flag

### What's Less Reliable

- Sharing a specific "Chrome tab" (different mechanism)
- Third-party recording software (varies widely)
- Older macOS versions (less consistent)

## Why We Chose This Approach

### 1. It's the Right Way

Apple provides `sharingType` specifically for this purpose. Using it is the "correct" solution, even if it's not perfect.

### 2. No Hacks Required

Some apps try clever workarounds (like drawing directly to the screen buffer), but these:
- Are fragile and break easily
- May violate Apple's guidelines
- Create security concerns

Using the official API is cleaner and more maintainable.

### 3. Works for Most Users

Despite the caveats, Protected Mode works for the majority of use cases. Most of our users will be:
- Using Google Meet or Microsoft Teams
- Sharing their entire screen
- On recent macOS versions

For this common case, it works well.

## What We Considered Instead

### Approach 1: Second Display

**Idea**: Tell users to put notes on a second monitor that isn't shared

**Pros**: Guaranteed to work
**Cons**: Requires extra hardware; users look away from camera
**Why we didn't choose it**: Defeats the purpose of having notes on the same screen

### Approach 2: Virtual Camera

**Idea**: Create a virtual camera that shows a modified screen without the overlay

**Pros**: Would be invisible to any screen share
**Cons**: Extremely complex to build; performance concerns; users would have to switch camera sources
**Why we didn't choose it**: Way too complex for MVP; uncertain user experience

### Approach 3: Browser Extension Only

**Idea**: Only work as a browser extension, injecting content into the page

**Pros**: Could potentially hide content from screen share
**Cons**: Only works in browser; demos often use native apps
**Why we didn't choose it**: Too limiting

### Approach 4: No Protection (Just Float)

**Idea**: Just make a floating window and tell users to hide it before sharing

**Pros**: Simple; no complexity
**Cons**: Users forget; defeats the core value proposition
**Why we didn't choose it**: This would make the app much less useful

## The Test Capture Feature

Because Protected Mode isn't guaranteed, we include a Test Capture feature that helps users verify it works with their setup.

**How it works**:
1. User opens the Test Capture instructions
2. Instructions guide them to start a test call
3. They share their screen with themselves (or a test participant)
4. They verify whether the overlay appears

This puts users in control and helps them build confidence before important presentations.

## Tradeoffs We Accept

1. **Not 100% reliable**: Some setups won't work. We're upfront about this.

2. **User testing required**: Users should verify before important calls.

3. **No guarantees**: We can't promise the overlay will be hidden.

We accept these tradeoffs because:
- The alternative approaches are impractical
- It works for most common scenarios
- Users can verify before critical presentations
- Even partial protection is valuable

## Messaging to Users

We're transparent about limitations:
- Menu shows "Protected Mode" not "Invisible Mode"
- Documentation explains "best effort" nature
- Test Capture feature encourages verification
- Fallback advice provided (share window/tab instead of full screen)

Honesty builds trust, even when we can't guarantee perfection.
