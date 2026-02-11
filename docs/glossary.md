# Glossary

Plain English definitions of terms used in Prompter documentation.

---

## A

### API (Application Programming Interface)
A set of rules that lets different software programs talk to each other. When we say "we use Apple's API," we mean we're using tools Apple provides for building Mac apps.

### App State
The "brain" of the application that keeps track of everything: which deck is open, which card you're viewing, your settings, etc. When you change something, App State makes sure all parts of the app update accordingly.

### AppKit
Apple's older (but still powerful) toolkit for building Mac apps. We use it for things SwiftUI can't do, like making windows float above everything else.

### Assets
The images you add to your cards. We copy them to a special folder so your decks are self-contained.

---

## B

### Borderless Window
A window without the usual title bar (the bar with the red/yellow/green buttons). Our overlay is borderless so it looks cleaner and more like a floating note.

---

## C

### Capture Protection
A macOS feature that tells screen recording tools to skip certain windows. We use this to try to hide the overlay from your audience during screen sharing.

### Carbon
An older set of Apple programming tools. The app originally used Carbon Event Manager for global hotkeys but has since migrated to CGEvent tap for long-term compatibility. The `Carbon.HIToolbox` import is still used for virtual key code constants (e.g., `kVK_ANSI_O`).

### Click-Through Mode
When enabled, mouse clicks pass through the overlay window to whatever is underneath. This lets you interact with your demo without moving the overlay.

### Codable
A Swift feature that lets us easily save data structures (like decks) to files and load them back. Think of it as automatic translation between your data and JSON files.

---

## D

### Deck
A collection of cards that you create for a presentation. Like a deck of index cards, but digital.

### Deprecated
When Apple marks something as "deprecated," they're saying "this still works, but we don't recommend it for new projects." Carbon is deprecated, but we use it because there's no better alternative for global hotkeys.

### Dock
The row of app icons at the bottom (or side) of your Mac screen. Prompter doesn't appear in the dock - it lives in the menu bar instead.

---

## E

### Electron
A way to build desktop apps using web technologies (HTML, CSS, JavaScript). We didn't use it because it's slower and can't access the macOS features we need.

---

## F

### Floating Window
A window that stays on top of other windows, even when you're working in a different app. Our overlay floats so your notes are always visible.

### Frosted Glass Effect
A visual style where the background is slightly blurred and translucent, like looking through frosted glass. It's a common macOS design pattern.

---

## G

### Global Hotkey
A keyboard shortcut that works across your entire system, not just in one app. Cmd+Shift+O toggles the overlay even when you're using other apps.

---

## I

### Info.plist
A configuration file in Mac apps that tells macOS how the app should behave. We use it to set up menu bar-only mode.

---

## J

### JSON (JavaScript Object Notation)
A text-based format for storing data. It's human-readable (you can open it in a text editor) and easy for programs to work with. We use JSON to save your decks.

---

## L

### Layout Template
A pre-designed arrangement of text and images for a card. We offer 6 layouts so you can quickly create cards without designing from scratch.

### LSUIElement
A setting in Info.plist that makes an app run without a dock icon. This is how we make Prompter a menu bar-only app.

---

## M

### Menu Bar
The row of icons and menus at the very top of your Mac screen. Prompter's icon lives here.

### MVP (Minimum Viable Product)
The simplest version of a product that still provides value. Our MVP includes the core features needed for presenter notes, without extra bells and whistles.

---

## N

### NSWindow
Apple's class (programming building block) for creating windows on macOS. We customize it to create our special overlay window.

---

## O

### Observable / ObservableObject
A Swift pattern where parts of the app automatically update when data changes. When you switch cards, the overlay instantly shows the new card because it's "observing" the current card number.

### Overlay Window
The floating panel that displays your notes during a presentation. It's designed to stay on top and (ideally) be hidden from screen capture.

---

## P

### Persistence
Saving data so it's still there after you quit and reopen the app. Your decks persist in files on your Mac.

### Presentation Timer
A built-in countdown timer that tracks time per card during your demo. Supports two modes: deck mode (total time divided across cards) and per-card mode (fixed time per card). Controlled via Cmd+Shift+T.

### Protected Mode
Our feature that attempts to hide the overlay from screen capture. It uses macOS's capture exclusion APIs.

---

## R

### Reactive
A programming style where changes automatically propagate. If you change the current card number in App State, the overlay automatically updates to show the new card. You don't have to manually tell it to refresh.

---

## S

### Sparkle
An open-source framework for macOS app auto-updates. Prompter uses Sparkle 2.x to check for and install updates via an appcast feed hosted on GitHub.

### Sidebar
The panel on the left side of the deck editor that shows all your cards. Click a card to select it for editing.

### SF Symbols
Apple's library of icons that come built into macOS. We use them for buttons and indicators throughout the app.

### Space (macOS Spaces)
Virtual desktops on Mac. You can have multiple Spaces and switch between them. Our overlay follows you across Spaces.

### Swift
Apple's modern programming language for building apps on Mac, iPhone, iPad, etc. It's what we use to write Prompter.

### SwiftUI
Apple's modern toolkit for building user interfaces. It makes creating buttons, menus, and layouts faster and easier than older approaches.

---

## T

### Template
See "Layout Template."

---

## U

### UUID (Universally Unique Identifier)
A random ID that's practically guaranteed to be unique. We use UUIDs to identify decks, cards, and assets so there are never conflicts.

---

## W

### Window Controller
Code that manages a window's lifecycle: creating it, showing it, hiding it, and cleaning up when it's closed.

---

*Don't see a term? Let us know and we'll add it.*
