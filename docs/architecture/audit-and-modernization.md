# Prompter audit and modernization: design

Status: proposed (2026-10-14). Written in parallel with the requirements brief `docs/requirements/audit-and-modernization.md` (stories `US-audit-and-modernization-1..24`, backlog `PRMT-007..PRMT-030`, findings `F-01..F-19`) on `req/prompter-audit`. This design uses the brief's story, finding, and identifier names wherever the two overlap. Findings the brief does not have are numbered `A-01..` here (section 2.6) for the BA to fold. Section 13 is the story review; section 15 maps stories to design sections.

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

**What changes.** (1) Audit fixes (Epic A). (2) CI/CD parity with ContainerBar plus Sentwise's tag-driven release (Epic B). (3) A Lucius daily QA lane modelled on ContainerBar's (Epic C). (4) A Liquid Glass makeover for macOS 26 (Epic D). Enabling all four is one cross-cutting change: **app flavors with isolated storage** (section 3.2), so tests, PR hunts, QA builds, and the released app never share data.

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
| F-12 | Medium | parity | `publish-release.sh` commits to `main` and recreates releases | Section 4.5; appcast moves to a `gh-pages` Pages source. |
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
 │   Build & Test │ SwiftLint │ macOS 14 smoke (option B only, macos-14)             │
 │ prowl-qa.yml  (same-repo PR, dispatch) ── self-hosted <prompter-runner>           │
 │ qa-build.yml  (dispatch: ref) ── GitHub-hosted; env qa-build; Prompter QA.app zip │
 │ release.yml   (tag v*, dispatch dry_run|resume) ── GitHub-hosted; env release     │
 │   → GitHub Release (zip, dmg, sha256) → gh-pages/appcast.xml → homebrew-tap cask  │
 │ claude.yml (@claude) │ claude-pr-description.yml                                  │
 └──────────────────────────────────────────────────────────────────────────────────┘
            │ artifacts / releases                        │ Pages (gh-pages branch)
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
| `swift-ci.yml` (new) | `pull_request` → main, `push` → main; concurrency per ref, cancel in progress | GitHub-hosted `macos-15`, Xcode 26.x selected exactly as ContainerBar's `swift-ci.yml` (`XCODE_PREFERRED: "26.2"`, fall back to newest `Xcode_26*`, fail listing installed versions) | **Build & Test**, **SwiftLint**, **macOS 14 smoke** (option B only), **Release validator tests** step inside Build & Test | none; `permissions: contents: read` |
| `prowl-qa.yml` (new) | `pull_request` → main (same-repo heads only), `workflow_dispatch` | `[self-hosted, macOS]` = `<prompter-runner>` | Prowl hunts against the hunt flavor | none |
| `qa-build.yml` (new) | `workflow_dispatch` with input `ref` | GitHub-hosted `macos-15` | Developer-ID-signed **qa** flavor zip for the pre-PR QA gate | env `qa-build`: `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID` |
| `release.yml` (new) | `push` tag `v*`; `workflow_dispatch` inputs `dry_run` (default true) and `resume` (`none`/`publish-tail`) | GitHub-hosted `macos-15` | gate → sign → notarize → release → appcast → cask | env `release`: all release secrets below |
| `claude.yml` (keep) | `@claude` mentions | ubuntu | unchanged; pin `actions/checkout` and the action to commit SHAs | `CLAUDE_CODE_OAUTH_TOKEN` (exists) |
| `claude-pr-description.yml` (new) | PR opened, same-repo | ubuntu | copy ContainerBar's portable file verbatim | `CLAUDE_CODE_OAUTH_TOKEN` |
| `claude-code-review.yml` | — | — | **removed** (A-10, decision 2026-10-12) | — |
| `.github/dependabot.yml` (new) | weekly | — | `github-actions` ecosystem only (Dependabot's Swift support does not read `.xcodeproj` package references) | — |

Every third-party action is pinned to a full commit SHA (ContainerBar's pins: `actions/checkout@11d5960a…` v4, `actions/cache@0057852b…` v4, `actions/upload-artifact@ea165f8d…` v4, `actions/setup-node@49933ea5…` v4). Also added: `.github/pull_request_template.md` and `.github/ISSUE_TEMPLATE/{bug.yml,feature.yml}` (US-3 AC2). The unmerged `sync-backlog.yml` on `chore/add-backlog-sync-workflow` is obsolete (Mission Control retired; PRMT-006) and is not part of the set.

**GitHub-hosted vs `<qa-mini>`.** Build, unit tests, lint, the macOS 14 smoke, the QA build, and the release all run on GitHub-hosted runners (free for a public repo; they keep signing material off `<qa-mini>` and never touch its desktop). Only `prowl-qa` needs the Mini, because it drives a GUI through Accessibility, which a hosted runner cannot be granted. Lucius' daily pass is not CI; it is an OpenClaw job (section 5).

### 4.2 Build & Test and the test target

1. Committed: `Prompter/Prompter.xcodeproj/xcshareddata/xcschemes/Prompter.xcscheme` (Build: Prompter; Test: PrompterTests, parallelization off because the tests share `@MainActor` singletons today, code coverage on); `Prompter/Prompter.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` (`.gitignore` gets a negation `!**/*.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` after the existing ignore). PRMT-007 (done on `prmt-007-clean-clone-build`) pinned Sparkle to `exactVersion 2.8.1`, the version v1.2.0 shipped with, and tracks `Package.resolved` through `.gitignore` negations; that pin is kept, and the release tooling fetches the Sparkle 2.8.1 tools to match. A Sparkle upgrade is its own later PR.
2. Steps: select Xcode → cache `.spm` keyed on `hashFiles('**/Package.resolved')` → `xcodebuild -resolvePackageDependencies -clonedSourcePackagesDirPath .spm` (fails here, naming Sparkle, if the pin cannot be fetched: US-1 AC4) → `xcodebuild build-for-testing` → `xcodebuild test-without-building` → `python3 Prompter/scripts/tests/test_validate_release.py`. Common flags: `-project Prompter/Prompter.xcodeproj -scheme Prompter -destination 'platform=macOS,arch=arm64' -derivedDataPath .dd -clonedSourcePackagesDirPath .spm -resultBundlePath TestResults.xcresult CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO`. Hardened runtime is off for the CI test build only, because library validation would refuse to load an ad-hoc-signed test bundle into an ad-hoc-signed hardened host. The xcresult is uploaded on failure (unit tests produce no screenshots).
3. **Does `PrompterTests` run headless without booting the app?** Today: it runs on a hosted runner (hosted macOS runners have a logged-in GUI session) but it **does boot the app** with side effects (A-01, A-02), and it must never run on `<qa-mini>` or a developer Mac in that state. After section 3.2: the host process still starts (it is an app-hosted bundle) but `AppEnvironment.unitTest` makes `applicationDidFinishLaunching` return before creating the status item, the event tap, Sparkle, or any storage, and every persistence test uses a temp root. That is enough for CI and for a `<qa-mini>` throwaway clone. **Rejected for now:** extracting `PrompterCore` (Models, Services, Utilities) into a local Swift package so the core tests run with `swift test` and no host at all. It is the cleaner end state but touches every file's imports in the same weeks as Epic A; revisit after Epic D.
4. **SwiftLint** job: pinned portable SwiftLint `0.65.1` (ContainerBar's pin), `cd Prompter && swiftlint lint --reporter github-actions-logging --no-cache` with `Prompter/.swiftlint.yml`. Errors fail the job; warnings are annotations. `--strict` is turned on after the 35 warnings are burned down (a later item, not a gate now). A-03 must merge in the same branch that adds the job.
5. **macOS 14 smoke** (option B only; section 8.2). `needs: build-test`; the build job also produces a Debug **hunt** flavor app (`build` action, ad-hoc signed, uploaded as an artifact). On `macos-14`: download, `xattr -cr`, run `Prompter.app/Contents/MacOS/Prompter --self-check "$RUNNER_TEMP/selfcheck"` (hunt flavor only; compiled out of production), which builds an `AppState` on a temp root, loads the hunt seed, renders the overlay for each seed card and the editor at its minimum size with `ImageRenderer` to PNGs, prints a JSON summary, and exits 0, or non-zero on any missing symbol, crash, or render failure. The PNGs are uploaded as an artifact (they are the "legacy look" evidence for US-21 AC4). If GitHub retires the `macos-14` image, the job moves to `macos-15` and 14 becomes untested (risk R-05).

### 4.3 prowl-qa

Mirror of ContainerBar's `prowl-qa.yml`: same-repo gate, `PROWL_VERSION` pinned to the version ContainerBar uses at merge time (0.1.8 today), checkout `prowl-tools/prowl` at that tag, `npm link`, build `prowl-macdriver`, Accessibility preflight, `Prompter/scripts/build-hunt-app.sh`, `prowl ci --junit`, strip `screenshots/` before upload (public repo), upload `.prowl/runs/` 14 days.

- `build-hunt-app.sh`: `xcodebuild build -configuration Debug -derivedDataPath .prowl/DerivedData PRODUCT_BUNDLE_IDENTIFIER=com.tookes.Prompter.hunt PROMPTER_FLAVOR=hunt CODE_SIGN_IDENTITY=- …`, copy `docs/qa/fixtures/` into `Contents/Resources/HuntSeed/`, re-sign ad hoc, `lsregister -f` the bundle. The bundle never goes to `/Applications` (US-4 AC4).
- Last step (`if: always()`): `osascript -e 'quit app id "com.tookes.Prompter.hunt"'` with a 10 s wait; if still running, report a warning (no `kill`; the runner is on `<qa-mini>` where a PID stop is allowed, but quitting through the app is enough and safer).
- Hunts (`.prowl/hunts/`): `status-item.yml` (identifier present), `editor-opens-seed.yml` (`editorCardList` has 5 rows, first row title "QA Card 1 - Opening"), `overlay-toggle.yml` (menu Show Overlay → `overlayWindow` value starts `card=1/5`), `card-select.yml` (select `editorCardRow-2` → overlay value `card=3/5`), `protected-toggle.yml` (menu Protected Mode → value `protected=off` → back on). Open-and-assert only.
- **Runner.** `homelab-it` registers `<prompter-runner>` for `michaeltookes/prompter` (personal-account runners are repository-scoped) on `<qa-mini>` under the same macOS user as the other runners, labels `self-hosted, macOS, ARM64`, and grants its host process Accessibility once (the `<owner>` clicks the TCC prompt; same as ContainerBar's runner). The CI-busy predicate (section 5.3) gains `repos/michaeltookes/prompter/actions/runners`.
- A queued job on an offline self-hosted runner waits (GitHub keeps it queued up to 24 h); `timeout-minutes: 30` bounds only a running job. The merge checklist treats a queued or missing check as not green, which is what US-4 AC3 needs (story review).

### 4.4 QA build for the pre-PR gate

`qa-build.yml` (dispatch, input `ref`): checkout `ref` → select Xcode → import the Developer ID certificate into a temporary keychain (Sentwise's step) → `xcodebuild archive -configuration Release PRODUCT_BUNDLE_IDENTIFIER=com.tookes.Prompter.qa PROMPTER_FLAVOR=qa PRODUCT_NAME="Prompter QA"` with manual Developer ID signing and hardened runtime → `ditto -c -k --keepParent` → upload artifact `Prompter-QA-<shortsha>.zip`, retention 3 days → delete keychain. Not notarized: Lucius fetches it with `gh run download`, which sets no quarantine attribute. Developer ID signing (not ad hoc) keeps the code-signing designated requirement stable across builds, so the one-time Accessibility grant for `com.tookes.Prompter.qa` survives every new QA build. Lucius installs it to `~/Applications/Prompter QA.app`, never `/Applications`.

### 4.5 Release on tag

One script, `Prompter/scripts/release.sh`, used by CI and locally (Sentwise model); the four existing scripts become its functions and read identity and credentials from the environment (A-05). `release.yml` supplies credentials. Order of steps, each failing the job before anything is published:

1. **Version gate** (`scripts/validate-release.py pre --tag "$GITHUB_REF_NAME"`): tag `vV` == `MARKETING_VERSION` (read with `xcodebuild -showBuildSettings`) == the `Info.plist` value after A-04; `CHANGELOG.md` has `## [V] - YYYY-MM-DD` and the date equals the tag's commit date in America/Chicago; `CURRENT_PROJECT_VERSION` is greater than the newest `sparkle:version` in the live appcast. Any mismatch prints both values and exits 1 (US-5 AC5).
2. **No re-release**: `gh release view vV` succeeds → fail (US-5 AC6), unless `resume=publish-tail` (step 9).
3. **Gate**: SwiftLint + build-for-testing + test-without-building (same flags as CI).
4. **Sign**: import `MACOS_CERTIFICATE_P12` into a temp keychain; archive Release (universal) with `CODE_SIGN_STYLE=Manual`, `CODE_SIGN_IDENTITY="Developer ID Application"`, `DEVELOPMENT_TEAM=$APPLE_TEAM_ID`, `OTHER_CODE_SIGN_FLAGS=--timestamp`; export with `scripts/ExportOptions.plist` (`developer-id`, manual; team from the environment, not the file).
5. **Notarize the app**: `ditto` zip → `xcrun notarytool submit --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$NOTARY_APP_SPECIFIC_PASSWORD" --wait` → on `Invalid`/`Rejected`, `notarytool log <id>` summary (issues array only) to the job log and exit 1 (US-5 AC7) → `stapler staple` → re-zip as `Prompter.zip`.
6. **DMG**: `create-dmg` (installed with `brew install create-dmg` if absent), codesign the DMG, notarize, staple → `Prompter.dmg`, `Prompter.dmg.sha256`.
7. **Verify** both artifacts: `codesign --verify --deep --strict`, `spctl --assess --type execute` (app), `spctl --assess --type open --context context:primary-signature` (DMG), `xcrun stapler validate` (US-5 AC2).
8. **Publish**: `gh release create vV Prompter.zip Prompter.dmg Prompter.dmg.sha256 --title "Prompter vV" --notes-file <CHANGELOG section> --verify-tag`.
9. **Appcast** (idempotent; skipped if an item with `sparkle:shortVersionString = V` already exists): fetch the Sparkle release tarball whose version equals the `Package.resolved` pin; write `SPARKLE_ED_PRIVATE_KEY` to a 0600 file in `$RUNNER_TEMP`; `sign_update --ed-key-file <file> Prompter.zip` → `edSignature`, `length`; `validate-release.py appcast-item` builds the item: `sparkle:version = CURRENT_PROJECT_VERSION`, `sparkle:shortVersionString = V`, `sparkle:minimumSystemVersion = MACOSX_DEPLOYMENT_TARGET`, enclosure URL `https://github.com/michaeltookes/prompter/releases/download/vV/Prompter.zip`, description = the CHANGELOG section converted to simple HTML (headings and list items only). Commit to branch **`gh-pages`** (`appcast.xml` at its root) with `GITHUB_TOKEN` (`contents: write`), push, then poll the public URL for up to 5 minutes until the new item is served. Never touches `main` (US-5 AC4).
10. **Cask**: Sentwise's tap step: clone `michaeltookes/homebrew-tap` with `TAP_PUSH_TOKEN`, skip if the tap already has V or newer, copy the template `Prompter/distribution/prompter.rb`, stamp `version` and `sha256` (from `Prompter.dmg.sha256` of the **uploaded** asset, re-downloaded with `gh release download`, US-6 AC3), commit `prompter: V`, push.
11. `if: always()`: delete the temp keychain and key file.

`resume=publish-tail` (dispatch only, for a tag whose release exists): runs 1, 9, 10 only. It is the recovery path when step 9 or 10 failed after step 8; it never edits or replaces the release.

**`workflow_dispatch dry_run=true`**: steps 1 (against the head, no tag check), 3, 4–7 unsigned (`CODE_SIGNING_ALLOWED=NO`, no notarization), the DMG layout, and the appcast item rendering to the job summary; nothing published. It is how the workflow is tested without secrets.

**Secrets** (names only; GitHub environment `release`, deployment policy "tags matching `v*`" so no branch or PR job can read them): `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_ID`, `APPLE_TEAM_ID`, `NOTARY_APP_SPECIFIC_PASSWORD`, `SPARKLE_ED_PRIVATE_KEY`, `TAP_PUSH_TOKEN`. Environment `qa-build` (dispatch from any branch; workflow_dispatch already requires write access): `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`. Same names as Sentwise's `release.yml` so the certificate, Apple ID, team, and notary password values are re-used; `SPARKLE_ED_PRIVATE_KEY` is **Prompter's own** key (the private half of the `SUPublicEDKey` in `Info.plist`), exported once by `<owner>` with Sparkle's `generate_keys -x`. No repository variables are required; the Xcode pin and Sparkle tool version live in the workflow file and `Package.resolved`.

**Appcast hosting move** (one-time, `vendor-ops` GitHub task, before the first CI release): create orphan branch `gh-pages` containing the current `appcast.xml` byte-for-byte and an empty `.nojekyll`; switch Pages source from `main /` to `gh-pages /`; verify `curl -sS https://michaeltookes.github.io/prompter/appcast.xml | shasum` equals the file's hash; only then delete `appcast.xml` from `main` (a docs-only change). The URL every installed copy uses does not change. Rollback: switch the Pages source back to `main /` (the file is in `main`'s history).

**Branch protection on `main`** (`vendor-ops`): required checks `Build & Test` and `SwiftLint` once `swift-ci.yml` is on `main`; `Prowl QA` added after three consecutive green runs; `macOS 14 smoke` added with Epic D under option B. No required reviews (the factory merges under its checklist).

### 4.6 Cask

Template in the repo at `Prompter/distribution/prompter.rb` (synced whole into the tap by step 10):

```ruby
cask "prompter" do
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/michaeltookes/prompter/releases/download/v#{version}/Prompter.dmg"
  name "Prompter"
  desc "macOS presenter overlay and teleprompter app"
  homepage "https://github.com/michaeltookes/prompter"

  auto_updates true
  depends_on macos: :sonoma   # option B; :tahoe under option A

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

The same fixtures are the hunt seed (section 4.3) and the macOS 14 smoke seed (section 4.2).

### 5.3 Shared rules with the other passes

- **CI-busy predicate** (verbatim from the factory rules): busy if `pgrep -x Runner.Worker` prints a PID, or any runner registered on this host is `busy: true` in `gh api repos/michaeltookes/{sentwise,ContainerBar,prompter}/actions/runners`; an API failure is recorded as `runner-api-unavailable` and (1) alone decides. Checked before the pass (wait up to 10 min, then BLOCKED `ci-busy`) and before every case (no wait).
- **Desktop lock**: the same workspace lock the Sentwise and ContainerBar passes take; wait up to 10 min, then BLOCKED `desktop-busy`.
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
`HotkeyManager` gets a main-actor-written, tap-read state `HotkeyGate { overlayVisible: Bool }`, updated from `AppState.$isOverlayVisible`. In `handleEvent`: `toggleOverlay` is always consumed; every other action is consumed **only** when `overlayVisible` is true; otherwise the event is passed through unchanged. Key repeats follow the same rule. Bindings stay ⌘⇧ (brief Q5 assumption). A pure function `shouldConsume(action:gate:) -> Bool` carries the rule and is unit-tested for every action in both states. The README table, `HotkeyAction.displayString`, and the menu stay generated from `HotkeyAction` (US-7 AC5).

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
Undo: the editor window's `UndoManager` is passed into `AppState` (`registerUndo` on card delete, move, duplicate, layout change, and title/notes commit); ⌘Z/⌘⇧Z work while the editor is key. Asset GC: after each deck flush and once at launch, `AssetManager.collect(referenced: Set<UUID>)` where `referenced` = all `AssetRef` ids across **all** decks plus those held by the undo stack's snapshots; unreferenced files **move** to `Assets/.Trash/` (so they are gone from `Assets/` within one save cycle, US-13 AC1) and `.Trash` is emptied at the next launch. Undo of a delete restores from `.Trash` if needed. Missing asset → placeholder "Image missing", reference kept (AC4).

## 7. APIs and contracts

Prompter has no network API of its own. Contracts that builders and QA depend on:

- **Storage layout** (unchanged plus two folders): `Decks/<uuid>.json`, `Decks/Unreadable/`, `Assets/<uuid>.<ext>`, `Assets/.Trash/`, `Settings.json` (gains optional `overlayDisplayUUID`). JSON with ISO 8601 dates, pretty-printed, sorted keys. No schema version is introduced; A-09 rule applies.
- **Overlay accessibility value** (section 3.3): `key=value` pairs joined by `;`, keys in fixed order; adding keys at the end is non-breaking; renaming is breaking for the recipe.
- **Appcast**: `sparkle:version` integer strictly increasing; `sparkle:shortVersionString` semver; `sparkle:minimumSystemVersion` = deployment target; one `enclosure` (zip) with `sparkle:edSignature` and exact `length`; served from `gh-pages`.
- **Release assets**: `Prompter.zip` (Sparkle), `Prompter.dmg` (cask), `Prompter.dmg.sha256`; names without version (existing convention; cask URL template depends on it).
- **`validate-release.py`** subcommands: `pre --tag vX.Y.Z` (exit 1 with both values on mismatch), `appcast-item --version … --build … --min … --signature … --length … --notes-file …` (prints the XML item), `appcast-check --url …` (top item parse, used by the hourly check). Unit tests in `Prompter/scripts/tests/test_validate_release.py` (stdlib only).
- **Self-check CLI** (hunt flavor only): `Prompter --self-check <outdir>` → exit 0 and `<outdir>/summary.json` `{"cards":5,"renders":[…],"macos":"14.x"}`.

## 8. Liquid Glass makeover (Epic D)

### 8.1 What macOS 26 changes for this app

- **Build SDK, not deployment target, turns it on.** Any build with Xcode 26 and the macOS 26 SDK makes standard AppKit and SwiftUI chrome render in the Liquid Glass style on macOS 26: menus (the status menu), toolbars and their buttons, sidebars in `NavigationSplitView`/source lists (floating glass), sheets, popovers, alerts, bordered and prominent buttons, segmented controls, larger and concentric window corners. On macOS 14/15 the same build keeps the old look. So the first CI-built release (Epic B) already changes the editor and menus on 26 while the custom overlay keeps its 2025 frosted look: a mixed look (R-06).
- **Custom surfaces do not change on their own.** The overlay's `RoundedRectangle.fill(.ultraThinMaterial)` + dark fill + accent glow (`OverlayWindowController.swift:176-213`), the fake traffic lights, `IconButton`/`IconButtonGroup` custom hover backgrounds (`Views/Shared/IconButton.swift:26-96`), `ThemedPanelWindow` forcing `darkAqua` (`Windows/ThemedPanelWindow.swift:33-37`), and the sidebar's opaque `controlBackgroundColor` (`CardListSidebar.swift:126`) all need explicit work.
- **New APIs** (macOS 26): SwiftUI `glassEffect(_:in:)` with `Glass.regular`/`.clear`, `.tint(_:)`, `.interactive()`; `GlassEffectContainer` and `glassEffectID` for grouped and morphing glass; `.buttonStyle(.glass)`/`.glassProminent`; `ToolbarSpacer`; concentric shapes (`ConcentricRectangle`, `.containerConcentric`); AppKit `NSGlassEffectView`/`NSGlassEffectContainerView`, `NSButton.BezelStyle.glass`.
- **Status item.** The macOS 26 menu bar is transparent by default; template images stay correct. Menus in 26 show symbols on many items; adding `NSMenuItem.image` SF Symbols is harmless on 14/15.
- **Typography.** SF Pro remains; titles in 26 are bolder in standard chrome. The overlay keeps its own sizes scaled by `fontScale` (an explicit project rule); the editor keeps Dynamic Type styles.
- **Dark/light.** The editor and panels follow the system appearance. The overlay stays a dark-tinted surface in both appearances (legibility over arbitrary slides and video is the product's job), which is now an explicit design rule.
- **Accessibility settings.** System glass adapts automatically to Reduce Transparency (frostier, near-opaque), Increase Contrast (borders), and Reduce Motion (no morphing). Custom code must read `accessibilityReduceTransparency` and `accessibilityReduceMotion` from the environment for the legacy path and for any custom animation. macOS 26.1+ also offers a user "Clear/Tinted" glass preference that system glass honours; we do not override it.
- **App icon.** macOS 26 draws non-conforming legacy icons inside a grey squircle plate. An Icon Composer `.icon` asset (Xcode 26) renders in Default, Dark, Clear, and Tinted styles and Xcode generates flat fallbacks for 14/15.
- **Compatibility switch.** Apple provides the `UIDesignRequiresCompatibility` Info.plist key to keep the pre-26 look for one release cycle. Use: set it to `YES` only in a release cut **before** Epic D lands, to avoid the mixed look; Epic D's first story removes it. The builder confirms by screenshot on `<qa-mini>` that the key is honoured for this AppKit app; if not, accept the mixed look for that release.

### 8.2 The two options for the owner

| | **A. Deployment target macOS 26** | **B. Keep macOS 14+, glass on 26 behind availability checks (recommended)** |
|---|---|---|
| Users | 14/15 users stay on 1.2.0 forever: Sparkle hides the new item (`minimumSystemVersion 26.0`), `brew upgrade` refuses (`depends_on macos: :tahoe`). Decision D008 superseded. | Everyone on 14+ updates. D008 stands. |
| Code | Use glass APIs directly; delete legacy material code; freely adopt 15/26-only APIs (`ScrollPosition`, `Observations`) elsewhere. | One `PrompterGlass` layer: `GlassSurface`, `GlassButtonStyle`, `GlassGroup` view modifiers with `if #available(macOS 26, *)` inside and today's look as the `else`. About 150 lines; every glass call goes through it (US-20 AC2 is then a grep for `glassEffect(` outside `Views/Shared/PrompterGlass.swift`). |
| QA | Mini (26.4) covers everything. | Mini covers 26. 14 is covered by the CI **macOS 14 smoke** (launch + ImageRenderer snapshots, section 4.2); 15 is not covered on device (the hosted `macos-15` runner runs the unit tests only). |
| Ongoing cost | Lowest. | Two looks per custom surface until the floor is raised; each Epic D story carries a legacy screenshot check (CI artifact). |
| Effort | Epic D ≈ 4 builder branches. | Epic D ≈ 5 builder branches (the extra one is `PrompterGlass` + the smoke job). |
| Reversible | Hard (users dropped cannot be re-offered without a re-release). | Easy (raise the floor later). |

**Recommendation: B.** The custom surfaces are few (overlay background, overlay controls, footer chips, two panels, icon buttons), so the availability layer is small, and the system chrome adapts on its own. Dropping working 14/15 users of a free app for appearance alone is a customer-facing change with no offsetting gain; presenters on managed corporate Macs often lag a major version (the brief's reasoning). Revisit when macOS 27 ships: raise the floor to 15 or 26 then.

### 8.3 Per-surface change list

| # | Surface (file) | macOS 26 | 14/15 under option B |
|---|---|---|---|
| 1 | Status item (`MenuBarController.swift:77-93`) | keep template SF Symbol `text.bubble`; add SF Symbols to menu items (eye, pencil.and.list.clipboard, shield, cursorarrow.click, timer, checkmark.shield, arrow.triangle.2.circlepath, power) | same images; no visual change otherwise |
| 2 | Overlay surface (`OverlayWindowController.swift:170-216`) | `GlassSurface`: `.glassEffect(.regular.tint(Theme.Glass.overlayTint.opacity(t)), in: .rect(cornerRadius: Theme.overlayCornerRadius))`, `t = 0.45 + 0.5 × overlayOpacity` (so 30 % still leaves a tint floor that keeps text contrast ≥ 4.5:1, US-21 AC2); drop the dark fill, the accent glow shadow, and the stroke; corner radius 18 → 22; content forced `.environment(\.colorScheme, .dark)` | today's material + fill + glow, unchanged (US-21 AC4 baseline) |
| 3 | Overlay top controls (`:240-307`) | fake traffic lights removed; one `GlassGroup` at top-left with a hide button (`xmark`, `.buttonStyle(.glass)`, label "Hide overlay", `overlayClose`) and the drag hint text kept | plain borderless `xmark` button with the same label and identifier (US-14 AC3 lands this first) |
| 4 | Overlay footer (`Views/Overlay/OverlayFooterView.swift`) | `GlassGroup` of capsule chips: counter, timer (tint orange in warning), Protected indicator (tint orange/red when off, "Visible to capture" text kept), click-through indicator | current footer |
| 5 | Layout renderers (`Views/Overlay/LayoutRenderers/*`) | content unchanged; image corners concentric to the surface (`ConcentricRectangle`) | 14 pt radius as today |
| 6 | Deck Editor window (`MenuBarController.swift:216-251`, `DeckEditorView.swift:16-60`) | host with `NSHostingController` (window `toolbarStyle = .unified`); `HSplitView` → `NavigationSplitView { CardListSidebar } detail: { CardCanvasView }`; remove `Theme.sidebarBackground` behind the sidebar; card rows become `List(selection:)` rows; toolbar items standard (glass automatically), `ToolbarSpacer(.fixed)` between groups | `NavigationSplitView` renders a standard source-list sidebar; toolbar as today (the structural change is shared) |
| 7 | Sheets and alerts (`DeckSettingsSheet`, new-deck sheet, delete alert) | system (automatic) | system |
| 8 | Themed panels (`ThemedPanelWindow.swift`, `TimeInputPanelView.swift`, `DeckPickerPanelView.swift`) | stop forcing `darkAqua` (follow system); content in a `GlassSurface`; primary button `.glassProminent`, secondary `.glass` | follow system; `.borderedProminent` / `.bordered` |
| 9 | Icon buttons (`Views/Shared/IconButton.swift`) | `.buttonStyle(.glass)`; `IconButtonGroup` → `GlassGroup` | current hover/press styling |
| 10 | Image drop zones (`Views/Shared/ImageDropZone.swift`) | content, not chrome: `.quaternary` fill, dashed stroke kept, concentric corners | as today |
| 11 | Test Protected Mode window (`Views/TestCapture/TestCaptureView.swift`) | standard window; Run Test `.glassProminent` | `.borderedProminent` |
| 12 | Theme (`Extensions/Theme.swift`) | add `Theme.Glass.{overlayTint, chipTint, warningTint, dangerTint}`; deprecate `accentGlow`, `trafficLight*`, `surfaceBackground` (legacy path only) | legacy tokens kept for the `else` path |
| 13 | App icon (`Resources/Assets.xcassets/AppIcon.appiconset`) | Icon Composer `Prompter.icon` (foreground speech-bubble glyph layer, background gradient layer) set as the app icon; the owner reviews the icon in Discord before merge (brand) | Xcode-generated fallback |
| 14 | Animations (`OverlayWindowController.swift:214-215`, `OverlayFooterView` pulse) | respect `accessibilityReduceMotion` (no pulse, no card transition) | same |
| 15 | Empty scene (`PrompterApp.swift`) | `Settings { EmptyView() }` (F-15) | same |

### 8.4 Verification on `<qa-mini>` (macOS 26.4) by screenshot

TC-PR-15 over the checker backdrop at 2×: overlay cards 1, 4, 5 at opacity 100 % and 30 %, Light and Dark; footer with Protected on and off and timer warning; editor at default and minimum size; both panels; status menu open; Finder `/Applications` icon in Default/Dark/Clear/Tinted (icon style is a System Settings > Appearance choice; switched through the UI in the release brief, restored after). Contrast for US-21 AC2 is measured by `scripts/qa/contrast.swift <png> <x,y,w,h>` (CoreGraphics, prints the WCAG ratio between the text's dominant colour and the surface sample). Reduce Transparency and Increase Contrast need System Settings > Accessibility > Display toggles: release brief only, toggled through the UI and restored, SKIPPED if the UI blocks. Legacy look (option B): the CI macOS 14 smoke artifacts compared against snapshots rendered from the pre-Epic-D commit (mean absolute difference ≤ 2 % per image, text antialiasing excluded by masking the text frames reported in `summary.json`), which is the tolerance for US-21 AC4.

## 9. Auth, billing, privacy and consent

- **Auth and billing:** none. Prompter is free, MIT, no accounts, no licensing, and this design adds none.
- **What leaves the device:** only Sparkle's update request to GitHub Pages and the zip download from GitHub Releases. Sparkle system profiling stays off (`SUEnableSystemProfiling` absent). No telemetry, no crash reporter is added. The self-test capture (6.4) stays in memory.
- **Permissions:** Accessibility (hotkeys, existing prompt and copy); Screen Recording only when the presenter clicks Run Test, with the explanatory copy from 6.4 shown first, never at launch.
- **Logging:** `os.Logger` stays (D012). Deck titles are logged today with default privacy (dynamic strings are redacted in release logs); new log lines log file names and counts only, never card text.
- **Secrets:** GitHub environment secrets only (4.5); never in the repo, logs, artifacts, briefs, or Discord. The personal Apple ID email leaves the scripts (A-05).
- **QA evidence privacy:** fictional seed only; screenshots cropped; CI artifacts strip screenshots (public repo); daily evidence stays on `<qa-mini>`.
- **Customer-facing copy needing the owner's approval:** Protected Mode claims (README, footer, Test window), the Screen Recording explanation, the deployment-target change in release notes (if option A), and the new app icon.

## 10. Non-functional requirements

- **Launch:** status item visible ≤ 2 s after launch on the Mini (TC-PR-02 allows 10 s for automation slack).
- **Hotkeys:** event-tap callback does no I/O and no allocation beyond the action lookup; < 1 ms per event; never blocks (a blocked tap is disabled by the system).
- **Persistence:** every edit on disk ≤ 1.5 s after the last keystroke; zero lost edits across deck switches and quit (US-12 AC1/AC2); writes are atomic.
- **Idle cost:** with the overlay hidden and no timer, CPU time growth < 36 s per hour and RSS < 150 MB (hourly check, after PRMT-013).
- **Offline:** everything except the update check works offline; a failed update check never blocks the overlay or hotkeys.
- **CI budget:** Build & Test ≤ 20 min, SwiftLint ≤ 10 min, macOS 14 smoke ≤ 15 min, prowl-qa ≤ 30 min, release ≤ 60 min, qa-build ≤ 30 min.
- **QA budget:** daily pass ≤ 1200 s; hourly check < 60 s, zero tokens.
- **Observability:** os_log subsystem `com.tookes.Prompter` (existing categories); the pass attaches `log show --predicate 'subsystem == "com.tookes.Prompter"' --last 25m --style compact` to every FAIL; CI uploads xcresult on failure.

## 11. Test strategy hooks

- **Unit tests the builder adds** (all run on CI, never on the MacBook): `shouldConsume` for every hotkey in both overlay states; `OverlayPlacement.clamp` (fully off, partly off right edge, larger than screen, two screens); scroll clamp math; `DeckStore` ordering (20 edits in 2 s → last content), cross-deck flush on switch, unreadable-file quarantine, write-error surfacing; asset GC reference counting across decks and the undo stack; overlay accessibility-value formatter; `AppEnvironment` resolution table; `validate-release.py` (version mismatch, CHANGELOG date, build-number monotonicity, appcast item rendering).
- **Seed data:** section 5.2 fixtures, used by the daily pass, gate runs, hunts, and the macOS 14 smoke.
- **Needs Lucius / a device:** every TC-PR case; anything with hotkeys, capture, fullscreen, Spaces, Sparkle UI, or appearance screenshots.
- **Needs a second display:** US-9 AC2–AC4 (not on the Mini unless the owner attaches one).
- **Cannot be tested in-house:** real Meet/Teams screen shares (proxy: TC-PR-10c Chrome preview), macOS 15 on device under option B.
- **Gate rule:** a story in Epics A or D gets its PR only after its TC-PR cases pass against a `qa-build` of the branch (factory QA gate). Epic B and C stories are config/docs and skip the gate.

## 12. Trade-offs considered

- **Appcast via a PR to `main` vs `gh-pages` vs Pages-from-Actions artifact:** a PR per release needs a human merge before users see the update; Actions-artifact Pages replaces the whole site on every deploy and loses the file's history; a `gh-pages` branch keeps the URL, keeps history, keeps `main` protected, and is one push. Chosen: `gh-pages`.
- **Appcast as a release asset (Sentwise model):** would change `SUFeedURL`, which every installed copy already has baked in. Rejected.
- **Running the release on `<qa-mini>`:** keeps the keychain-based notary profile, but puts signing keys on the shared QA machine and competes with its desktop. Rejected; GitHub-hosted with environment-scoped secrets.
- **Test isolation by a `PrompterCore` package vs an `AppEnvironment` guard:** the package is cleaner but is a large import churn during Epic A. Chosen: guard + injectable storage now; package later.
- **Ad-hoc-signed QA builds:** simpler (no secrets) but every build changes the code signature, so the Accessibility grant would have to be redone by the owner for every gate run. Chosen: Developer ID signed, not notarized.
- **Leaving Prompter running on the Mini (ContainerBar parity):** gives an "alive" hourly signal but, until F-01 is fixed, steals shortcuts from the other passes. Chosen: quit between passes until PRMT-013 ships.
- **A Peekaboo-free in-app QA mode (`--qa` flag scripting the cases):** would test a different code path than users run. Rejected, as in ContainerBar.
- **Keeping the Claude code-review workflow for parity with ContainerBar:** contradicts the 2026-10-12 factory decision. Rejected (A-10).
- **Option A (26-only) for the makeover:** see 8.2.

## 13. Story review

Applied to `docs/requirements/audit-and-modernization.md` on 2026-10-14 (same branch), with the orchestrator's rulings: US-3 and US-19 as designed here. US-27 (credentials and personal data out of the release scripts, finding F-20) was added at that time. The BA folds the backlog.

| Story | Verdict | Change proposed |
|---|---|---|
| US-1 | feasible | Add technical task: test isolation (`AppEnvironment.unitTest`, `PersistenceService(rootURL:)`, temp-dir tests; A-01, A-02) — without it the 134 tests overwrite real data wherever they run. AC1: "on a clean macOS runner in CI", not "a Mac" (testing never runs on the owner's machines). AC2: keep "pins one exact version" (Package.resolved always does) and add "the project requirement is `upToNextMinor`". |
| US-2 | feasible | Add task: A-03 (split `AppState` so SwiftLint has no error) in the same branch as the lint job. Add: CI test build uses the signing overrides in 4.2. |
| US-3 | **conflicts with decision 2026-10-12** | AC1: replace the Claude code-review workflow with "the Claude code-review workflow is removed; `claude.yml` stays; `claude-pr-description.yml` is added". Orchestrator to confirm. |
| US-4 | feasible | AC2 names: bundle id `com.tookes.Prompter.hunt`, data root `Prompter-Hunt/`. AC3: a job on an offline self-hosted runner stays *queued* (GitHub holds it up to 24 h); `timeout-minutes` cannot fail it at 30 min. Reword: "the check stays pending or fails, never reports success; the merge checklist treats pending as not green". Add task: `homelab-it` registers `<prompter-runner>` and the owner grants its host Accessibility. Depends on the flavor work (US-25 below). |
| US-5 | feasible | AC1 date: "equals the tag's commit date in America/Chicago". AC4: Pages source is `gh-pages`. AC6: add "a `resume=publish-tail` dispatch finishes appcast and cask for an existing release without modifying it". Add tasks: A-04 (version single source), A-05 (credentials from env), appcast hosting move (4.5), environment `release` with tag policy. Precondition: owner exports the Sparkle key (Q2). |
| US-6 | feasible | AC1: `brew audit` runs at the end of `release.yml`. Add: the live-tap fix can merge now (genkei-ops 16b). |
| US-7 | feasible | Design 6.1. AC5 depends on brief Q5. |
| US-8 | feasible | Step = 3 lines = 72 pt at scale 1.0 (6.2). |
| US-9 | feasible | Data change: optional `Settings.overlayDisplayUUID` (6.3). AC2–AC4 need a second display (not on the Mini by default). |
| US-10 | feasible, two branches | Split: **10a** measurement + docs (Lucius TC-PR-10, no code) and **10b** the self-test (6.4). AC3: "within 5 s *when Screen Recording is already granted*"; first grant on macOS 15+ needs a relaunch, which AC4's copy must say. AC1 tools named: `screencapture -x -D 1` and Peekaboo's ScreenCaptureKit capture; weekly Chrome `getDisplayMedia` preview. |
| US-11 | feasible | Poll design 6.5 meets "within 5 s". |
| US-12 | feasible | Design 6.6 (`DeckStore` actor). |
| US-13 | feasible, AC conflict | AC1 ("file gone within one save cycle") vs AC3 (undo restores images): reword AC1 to "moved out of `Assets/` to `Assets/.Trash/` within one save cycle and deleted at next launch". Two branches: undo, then GC. |
| US-14 | feasible | Fine. Add A-13 explicitly (already in AC1). |
| US-15 | feasible | Identifier list extended (3.3) plus the overlay `accessibilityValue` contract. Seed (5.2) matches AC2 (5 cards, card 3 has 40 bullets, test-pattern images). |
| US-16 | feasible | AC3 add `lsappinfo` check for no Dock tile (TC-PR-02). |
| US-17 | feasible | AC5 tools named (TC-PR-10). AC7 detection uses `menuHotkeyStatus` once US-11 ships; before that, "hotkey had no effect on the overlay value". |
| US-18 | feasible | Fine. |
| US-19 | **AC1/AC3 conflict with A-11** | Until the release containing PRMT-013 is installed on the Mini, restore leaves Prompter **quit** and the hourly check asserts `pgrep -x Prompter` is empty; after it, running. Schedule: 08:15 CT daily (5.4). |
| US-20 | feasible | AC2 check named: CI **macOS 14 smoke** (4.2). Add: remove `UIDesignRequiresCompatibility` if an interim release set it. |
| US-21 | feasible | AC2 met by design via the tint floor (8.3 row 2). AC4 tolerance: mean absolute difference ≤ 2 % with text masked. AC5 runs in the release brief only. |
| US-22 | feasible | AC4 is automatic: with click-through on, the whole window ignores mouse events. Footer has no opacity control today; AC2 should list counter, timer, Protected, click-through. |
| US-23 | feasible | Structural change (`NavigationSplitView`, `NSHostingController`) applies on all OS versions. |
| US-24 | feasible | Icon design is a brand asset: owner review in Discord before merge. |
| **US-25 (new)** | proposed | *App flavors and isolated storage* (3.2): AC — production/qa/hunt/unitTest resolved as tabled; hunt and qa never read `Prompter/`; unit tests never touch `~/Library`; production ignores `PROMPTER_HUNT_MODE`. Blocks US-1 (tests), US-4, US-26, the gate. |
| **US-26 (new)** | proposed | *QA build for the pre-PR gate* (`qa-build.yml`, 4.4): dispatch with a ref → Developer-ID-signed `Prompter QA.app` zip artifact, 3-day retention; installs beside the release without touching its data. Blocks the QA gate for Epics A and D. |
| **US-27 (new)** | proposed | *Release validator and appcast hosting* could be folded into US-5 instead; listed so the BA decides. |

**Suggested order for the planner** (dependencies, not dates): M1 foundations — PRMT-007 (US-1, dispatched), US-25, US-2 (+A-03), US-3 (as amended), US-14; M2 QA plumbing — US-15, US-26, US-4 (runner), Lucius setup + US-16..19 (pass starts with known-failures); M3 release — appcast move, US-5, US-6 → cut 1.3.0 with `UIDesignRequiresCompatibility = YES`; M4 audit fixes behind the gate — US-7, US-11, US-8, US-9, US-12, US-13, US-10a then 10b → 1.4.0; M5 makeover — US-20 (+ smoke job), US-21, US-22, US-23, US-24 → 2.0.0.

## 14. Risks and open questions

**Risks**
- **R-01 Protected Mode may not protect on macOS 15+/26** (F-04). If TC-PR-10 shows ScreenCaptureKit captures the overlay, the product's headline promise is false for most users. Mitigation: measure first; copy changes go to the owner; there is no supported API that excludes a window from all ScreenCaptureKit capture, so the honest outcome may be a caveat, not a fix.
- **R-02 Sparkle private key custody.** If the private key matching `SUPublicEDKey` cannot be found, CI cannot sign updates that 1.2.0 installs will accept. Mitigation: owner checks the keychain first (Q2); if lost, the next release must ship a new public key via a Developer-ID-signed build that users install manually or through the cask, and Sparkle-only users are stranded on 1.2.0.
- **R-03 Synthetic hotkeys vs the event tap.** Peekaboo-posted key events must reach a session-level event tap; if they do not on 26.4, hotkey cases become BLOCKED. Mitigation: the first setup run verifies with TC-PR-05; fallback posts with `CGEvent.post(tap: .cghidEventTap)` from a tiny helper on the Mini.
- **R-04 Menu-item identifiers** may not surface through Peekaboo; recipe falls back to fixed titles.
- **R-05 `macos-14` hosted image retirement** removes the only 14 coverage under option B.
- **R-06 Mixed look** in any release built with Xcode 26 before Epic D; mitigated by `UIDesignRequiresCompatibility` if honoured.
- **R-07 Signing secrets in a public repo's workflows.** Mitigated by environment scoping (tags `v*` only for `release`), same-repo gates on every secret-using workflow, and SHA-pinned actions.
- **R-08 Shared desktop on the Mini** (prowl-qa hunts and gate runs boot Prompter builds next to the other passes). Mitigated by the CI-busy predicate including this repo's runner and by distinct bundle ids.

**Open questions for the owner** (assumption in force until answered)
1. **Deployment target:** option A (macOS 26 only) or option B (keep 14+, glass on 26)? *Assumed B* (8.2).
2. **Release credentials:** confirm Prompter's Sparkle EdDSA private key is in your login keychain and approve exporting it (`generate_keys -x`) into the `SPARKLE_ED_PRIVATE_KEY` secret, and approve re-using the Developer ID certificate, Apple ID, team, and notary app-specific password already used by Sentwise's release workflow for Prompter's `release` and `qa-build` environments. *Assumed yes*; US-5 cannot publish until the key is in place, and if the key is lost, R-02 applies.
3. **One-time grants on Lucius' Mini:** you grant Accessibility to `/Applications/Prompter.app`, `~/Applications/Prompter QA.app`, and the new `<prompter-runner>` host (and Screen Recording to Chrome for the weekly browser-share leg). *Assumed you will, once, over Screen Sharing*; until then hotkey cases are BLOCKED `tcc-accessibility` and prowl-qa fails its preflight.

## 15. Story-to-design map

| Work | Owner | Design sections | Blocks |
|---|---|---|---|
| PRMT-007 / US-1: shared scheme, Package.resolved, dist out of git | builder (dispatched) | 2.2 F-10/F-11, 4.2 | CI |
| US-25 (new): flavors + isolated storage + test isolation | builder | 3.2, 2.3 A-01/A-02 | US-1 tests, US-4, US-26, gate |
| US-2: swift-ci.yml + A-03 | builder | 4.1, 4.2 | branch protection |
| US-3 (amended): workflows/templates, remove claude-code-review | builder | 4.1, A-10 | — |
| US-4: prowl-qa + hunt build + runner | builder; homelab-it (runner); owner (TCC) | 4.3, 3.3 | required check later |
| US-26 (new): qa-build.yml | builder; vendor-ops (env + secrets) | 4.4 | QA gate |
| Appcast to gh-pages, environments, branch protection | vendor-ops | 4.5 | US-5 |
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
| US-20 (+ macOS 14 smoke) | builder | 8.1, 8.2, 4.2 | Epic D |
| US-21, US-22 | builder | 8.3 rows 2–5, 14; 8.4 | — |
| US-23 | builder | 8.3 rows 6–9, 11 | — |
| US-24 | builder; owner (icon review) | 8.3 rows 1, 13 | 2.0.0 |
