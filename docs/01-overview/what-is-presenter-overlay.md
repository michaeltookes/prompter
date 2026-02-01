# What is Presenter Overlay?

## The Problem

Imagine you're a sales engineer giving a technical demo over a video call. You're sharing your entire screen to show a product, but you also need to remember key talking points, customer-specific details, or the next steps in your demo flow.

**The challenge**: Any notes you have on screen are visible to everyone on the call.

Traditional solutions don't work well:
- **Physical sticky notes**: You have to look away from the screen
- **Second monitor notes**: Viewers see your eyes wandering
- **Presenter view in slides**: Only works when presenting slides, not live demos
- **Phone/tablet notes**: Awkward to glance at during a call

## The Solution

**Presenter Overlay** is a Mac app that displays your notes in a floating window that:

1. **Stays on top** of everything else on your screen
2. **Only you can see** - it's hidden from screen sharing (best-effort)
3. **Doesn't interfere** with your demo - you can click through it
4. **Works everywhere** - during any app, any presentation, any demo

Think of it like having a teleprompter that only you can see, floating right on your screen while you demo.

## How It Works (Simple Version)

1. **Before your demo**: Create a "deck" of cards with your notes, images, and talking points
2. **During your demo**: Press a keyboard shortcut to show your notes overlay
3. **Navigate**: Use keyboard shortcuts to flip through your cards as you progress
4. **Stay focused**: The overlay floats above your demo but doesn't capture mouse clicks

Your audience sees your demo. You see your demo AND your notes.

## Key Insight

The app lives in your **menu bar** (the icons at the top-right of your Mac screen). It doesn't clutter your dock or take up space. It's there when you need it, invisible when you don't.

## Is It Really Hidden?

We use a macOS feature called "Protected Mode" that tells the system to exclude our window from screen capture. This works with most video conferencing tools like Google Meet and Microsoft Teams.

**Important caveat**: This is "best-effort" protection. Some screen recording tools may still capture the overlay. Always test before an important presentation.

---

Next: [Who is it for?](who-is-it-for.md)
