# Decision Log

This document tracks all significant decisions made during the development of Presenter Overlay. Each entry explains what we decided, why, and what alternatives we considered.

---

## How to Read This Log

Each decision follows this format:
- **Decision**: What we chose
- **Date**: When we decided
- **Context**: The situation that led to this decision
- **Options Considered**: What alternatives we evaluated
- **Why This Choice**: Our reasoning
- **Tradeoffs**: What we gave up or risks we accepted

---

## Decisions

### D001: macOS Platform Only (Not Cross-Platform)

**Decision**: Build for macOS only, not Windows/Linux

**Date**: Project inception

**Context**: We needed to choose our target platform(s).

**Options Considered**:
1. macOS only
2. macOS + Windows
3. Cross-platform (Electron/web-based)

**Why This Choice**:
- macOS has unique window capabilities we need (capture protection, floating windows)
- Our primary users (sales engineers at tech companies) predominantly use Macs
- Native performance is important for a tool that runs during presentations
- Cross-platform would require significant compromises on core features

**Tradeoffs**:
- Windows users cannot use the app
- Smaller potential user base
- No web version for quick access

---

### D002: Swift + SwiftUI (Not Electron/React Native)

**Decision**: Use Swift and SwiftUI for development

**Date**: Project inception

**Context**: Choosing the programming language and UI framework.

**Options Considered**:
1. Swift + SwiftUI (native Apple)
2. Swift + AppKit (older native Apple)
3. Electron (JavaScript-based)
4. React Native for macOS

**Why This Choice**:
- SwiftUI is Apple's modern UI framework with excellent macOS support
- Native code gives best access to low-level window features (capture protection)
- Better performance than JavaScript-based alternatives
- Smaller app size, faster startup
- AppKit available when SwiftUI falls short (hybrid approach)

**Tradeoffs**:
- Steeper learning curve than web technologies
- Fewer developers familiar with SwiftUI
- Can't share code with potential future web version

See: [Why Swift/SwiftUI](why-swift-swiftui.md)

---

### D003: Menu Bar App (Not Dock App)

**Decision**: App lives in menu bar, not dock

**Date**: Project inception

**Context**: Deciding how users will access and see the app.

**Options Considered**:
1. Menu bar app (no dock icon)
2. Standard dock app
3. Dock app with menu bar helper
4. Completely hidden (keyboard-only access)

**Why This Choice**:
- Minimal visual footprint during demos
- Always accessible with one click
- Fits the "utility" nature of the app
- Doesn't clutter dock during presentations

**Tradeoffs**:
- Less discoverable than dock apps
- New users might forget it's running
- Less familiar to casual Mac users

See: [Why Menu Bar App](../02-architecture/why-menu-bar-app.md)

---

### D004: Carbon Event Manager for Hotkeys

**Decision**: Use Carbon Event Manager for global hotkeys

**Date**: Phase 1 implementation

**Context**: We need keyboard shortcuts that work even when other apps are focused.

**Options Considered**:
1. Carbon Event Manager (legacy Apple API)
2. CGEvent tap
3. Third-party hotkey library
4. Accessibility API

**Why This Choice**:
- Carbon is the established, reliable method for global hotkeys
- Well-documented with many examples
- Works consistently across macOS versions
- Simpler to implement than CGEvent tap

**Tradeoffs**:
- Carbon is technically deprecated (but still works and is used by many apps)
- Requires importing Carbon framework
- May need migration in future macOS versions

See: [Why Carbon Hotkeys](why-carbon-hotkeys.md)

---

### D005: Five Fixed Layouts (Not Freeform Canvas)

**Decision**: Offer 5 pre-designed card layouts, not freeform editing

**Date**: MVP scoping

**Context**: Deciding how users will design their cards.

**Options Considered**:
1. Fixed layout templates (our choice)
2. Freeform canvas (like Canva)
3. Simple text-only cards
4. Import from other tools

**Why This Choice**:
- Faster to create cards (no design decisions)
- Consistent, readable results
- Much simpler to implement
- Covers most common use cases

**Tradeoffs**:
- Less flexibility for unusual content
- Users can't customize layouts
- May feel limiting to some users

See: [Why 5 Layouts](why-5-layouts.md)

---

### D006: Local Storage Only (Not Cloud Sync)

**Decision**: Store data locally, no cloud synchronization

**Date**: MVP scoping

**Context**: Deciding where user data lives.

**Options Considered**:
1. Local only (our choice)
2. iCloud sync
3. Custom cloud backend
4. Export/import for manual sync

**Why This Choice**:
- Simpler to implement and maintain
- Works offline (critical for demos)
- No account required
- No privacy concerns about cloud storage
- Faster and more reliable

**Tradeoffs**:
- No multi-device sync
- User responsible for backups
- Can't easily share decks with teammates

---

### D007: JSON for Data Storage (Not SQLite/Core Data)

**Decision**: Store decks as JSON files

**Date**: Phase 1 implementation

**Context**: Choosing how to persist user data.

**Options Considered**:
1. JSON files (our choice)
2. SQLite database
3. Core Data (Apple's data framework)
4. Property lists (plist)

**Why This Choice**:
- Human-readable (can be inspected/edited)
- Simple to implement
- Easy to debug
- Portable (could be used by future web version)
- Swift's Codable makes JSON trivial

**Tradeoffs**:
- Less efficient for very large decks (not a concern for our use case)
- No advanced querying (not needed)
- No built-in migration tools

---

### D008: macOS 14 Minimum (Not Older Versions)

**Decision**: Require macOS 14 Sonoma or later

**Date**: Project inception

**Context**: Setting minimum OS version.

**Options Considered**:
1. macOS 14 Sonoma (our choice)
2. macOS 13 Ventura
3. macOS 12 Monterey

**Why This Choice**:
- SwiftUI improvements in macOS 14 simplify our code
- Better window management APIs
- Users running demos typically have updated hardware
- Two years of OS support is reasonable

**Tradeoffs**:
- Users on older Macs can't use the app
- Limits initial audience slightly

---

### D009: Sandbox Disabled (Required for Global Hotkeys)

**Decision**: Disable the macOS app sandbox

**Date**: Phase 1 implementation

**Context**: We need to register global hotkeys that work when other apps are focused.

**Options Considered**:
1. Disable sandbox entirely (our choice)
2. Sandbox with Accessibility API
3. Sandbox with user-granted permissions

**Why This Choice**:
- Carbon Event Manager (our hotkey solution) does not work inside a sandboxed app
- Global hotkeys are a core feature - the app is nearly useless without them
- Accessibility API requires explicit user permission AND still needs sandbox disabled for some hotkey scenarios
- Many popular productivity apps (Alfred, Rectangle, Raycast) also run without sandbox for the same reason

**Tradeoffs**:
- Cannot distribute through Mac App Store (requires sandbox)
- Reduced security isolation (app has more system access)
- Must distribute directly or through third-party stores (Homebrew, SetApp, direct download)

**Mac App Store Alternative**:
If Mac App Store distribution becomes important, we would need to:
1. Switch to CGEvent tap with user-granted Accessibility permission
2. Accept that some hotkey combinations may not work reliably
3. Add significant UI for permission management

For a productivity tool aimed at technical users (sales engineers), direct distribution is acceptable.

**File Reference**: `PresenterOverlay/Resources/PresenterOverlay.entitlements`

---

## Future Decisions (Not Yet Made)

The following decisions are documented for future phases:

- **D-TBD**: Export/import format for decks
- **D-TBD**: Additional layout templates
- **D-TBD**: Integration with presentation tools
- **D-TBD**: Team/sharing features

---

*This log is updated as new decisions are made.*
