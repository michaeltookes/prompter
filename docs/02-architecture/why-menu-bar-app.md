# Why a Menu Bar App?

## The Decision

We chose to make Prompter a **menu bar app** rather than a regular dock app.

## What's the Difference?

### Regular Dock App
- Icon appears in the Dock (bottom/side of screen)
- Visible whenever the app is running
- Takes up dock space
- Opens windows that appear in the window list

### Menu Bar App
- Icon appears in the menu bar (top-right of screen)
- Minimal visual footprint
- No dock icon at all
- More "utility" feeling

## Why We Chose Menu Bar

### 1. Minimal Distraction During Demos

When you're presenting, your dock is often visible to your audience. Having a "Prompter" icon in the dock could:
- Reveal that you're using presentation aids
- Raise questions from the audience
- Look unprofessional to some viewers

A menu bar icon is smaller, less noticeable, and often hidden behind the notch on modern MacBooks.

### 2. Always Accessible

Menu bar apps are always one click away. You don't need to:
- Switch applications
- Use Cmd+Tab to find the app
- Look for it in Spotlight

Just glance up, click, and you have access to all controls.

### 3. Fits the Use Case

Prompter is a **utility**, not a primary application. You don't spend hours working "in" it. You:
- Set up your deck beforehand
- Toggle it on during your presentation
- Control it with keyboard shortcuts

This usage pattern fits menu bar apps perfectly.

### 4. Professional Appearance

Many professional tools live in the menu bar:
- Screenshot utilities
- Password managers
- Meeting schedulers
- System monitors

Being a menu bar app puts Prompter in good company.

## What We Considered Instead

### Regular Dock App
**Pros**: More visible, more familiar to users
**Cons**: Takes dock space, visible during demos, feels "heavier"
**Why we didn't choose it**: The visibility during demos was a deal-breaker

### Completely Hidden (No Icon)
**Pros**: Maximum stealth
**Cons**: No way to access settings or editor without keyboard shortcuts
**Why we didn't choose it**: Too hard to discover features, frustrating for new users

### System Preferences Extension
**Pros**: Integrates with macOS settings
**Cons**: Complex to build, limited UI options, not suited for our use case
**Why we didn't choose it**: Over-engineered for what we need

## The Tradeoff

Menu bar apps can be **easy to forget**. If you're not familiar with menu bar apps, you might:
- Not notice it's running
- Forget how to access settings
- Miss that the app is even installed

We accept this tradeoff because our target users (sales engineers) are typically power users who are comfortable with menu bar apps.

---

Next: [Why an Overlay Window?](why-overlay-window.md)
