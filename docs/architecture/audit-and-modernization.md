# Prompter audit and modernization: design

Status: proposed (2026-10-14). Written in parallel with the requirements brief `docs/requirements/audit-and-modernization.md` (stories `US-audit-and-modernization-1..24`, backlog `PRMT-007..PRMT-030`, findings `F-01..F-19`) on `req/prompter-audit`. This design uses the brief's story, finding, and identifier names wherever the two overlap. **Owner answers applied 2026-10-14** (`req/prompter-answers`): deployment target macOS 26.0 built with the current SDK (section 8 rewritten for 26 and 27; the macOS 14 smoke job and option B dropped), signing and notarization with the owner's personal Apple Developer account (4.4, 4.5), Mini grants approved as each target exists, ⌘⇧ hotkeys kept and consumed only while the overlay is visible (6.1), Prompter is a commercial product eventually (section 9). The desktop lock's heartbeat is live (4.3, R-09). Findings the brief does not have are numbered `A-01..` here (section 2.6) for the BA to fold. Section 13 is the story review; section 15 maps stories to design sections.

This repository is public. Every machine, runner, account, and credential below is a placeholder or a secret name; the real values live in GitHub encrypted secrets, the owner's keychain, or the QA machine's private configuration.

| Placeholder | Meaning |
|---|---|
| `<qa-mini>` | Lucius' Mac mini: the agent/QA machine (macOS 26.4, one display). It already hosts self-hosted runners for other repos and the Sentwise and ContainerBar desktop QA passes. |
| `<prompter-runner>` | The new repository-scoped self-hosted runner for `michaeltookes/prompter` on `<qa-mini>` (section 4.3). |
| `<owner>` | The repository owner (Developer ID holder, Sparkle key holder). |

Severity scale (same as the brief): **Critical** breaks the core promise for most users; **High** breaks a documented feature or another app's normal use; **Medium** loses data or blocks the factory in a plausible case; **Low** hygiene. Category: **fix** (audit fix, Epic A), **parity** (CI/CD and QA parity, Epics B and C), **makeover** (Liquid Glass, Epic D).

---

## 1. Context

**What exists.** Prompter 1.2.0 (released 2026-02-12) is a menu-bar-only (`LSUIElement`) macOS 14+ app: an Xcode project at `Prompter/Prompter.xcodeproj` (objectVersion 56, created with Xcode 15, Swift 5.9 language mode), one app target and one hosted unit-test target (`PrompterTests`, 10 files, 134 tests), one SPM dependency (Sparkle, `upToNextMajor` from 2.0.0 on `main`, resolving to 2.10.0 today; PRMT-007 pins exactly 2.8.1, the version v1.2.0 shipped), not sandboxed, hardened runtime on, Developer ID distribution through four local shell scripts (`Prompter/scripts/`), a Sparkle appcast at the repo root served by GitHub Pages from `main`, a DMG for the Homebrew cask (`michaeltookes/homebrew-tap`, `Casks/prompter.rb`), and two Claude workflows. No build, test, lint, or release workflow exists; `main` is unprotected; no self-hosted runner is registered for this repo.

Confirmed on 2026-10-14 (MacBook, Xcode 26.2, `xcodebuild build-for-testing`, signing disabled, derived data in a temp dir, nothing launched): the project builds with the macOS 26 SDK; one Swift 6 warning (`App/AppState.swift:173`, main-actor `PersistenceService.shared` referenced from a default argument). SwiftLint 0.63.2 with `Prompter/.swiftlint.yml`: **1 error** (`App/AppState.swift:19`, `type_body_length` 602 > 600) and 35 warnings, so a lint gate fails on day one (A-03).

**What changes.** (1) Audit fixes (Epic A). (2) CI/CD parity with ContainerBar plus Sentwise's tag-driven release (Epic B). (3) A Lucius daily QA lane modelled on ContainerBar's (Epic C). (4) A Liquid Glass makeover for macOS 26 and 27, with the deployment target raised to macOS 26.0 (Epic D). Enabling all four is one cross-cutting change: **app flavors with isolated storage** (section 3.2), so tests, PR hunts, QA builds, and the released app never share data.

**What stays.** The data model and file layout (`~/Library/Application Support/Prompter/{Decks,Assets,Settings.json}`), the six layouts, the CGEvent-tap hotkey mechanism (decision D004), Sparkle (D010), JSON persistence (D007), no sandbox (D009), Developer ID + cask + Sparkle distribution, the appcast URL `https://michaeltookes.github.io/prompter/appcast.xml` (baked into every installed copy), and the bundle identifier `com.tookes.Prompter`.

## 2. Architecture audit

### 2.1 Components as they are

```
PrompterApp (@main, SwiftUI App)  ── empty WindowGroup (F-15)
  └─ AppDelegate (@MainActor, NSApplicationDelegate)          App/AppDelegate.swift
       ├─ AppState (@MainActor ObservableObject, 25 @Published) App/AppState.swift (894 lines)
       │    ├─ PersistenceService.shared (@MainActor singleton) Services/PersistenceService.swift
       │    │     Task.detached writes, unused ioQueue (F-07)
       │    ├─ Debouncer deck 1.0 s / settings 0.5 s           Utilities/Debouncer.swift
       │    └─ Timer (Combine Timer.publish 1 Hz)               AppState.swift:681
       ├─ OverlayWindowController ── OverlayWindow (NSWindow, .floating, all Spaces, sharingType)
       │    └─ OverlayContentView (SwiftUI) → OverlayCardRenderer → 6 LayoutRenderers, OverlayFooterView
       ├─ MenuBarController (NSStatusItem + NSMenu rebuilt in menuNeedsUpdate)
       │    ├─ Deck Editor NSWindow + NSHostingView(DeckEditorView: HSplitView sidebar|canvas)
       │    ├─ Test Protected Mode NSWindow (TestCaptureView)
       │    └─ ThemedPanelWindow (NSPanel, forced darkAqua): TimeInputPanelView, DeckPickerPanelView
       ├─ HotkeyManager.shared (not actor-isolated; CGEvent tap on main run loop; AX prompt w/ 12 h cooldown)
       └─ UpdateManager (Sparkle SPUStandardUpdaterController, validated config)
  AssetManager.shared (@MainActor; Assets/ files; 50-entry NSImage cache)  Services/AssetManager.swift
```

**Concurrency and state.** Everything UI-facing is `@MainActor`. `AppState` is one `ObservableObject`; every `@Published` change (including the 1 Hz timer tick, `AppState.swift:691`) invalidates every view that holds the environment object, so the whole Deck Editor re-evaluates once a second while a timer runs (A-07). Background work is ad hoc `Task.detached` (persistence writes, image import/decoding, drop handling in `Views/Shared/ImageDropZone.swift:93,122,140`) that captures non-`Sendable` state; it compiles only because the target is in Swift 5 mode with minimal checking (A-08). `HotkeyManager` is a non-isolated singleton whose event-tap callback runs on the main run loop and hops to `DispatchQueue.main` again (`HotkeyManager.swift:332`). Settings are auto-saved by 13 Combine sinks (`AppState.swift:726-803`), one of which saves Settings on every `currentDeck` change, so every keystroke in the editor schedules a Settings write as well as a deck write.

**Dependencies.** Sparkle only, `upToNextMajor` 2.0.0, `Package.resolved` not committed (`.gitignore:9-12` ignores `project.xcworkspace/` where it lives), so each machine and each day can resolve a different Sparkle; `publish-release.sh` then finds `sign_update` by searching DerivedData (F-10). No other packages.

**Build settings.** `MACOSX_DEPLOYMENT_TARGET = 14.0` everywhere; `SWIFT_VERSION = 5.9`; `CODE_SIGN_STYLE = Automatic` with the owner's team in the project (overridden to Manual + Developer ID by `build-release.sh`); `ENABLE_HARDENED_RUNTIME = YES`; entitlements: `app-sandbox = false` only; `LastUpgradeCheck = 1500`; Release builds universal (arm64 + x86_64). `Info.plist` hardcodes `CFBundleShortVersionString 1.2.0` and `CFBundleVersion 4` while the project also carries `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` four times each: two sources of truth for the version (A-04). No shared scheme (F-10): `xcodebuild -list` shows an auto-generated `Prompter` scheme today, which is not guaranteed on a clean runner and cannot carry test-action settings.

**Tests.** 134 XCTest cases, hosted in the app (`TEST_HOST = Prompter.app`, `PrompterTests` build settings at `project.pbxproj:713-742`). Running them **launches the full app**: `applicationDidFinishLaunching` creates the status item, prompts for Accessibility, installs the event tap if trusted, starts Sparkle against the live appcast, and loads/creates decks in the real `~/Library/Application Support/Prompter/`. `PersistenceServiceTests` uses `PersistenceService.shared` on the real folder and `testSaveAndLoadSettings` overwrites the real `Settings.json` (`PrompterTests/PersistenceServiceTests.swift:44-60`). On a developer Mac that clobbers the user's settings; on `<qa-mini>` it would clobber the QA baseline (A-01, A-02).

### 2.2 Findings already in the brief (confirmed, with design notes)

| # | Sev | Cat | Confirmed at | Design note |
|---|---|---|---|---|
| F-01 | High | fix | `Services/HotkeyManager.swift:312-339` returns `nil` for every mapped ⌘⇧ key regardless of state | Section 6.1. Also a QA-lane hazard: while Prompter runs on `<qa-mini>` it swallows ⌘⇧←/→ (text selection) and ⌘⇧T/[/] from the Sentwise and ContainerBar passes (A-11). |
| F-02 | High | fix | `AppState.swift:564-571` writes `overlayScrollOffset`; nothing reads it (only `AppState.swift` references it) | Section 6.2. |
| F-03 | High | fix | `OverlayWindowController.swift:43` uses the saved rect verbatim; no `NSScreen` reference in the app | Section 6.3. |
| F-04 | High (verify) | fix | `Windows/OverlayWindow.swift:59,79-85` relies only on `sharingType` | Section 6.4. The measurement (TC-PR-10) runs before any copy changes. |
| F-05 | Medium | fix | `AppDelegate.swift:98-117` 12 × 5 s then stops; no revoke detection | Section 6.5. |
| F-06 | Medium | fix | one `deckDebouncer` (`AppState.swift:119`); `saveDeckSync` cancels it (`:853-857`) | Section 6.6; `Debouncer.flush()` (`Utilities/Debouncer.swift:104`) already exists and is unused. |
| F-07 | Medium | fix | `PersistenceService.swift:228-242` unordered detached writes; `ioQueue` unused (`:63`); `loadDeck` returns nil on decode error (`:215-223`) | Section 6.6. |
| F-08 | Medium | fix | no `UndoManager` use | Section 6.7. |
| F-09 | Medium | fix | `AssetManager.swift:202-233` cleanup has no callers; clone shares `AssetRef`s (`AppState.swift:271-280`) | Section 6.7; GC must count references across all decks and the undo stack. |
| F-10 | Medium | parity | no `xcshareddata/`; `.gitignore:9-12` | Section 4.2. Already dispatched as PRMT-007. |
| F-11 | Medium | parity | 74 tracked files under `Prompter/dist/` despite `.gitignore:13` | `git rm -r --cached Prompter/dist` in PRMT-007. |
| F-12 | Medium | parity | `publish-release.sh` commits to `main` and recreates releases | Section 4.5; appcast file of record moves to a `gh-pages` branch, published by `actions/deploy-pages`. |
| F-13 | Low | parity | `homebrew-tap/Casks/prompter.rb:9` `depends_on macos: ">= :sonoma"`, no `auto_updates` | Section 4.6. The live tap can be fixed now, independent of a release (genkei-ops 16b). |
| F-14 | Low | fix | dead code list in section 2.4 | |
| F-15 | Low (verify) | fix | `App/PrompterApp.swift:15-21` | Replace with `Settings { EmptyView() }` (no window until opened); Epic D may later fill it. |
| F-16 | Low | fix/makeover | `OverlayWindowController.swift:257-306` | Superseded by the glass hide button (section 8.4); US-14 AC3 lands first as a plain `Button`. |
| F-17 | Low | parity | `appcast.xml` stub notes | Release notes are generated from the CHANGELOG section (section 4.5). |
| F-18 | Low | fix | `CLAUDE.md`, `AGENTS.md` | Also: `CLAUDE.md` "Validation script: Not yet implemented" becomes `scripts/validate-release.py`. |
| F-19 | Low (verify) | parity | `.floating` level | TC-PR-13 (weekly leg). If Keynote/PowerPoint slideshows cover it, the fix is `.statusBar` level or `.screenSaver - 1`; decide on evidence, not now. |

### 2.3 Additional findings (A-xx, for the BA to fold)

