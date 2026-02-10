# Decision Log

This document tracks all significant decisions made during the development of Prompter. Each entry explains what we decided, why, and what alternatives we considered.

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

### D004: CGEvent Tap for Hotkeys

**Decision**: Use CGEvent tap for global hotkeys (migrated from Carbon Event Manager)

**Date**: Phase 1 implementation (Carbon); migrated to CGEvent tap pre-release

**Context**: We need keyboard shortcuts that work even when other apps are focused. Originally implemented with Carbon Event Manager, migrated to CGEvent tap before v1.0 release for long-term compatibility.

**Options Considered**:
1. Carbon Event Manager (legacy Apple API) — used initially, now replaced
2. CGEvent tap — **current implementation**
3. Third-party hotkey library
4. Accessibility API

**Why CGEvent Tap**:
- Carbon Event Manager is deprecated with no guarantee of future support
- CGEvent tap is a modern, supported API
- Provides finer control over event handling (can consume events to prevent propagation)
- Requires Accessibility permissions, which the app handles with automatic prompting and retry

**Tradeoffs**:
- Requires Accessibility permissions (prompted on first launch via `AXIsProcessTrustedWithOptions`)
- Slightly more complex than Carbon, but well-contained in `HotkeyManager.swift`
- Must handle tap-disabled-by-timeout events (auto re-enabled)

See: [Hotkey Implementation History](why-carbon-hotkeys.md)

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
- CGEvent tap (our hotkey solution) requires Accessibility permissions which conflict with strict sandbox
- Global hotkeys are a core feature - the app is nearly useless without them
- Many popular productivity apps (Alfred, Rectangle, Raycast) also run without sandbox for the same reason

**Tradeoffs**:
- Cannot distribute through Mac App Store (requires sandbox)
- Reduced security isolation (app has more system access)
- Must distribute directly or through third-party stores (Homebrew, direct download)

For a productivity tool aimed at technical users (sales engineers), direct distribution is acceptable.

**File Reference**: `Prompter/Resources/Prompter.entitlements`

---

### D010: Sparkle for Auto-Updates (Not Mac App Store)

**Decision**: Use Sparkle 2.x framework for automatic updates

**Date**: v1.1.0 release prep

**Context**: Users need a way to receive updates without manually checking GitHub.

**Options Considered**:
1. Sparkle framework (our choice)
2. Mac App Store
3. Manual download only
4. Custom update mechanism

**Why This Choice**:
- Sparkle is the de facto standard for non-App Store macOS apps
- EdDSA signing provides secure, tamper-proof updates
- Appcast XML hosted on GitHub (no infrastructure needed)
- Seamless user experience with background checks and one-click install

**Tradeoffs**:
- First version with Sparkle (v1.1.0) requires manual upgrade from v1.0
- Appcast must be on the main branch for raw GitHub URL accessibility
- EdDSA private key must be securely stored in the developer's Keychain

---

### D011: Presentation Timer in AppState (Not Separate Service)

**Decision**: Manage timer state directly in AppState rather than a separate TimerService

**Date**: v1.1.0 feature development

**Context**: Adding a per-card countdown timer for presentation pacing.

**Options Considered**:
1. Timer logic in AppState (our choice)
2. Separate TimerService class
3. Timer in OverlayWindowController

**Why This Choice**:
- Timer state (seconds remaining, paused, running) is tightly coupled to card navigation
- Card changes reset the timer, which is already coordinated in AppState
- Avoids additional indirection for a feature that touches many existing AppState properties
- Timer settings (mode, durations, scope) are part of the persisted Settings model

**Tradeoffs**:
- AppState grows larger (mitigated by clear MARK sections)
- Timer logic is not independently testable without AppState (mitigated by comprehensive TimerTests)

---

### D012: os.Logger for Logging (Not print or Third-Party)

**Decision**: Use Apple's unified logging (`os.Logger`) instead of `print()` statements

**Date**: v1.1.0 release prep

**Context**: 59 `print()` calls needed to be replaced with proper logging for a release build.

**Options Considered**:
1. Apple os.Logger (our choice)
2. Keep print() statements
3. Third-party logging library (CocoaLumberjack, SwiftyBeaver)

**Why This Choice**:
- Built into macOS, no dependencies
- Debug-level messages hidden in release builds (better performance)
- Filterable by subsystem/category in Console.app
- Per-file Logger instances with descriptive categories

**Tradeoffs**:
- String interpolation in log messages requires `\(variable, privacy: .public)` for non-private data
- Cannot easily redirect logs to a file without additional work

---

## Future Decisions (Not Yet Made)

The following decisions are documented for future phases:

- **D-TBD**: Export/import format for decks
- **D-TBD**: Additional layout templates
- **D-TBD**: Integration with presentation tools
- **D-TBD**: Team/sharing features

---

*This log is updated as new decisions are made.*
