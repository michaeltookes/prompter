# Why Carbon for Global Hotkeys?

## The Decision

We use Apple's **Carbon Event Manager** to register global keyboard shortcuts (hotkeys) that work even when other applications are focused.

## What's a Global Hotkey?

A **global hotkey** is a keyboard shortcut that works across your entire system, not just within one app.

**Example**:
- **Local shortcut**: Cmd+C copies text, but only when you're in an app that supports it
- **Global hotkey**: Cmd+Shift+O toggles the Prompter, no matter what app you're using

Global hotkeys are essential because during a demo, you're focused on *your demo app*, not Prompter. You need shortcuts that work from anywhere.

## What is Carbon?

Carbon is an older set of Apple programming tools (APIs) that date back to the Mac OS 9 era (early 2000s). While most of Carbon has been replaced by modern alternatives, the **Event Manager** portion is still the standard way to register global hotkeys.

**Why does this old technology still get used?**
- It works reliably
- Apple hasn't provided a modern replacement
- Many popular apps use it (Alfred, Spectacle, etc.)

## Why We Chose Carbon

### 1. Industry Standard for This Purpose

Almost every Mac app with global hotkeys uses Carbon Event Manager:
- Alfred (productivity app)
- Spectacle (window management)
- Bartender (menu bar organizer)
- Many others

When so many successful apps use the same approach, it's a safe choice.

### 2. Reliable Across macOS Versions

Carbon hotkey registration has worked consistently for decades. Apple maintains backward compatibility because so many apps depend on it.

### 3. Well-Documented

Because Carbon has been used for so long, there are:
- Many code examples available
- Known solutions to common problems
- Community knowledge from years of use

### 4. Simpler Than Alternatives

The alternative (CGEvent tap) requires:
- More complex code
- Accessibility permissions
- Handling more edge cases

Carbon is more straightforward for our needs.

## What We Considered Instead

### CGEvent Tap

**What it is**: A lower-level API that intercepts input events at the system level.

**Pros**:
- More modern API
- More control over event handling
- Can intercept any input, not just keyboards

**Cons**:
- Requires Accessibility permissions
- More complex to implement correctly
- Overkill for our needs (we just need keyboard shortcuts)
- Potential security concerns (can log keystrokes)

**Why we didn't choose it**: More complexity for no benefit; Carbon does exactly what we need.

### Third-Party Libraries

**Examples**: HotKey (Swift library), MASShortcut (Objective-C library)

**Pros**:
- Higher-level API (easier to use)
- Handles edge cases
- Some offer UI for shortcut recording

**Cons**:
- Another dependency to maintain
- May not be updated for future macOS versions
- Adds to app size

**Why we didn't choose it**: Carbon is simple enough that we don't need a wrapper; we'd rather own the code.

### Listening Only When App is Active

**Idea**: Just use regular keyboard shortcuts that work when the app is focused.

**Pros**:
- Much simpler
- No special APIs needed

**Cons**:
- Completely defeats the purpose! Users would have to click on the overlay before using shortcuts.

**Why we didn't choose it**: This would make the app unusable during demos.

## Tradeoffs We Accept

### 1. Carbon is "Deprecated"

Apple has marked Carbon as deprecated, meaning they don't recommend it for new code. However:
- "Deprecated" doesn't mean "will stop working"
- Apple can't remove it without breaking thousands of apps
- There's no replacement for global hotkeys

We'll monitor macOS updates and migrate if Apple provides a modern alternative.

### 2. Importing Carbon Framework

Using Carbon requires importing a legacy framework into our modern Swift project. This:
- Adds a small amount of complexity
- Is a well-known pattern (many Swift apps do this)
- Works perfectly fine

### 3. Can't Record Custom Shortcuts (Yet)

The Carbon API makes it easy to *register* shortcuts but harder to *record* new ones from user input. For MVP, we use fixed shortcuts. Custom shortcuts could be added later.

## How It Works (Simplified)

```
1. App starts up

2. We tell Carbon: "Listen for Cmd+Shift+O globally"
   └─→ Carbon registers this with macOS

3. User presses Cmd+Shift+O (while in any app)

4. macOS recognizes the shortcut
   └─→ Sends event to Carbon

5. Carbon sends event to our app
   └─→ Our code runs: toggle the overlay
```

This all happens in milliseconds, so the overlay responds instantly.