| # | Sev | Cat | Where | Finding | Disposition |
|---|---|---|---|---|---|
| A-01 | High (for the QA lane), Medium otherwise | parity | `PrompterTests/PersistenceServiceTests.swift:17,55,80`; `PersistenceService.swift:70-83` | Unit tests read and write the real Application Support folder through the singleton; `testSaveAndLoadSettings` overwrites the real `Settings.json` with a random `lastOpenedDeckId`. | `PersistenceService(rootURL:)` + temp-dir tests (section 3.2). Must land before any suite runs on `<qa-mini>`. |
| A-02 | Medium | parity | `AppDelegate.swift:40-77` | Hosted tests boot the full app: status item, Accessibility prompt, event tap, Sparkle check against the live appcast, real deck load. On CI the Sparkle check will show an update alert once a newer release exists than the PR's version. | `AppEnvironment.unitTest` short-circuits launch (section 3.2). |
| A-03 | Medium | parity | `App/AppState.swift:19` | SwiftLint `type_body_length` error (602 lines): the lint gate fails as soon as it is added. | Move the timer (`:579-721`) and auto-save sinks (`:723-803`) into `AppState+Timer.swift` and `AppState+AutoSave.swift` extensions. Folded into US-2. |
| A-04 | Low | parity | `Resources/Info.plist` `CFBundleShortVersionString`/`CFBundleVersion` | Version kept in two places (plist literal and 8 pbxproj settings); release-prep edits 10 places. | Plist values become `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)`; the validator reads the build settings. Folded into US-5. |
| A-05 | Low (privacy) | parity | `Prompter/scripts/notarize.sh:6`, `build-release.sh:4`, `create-dmg.sh:4` | The owner's personal Apple ID email and signing identity string are hardcoded in a public repo. | Scripts read `NOTARY_APPLE_ID`, `NOTARY_TEAM_ID`, `SIGNING_IDENTITY` from the environment (CI secrets, or a local `.env` that is gitignored); the email is removed from the file (history keeps it; rotate nothing, it is an email, not a secret). Folded into US-5. |
| A-06 | Low | fix | `Services/AssetManager.swift:238-246` | "FIFO" cache eviction removes `imageCache.keys.first`, an arbitrary key. | Replace with an `NSCache` (cost = pixel count). With US-13. |
| A-07 | Low (perf) | fix | `AppState.swift:681-721` | 1 Hz timer republishes the whole `ObservableObject`; the editor re-evaluates each second while timing. | Not a story now. Candidate for a later item: move timer state to its own `@Observable` model (macOS 14 has Observation). |
| A-08 | Low | fix | `Task.detached` sites listed in 2.1; `AppState.swift:173` | Not Swift 6 ready; one warning that is an error in Swift 6 mode. | No language-mode change in this intake. The persistence rewrite (section 6.6) removes the riskiest sites; the rest is a later item. |
| A-09 | Low | fix | `Models/Card.swift`, `Models/Deck.swift` | Synthesized `Codable`: any future non-optional field makes every existing deck unreadable (and today an unreadable deck vanishes, F-07). | This intake adds no deck fields. Any later field must be optional or decoded with `decodeIfPresent`; written into `DATA_MODEL.md` by US-14. |
| A-10 | Medium | parity | `.github/workflows/claude-code-review.yml` | The factory dropped the Claude code-review workflow on 2026-10-12 (Codex pre-PR review plus the repo's bot reviewer replace it). Keeping it here contradicts that decision; the brief's US-3 asks for it. | Remove it; keep `claude.yml`; add `claude-pr-description.yml` (section 4.1, story review US-3). |
| A-11 | High (QA lane) | parity | F-01 on a shared desktop | A running Prompter on `<qa-mini>` takes ⌘⇧ arrows/T/[/]/P/C/O/=/- from every other desktop pass. | Until a release containing PRMT-013 is installed on `<qa-mini>`, the pass quits Prompter at restore and the hourly check asserts it is **not** running (section 5.6). |
| A-12 | Low | parity | `Prompter/dist/ExportOptions.plist` vs `Prompter/scripts/ExportOptions.plist` | Two export option files; scripts use the one in `scripts/`. | Goes with F-11. |
| A-13 | Low | fix | `MenuBarController.swift:249,299,455,502,528` | `NSApp.activate(ignoringOtherApps:)` deprecated in macOS 14 (part of F-14). | `NSApp.activate()`. |

### 2.4 Dead code (F-14, confirmed by reference search)

Unused in the app: `Windows/TestCaptureWindowController.swift` (whole file; `MenuBarController` builds its own window at `:263-300`); `Views/Shared/FrostedPanelView.swift` (only its preview references it); `PersistenceService.clearAllData`, `.totalDataSize`, `.loadDeckMetadata` (tests only), `.ioQueue`; `AssetManager.importImage(from:)` and `.importImage(data:)` (sync variants), `.totalAssetSize`; `AppState.reloadDecks`; the alias pairs `AppState.loadDeck`/`openDeck` and `navigateToCard`/`goToCard`; the stale comment `UpdateManager.swift:95-96`; the placeholder views `DeckEditorPlaceholderView` and `TestCapturePlaceholderView` (`MenuBarController.swift:540-600`, unreferenced). **Become live** with this design rather than deleted: `Debouncer.flush()`, `AssetManager.cleanupUnusedAssets`, `AssetManager.deleteAsset`, `Deck.allAssetRefs`. Tests that cover deleted helpers are deleted with them.

## 3. Components and boundaries (target)

### 3.1 Diagram

```
 GitHub (public repo michaeltookes/prompter)
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │ swift-ci.yml  (PR, push main)  ── GitHub-hosted macos-15, Xcode 26.x              │
 │   Build & Test │ SwiftLint   (Xcode 27 on a hosted macOS 26 image from PRMT-026)  │
 │ prowl-qa.yml  (same-repo PR, dispatch) ── self-hosted <prompter-runner>           │
 │ qa-build.yml  (dispatch: ref) ── GitHub-hosted; env qa-build; Prompter QA.app zip │
 │ release.yml   (tag v*, dispatch dry_run|resume) ── GitHub-hosted; env release     │
 │   → Release (zip,dmg,sha256) → gh-pages → deploy-pages → tap cask │
 │ claude.yml (@claude) │ claude-pr-description.yml                                  │
 └──────────────────────────────────────────────────────────────────────────────────┘
            │ artifacts / releases                        │ Pages (Actions deployment)
            ▼                                             ▼
 <qa-mini> (macOS 26.4, logged-in GUI session of the operator agent)
 ┌──────────────────────────────────────────────────────────────────────────────────┐
 │ OpenClaw cron "Prompter daily QA" 08:15 CT ── brief tasks/<date>-prompter-daily.md │
 │   Peekaboo (AX + screenshots + video)                                            │
 │   /Applications/Prompter.app  (cask = notarized DMG)  flavor production          │
 │       data: ~/Library/Application Support/Prompter/  (QA baseline, restored)     │
 │   ~/Applications/Prompter QA.app (qa-build artifact, pre-PR gate) flavor qa      │
 │       data: ~/Library/Application Support/Prompter-QA/                           │
 │ launchd com.genkeilabs.prompter-hourly (zero tokens, < 60 s)                     │
 │ <prompter-runner> → .prowl/DerivedData/.../Prompter.app  flavor hunt             │
 │       data: ~/Library/Application Support/Prompter-Hunt/ (wiped + seeded per launch)│
 │ shared desktop lock + CI-busy predicate (Runner.Worker / runners API)            │
 └──────────────────────────────────────────────────────────────────────────────────┘
 Outputs: ~/.openclaw/workspace/artifacts/prompter-qa/runs/<date>-<kind>-<HHMM>/ → one Discord message
```

Ownership: a `builder` owns repo changes; `vendor-ops` owns GitHub settings (Pages source, environments, secrets placement, branch protection); `homelab-it` owns `<prompter-runner>` registration on `<qa-mini>`; the orchestrator owns the Lucius brief, recipe, cron job, and launchd job; `<owner>` supplies credentials and the one-time TCC grants.

### 3.2 App flavors and isolated storage (new, cross-cutting)

One new file `App/AppEnvironment.swift` and one `Services/StoragePaths.swift`. Resolved once at launch, before anything touches disk.

| Flavor | How it is selected | Bundle id | Data root | Status item | Event tap | Sparkle | Defaults domain |
|---|---|---|---|---|---|---|---|
| `production` | default | `com.tookes.Prompter` | `~/Library/Application Support/Prompter/` | yes | yes | yes | standard |
| `qa` | `Info.plist` key `PrompterFlavor = qa` (build setting `PROMPTER_FLAVOR=qa`) | `com.tookes.Prompter.qa` | `~/Library/Application Support/Prompter-QA/` | yes, label "Prompter QA" | yes | **no** | its own (bundle id) |
| `hunt` | `PrompterFlavor = hunt`, or `PROMPTER_HUNT_MODE=1` in Debug builds only, or the bundle path contains `/.prowl/DerivedData/` (ContainerBar parity) | `com.tookes.Prompter.hunt` | `~/Library/Application Support/Prompter-Hunt/`, deleted and re-seeded from `Contents/Resources/HuntSeed/` on every launch | yes | **no** | **no** | its own, `removePersistentDomain` on launch |
| `unitTest` | `ProcessInfo.environment["XCTestConfigurationFilePath"] != nil` | (test host) | none: `AppDelegate` returns right after `setActivationPolicy(.accessory)` | no | no | no | not touched |

- `Info.plist` gains `PrompterFlavor` = `$(PROMPTER_FLAVOR)`; the project sets `PROMPTER_FLAVOR = production` at project level. Production builds ignore `PROMPTER_HUNT_MODE` (compiled out with `#if DEBUG`), so no environment variable can redirect a user's data.
- `StoragePaths(root:)` derives `decks`, `assets`, `settings`, and (new) `decksUnreadable = Decks/Unreadable/`, `assetsTrash = Assets/.Trash/`. `PersistenceService` and `AssetManager` take `StoragePaths` in their initializers; the `shared` instances are built from `AppEnvironment.current`. Tests construct both with a temp-dir root (`FileManager.default.temporaryDirectory/PrompterTests-<uuid>`) and delete it in `tearDown`.
- The legacy `PresenterOverlay` migration (`PersistenceService.swift:85-148`) runs only in `production`.
- The QA and hunt flavors show their flavor in the status item's accessibility label and the About text, so a screenshot can never be mistaken for the release.
- **Every non-production flavor needs its matching bundle id** (behaviour change shipped in PRMT-031, `App/AppEnvironment.swift`): a declared `PrompterFlavor = qa` is honoured only under `com.tookes.Prompter.qa`; `hunt` (declared, `PROMPTER_HUNT_MODE=1` in Debug, or a `.prowl/DerivedData/` bundle path) only under `com.tookes.Prompter.hunt`. Any other combination resolves to `production` and logs one line that the request was ignored, so QA or hunt behaviour (wipe and re-seed, no Sparkle) can never run under the released app's bundle id and defaults domain. Builds of the qa and hunt flavors must therefore set `PRODUCT_BUNDLE_IDENTIFIER` and `PROMPTER_FLAVOR` together (4.3, 4.4).

### 3.3 Accessibility handles (US-15)

Identifiers are the brief's list plus the ones the cases in section 5.7 need. AppKit: `setAccessibilityIdentifier(_:)` on the status button and on each `NSMenuItem` (`NSMenuItem` conforms to `NSAccessibility` identifiers via `setAccessibilityIdentifier`; the builder confirms Peekaboo sees menu-item identifiers on 26.4 and, if not, the recipe matches menu titles, which are fixed strings). SwiftUI: `.accessibilityIdentifier(_:)`.

| Surface | Identifiers |
|---|---|
| Status item and menu | `prompterStatusItem`, `menuHotkeyStatus` (US-11), `menuToggleOverlay`, `menuOpenEditor`, `menuMoveOverlayTo` (US-9), `menuProtectedMode`, `menuClickThrough`, `menuTimer`, `menuTimerStartStop`, `menuTestProtectedMode`, `menuCheckForUpdates`, `menuQuit` |
| Overlay | `overlayWindow`, `overlayCardTitle`, `overlayCardBody`, `overlayCardCounter`, `overlayTimer`, `overlayProtectedIndicator`, `overlayClickThroughIndicator`, `overlayClose`, `overlayScroll` |
| Editor | `editorWindow`, `editorDeckList`, `editorDeckRow-<index>`, `editorCardList`, `editorCardRow-<index>`, `editorAddCard`, `editorLayoutPicker`, `editorCardTitleField`, `editorUnreadableNotice` (US-12 AC3), `editorSaveErrorNotice` (US-12 AC4), `toolbarToggleOverlay`, `toolbarDeckMenu` |
| Panels and windows | `timeInputField`, `timeInputSave`, `deckPickerRow-<index>`, `deckPickerDone`, `testCaptureWindow`, `testCaptureRun`, `testCaptureResult` |

**Overlay state contract.** The overlay window's `accessibilityValue` is a stable machine-readable string updated on every state change: `card=3/5;protected=on;clickthrough=off;opacity=85;font=100;scroll=0;timer=00:42;display=<localizedName>`. The QA recipe asserts on this string instead of OCR wherever the case is about state; screenshots remain the evidence for anything visual. A unit test covers the formatter.

**`.prowl/config.yml` forbiddenSelectors** add `menuCheckForUpdates`, `menuTestProtectedMode`, `testCaptureRun` (would request Screen Recording), `editorDeleteDeck`, and the substring families `menu=` and `text=` (ContainerBar parity).

## 4. CI/CD parity

### 4.1 Workflow set

| File | Trigger | Runner | Jobs / purpose | Secrets used |
|---|---|---|---|---|
| `swift-ci.yml` (new) | `pull_request` → main, `push` → main; concurrency per ref, cancel in progress | GitHub-hosted `macos-15`, Xcode 26.x selected exactly as ContainerBar's `swift-ci.yml` (`XCODE_PREFERRED: "26.2"`, fall back to newest `Xcode_26*`, fail listing installed versions) | **Build & Test**, **SwiftLint**, **Release validator tests** step inside Build & Test (no macOS 14 smoke: owner answer 2026-10-14). From PRMT-026: Xcode 27.x on a hosted macOS 26 image | none; `permissions: contents: read` |
| `prowl-qa.yml` (new) | `pull_request` → main (same-repo heads only), `workflow_dispatch` | job `build-hunt` on GitHub-hosted macOS (same Xcode pin as `swift-ci.yml`); job `hunt` on `[self-hosted, macOS]` = `<prompter-runner>` | `build-hunt` builds the ad-hoc-signed hunt app and uploads it; `hunt` downloads it and runs the Prowl hunts (the Mini never compiles) | none |
| `qa-build.yml` (new) | `workflow_dispatch` with input `ref` | GitHub-hosted `macos-15` | Developer-ID-signed **qa** flavor zip for the pre-PR QA gate | env `qa-build`: `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID` |
| `release.yml` (new) | `push` tag `v*`; `workflow_dispatch` inputs `dry_run` (default true) and `resume` (`none`/`publish-tail`) | GitHub-hosted `macos-15` | gate → sign → notarize → release → appcast on `gh-pages` → `deploy-appcast` job (deploy-pages) → cask | env `release`: all release secrets below |
| `pages.yml` (new) | `workflow_dispatch` | ubuntu | redeploys branch `gh-pages` to Pages with `actions/upload-pages-artifact` + `actions/deploy-pages` (recovery; `release.yml`'s `deploy-appcast` job does the same on every release) | none; `pages: write`, `id-token: write`, environment `github-pages` |
| `claude.yml` (keep) | `@claude` mentions | ubuntu | unchanged; pin `actions/checkout` and the action to commit SHAs | `CLAUDE_CODE_OAUTH_TOKEN` (exists) |
| `claude-pr-description.yml` (new) | PR opened, same-repo | ubuntu | copy ContainerBar's portable file verbatim | `CLAUDE_CODE_OAUTH_TOKEN` |
| `claude-code-review.yml` | — | — | **removed** (A-10, decision 2026-10-12) | — |
| `.github/dependabot.yml` (new) | weekly | — | `github-actions` ecosystem only (Dependabot's Swift support does not read `.xcodeproj` package references) | — |

Every third-party action is pinned to a full commit SHA (ContainerBar's pins: `actions/checkout@11d5960a…` v4, `actions/cache@0057852b…` v4, `actions/upload-artifact@ea165f8d…` v4, `actions/setup-node@49933ea5…` v4). Also added: `.github/pull_request_template.md` and `.github/ISSUE_TEMPLATE/{bug.yml,feature.yml}` (US-3 AC2). The unmerged `sync-backlog.yml` on `chore/add-backlog-sync-workflow` is obsolete (Mission Control retired; PRMT-006) and is not part of the set.

**GitHub-hosted vs `<qa-mini>`.** Build, unit tests, lint, the QA build, and the release all run on GitHub-hosted runners (free for a public repo; they keep signing material off `<qa-mini>` and never touch its desktop). Only `prowl-qa` needs the Mini, because it drives a GUI through Accessibility, which a hosted runner cannot be granted. Lucius' daily pass is not CI; it is an OpenClaw job (section 5).

### 4.2 Build & Test and the test target

1. Committed: `Prompter/Prompter.xcodeproj/xcshareddata/xcschemes/Prompter.xcscheme` (Build: Prompter; Test: PrompterTests, parallelization off because the tests share `@MainActor` singletons today, code coverage on); `Prompter/Prompter.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (`.gitignore` gets a negation `!**/*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` after the existing ignore). PRMT-007 (done on `prmt-007-clean-clone-build`) pinned Sparkle to `exactVersion 2.8.1`, the version v1.2.0 shipped with, and tracks `Package.resolved` through `.gitignore` negations; that pin is kept, and the release tooling fetches the Sparkle 2.8.1 tools to match. A Sparkle upgrade is its own later PR.
2. Steps: select Xcode → cache `.spm` keyed on `hashFiles('**/Package.resolved')` → `xcodebuild -resolvePackageDependencies -clonedSourcePackagesDirPath .spm` (fails here, naming Sparkle, if the pin cannot be fetched: US-1 AC4) → `xcodebuild build-for-testing -resultBundlePath "$RUNNER_TEMP/Build.xcresult"` → `xcodebuild test-without-building -resultBundlePath "$RUNNER_TEMP/Test.xcresult"` → `python3 Prompter/scripts/tests/test_validate_release.py`. Each invocation gets its **own** result bundle path (xcodebuild refuses to write into an existing bundle), and both live under `$RUNNER_TEMP`, which is empty at job start. Common flags (no result bundle among them): `-project Prompter/Prompter.xcodeproj -scheme Prompter -destination 'platform=macOS,arch=arm64' -derivedDataPath .dd -clonedSourcePackagesDirPath .spm CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO`. Hardened runtime is off for the CI test build only, because library validation would refuse to load an ad-hoc-signed test bundle into an ad-hoc-signed hardened host. Both xcresult bundles are uploaded on failure (unit tests produce no screenshots).
3. **Does `PrompterTests` run headless without booting the app?** Today: it runs on a hosted runner (hosted macOS runners have a logged-in GUI session) but it **does boot the app** with side effects (A-01, A-02), and it must never run on `<qa-mini>` or a developer Mac in that state. After section 3.2: the host process still starts (it is an app-hosted bundle) but `AppEnvironment.unitTest` makes `applicationDidFinishLaunching` return before creating the status item, the event tap, Sparkle, or any storage, and every persistence test uses a temp root. That is enough for CI and for a `<qa-mini>` throwaway clone. **Rejected for now:** extracting `PrompterCore` (Models, Services, Utilities) into a local Swift package so the core tests run with `swift test` and no host at all. It is the cleaner end state but touches every file's imports in the same weeks as Epic A; revisit after Epic D.
4. **SwiftLint** job: pinned portable SwiftLint `0.65.1` (ContainerBar's pin), `cd Prompter && swiftlint lint --reporter github-actions-logging --no-cache` with `Prompter/.swiftlint.yml`. Errors fail the job; warnings are annotations. `--strict` is turned on after the 35 warnings are burned down (a later item, not a gate now). A-03 must merge in the same branch that adds the job.
5. **macOS 14 smoke: dropped** (owner answer 2026-10-14: deployment target macOS 26.0, section 8.2). No `macos-14` job, no `--self-check` flag, no legacy-look snapshots.

### 4.3 prowl-qa

Mirror of ContainerBar's `prowl-qa.yml`: same-repo gate, `PROWL_VERSION` pinned to the version ContainerBar uses at merge time (0.1.8 today), checkout `prowl-tools/prowl` at that tag, `npm link`, build `prowl-macdriver`, Accessibility preflight, download and install the hunt app built by the hosted `build-hunt` job (below), then the GUI segment under the desktop lock (below), strip `screenshots/` before upload (public repo), upload `.prowl/runs/` 14 days.

- **Host-wide desktop lock (required).** `<prompter-runner>` is repository-scoped and runs independently of the Sentwise and ContainerBar runners on the same desktop, and a hunt can start after a daily pass has already passed its CI-busy check. So the hunt job takes the same lock the Sentwise and ContainerBar desktop passes and hourly checks use: the directory lock `~/.openclaw/workspace/artifacts/sentwise-qa/device.lock`, managed by the operator workspace's `tools/sentwise-qa/device_lock.py` (mkdir-based; exit 75 = busy, 124 = timeout; a heartbeat thread refreshes the lock every 60 s while the command runs, and a takeover happens only on a dead owner PID or a heartbeat older than `--stale-minutes`). The workflow reads both paths from the runner's environment (`QA_DEVICE_LOCK_DIR`, `QA_DEVICE_LOCK_TOOL`, set by `homelab-it` in the runner's `.env`; the runner runs as the operator user, so the path is writable) and fails with a clear error if they are unset. Building (`build-hunt-app.sh`) happens **before** the lock (no GUI). One step then wraps the whole GUI segment, `prowl ci --junit` **and** the hunt-app quit, in a single `device_lock.py --lock "$QA_DEVICE_LOCK_DIR" --run "gh-$GITHUB_RUN_ID" --session prompter-prowl-qa --job prompter-prowl-qa --timeout 1500 -- <segment>` call, retried every 30 s while it exits 75, for at most **20 minutes**; still busy → the job fails with `desktop-busy` (never success; the PR shows a red Prowl QA that a re-run clears). Holding the lock also pauses the hourly monitors, which skip while it is held. The heartbeat is live on the operator workspace (2026-10-14), so a 25-minute hunt holding the lock is not taken over with the default `--stale-minutes`; `--stale-minutes 30` is **no longer required** and no other caller changes (R-09 closed). `homelab-it` still must set `QA_DEVICE_LOCK_DIR` and `QA_DEVICE_LOCK_TOOL` before the first run.

- **The hunt app is built on a hosted runner, never on the Mini** (decided 2026-10-14, Codex P2 on `req/prompter-answers`). From PRMT-030 the app calls `NSMenuItem.preferredImageVisibility`, a macOS 27 SDK API; `#available` guards the call at run time but does not let an older SDK compile it. `<qa-mini>` is on macOS 26.4 and cannot install Xcode 27 (needs 26.6+), so a local hunt build would fail while every hosted workflow passes. Therefore `prowl-qa.yml` has two jobs:
  - `build-hunt` (GitHub-hosted macOS, the same pinned Xcode as `swift-ci.yml`: 26.2 today, 27.x from PRMT-026): `Prompter/scripts/build-hunt-app.sh` = `xcodebuild build -configuration Debug -derivedDataPath .prowl/DerivedData PRODUCT_BUNDLE_IDENTIFIER=com.tookes.Prompter.hunt PROMPTER_FLAVOR=hunt CODE_SIGN_IDENTITY=- …`, copy `docs/qa/fixtures/` into `Contents/Resources/HuntSeed/`, re-sign ad hoc, `ditto -c -k --keepParent` → artifact `Prompter-Hunt-<shortsha>.zip` (retention 3 days). Ad hoc is enough: the Accessibility grant belongs to the runner's host process that drives the GUI, not to the hunt app, so a new signature per build costs nothing.
  - `hunt` (`needs: build-hunt`, `<prompter-runner>`): `actions/download-artifact`, `ditto -x -k` into `.prowl/DerivedData/Build/Products/Debug/` in the job's workspace (the path also matches the hunt-flavor rule of 3.2), `xattr -cr`, `lsregister -f` the bundle, then the locked GUI segment. `.prowl/config.yml` points at that prebuilt bundle and has no build command, so Prowl never invokes `xcodebuild` on the Mini. The bundle never goes to `/Applications` (US-4 AC4).
  - A failed `build-hunt` fails the check before the Mini is touched; a missing or corrupt artifact fails `hunt` at the download step, before the lock is taken, and never reports success.
  - **Alternative (b), not chosen:** upgrade `<qa-mini>` to macOS 26.6+ with Xcode 27 and keep building locally. That is a fleet change Michael decides (the design-research scan of 2026-10-14 already lists the Mini's move); it is filed as a separate `homelab-it` precondition and does not block PRMT-010 or PRMT-026. Even after it, design (a) stays, because it keeps compilation off the shared QA desktop.
- Cleanup inside the locked segment: after `prowl ci` (whatever its result), `osascript -e 'quit app id "com.tookes.Prompter.hunt"'` with a 10 s wait, then the lock is released by `device_lock.py`. If the app is still running, the step reports a warning (no `kill`; the runner is on `<qa-mini>` where a PID stop is allowed, but quitting through the app is enough and safer). A separate `if: always()` step re-checks `pgrep -x Prompter` against the hunt bundle path only for the warning; it never touches the GUI outside the lock.
- Hunts (`.prowl/hunts/`): `status-item.yml` (identifier present), `editor-opens-seed.yml` (`editorCardList` has 5 rows, first row title "QA Card 1 - Opening"), `overlay-toggle.yml` (menu Show Overlay → `overlayWindow` value starts `card=1/5`), `card-select.yml` (select `editorCardRow-2` → overlay value `card=3/5`), `protected-toggle.yml` (menu Protected Mode → value `protected=off` → back on). Open-and-assert only.
- **Runner.** `homelab-it` registers `<prompter-runner>` for `michaeltookes/prompter` (personal-account runners are repository-scoped) on `<qa-mini>` under the same macOS user as the other runners, labels `self-hosted, macOS, ARM64`, and grants its host process Accessibility once (the `<owner>` clicks the TCC prompt; same as ContainerBar's runner). The CI-busy predicate (section 5.3) gains `repos/michaeltookes/prompter/actions/runners`.
- A queued job on an offline self-hosted runner waits (GitHub keeps it queued up to 24 h); `timeout-minutes: 30` bounds only a running job. The merge checklist treats a queued or missing check as not green, which is what US-4 AC3 needs (story review).

### 4.4 QA build for the pre-PR gate

`qa-build.yml` (dispatch, input `ref`): checkout `ref` → select Xcode → import the Developer ID certificate into a temporary keychain (Sentwise's step) → `xcodebuild archive -configuration Release PRODUCT_BUNDLE_IDENTIFIER=com.tookes.Prompter.qa PROMPTER_FLAVOR=qa PRODUCT_NAME="Prompter QA"` with manual Developer ID signing and hardened runtime → `ditto -c -k --keepParent` → upload artifact `Prompter-QA-<shortsha>.zip`, retention 3 days → delete keychain. Not notarized: Lucius fetches it with `gh run download`, which sets no quarantine attribute. Developer ID signing (not ad hoc) keeps the code-signing designated requirement stable across builds, so the one-time Accessibility grant for `com.tookes.Prompter.qa` survives every new QA build. Lucius installs it to `~/Applications/Prompter QA.app`, never `/Applications`. Signing material: the Developer ID Application certificate and team id of the owner's **personal** Apple Developer account (brief Q6, 2026-10-14), not the Genkei Labs organization's. The owner grants the QA app Accessibility once when the first QA build is on the Mini (brief Q7, approved).

*As built (PRMT-032, 2026-10-16):* job `qa-build`, artifact `prompter-qa-build` holding `Prompter-QA-<shortsha>.zip` and `BUILD_INFO.txt`; also `workflow_call` for prowl-qa. The app is built unsigned with `xcodebuild build -configuration Release`, stamped (`PrompterGitCommit`, `PrompterQABuildNumber`, `PrompterQASigning`), then signed by `codesign` with the imported identity (Apple Development preferred, Developer ID Application accepted) and the hardened runtime. Missing secrets produce an ad-hoc build marked "UNSIGNED QA BUILD" rather than a failure (orchestrator ruling 2026-10-16; `require_signed` restores the failure). Readme: `docs/qa/qa-build.md`.

### 4.5 Release on tag

One script, `Prompter/scripts/release.sh`, used by CI and locally (Sentwise model); the four existing scripts become its functions and read identity and credentials from the environment (A-05). `release.yml` supplies credentials. Order of steps, each failing the job before anything is published:

1. **Version gate** (`scripts/validate-release.py pre --tag "$GITHUB_REF_NAME"`): tag `vV` == `MARKETING_VERSION` (read with `xcodebuild -showBuildSettings`) == the `Info.plist` value after A-04; `CHANGELOG.md` has `## [V] - YYYY-MM-DD` and the date equals the tag's commit date in America/Chicago; `CURRENT_PROJECT_VERSION` is greater than the newest `sparkle:version` in the live appcast. Any mismatch prints both values and exits 1 (US-5 AC5).
   **Resume mode** (`validate-release.py pre --tag vV --resume`, used only by `resume=publish-tail`): the version-and-changelog checks are the same; the appcast check becomes a three-way rule. (a) The live appcast has **no** item for V and its newest `sparkle:version` is lower than `CURRENT_PROJECT_VERSION` → accept, appcast step still to do. (b) The live appcast has an item whose `sparkle:shortVersionString = V`, `sparkle:version = CURRENT_PROJECT_VERSION`, and enclosure URL = `https://github.com/michaeltookes/prompter/releases/download/vV/Prompter.zip` → accept, appcast step will be skipped (this is the state after a successful appcast and a failed cask step). (c) Anything else (an item for V with a different build or URL, or a newer build under another version) → reject with both items printed. Resume also requires that release `vV` exists and is not a draft.
2. **No re-release**: `gh release view vV` succeeds → fail (US-5 AC6), unless `resume=publish-tail` (then step 1 runs in resume mode and the job jumps to step 9).
3. **Gate**: SwiftLint + build-for-testing + test-without-building (same flags and the same two distinct result-bundle paths as CI).
4. **Sign**: import `MACOS_CERTIFICATE_P12` into a temp keychain; archive Release (universal) with `CODE_SIGN_STYLE=Manual`, `CODE_SIGN_IDENTITY="Developer ID Application"`, `DEVELOPMENT_TEAM=$APPLE_TEAM_ID`, `OTHER_CODE_SIGN_FLAGS=--timestamp`; export with `scripts/ExportOptions.plist` (`developer-id`, manual; team from the environment, not the file).
5. **Notarize the app**: `ditto` zip → `xcrun notarytool submit --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$NOTARY_APP_SPECIFIC_PASSWORD" --wait` → on `Invalid`/`Rejected`, `notarytool log <id>` summary (issues array only) to the job log and exit 1 (US-5 AC7) → `stapler staple` → re-zip as `Prompter.zip`.
6. **DMG**: `create-dmg` (installed with `brew install create-dmg` if absent), codesign the DMG, notarize, staple → `Prompter.dmg`, `Prompter.dmg.sha256`.
7. **Verify** both artifacts: `codesign --verify --deep --strict`, `spctl --assess --type execute` (app), `spctl --assess --type open --context context:primary-signature` (DMG), `xcrun stapler validate` (US-5 AC2).
8. **Publish**: `gh release create vV Prompter.zip Prompter.dmg Prompter.dmg.sha256 --title "Prompter vV" --notes-file <CHANGELOG section> --verify-tag`.
9. **Appcast** (idempotent; skipped when step 1's resume rule (b) matched): download the **published** asset into an empty directory, `gh release download vV --pattern Prompter.zip --dir "$RUNNER_TEMP/published"` (in every mode, not only resume: a resumed run on a fresh runner has no local build, and signing the downloaded bytes guarantees the signature and `length` match exactly what users download); fetch the Sparkle release tarball whose version equals the `Package.resolved` pin (2.8.1); write `SPARKLE_ED_PRIVATE_KEY` to a 0600 file in `$RUNNER_TEMP`; `sign_update --ed-key-file <file> "$RUNNER_TEMP/published/Prompter.zip"` → `edSignature`, `length` (cross-checked against the asset's `size` from `gh release view vV --json assets`); `validate-release.py appcast-item` builds the item: `sparkle:version = CURRENT_PROJECT_VERSION`, `sparkle:shortVersionString = V`, `sparkle:minimumSystemVersion = MACOSX_DEPLOYMENT_TARGET`, enclosure URL `https://github.com/michaeltookes/prompter/releases/download/vV/Prompter.zip`, description = the CHANGELOG section converted to simple HTML (headings and list items only). Insert it at the top of the item list of the current `appcast.xml` on branch **`gh-pages`** (the file's history of record), commit with `GITHUB_TOKEN` (`contents: write`), push. A push made with `GITHUB_TOKEN` does **not** trigger a Pages build, so publication is an explicit deployment: a separate job **`deploy-appcast`** (`needs: release`, `permissions: pages: write, id-token: write, contents: read`, `environment: github-pages`) checks out `gh-pages`, runs `actions/upload-pages-artifact` on its root (`appcast.xml`, `.nojekyll`, `index.html`), then `actions/deploy-pages`; the job then polls the public URL for up to 5 minutes until the new item is served and fails otherwise. Never touches `main` (US-5 AC4). A standalone `pages.yml` (`workflow_dispatch` only, same deploy steps) redeploys `gh-pages` as-is for recovery.
10. **Cask**: Sentwise's tap step: clone `michaeltookes/homebrew-tap` with `TAP_PUSH_TOKEN`, skip if the tap already has V or newer, copy the template `Prompter/distribution/prompter.rb`, stamp `version` and `sha256` (from `Prompter.dmg.sha256` of the **uploaded** asset, re-downloaded with `gh release download`, US-6 AC3), commit `prompter: V`, push.
11. `if: always()`: delete the temp keychain and key file.

`resume=publish-tail` (dispatch only, for a tag whose release exists): runs 1 (resume mode), 9 (download, sign, update `gh-pages`, deploy; skipped under rule (b)), and 10 only; it needs no build and works on a fresh runner. It is the recovery path when step 9 or 10 failed after step 8; it never edits or replaces the release.

**`workflow_dispatch dry_run=true`**: steps 1 (against the head, no tag check), 3, 4–7 unsigned (`CODE_SIGNING_ALLOWED=NO`, no notarization), the DMG layout, and the appcast item rendering to the job summary; nothing published. It is how the workflow is tested without secrets.

**Permissions**: the `release` job has `contents: write` (release, `gh-pages` push); only `deploy-appcast` and `pages.yml` have `pages: write` and `id-token: write`.

**Secrets** (names only; GitHub environment `release`, deployment policy "tags matching `v*`" so no branch or PR job can read them): `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_ID`, `APPLE_TEAM_ID`, `NOTARY_APP_SPECIFIC_PASSWORD`, `SPARKLE_ED_PRIVATE_KEY`, `TAP_PUSH_TOKEN`. Environment `qa-build` (dispatch from any branch; workflow_dispatch already requires write access): `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`. Same names as Sentwise's `release.yml`, **different values** (brief Q6, answered 2026-10-14): Prompter signs and notarizes with `<owner>`'s **personal** Apple Developer account, not the Genkei Labs organization account, so `MACOS_CERTIFICATE_P12`/`MACOS_CERTIFICATE_PASSWORD` hold that account's Developer ID Application certificate, `APPLE_ID` and `APPLE_TEAM_ID` are that account's, and `NOTARY_APP_SPECIFIC_PASSWORD` is an app-specific password of that Apple ID, all exported by `<owner>` for `vendor-ops` to place; `SPARKLE_ED_PRIVATE_KEY` is **Prompter's own** key (the private half of the `SUPublicEDKey` in `Info.plist`), exported once by `<owner>` with Sparkle's `generate_keys -x`. No repository variables are required; the Xcode pin and Sparkle tool version live in the workflow file and `Package.resolved`.

**Appcast hosting move** (one-time, `vendor-ops` GitHub task plus one builder PR, before the first CI release): (1) the builder's PR adds `pages.yml` and creates orphan branch `gh-pages` containing the current `appcast.xml` byte-for-byte, an empty `.nojekyll`, and a one-line `index.html` linking to the repo; (2) `vendor-ops` switches the Pages source from "Deploy from a branch: `main /`" to **"GitHub Actions"** and edits the `github-pages` environment's deployment policy to allow `main` and tags matching `v*` (by default it allows only the default branch, which would reject `deploy-appcast` on a tag run); (3) dispatch `pages.yml`; (4) verify `curl -sS https://michaeltookes.github.io/prompter/appcast.xml | shasum` equals the file's hash; only then delete `appcast.xml` from `main` (a docs-only change). The URL every installed copy uses does not change. Rollback: switch the Pages source back to "Deploy from a branch: `main /`" (the file is in `main`'s history).

**Branch protection on `main`** (`vendor-ops`): required checks `Build & Test` and `SwiftLint` once `swift-ci.yml` is on `main`; `Prowl QA` added after three consecutive green runs (no macOS 14 smoke check: dropped 2026-10-14). No required reviews (the factory merges under its checklist).

### 4.6 Cask

Template in the repo at `Prompter/distribution/prompter.rb` (synced whole into the tap by step 10):

```ruby
cask "prompter" do
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/michaeltookes/prompter/releases/download/v#{version}/Prompter.dmg"
  name "Prompter"
  desc "macOS presenter overlay and teleprompter app"   # copy rule: never "free forever"
  homepage "https://github.com/michaeltookes/prompter"

  auto_updates true
  depends_on macos: :tahoe    # deployment target 26.0 from PRMT-026; the live tap keeps :sonoma for 1.2.x until then

  app "Prompter.app"

  zap trash: [
    "~/Library/Application Support/Prompter",
    "~/Library/Caches/com.tookes.Prompter",
    "~/Library/HTTPStorages/com.tookes.Prompter",
    "~/Library/Preferences/com.tookes.Prompter.plist",
  ]
end
```

The live tap's `depends_on` line and `auto_updates true` can be fixed today in a tap PR without a version change (genkei-ops 16b); `brew audit --cask --strict michaeltookes/tap/prompter` runs as the last step of `release.yml` (it is a lint, not an app test).

## 5. Lucius daily QA lane

Mirrors ContainerBar's design (`docs/architecture/lucius-daily-qa.md` on ContainerBar's `req/containerbar-factory-intake`): released, notarized build; open-and-assert plus prefs-only mutations; one shared desktop lock; the one CI-busy predicate; per-run snapshot and restore; evidence under the OpenClaw workspace; one Discord message. What differs: Prompter needs no remote fixtures (its data is local files), it needs the Accessibility permission for hotkeys, and its global hotkeys can disturb other passes (A-11).

### 5.1 One-time setup on `<qa-mini>` (orchestrator brief + `<owner>` for TCC)

1. Install with the cask (`brew install --cask michaeltookes/tap/prompter`) so the install path under test is the one users run.
2. `<owner>` grants Accessibility to `/Applications/Prompter.app` (and later to `~/Applications/Prompter QA.app`) once, by clicking the system prompt or the System Settings toggle over Screen Sharing. Lucius never grants a permission.
3. Seed: with Prompter quit, copy `docs/qa/fixtures/Decks/*.json`, `docs/qa/fixtures/Assets/*`, and `docs/qa/fixtures/Settings.json` into `~/Library/Application Support/Prompter/`, then snapshot it: `ditto` the folder to `~/qa/prompter/baseline/appsupport/`, write `baseline.manifest` (`find … -type f -exec shasum -a 256`), and `defaults export com.tookes.Prompter ~/qa/prompter/baseline/defaults.plist`. Sparkle's keys in that domain (`SUEnableAutomaticChecks`, `SULastCheckTime`) are excluded from the comparison allowlist.
4. Recipe `PROMPTER_QA.md` in the OpenClaw workspace (element identifiers, case steps, restore steps; private section holds runner names). It names the recipe as stale (US-15 AC4) when an identifier is missing.

### 5.2 Seed content (fictional speaker notes; the planner copies this into `docs/qa/seed-data.md`)

Deck file `docs/qa/fixtures/Decks/00000000-0000-4000-8000-00000000d0c1.json`, title **"QA Demo Deck"**, five cards with fixed UUIDs `…-00000000c001` to `…c005`. All text is invented for a fictional product "Orbit Notes" by a fictional company "Example Co."; the only address is `demo@example.com`.

| # | Layout | Content |
|---|---|---|
| 1 | `TITLE_BULLETS` | Title "QA Card 1 - Opening". Bullets: "Welcome the Example Co. team", "Agenda: setup, live walkthrough, questions", "Follow-ups go to demo@example.com". |
| 2 | `TITLE_NOTES` | Title "QA Card 2 - Discovery". Notes: three short paragraphs of invented discovery questions ("How many people present each week?", …). |
| 3 | `TITLE_BULLETS` | Title "QA Card 3 - Long list". 40 bullets "QA bullet 01 - …" to "QA bullet 40 - end of list" (taller than the overlay at baseline frame and font: the scroll case). |
| 4 | `IMAGE_TOP_NOTES` | Image `Assets/00000000-0000-4000-8000-00000000a001.png` (test pattern), notes "QA Card 4 - Image notes". |
| 5 | `GRID_2X2_CAPTION` | Four images `…a002` to `…a005`, caption "QA Card 5 - Grid". Sentinel text for capture checks is the title of card 1 ("QA Card 1 - Opening"). |

Images: 800 × 450 PNG test patterns (colour bars plus the label "QA-IMG-A" … "QA-IMG-E" in large black text on white), generated once by `scripts/qa/make-fixture-images.swift` (CoreGraphics, deterministic) and committed (about 10 KB each). Baseline `Settings.json`: opacity 0.85, font scale 1.0, overlay frame x 80, y 140, w 480, h 560 (main display), click-through off, Protected Mode on, timer enabled, per-card mode 20 s, pause button shown, apply to all decks, `lastOpenedDeckId` = the QA deck. Backdrop for screenshots (Epic D): a high-contrast checkerboard wallpaper `docs/qa/fixtures/backdrop-checker.png` (2560 × 1440, 64 px squares), set as the desktop picture for the pass and restored after.

The same fixtures are the hunt seed (section 4.3).

### 5.3 Shared rules with the other passes

- **CI-busy predicate** (verbatim from the factory rules): busy if `pgrep -x Runner.Worker` prints a PID, or any runner registered on this host is `busy: true` in `gh api repos/michaeltookes/{sentwise,ContainerBar,prompter}/actions/runners`; an API failure is recorded as `runner-api-unavailable` and (1) alone decides. Checked before the pass (wait up to 10 min, then BLOCKED `ci-busy`) and before every case (no wait).
- **Desktop lock**: `~/.openclaw/workspace/artifacts/sentwise-qa/device.lock` through `device_lock.py`, the same lock the Sentwise and ContainerBar passes, their hourly checks, and Prompter's `prowl-qa` hunts take; wait up to 10 min, then BLOCKED `desktop-busy`. The lock heartbeats, so acquirers keep the default `--stale-minutes` (R-09 closed 2026-10-14).
- **Monitor pause**: all hourly launchd checks skip while the lock is held.
- **No signals**: Prompter is quit only through `menuQuit` or `osascript -e 'quit app id "com.tookes.Prompter"'`; no `kill`, `pkill`, or `killall` (US-19 AC5).
- **System dialogs** (TCC, Keychain, Gatekeeper): BLOCKED, cropped screenshot, one line to the owner; never grant or type.

### 5.4 Schedule

**Daily pass: 08:15 America/Chicago, every day**, OpenClaw cron job "Prompter daily QA", isolated session, model `openai/gpt-6-astra` (judgment-heavy QA per the 2026-10-10 model policy), budget 1200 s. ContainerBar's pass starts 07:05 and, with its own 10-minute CI and lock waits, finishes by 07:45 in the worst case; Prompter's worst case (two 10-minute waits plus 20 minutes) ends by 08:55, before Sentwise's 09:35. The lock makes any residual overlap a wait, not a collision. **Hourly check** `com.genkeilabs.prompter-hourly`, launchd, 08:00–20:00, zero tokens, under 60 s, skipped while the lock is held:
1. Release consistency: latest GitHub release tag, appcast top `sparkle:shortVersionString` (Pages URL), tap cask `version`, installed `CFBundleShortVersionString` agree.
2. Gatekeeper: `spctl --assess` on `/Applications/Prompter.app`.
3. Process state: until the release containing PRMT-013 is installed, `pgrep -x Prompter` must print **nothing** outside a pass (A-11); after it, Prompter must be running, with RSS < 150 MB and CPU time growth < 36 s/h from `ps -o rss=,time=`.
It posts to Discord only on a state change and logs to `~/.openclaw/workspace/artifacts/prompter-qa/hourly.log`, rotated weekly.

**Weekly legs** (Wednesday): TC-PR-13 (fullscreen and Spaces) and TC-PR-10c (browser capture). **Release brief** (orchestrator-fired on release day, never scheduled): TC-PR-01 with `brew upgrade --cask prompter`, TC-PR-16 (Sparkle offer from the previous release), TC-PR-15 Reduce Transparency and Increase Contrast screenshots.

### 5.5 Daily pass sequence (happy path)

```
cron 08:15 → isolated session reads tasks/<date>-prompter-daily.md (Environment preamble + this pass)
 0 Preflight (shell, no GUI)
   a CI-busy predicate (wait ≤ 10 min) → else BLOCKED ci-busy
   b acquire desktop lock (wait ≤ 10 min) → else BLOCKED desktop-busy; pause monitors
   c if Prompter is running: quit via osascript; wait ≤ 10 s for exit
   d snapshot: ditto App Support → <run>/appsupport-before/; manifest diff vs baseline.manifest;
     defaults export → <run>/defaults-before.plist; drift = finding "previous run left state"; restore baseline
   e install check: codesign --verify --deep --strict, spctl --assess --type execute, xcrun stapler validate;
     installed version == GitHub latest == appcast top == cask (TC-PR-01)
   f set desktop picture to the checker backdrop (recorded previous picture for restore)
 1 Launch: open /Applications/Prompter.app; wait ≤ 10 s for prompterStatusItem (TC-PR-02)
 2 Read-only legs: TC-PR-03, 04, 05, 06, 10a/10b, 14
 3 Mutating legs (prefs only): TC-PR-07, 08, 09, 11, 12
 4 Restore: quit Prompter via menuQuit; restore baseline App Support + defaults import; restore desktop picture;
   close TextEdit without saving; no Sparkle/Test Protected Mode/editor window left; Prompter left QUIT
   (until PRMT-013 ships, A-11) or relaunched with overlay hidden (after); resume monitors; release lock
 5 Evidence: report.md + assets; one Discord message "QA PASS — Prompter V" or "QA FAIL — Prompter V";
   inbox line only on FAIL/BLOCKED (prompter#qa | lucius | qa-found|blocked | <run path> | …)
```

### 5.6 Failure paths

| Failure | Detected at | Report | Retry | Restore |
|---|---|---|---|---|
| CI job on any Mini runner | 0a; every case | BLOCKED `ci-busy`; remaining cases BLOCKED | none | step 4 |
| Lock held by another brief | 0b | BLOCKED `desktop-busy` | none | none needed |
| Signature, Gatekeeper, or staple failure | 0e | FAIL TC-PR-01 with tool output; Prompter not launched | none | step 4 |
| Release drift (tag ≠ appcast ≠ cask ≠ installed) | 0e | FAIL TC-PR-01 `stale-install` with the four versions; other cases run on the installed build | none | — |
| No Accessibility grant | TC-PR-05 (first hotkey; overlay value unchanged and `menuHotkeyStatus` present once US-11 ships) | BLOCKED `tcc-accessibility`, cropped menu screenshot, one line to owner | none | step 4 |
| Identifier missing (UI changed) | any step | step `blocked`, recipe named stale, `peekaboo see` element list as text | none; never improvise | step 4 |
| Protected capture shows the overlay | TC-PR-10 | FAIL, unless US-10 recorded the method as unsupported on 26.x → `known-limitation` | none | — |
| Pass aborted mid-way | next run 0d | finding with the manifest diff | — | baseline restored automatically |
| Known product defect (F-01, F-02, F-03 before their fix ships) | TC-PR-14, 08, 12b | `known-failure {PRMT-013/014/015, fixed-in: pending}`; does not turn the run red | — | — |

### 5.7 Test cases (TC-PR-xx; the planner copies them into `docs/qa/test-cases.md`)

| ID | Case | Kind | Pass when | Story |
|---|---|---|---|---|
| TC-PR-01 | Installed build is the signed latest release | read-only (release brief: `brew upgrade`) | three signature checks exit 0; four versions agree | US-16 |
| TC-PR-02 | Menu-bar-only launch | read-only | `prompterStatusItem` visible ≤ 10 s; one `pgrep -x Prompter` PID; `lsappinfo info -only ApplicationType -app com.tookes.Prompter` reports `UIElement`; no Dock tile | US-16 |
| TC-PR-03 | Seed deck in the editor | read-only | `menuOpenEditor` → `editorCardList` has 5 rows; row 1 "QA Card 1 - Opening"; one screenshot per card selected | US-15 |
| TC-PR-04 | Overlay shows from the menu | read-only | `menuToggleOverlay` → `overlayWindow` value `card=1/5;protected=on;…` ≤ 2 s; screenshot | US-17 AC1 |
| TC-PR-05 | Hotkey navigation and toggle | read-only | ⌘⇧→ ×2 → `card=3/5`; ⌘⇧← → `card=2/5`; ⌘⇧O hides then shows; screenshot per step; video | US-17 AC2 |
| TC-PR-06 | Image layouts render | read-only | cards 4 and 5 show QA-IMG-A … E (cropped screenshots; labels legible) | US-15 |
| TC-PR-07 | Font and opacity hotkeys | mutating (prefs) | ⌘⇧= → `font=110`; ⌘⇧] → `opacity=95`; screenshots differ; values restored by ⌘⇧-, ⌘⇧[ | US-17 AC2 |
| TC-PR-08 | Scroll hotkeys | read-only | card 3, ⌘⇧↓ → `scroll` > 0 and screenshot differs; at bottom no further change; next/previous resets `scroll=0` (known-failure until PRMT-014) | US-8, US-17 AC2 |
| TC-PR-09 | Click-through | mutating (prefs) | `menuClickThrough` on; TextEdit window under the overlay; click overlay centre → TextEdit caret moves, overlay not key; off again | US-17 AC6 |
| TC-PR-10 | Protected Mode vs capture | read-only | (a) `screencapture -x -D 1` and (b) Peekaboo's ScreenCaptureKit screen capture, each with Protected Mode on and off; the report records per method whether "QA Card 1 - Opening" is in the image (crop to the overlay frame from the window value); off → visible in both; on → hidden or `known-limitation`. (c, weekly) Chrome `getDisplayMedia` preview page `docs/qa/fixtures/share-preview.html` opened from disk, entire-screen share, screenshot of the preview | US-10 AC1, US-17 AC5, US-21 AC3 |
| TC-PR-11 | Timer | read-only (runtime) | ⌘⇧T starts `timer=00:20`; counts down; warning state at ≤ 4 s (orange, screenshot); pause/resume via ⌘⇧T; video | US-17 |
| TC-PR-12 | Settings persist across relaunch; off-screen frame recovers | mutating (prefs) | (a) US-18 AC1/AC2 sequence; (b) with Prompter quit, write frame x 10000, y 10000 into `Settings.json`, relaunch, overlay fully on screen (known-failure until PRMT-015); restore | US-18, US-9 AC1, US-17 AC4 |
| TC-PR-13 | Above fullscreen and on all Spaces (weekly) | read-only | TextEdit fullscreen → overlay visible above it; switch Space → overlay visible; video | F-19 |
| TC-PR-14 | Hotkeys pass through while overlay hidden | read-only | TextEdit "alpha beta gamma", caret after "beta", ⌘⇧← selects "alpha beta" (known-failure until PRMT-013) | US-7, US-17 AC3 |
| TC-PR-15 | Appearance screenshots (Epic D) | read-only | overlay (cards 1, 4, 5), footer, editor, both panels, status menu, in Light and Dark, over the checker backdrop, 2× scale; Reduce Transparency and Increase Contrast in the release brief only | US-21..24 |
| TC-PR-16 | Sparkle offer from previous release (release brief only) | release | previous release zip in a temp dir, launched, `menuCheckForUpdates` → offer names V; "Remind Me Later"; quit; temp dir removed | US-18 AC4 |
| TC-PR-17 | Update check on the installed release | read-only | `menuCheckForUpdates` → "up to date" dialog; dismiss | US-18 AC3 |

Assets: one screenshot per step, cropped to the app's windows or the overlay frame (never the full screen except TC-PR-10 captures, which show only the backdrop and the overlay because the pass hides other windows first); one MP4 for TC-PR-05, 09, 11, 12, 13. Evidence layout: `~/.openclaw/workspace/artifacts/prompter-qa/runs/<YYYY-MM-DD>-<daily|release|gate>-<HHMM>/` with `report.md`, `appsupport-before.manifest`, `defaults-before.plist`, `assets/<TC-id>/NN-<slug>.png`, `assets/<TC-id>.mp4`; kept 30 days. Story-level gate runs land in the repo's `docs/qa/runs/<date>-<story>/` with text and cropped app-window images only (public repo).

**Pre-PR QA gate** (feature stories in Epics A and D): the orchestrator dispatches `qa-build.yml` for the branch, sends Lucius a gate brief naming the story's TC-PR cases, Lucius installs `Prompter QA.app`, seeds `Prompter-QA/` from the same fixtures, runs the cases against `com.tookes.Prompter.qa` (identifiers are the same; the overlay value is the same), and reports. The released app's data is never touched by a gate run.

### 5.8 What the pass proves

Every morning: the build users install is the signed, notarized, latest one; it starts as a menu-bar app; the presenter's core loop works on macOS 26 (overlay, navigation, font and opacity, timer, click-through); Protected Mode is measured, not assumed, against two capture paths daily and a browser share weekly; settings survive a relaunch; updates are found; the app does not break other apps' shortcuts (once PRMT-013 ships). It does not prove behaviour on macOS 14 or 15 (the Mini runs 26.4; covered only by the CI smoke under option B), on a second display (only if one is attached), or inside real Meet or Teams calls (needs an account and a call; the Chrome preview is the proxy).

## 6. Audit-fix designs (Epic A)

### 6.1 Hotkey consumption (US-7, F-01)
`HotkeyManager` gets a main-actor-written, tap-read state `HotkeyGate { overlayVisible: Bool }`, updated from `AppState.$isOverlayVisible`. In `handleEvent`: `toggleOverlay` is always consumed; every other action is consumed **only** when `overlayVisible` is true; otherwise the event is passed through unchanged. Key repeats follow the same rule. Bindings stay ⌘⇧ (brief Q5, answered by the owner 2026-10-14). A pure function `shouldConsume(action:gate:) -> Bool` carries the rule and is unit-tested for every action in both states. The README table, `HotkeyAction.displayString`, and the menu stay generated from `HotkeyAction` (US-7 AC5).

### 6.2 Scroll (US-8, F-02)
Step = `Theme.scrollStepLines` (3) × notes line height (`Theme.notesFontSize` × 1.2) × `overlayFontScale`, i.e. 72 pt at scale 1.0. The overlay's `ScrollView` gets an anchor column: invisible zero-height views with ids `scroll-<n>` every step, and a `ScrollViewReader` that scrolls to `scroll-<overlayScrollOffset / step>` with `.top` anchor (works on macOS 14; `ScrollPosition` would need 15). The view reports its content and viewport heights with `onGeometryChange` (back-deployed) into `AppState.overlayMaxScroll`; `scrollDown` clamps to it, `scrollUp` to 0; card changes reset to 0 (already done in `AppState`). Mouse-wheel scrolling keeps working because the `ScrollView` stays.

### 6.3 Overlay placement (US-9, F-03)
`OverlayPlacement.clamp(frame:, screens: [CGRect visibleFrame], main:) -> CGRect` (pure, unit-tested): if the frame intersects no screen, place it centred on the main screen's visible frame; if partly off a screen, move it fully inside the screen with the largest intersection; shrink to fit if larger. Applied at `createWindow`, at `showWindow`, and on `NSApplication.didChangeScreenParametersNotification` (US-9 AC2, ≤ 2 s). "Move Overlay to" submenu (`menuMoveOverlayTo`, shown only with ≥ 2 screens) lists `NSScreen.localizedName`; choice persisted as `Settings.overlayDisplayUUID: String?` (from `CGDisplayCreateUUIDFromDisplayID`). **Data change:** one optional `Settings` field decoded with `decodeIfPresent` (the custom decoder at `Models/Settings.swift:102-117` already tolerates absent keys). Rollback: an older build ignores the unknown key and drops it on its next save; no migration.

### 6.4 Protected Mode truth (US-10, F-04)
Two parts. **Measure first:** TC-PR-10 runs on 26.4 as soon as the identifiers ship; its result is written into `.claude/reference-docs/CAPTURE_PROTECTION.md` and `docs/qa/`. **Then the self-test:** "Test Protected Mode…" gets a Run Test button. With Screen Recording already granted (`CGPreflightScreenCaptureAccess()`), the app: (1) captures the overlay's display with `SCScreenshotManager.captureImage(contentFilter:configuration:)` (macOS 14+) cropped to the overlay frame; (2) orders the overlay out for one frame, captures the same rect again, orders it back; (3) compares the two (mean absolute pixel difference over the rect; threshold 2 %): different → "Visible to capture", same → "Hidden from capture"; thumbnails shown, nothing written to disk. Without permission it explains first, then calls `CGRequestScreenCaptureAccess()`; on macOS 15+ granting requires quitting and reopening the app, which the window says (US-10 AC4 path). Copy constraint (from the brief, binding on the builder): before the system prompt the window says Prompter captures only its own overlay area to check whether it is hidden, keeps nothing, and sends nothing. Any change to the footer's "Protected" wording or the README's Protected Mode claim is customer-facing and waits for `<owner>` approval.

### 6.5 Hotkey liveness (US-11, F-05)
Replace the 12-shot retry with a `PermissionMonitor`: polls `AXIsProcessTrusted()` every 2 s while unregistered and every 10 s while registered (cheap), plus once in `menuNeedsUpdate`. Untrusted → registered: `registerAllHotkeys(promptIfNeeded: false)`. Registered → untrusted: `unregisterAllHotkeys()`. `menuHotkeyStatus` ("Hotkeys off: grant Accessibility…", first item, only while unregistered) opens `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`. The 12-hour prompt cooldown stays.

### 6.6 Persistence (US-12, F-06, F-07)
A `DeckStore` actor replaces the detached tasks: per-deck pending snapshots (`[UUID: Deck]`), one serial writer, last-write-wins per deck, `.atomic` writes, and `flushAll()` that writes every pending deck. `AppState` calls `flushAll()` (awaited) before switching, creating, cloning, or deleting a deck, and `applicationWillTerminate` calls a synchronous `flushAllSync()` (the store keeps a lock-protected copy for this path). Settings get the same treatment through the store. Write errors return to `AppState.saveError: SaveError?` (deck title + reason) → `editorSaveErrorNotice` banner; the in-memory deck is kept. **Unreadable decks:** a decode failure moves the file to `Decks/Unreadable/<original name>` (suffix `-<n>` on collision), logs at `.error` with the file name only (no content), and sets `AppState.unreadableDeckCount` → `editorUnreadableNotice` ("1 deck could not be opened and was set aside"). Nothing is deleted. `ioQueue` and the detached writes are removed.

### 6.7 Undo and asset lifetime (US-13, F-08, F-09)
Undo: the editor window's `UndoManager` is passed into `AppState` (`registerUndo` on card delete, move, duplicate, layout change, and title/notes commit); ⌘Z/⌘⇧Z work while the editor is key. Asset GC: after each deck flush and once at launch, `AssetManager.collect(referenced: Set<UUID>)` where `referenced` = all `AssetRef` ids across **all** decoded decks, plus those held by the undo stack's snapshots, plus **every asset referenced by a quarantined deck**: each file in `Decks/Unreadable/` is scanned as text (it may not be valid JSON) for UUID strings (`[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}`), and any match is treated as live; if any quarantined file cannot be read at all, GC is skipped for that cycle and logged. This keeps the images of a deck the user may still repair (§6.6 never deletes a quarantined deck, so GC must not delete what it points to); unreferenced files **move** to `Assets/.Trash/` (so they are gone from `Assets/` within one save cycle, US-13 AC1) and `.Trash` is emptied at the next launch. Undo of a delete restores from `.Trash` if needed. Missing asset → placeholder "Image missing", reference kept (AC4).

## 7. APIs and contracts

Prompter has no network API of its own. Contracts that builders and QA depend on:

- **Storage layout** (unchanged plus two folders): `Decks/<uuid>.json`, `Decks/Unreadable/`, `Assets/<uuid>.<ext>`, `Assets/.Trash/`, `Settings.json` (gains optional `overlayDisplayUUID`). JSON with ISO 8601 dates, pretty-printed, sorted keys. No schema version is introduced; A-09 rule applies.
- **Overlay accessibility value** (section 3.3): `key=value` pairs joined by `;`, keys in fixed order; adding keys at the end is non-breaking; renaming is breaking for the recipe.
- **Appcast**: `sparkle:version` integer strictly increasing; `sparkle:shortVersionString` semver; `sparkle:minimumSystemVersion` = deployment target; one `enclosure` (zip) with `sparkle:edSignature` and exact `length`, both computed from the published asset's bytes; file of record on branch `gh-pages`, served by a GitHub Actions Pages deployment.
- **Release assets**: `Prompter.zip` (Sparkle), `Prompter.dmg` (cask), `Prompter.dmg.sha256`; names without version (existing convention; cask URL template depends on it).
- **`validate-release.py`** subcommands: `pre --tag vX.Y.Z [--resume]` (exit 1 with both values on mismatch; `--resume` applies the three-way appcast rule of 4.5 step 1), `appcast-item --version … --build … --min … --signature … --length … --notes-file …` (prints the XML item), `appcast-check --url …` (top item parse, used by the hourly check). Unit tests in `Prompter/scripts/tests/test_validate_release.py` (stdlib only).
- **Self-check CLI** (hunt flavor only): `Prompter --self-check <outdir>` → exit 0 and `<outdir>/summary.json` `{"cards":5,"renders":[…],"macos":"14.x"}`.

## 8. Liquid Glass makeover (Epic D)

Rewritten 2026-10-14 after the owner's answer (brief Q1: **deployment target macOS 26.0, built with the current SDK**) and the design research scan of the same day on the macOS 27 SDK (Apple's macOS 27 and Xcode 27 release notes, the `UIDesignRequiresCompatibility` reference, HIG Menus, WWDC26 sessions 269 and 289). Every point marked **(27)** is **verify on a 27 machine; the QA Mini is on 26.x**; until a 27 machine exists those points are reported `unverified-27` and block no merge.

### 8.1 What macOS 26 and 27 change for this app

- **Toolchain.** macOS 27 shipped 2026-09-14; Xcode 27 ships the macOS 27 SDK, deploys back to macOS 12, installs only on Apple silicon Macs running macOS 26.6 or later. Prompter builds with Xcode 27 from PRMT-026 on, in CI on a GitHub-hosted macOS 26 image (hosted `macos-15` cannot run Xcode 27; the builder confirms the image carries it, brief Q9). The QA Mini (26.x) installs and runs the builds; it cannot build with Xcode 27 below 26.6 and cannot show the 27 look.
- **Build SDK turns it on.** A build with the 27 SDK running on macOS 26 draws standard AppKit and SwiftUI chrome in the macOS 26 Liquid Glass style: menus (the status menu), toolbars and their buttons, sidebars in `NavigationSplitView`/source lists (floating glass), sheets, popovers, alerts, bordered and prominent buttons, segmented controls, larger and concentric window corners. **(27)** On macOS 27 the same build picks up the 27 changes without code: interactive glass bounces when clicked, improved contrast and window shadows, standardized toolbars, sidebars that extend to the window edges, bordered toolbar items over the sidebar in glass, glass button hover states outside toolbars.
- **No availability layer.** With 26.0 as the floor, every macOS 26 glass API (`glassEffect(_:in:)`, `GlassEffectContainer`, `.buttonStyle(.glass)`, `NSGlassEffectView`, concentric shapes) is called directly: no `if #available(macOS 26, *)`, no legacy material path, no macOS 14 smoke job. `PrompterGlass` stays only as shared modifiers (`GlassSurface`, `GlassGroup`) so every surface uses the same tint tokens. APIs first shipped in the 27 SDK (`NSMenuItem.preferredImageVisibility`, `ToolbarOverflowMenu`, swipe actions on any view, `TabsPickerStyle`) sit inside `if #available(macOS 27, *)` with the 26 behaviour as the fallback.
- **Custom surfaces do not change on their own.** The overlay's `RoundedRectangle.fill(.ultraThinMaterial)` + dark fill + accent glow (`OverlayWindowController.swift:176-213`), the fake traffic lights, `IconButton`/`IconButtonGroup` custom hover backgrounds (`Views/Shared/IconButton.swift:26-96`), `ThemedPanelWindow` forcing `darkAqua` (`Windows/ThemedPanelWindow.swift:33-37`), and the sidebar's opaque `controlBackgroundColor` (`CardListSidebar.swift:126`) all need explicit work.
- **Menu item images.** macOS 26 shows a symbol image on any menu item that sets one. **(27)** Apps linked on the 27 SDK get a reduced set: `NSMenu` hides menu item symbol images by default (non-symbol images too), `NSMenuItem.preferredImageVisibility` forces one on, and the HIG (updated 2026-06-08) says "use menu item icons sparingly and with purpose" and "provide icons for all menu items in a group, or none of them". Design: images on one separator group only (default: Show/Hide Overlay, Open Deck Editor…), forced visible on 27; no other item gets an image on either version.
- **Interactive glass.** `.interactive()` / `effectIsInteractive` goes only on controls and glass containers of controls (the hide button, icon buttons, panel buttons, Run Test). **(27)** Interactive glass bounces when clicked; Apple says to use it for controls and buttons only. The overlay surface and the footer chips (counter, timer, Protected, click-through) are indicators and are never interactive, so they never bounce.
- **Glass preference.** macOS 26.1+ offers a Clear/Tinted glass preference (press-sourced; not in Apple's 26.1 notes). **(27)** It becomes a continuous Liquid Glass slider from ultra-clear to fully tinted under Appearance (press-sourced, unverified). System glass honours it; Prompter does not override it, so the overlay's tint floor (row 2) must keep text contrast at the clearest position.
- **Glass on glass.** Apple's adoption guide keeps glass in the navigation and control layer and warns against overuse; the overlay is a content surface and the footer is a glass group on top of it. Before PRMT-027 is built, the design-experimenter renders two variants on video over a bright slide on the Mini: (a) glass surface with glass footer chips, (b) plain dark material surface with glass controls and chips only; the ui-designer picks and records why. Rows 2 and 4 describe (a) as the default.
- **Typography.** SF Pro remains; titles are bolder in standard chrome. The overlay keeps its own sizes scaled by `fontScale` (an explicit project rule); the editor keeps Dynamic Type styles.
- **Dark/light.** The editor and panels follow the system appearance. The overlay stays a dark-tinted surface in both appearances (legibility over arbitrary slides and video is the product's job), which is an explicit design rule.
- **Accessibility settings.** System glass adapts automatically to Reduce Transparency (frostier, near-opaque), Increase Contrast (borders), and Reduce Motion (no morphing). Custom animation reads `accessibilityReduceMotion`.
- **App icon.** macOS 26 draws a legacy icon on a system-provided background plate. An Icon Composer `.icon` asset renders in Default, Dark, Clear, and Tinted; with a 26.0 floor no asset-catalog fallback is needed. **(27)** Icon Composer 2.0 (Xcode 27) previews a second design generation for the 2027 releases (refraction, outside speculars, deeper shadows); the icon is tuned in both generations before merge.
- **Compatibility switch.** `UIDesignRequiresCompatibility` keeps the pre-26 look only for apps built with the macOS 26 SDK; the system ignores it when the app is built for macOS 27 or later. So it is a bridge for releases cut **before** PRMT-026 (Xcode 26.2 pin, deployment target 14.0, brief Q8), which may set it to `YES` to avoid the mixed look on 26 (the builder confirms on the Mini that it is honoured for this AppKit app; if not, that release ships the mixed look). PRMT-026 removes it, and from then no release is cut until PRMT-027 to PRMT-030 merge.

### 8.2 Deployment target: decided

The owner chose macOS 26.0 on 2026-10-14 (formerly option A; option B, keep 14+ with an availability layer, is dropped).

| Topic | Consequence |
|---|---|
| Users | Macs on 14 or 15 stay on the last release built for 14.0: Sparkle hides newer items (`minimumSystemVersion 26.0`), `brew upgrade` refuses (`depends_on macos: :tahoe`). Decision D008 (macOS 14+) is superseded. The README and the first 26.0 release's notes say so (customer-facing; owner approves the wording). |
| Code | Glass APIs called directly; legacy material code and tokens deleted; 15/26 APIs (`ScrollPosition`, `Observations`) free to use elsewhere; 27-SDK APIs behind `if #available(macOS 27, *)`. |
| CI | No macOS 14 smoke job. Swift CI, QA build, and release select one pinned Xcode 27.x from PRMT-026 on. |
| QA | The Mini (26.x) covers macOS 26 (TC-PR-15). macOS 27 has no device in the fleet: the (27) points stay `unverified-27` until `homelab-it` moves a machine to 27 (Xcode 27 also needs 26.6+ on any machine that builds). |
| Effort | Epic D ≈ 4 builder branches plus the overlay experiment. |
| Reversible | Hard (users dropped cannot be re-offered without a re-release); accepted by the owner. |

### 8.3 Per-surface change list

| # | Surface (file) | macOS 26 (built with Xcode 27) | **(27)** differences (verify on a 27 machine; the QA Mini is on 26.x) | Interactive glass |
|---|---|---|---|---|
| 1 | Status item and menu (`MenuBarController.swift:77-93`, `:106-191`) | keep template SF Symbol `text.bubble`; symbol images only on one menu group (default Show/Hide Overlay `eye`, Open Deck Editor… `pencil.and.list.clipboard`), all or none in that group; no image on any other item | 27 hides menu item symbol images by default: the same items set `preferredImageVisibility` to visible inside `if #available(macOS 27, *)`; every other item stays imageless | n/a |
| 2 | Overlay surface (`OverlayWindowController.swift:170-216`) | variant (a): `GlassSurface`: `.glassEffect(.regular.tint(Theme.Glass.overlayTint.opacity(t)), in: .rect(cornerRadius: Theme.overlayCornerRadius))`, `t = 0.45 + 0.5 × overlayOpacity` (so 30 % still leaves a tint floor that keeps text contrast ≥ 4.5:1, US-21 AC2); drop the dark fill, the accent glow shadow, and the stroke; corner radius 18 → 22; content forced `.environment(\.colorScheme, .dark)`. Variant (b) if the experiment picks it: plain dark material with the same tint floor | 27 glass rendering and contrast changes apply; contrast re-measured at the transparency slider's clearest and fully tinted positions (US-21 AC4) | **no** (never `.interactive()`) |
| 3 | Overlay top controls (`:240-307`) | fake traffic lights removed; one `GlassGroup` at top-left with a hide button (`xmark`, `.buttonStyle(.glass)`, label "Hide overlay", `overlayClose`) and the drag hint text kept (US-14 AC3 lands the plain labelled button first) | bounces on click; hover state outside toolbars | **yes** |
| 4 | Overlay footer (`Views/Overlay/OverlayFooterView.swift`) | `GlassGroup` of capsule **indicator** chips: counter, timer (tint orange in warning), Protected indicator (tint orange/red when off, "Visible to capture" text kept), click-through indicator; accessibility: static text with label and value, not buttons | none (not interactive, so no bounce) | **no** |
| 5 | Layout renderers (`Views/Overlay/LayoutRenderers/*`) | content unchanged; image corners concentric to the surface (`ConcentricRectangle`) | none | n/a |
| 6 | Deck Editor window (`MenuBarController.swift:216-251`, `DeckEditorView.swift:16-60`) | host with `NSHostingController` (window `toolbarStyle = .unified`); `HSplitView` → `NavigationSplitView { CardListSidebar } detail: { CardCanvasView }`; remove `Theme.sidebarBackground` behind the sidebar; card rows become `List(selection:)` rows; toolbar items standard (glass automatically), `ToolbarSpacer(.fixed)` between groups | standardized toolbar, sidebar to the window edges, bordered toolbar items over the sidebar in glass (all automatic); `ToolbarOverflowMenu` optional, behind `#available(macOS 27, *)` | system toolbar buttons |
| 7 | Sheets and alerts (`DeckSettingsSheet`, new-deck sheet, delete alert) | system (automatic) | system | system |
| 8 | Themed panels (`ThemedPanelWindow.swift`, `TimeInputPanelView.swift`, `DeckPickerPanelView.swift`) | stop forcing `darkAqua` (follow system); content in a `GlassSurface`; primary button `.glassProminent`, secondary `.glass` | buttons bounce and show hover | buttons yes, surface no |
| 9 | Icon buttons (`Views/Shared/IconButton.swift`) | `.buttonStyle(.glass)`; `IconButtonGroup` → `GlassGroup` | bounce on click | **yes** |
| 10 | Image drop zones (`Views/Shared/ImageDropZone.swift`) | content, not chrome: `.quaternary` fill, dashed stroke kept, concentric corners | none | no |
| 11 | Test Protected Mode window (`Views/TestCapture/TestCaptureView.swift`) | standard window; Run Test `.glassProminent` | Run Test bounces | Run Test yes |
| 12 | Theme (`Extensions/Theme.swift`) | add `Theme.Glass.{overlayTint, chipTint, warningTint, dangerTint}`; **delete** `accentGlow`, `trafficLight*`, `surfaceBackground` (no legacy path) | none | n/a |
| 13 | App icon (`Resources/Assets.xcassets/AppIcon.appiconset`) | Icon Composer `Prompter.icon` (foreground speech-bubble glyph layer, background gradient layer, at most four groups) replaces the asset-catalog icon; the owner reviews it in Discord before merge (brand) | second design generation (refraction, outside specular, deeper shadows) previewed in Icon Composer 2.0 before merge; Finder rendering checked on a 27 machine | n/a |
| 14 | Animations (`OverlayWindowController.swift:214-215`, `OverlayFooterView` pulse) | respect `accessibilityReduceMotion` (no pulse, no card transition) | same | n/a |
| 15 | Empty scene (`PrompterApp.swift`) | `Settings { EmptyView() }` (F-15) | same | n/a |

### 8.4 Verification

**On `<qa-mini>` (macOS 26.x), TC-PR-15**, over the checker backdrop at 2×: overlay cards 1, 4, 5 at opacity 100 % and 30 %, Light and Dark, glass preference default and Clear (where 26 offers it); footer with Protected on and off and timer warning; editor at default and minimum size; both panels; status menu open (images only on the chosen group); Finder `/Applications` icon in Default/Dark/Clear/Tinted (icon style is a System Settings > Appearance choice; switched through the UI in the release brief, restored after). Contrast for US-21 AC2 is measured by `scripts/qa/contrast.swift <png> <x,y,w,h>` (CoreGraphics, prints the WCAG ratio between the text's dominant colour and the surface sample). Reduce Transparency and Increase Contrast need System Settings > Accessibility > Display toggles: release brief only, toggled through the UI and restored, SKIPPED if the UI blocks.

**On a macOS 27 machine (none in the fleet yet), TC-PR-15b**: the same set plus the transparency slider at its clearest and fully tinted positions, the status menu's forced images, the bounce check (hide button bounces; surface and chips do not), the editor's standard toolbar and edge-to-edge sidebar, and the icon's 27 generation in Finder. Until the machine exists, the release brief records TC-PR-15b as `unverified-27`.

## 9. Auth, billing, privacy and consent

- **Auth and billing:** none in this design. Prompter is free and MIT-licensed **today**, with no accounts and no licensing; it is a public product that will be charged for eventually (owner, 2026-10-14), so no copy this design touches (README, Pages `index.html`, cask `desc`, release notes, appcast notes, in-app text) promises "free forever"; "free and open source" describes today.
- **What leaves the device:** only Sparkle's update request to GitHub Pages and the zip download from GitHub Releases. Sparkle system profiling stays off (`SUEnableSystemProfiling` absent). No telemetry, no crash reporter is added. The self-test capture (6.4) stays in memory.
- **Permissions:** Accessibility (hotkeys, existing prompt and copy); Screen Recording only when the presenter clicks Run Test, with the explanatory copy from 6.4 shown first, never at launch.
- **Logging:** `os.Logger` stays (D012). Deck titles are logged today with default privacy (dynamic strings are redacted in release logs); new log lines log file names and counts only, never card text.
- **Secrets:** GitHub environment secrets only (4.5), from the owner's personal Apple Developer account; never in the repo, logs, artifacts, briefs, or Discord. The personal Apple ID email leaves the scripts (A-05).
- **QA evidence privacy:** fictional seed only; screenshots cropped; CI artifacts strip screenshots (public repo); daily evidence stays on `<qa-mini>`.
- **Customer-facing copy needing the owner's approval:** Protected Mode claims (README, footer, Test window), the Screen Recording explanation, the deployment-target change (README requirements line and the first 26.0 release's notes, naming the last version for macOS 14 and 15), and the new app icon.

## 10. Non-functional requirements

- **Launch:** status item visible ≤ 2 s after launch on the Mini (TC-PR-02 allows 10 s for automation slack).
- **Hotkeys:** event-tap callback does no I/O and no allocation beyond the action lookup; < 1 ms per event; never blocks (a blocked tap is disabled by the system).
- **Persistence:** every edit on disk ≤ 1.5 s after the last keystroke; zero lost edits across deck switches and quit (US-12 AC1/AC2); writes are atomic.
- **Idle cost:** with the overlay hidden and no timer, CPU time growth < 36 s per hour and RSS < 150 MB (hourly check, after PRMT-013).
- **Offline:** everything except the update check works offline; a failed update check never blocks the overlay or hotkeys.
- **CI budget:** Build & Test ≤ 20 min, SwiftLint ≤ 10 min, prowl-qa ≤ 30 min, release ≤ 60 min, qa-build ≤ 30 min.
- **QA budget:** daily pass ≤ 1200 s; hourly check < 60 s, zero tokens.
- **Observability:** os_log subsystem `com.tookes.Prompter` (existing categories); the pass attaches `log show --predicate 'subsystem == "com.tookes.Prompter"' --last 25m --style compact` to every FAIL; CI uploads xcresult on failure.

## 11. Test strategy hooks

- **Unit tests the builder adds** (all run on CI, never on the MacBook): `shouldConsume` for every hotkey in both overlay states; `OverlayPlacement.clamp` (fully off, partly off right edge, larger than screen, two screens); scroll clamp math; `DeckStore` ordering (20 edits in 2 s → last content), cross-deck flush on switch, unreadable-file quarantine, write-error surfacing; asset GC reference counting across decks and the undo stack; overlay accessibility-value formatter; `AppEnvironment` resolution table; `validate-release.py` (version mismatch, CHANGELOG date, build-number monotonicity, appcast item rendering).
- **Seed data:** section 5.2 fixtures, used by the daily pass, gate runs, and hunts.
- **Needs Lucius / a device:** every TC-PR case; anything with hotkeys, capture, fullscreen, Spaces, Sparkle UI, or appearance screenshots.
- **Needs a second display:** US-9 AC2–AC4 (not on the Mini unless the owner attaches one).
- **Cannot be tested in-house:** real Meet/Teams screen shares (proxy: TC-PR-10c Chrome preview), macOS 27 until a 27 machine exists (the (27) points in section 8 are reported `unverified-27`).
- **Gate rule:** a story in Epics A or D gets its PR only after its TC-PR cases pass against a `qa-build` of the branch (factory QA gate). Epic B and C stories are config/docs and skip the gate.

## 12. Trade-offs considered

- **Appcast via a PR to `main` vs `gh-pages` vs Pages-from-Actions artifact:** a PR per release needs a human merge before users see the update; Actions-artifact Pages replaces the whole site on every deploy and loses the file's history; a `gh-pages` branch keeps the URL, keeps history, and keeps `main` protected, but a `GITHUB_TOKEN` push does not trigger a Pages build. Chosen: both together: `gh-pages` holds the file and its history, and an `actions/deploy-pages` deployment of that branch's content publishes it (no PAT needed). A scoped PAT pushing to a branch-sourced Pages site was rejected: one more long-lived credential for the same result.
- **Appcast as a release asset (Sentwise model):** would change `SUFeedURL`, which every installed copy already has baked in. Rejected.
- **Running the release on `<qa-mini>`:** keeps the keychain-based notary profile, but puts signing keys on the shared QA machine and competes with its desktop. Rejected; GitHub-hosted with environment-scoped secrets.
- **Test isolation by a `PrompterCore` package vs an `AppEnvironment` guard:** the package is cleaner but is a large import churn during Epic A. Chosen: guard + injectable storage now; package later.
- **Ad-hoc-signed QA builds:** simpler (no secrets) but every build changes the code signature, so the Accessibility grant would have to be redone by the owner for every gate run. Chosen: Developer ID signed, not notarized.
- **Leaving Prompter running on the Mini (ContainerBar parity):** gives an "alive" hourly signal but, until F-01 is fixed, steals shortcuts from the other passes. Chosen: quit between passes until PRMT-013 ships.
- **A Peekaboo-free in-app QA mode (`--qa` flag scripting the cases):** would test a different code path than users run. Rejected, as in ContainerBar.
- **Keeping the Claude code-review workflow for parity with ContainerBar:** contradicts the 2026-10-12 factory decision. Rejected (A-10).
- **Option B (keep macOS 14+ with a glass path on 26):** recommended in the first draft, declined by the owner 2026-10-14 in favour of a macOS 26 minimum; see 8.2.

## 13. Story review

Applied to `docs/requirements/audit-and-modernization.md` on 2026-10-14 (same branch), with the orchestrator's rulings: US-3 and US-19 as designed here. US-27 (credentials and personal data out of the release scripts, finding F-20) was added at that time. The BA folds the backlog.

| Story | Verdict | Change proposed |
|---|---|---|
| US-1 | feasible | Add technical task: test isolation (`AppEnvironment.unitTest`, `PersistenceService(rootURL:)`, temp-dir tests; A-01, A-02) — without it the 134 tests overwrite real data wherever they run. AC1: "on a clean macOS runner in CI", not "a Mac" (testing never runs on the owner's machines). AC2: keep "pins one exact version" (Package.resolved always does) and add "the project requirement is `upToNextMinor`". |
| US-2 | feasible | Add task: A-03 (split `AppState` so SwiftLint has no error) in the same branch as the lint job. Add: CI test build uses the signing overrides in 4.2. |
| US-3 | **conflicts with decision 2026-10-12** | AC1: replace the Claude code-review workflow with "the Claude code-review workflow is removed; `claude.yml` stays; `claude-pr-description.yml` is added". Orchestrator to confirm. |
| US-4 | feasible | **Codex P2 follow-up:** add the desktop-lock acceptance (section 13a). AC2 names: bundle id `com.tookes.Prompter.hunt`, data root `Prompter-Hunt/`. AC3: a job on an offline self-hosted runner stays *queued* (GitHub holds it up to 24 h); `timeout-minutes` cannot fail it at 30 min. Reword: "the check stays pending or fails, never reports success; the merge checklist treats pending as not green". Add task: `homelab-it` registers `<prompter-runner>` and the owner grants its host Accessibility. Depends on the flavor work (US-25 below). |
| US-5 | feasible | **Codex P2 follow-up:** AC4 and AC6 wording in section 13a. AC1 date: "equals the tag's commit date in America/Chicago". AC4: `gh-pages` file of record plus an `actions/deploy-pages` deployment. AC6: add "a `resume=publish-tail` dispatch finishes appcast and cask for an existing release without modifying it". Add tasks: A-04 (version single source), A-05 (credentials from env), appcast hosting move (4.5), environment `release` with tag policy. Precondition: owner exports the Sparkle key (Q2). |
| US-6 | feasible | AC1: `brew audit` runs at the end of `release.yml`. Add: the live-tap fix can merge now (genkei-ops 16b). |
| US-7 | feasible | Design 6.1. AC5: brief Q5 answered 2026-10-14 (keep ⌘⇧, consumed only while the overlay is visible). |
| US-8 | feasible | Step = 3 lines = 72 pt at scale 1.0 (6.2). |
| US-9 | feasible | Data change: optional `Settings.overlayDisplayUUID` (6.3). AC2–AC4 need a second display (not on the Mini by default). |
| US-10 | feasible, two branches | Split: **10a** measurement + docs (Lucius TC-PR-10, no code) and **10b** the self-test (6.4). AC3: "within 5 s *when Screen Recording is already granted*"; first grant on macOS 15+ needs a relaunch, which AC4's copy must say. AC1 tools named: `screencapture -x -D 1` and Peekaboo's ScreenCaptureKit capture; weekly Chrome `getDisplayMedia` preview. |
| US-11 | feasible | Poll design 6.5 meets "within 5 s". |
| US-12 | feasible | Design 6.6 (`DeckStore` actor). |
| US-13 | feasible, AC conflict; **Codex P2 follow-up:** add AC5 (section 13a) | AC1 ("file gone within one save cycle") vs AC3 (undo restores images): reword AC1 to "moved out of `Assets/` to `Assets/.Trash/` within one save cycle and deleted at next launch". Two branches: undo, then GC. |
| US-14 | feasible | Fine. Add A-13 explicitly (already in AC1). |
| US-15 | feasible | Identifier list extended (3.3) plus the overlay `accessibilityValue` contract. Seed (5.2) matches AC2 (5 cards, card 3 has 40 bullets, test-pattern images). |
| US-16 | feasible | AC3 add `lsappinfo` check for no Dock tile (TC-PR-02). |
| US-17 | feasible | AC5 tools named (TC-PR-10). AC7 detection uses `menuHotkeyStatus` once US-11 ships; before that, "hotkey had no effect on the overlay value". |
| US-18 | feasible | Fine. |
| US-19 | **AC1/AC3 conflict with A-11** | Until the release containing PRMT-013 is installed on the Mini, restore leaves Prompter **quit** and the hourly check asserts `pgrep -x Prompter` is empty; after it, running. Schedule: 08:15 CT daily (5.4). |
| US-20 | feasible (rewritten 2026-10-14) | Owner chose macOS 26.0: no macOS 14 smoke; Xcode 27 in all three workflows; remove `UIDesignRequiresCompatibility` (ignored on the 27 SDK); 27-only APIs behind `#available(macOS 27, *)`. |
| US-21 | feasible | AC2 met by design via the tint floor (8.3 row 2). The former legacy-look AC4 is gone with option B; AC4 is now the (27) slider and no-bounce check. AC5 runs in the release brief only. |
| US-22 | feasible | AC4 is automatic: with click-through on, the whole window ignores mouse events. Footer has no opacity control today; AC2 should list counter, timer, Protected, click-through. |
| US-23 | feasible | Structural change (`NavigationSplitView`, `NSHostingController`) applies on all OS versions. |
| US-24 | feasible | Icon design is a brand asset: owner review in Discord before merge. |
| **US-25 (new)** | proposed | *App flavors and isolated storage* (3.2): AC — production/qa/hunt/unitTest resolved as tabled; hunt and qa never read `Prompter/`; unit tests never touch `~/Library`; production ignores `PROMPTER_HUNT_MODE`. Blocks US-1 (tests), US-4, US-26, the gate. |
| **US-26 (new)** | proposed | *QA build for the pre-PR gate* (`qa-build.yml`, 4.4): dispatch with a ref → Developer-ID-signed `Prompter QA.app` zip artifact, 3-day retention; installs beside the release without touching its data. Blocks the QA gate for Epics A and D. |
| **US-27 (new)** | proposed | *Release validator and appcast hosting* could be folded into US-5 instead; listed so the BA decides. |

### 13a. Acceptance text changes from the Codex review (2026-10-14), for the BA to mirror in the brief

- **US-4, new AC5 (desktop lock).** "Given another desktop pass or hourly check holds the host-wide desktop lock on the Mini, when a Prowl QA job reaches its GUI segment, then it waits (retrying every 30 s) up to 20 minutes and, if the lock is still held, fails with `desktop-busy` and never reports success; given it acquires the lock, then the hunts and the hunt-app quit both run while it is held, and the lock is released when the segment ends, whatever the hunt result. The hunt app is never launched outside the lock." Preconditions add: `homelab-it` sets `QA_DEVICE_LOCK_DIR` and `QA_DEVICE_LOCK_TOOL` in the runner's environment. (The `--stale-minutes 30` move is no longer needed: the lock heartbeat is live, R-09.)
- **US-5 AC4 (replace).** "…then the appcast change is committed to the `gh-pages` branch and published by an `actions/deploy-pages` deployment (Pages source: GitHub Actions; same public URL), never pushed to `main`; the job fails if the public URL does not serve the new item within 5 minutes; signing identities, the notarization credentials, and the Sparkle private key come from GitHub secrets and appear in no log."
- **US-5 AC6 (replace the resume clause).** "…a `workflow_dispatch` with `resume=publish-tail` for that tag downloads the published `Prompter.zip`, signs those bytes for the appcast, and finishes the appcast and cask steps; it accepts a live appcast that already lists V with the same build and URL (and then skips the appcast step), rejects a live appcast that lists V with a different build or URL or a newer build under another version, and never modifies the release."
- **US-5, new AC9 (signature matches the download).** "Given the published release, when its `Prompter.zip` is downloaded and `sign_update --verify` checks it against the appcast item's `sparkle:edSignature`, then it verifies, and the item's `length` equals the asset's byte size."
- **US-5 precondition (replace the Pages bullet).** "`vendor-ops` switches the Pages source to GitHub Actions and allows `main` and tags `v*` in the `github-pages` environment's deployment policy, after a builder PR has created the `gh-pages` branch (today's `appcast.xml` byte-for-byte) and `pages.yml`; `appcast.xml` leaves `main` only after the public URL serves identical bytes."
- **US-13, new AC5 (quarantine then GC).** "Given deck A references image X and no other deck does, when deck A's file is corrupted so that it is moved to `Decks/Unreadable/` at launch, then X stays in `Assets/` through that launch's GC and every later save cycle while A's file remains in `Decks/Unreadable/`; a unit test drives quarantine followed by GC on a temp root and asserts X is neither moved to `Assets/.Trash/` nor deleted."
- **US-2 (no AC change).** The CI test step uses distinct result-bundle paths; already covered by AC1/AC2 as written.

**Suggested order for the planner** (dependencies, not dates): M1 foundations — PRMT-007 (US-1, dispatched), US-25, US-2 (+A-03), US-3 (as amended), US-14; M2 QA plumbing — US-15, US-26, US-4 (runner), Lucius setup + US-16..19 (pass starts with known-failures); M3 release — appcast move, US-5, US-6 → cut 1.3.0 with `UIDesignRequiresCompatibility = YES` (Xcode 26.2 pin, target 14.0; the key works only on the 26 SDK); M4 audit fixes behind the gate — US-7, US-11, US-8, US-9, US-12, US-13, US-10a then 10b → 1.4.0; M5 makeover — US-20 (Xcode 27, target 26.0), the overlay experiment, US-21, US-22, US-23, US-24 → 2.0.0 (no release between US-20 and US-24).

## 14. Risks and open questions

**Risks**
- **R-01 Protected Mode may not protect on macOS 15+/26** (F-04). If TC-PR-10 shows ScreenCaptureKit captures the overlay, the product's headline promise is false for most users. Mitigation: measure first; copy changes go to the owner; there is no supported API that excludes a window from all ScreenCaptureKit capture, so the honest outcome may be a caveat, not a fix.
- **R-02 Sparkle private key custody.** If the private key matching `SUPublicEDKey` cannot be found, CI cannot sign updates that 1.2.0 installs will accept. Mitigation: owner checks the keychain first (Q2); if lost, the next release must ship a new public key via a Developer-ID-signed build that users install manually or through the cask, and Sparkle-only users are stranded on 1.2.0.
- **R-03 Synthetic hotkeys vs the event tap.** Peekaboo-posted key events must reach a session-level event tap; if they do not on 26.4, hotkey cases become BLOCKED. Mitigation: the first setup run verifies with TC-PR-05; fallback posts with `CGEvent.post(tap: .cghidEventTap)` from a tiny helper on the Mini.
- **R-04 Menu-item identifiers** may not surface through Peekaboo; recipe falls back to fixed titles.
- **R-05 (closed 2026-10-14)** `macos-14` hosted image retirement: no longer relevant, there is no macOS 14 coverage to lose under a 26.0 floor.
- **R-06 Mixed look** in any release built before Epic D. With the Xcode 26.2 pin it is mitigated by `UIDesignRequiresCompatibility` if honoured; with Xcode 27 the key is ignored, so no release is cut between PRMT-026 and the end of Epic D.
- **R-07 Signing secrets in a public repo's workflows.** Mitigated by environment scoping (tags `v*` only for `release`), same-repo gates on every secret-using workflow, and SHA-pinned actions.
- **R-08 Shared desktop on the Mini** (prowl-qa hunts and gate runs boot Prompter builds next to the other passes). Mitigated by the hunts taking the host-wide desktop lock (4.3), the CI-busy predicate including this repo's runner, and distinct bundle ids.
- **R-09 Lock staleness (closed).** Before 2026-10-14 `device_lock.py` had no heartbeat; with the default `--stale-minutes 15`, a second acquirer archives and takes over a lock whose live owner has held it longer than 15 minutes (a 20-minute daily pass or a 25-minute hunt). **Closed 2026-10-14:** the tool's heartbeat is live (lock refreshed every 60 s; takeover only on a dead PID or a stale heartbeat), so no caller needs `--stale-minutes 30`.
- **R-10 macOS 27 unverifiable in-house.** No fleet machine runs 27 (the QA Mini is on 26.x), so the (27) points of section 8 cannot be seen before users do. Mitigation: they are marked `unverified-27` in every report; `homelab-it` plans a 27 machine (or the Mini's move once its other passes allow); the 27 behaviour comes from Apple's release notes and WWDC26 sessions, the slider from press only.
- **R-12 Local builds on the Mini.** Anything that compiles Prompter on `<qa-mini>` breaks once the code uses 27-SDK APIs (PRMT-030), because the Mini (26.4) cannot run Xcode 27. Mitigation: hunts use the hosted `build-hunt` artifact (4.3), the QA gate uses the hosted `qa-build.yml` artifact (4.4), the daily pass uses the released app; no Mini path builds. Any throwaway-clone unit-test run on the Mini must stop once PRMT-026 lands (CI only) unless option (b) has happened.
- **R-11 Hosted Xcode 27.** If no GitHub-hosted macOS 26 image carries Xcode 27, PRMT-026 is blocked (brief Q9); signing on the shared QA Mini stays rejected (section 12).

**Open questions for the owner**: answered 2026-10-14.
1. **Deployment target:** **macOS 26.0**, built with the current SDK (section 8.2). Option B dropped.
2. **Release credentials:** the owner's **personal** Apple Developer account signs and notarizes Prompter (not the Genkei Labs organization; nothing re-used from Sentwise); Prompter's Sparkle key is exported by the owner. R-02 still applies if the key cannot be found.
3. **One-time grants on Lucius' Mini:** approved as soon as each target exists: the `<prompter-runner>` host now, Chrome's Screen Recording now, `~/Applications/Prompter QA.app` when PRMT-032 ships, `/Applications/Prompter.app` when the lane installs the release.

New, with assumptions (brief Q8, Q9): releases before PRMT-026 keep deployment target 14.0; a hosted macOS 26 image carries Xcode 27.

## 15. Story-to-design map

| Work | Owner | Design sections | Blocks |
|---|---|---|---|
| PRMT-007 / US-1: shared scheme, Package.resolved, dist out of git | builder (dispatched) | 2.2 F-10/F-11, 4.2 | CI |
| US-25 (new): flavors + isolated storage + test isolation | builder | 3.2, 2.3 A-01/A-02 | US-1 tests, US-4, US-26, gate |
| US-2: swift-ci.yml + A-03 | builder | 4.1, 4.2 | branch protection |
| US-3 (amended): workflows/templates, remove claude-code-review | builder | 4.1, A-10 | — |
| US-4: prowl-qa + hunt build + runner | builder; homelab-it (runner); owner (TCC) | 4.3, 3.3 | required check later |
| US-26 (new): qa-build.yml | builder; vendor-ops (env + secrets) | 4.4 | QA gate |
| Appcast: `gh-pages` branch + `pages.yml` (builder), Pages source = GitHub Actions + `github-pages` env policy, environments, branch protection | builder, vendor-ops | 4.5 | US-5 |
| US-5: release.yml + release.sh + validate-release.py + A-04/A-05 | builder; owner (Sparkle key) | 4.5, 7 | 1.3.0 |
| US-6: cask template + live tap fix | builder | 4.6 | — |
| US-7 | builder | 6.1 | TC-PR-14 green; A-11 lifted |
| US-8 | builder | 6.2 | TC-PR-08 |
| US-9 | builder | 6.3, 7 | TC-PR-12b |
| US-10a / US-10b | Lucius (a), builder (b), owner (copy) | 6.4, 9 | Protected Mode copy |
| US-11 | builder | 6.5 | TC-PR-05 detection |
| US-12 | builder | 6.6, 7 | — |
| US-13 | builder | 6.7, 7 | — |
| US-14 | builder | 2.4, F-15, F-16 | — |
| US-15: identifiers + fixtures + seed-data/test-cases docs | builder (code), project-planner (docs) | 3.3, 5.2, 5.7 | every TC-PR case |
| US-16..US-19: Lucius lane (brief, recipe, cron, launchd, baseline) | orchestrator → Lucius; owner (TCC) | 5.1–5.8 | daily evidence |
| US-20 (Xcode 27, target 26.0) | builder | 8.1, 8.2, 4.1 | Epic D |
| US-21, US-22 | builder | 8.3 rows 2–5, 14; 8.4 | — |
| US-23 | builder | 8.3 rows 6–9, 11 | — |
| US-24 | builder; owner (icon review) | 8.3 rows 1, 13 | 2.0.0 |
