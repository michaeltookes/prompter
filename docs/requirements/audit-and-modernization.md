# Requirements: Prompter audit and modernization

| Field | Value |
|---|---|
| Slug | `audit-and-modernization` (story ids `US-audit-and-modernization-<n>`) |
| Branch | `req/prompter-audit` (design merged in from `req/prompter-audit-arch`: `docs/architecture/audit-and-modernization.md`) |
| Source | Owner intake 2026-10-14: audit the whole app, bring it into the Lucius QA lane the way ContainerBar is, add the CI/CD ContainerBar has, and give it a Liquid Glass makeover for macOS 26 |
| Baseline | `main` at `0e3e602` (code as of `b536f1b`, 2026-02-18; last release v1.2.0) |
| Backlog | `docs/backlog.md`, items PRMT-007 to PRMT-034 (Epics B, A, C, D in build order; PRMT-031 to PRMT-034 added by the architect review); PRMT-007 completed; PRMT-006 marked obsolete |
| Status | Reconciled with the architect's design 2026-10-14 (feasibility review applied: US-25, US-26, US-27 added, US-10 split into 10a/10b, rulings on US-3 and US-19 recorded). Waiting on the owner's answers to section 9 (Q1, Q6, Q7). |

## 1. Problem

Prompter has not been opened since February 2026. It shipped four releases in two weeks (v1.0.0 2026-02-02 to v1.2.0 2026-02-12) and then stopped. Since then:

- **Nothing checks a change.** The repo has two Claude workflows and no build, test, lint, or QA workflow (`.github/workflows/` holds only `claude.yml` and `claude-code-review.yml`). Every release was built, signed, notarized, and published by hand from the owner's MacBook with four scripts.
- **Nobody watches the released app.** ContainerBar now has a daily Lucius pass that proves the released build installs, launches, and does its job. Prompter has no equivalent and no `docs/qa/`.
- **macOS 26 shipped Liquid Glass.** Prompter's overlay, panels, and icon were designed against macOS 14/15 materials (`.ultraThinMaterial` plus a dark fill, custom fake traffic lights). On macOS 26 it will look like an app from the previous generation next to the system UI.
- **The audit below found defects a presenter would hit during a live demo**, the worst of which are that the app swallows common shortcuts in every other app (F-01) and that the documented scroll shortcuts do nothing (F-02).

How we know: the code read for this brief (findings cite file and line), the GitHub release list, and the PM's intake snapshot (section 2.3).

## 2. Audit brief

### 2.1 What the app does today

**The user and the job.** A sales rep or solution architect is screen-sharing a live product demo in Google Meet or Microsoft Teams. They want their talking points (titles, bullets, notes, reference screenshots) visible to them and invisible to the audience, and they want to step through those points without touching the mouse or leaving the app they are demoing.

**Surfaces.**

| Surface | What it is | Where |
|---|---|---|
| Status item | SF Symbol `text.bubble`, template image, accessibility description "Prompter"; no title | `App/MenuBarController.swift:77-93` |
| Status menu | Show/Hide Overlay, Open Deck Editor…, Protected Mode (check), Click-through Overlay (check), Presentation Timer submenu (start/stop, deck vs per-card mode, set times, pause button, apply to all/selected decks), Test Protected Mode…, Check for Updates…, Quit Prompter (⌘Q) | `MenuBarController.swift:106-191`, `305-386` |
| Overlay | Borderless, resizable `NSWindow` at `.floating` level, on all Spaces and over full-screen apps, drag anywhere, `sharingType = .none` when Protected Mode is on, click-through via `ignoresMouseEvents`; SwiftUI content: drag handle with fake traffic lights (only the red one works, it hides the overlay), the card in a `ScrollView`, footer with card counter, timer, opacity, Protected Mode warning | `Windows/OverlayWindow.swift`, `Windows/OverlayWindowController.swift:170-307`, `Views/Overlay/` |
| Deck Editor | 1000×700 `NSWindow` with an `HSplitView`: deck list (max 10 decks), card list with thumbnails, move up/down, duplicate, delete; per-layout editor; image drop zones with Browse | `Views/DeckEditor/` |
| Layouts | Six: Title + Bullets, Title + Notes, Image Top + Notes, Two Images + Notes, 2×2 Grid + Caption, Full-bleed Image + 3 Bullets | `Models/LayoutType.swift` |
| Panels | Themed `NSPanel` dialogs for timer times and the timer deck picker | `Windows/ThemedPanelWindow.swift`, `Views/Shared/TimeInputPanelView.swift`, `DeckPickerPanelView.swift` |
| Test Protected Mode | A window of instructions for checking capture exclusion by hand; it does not test anything itself | `Views/TestCapture/TestCaptureView.swift` |

**Global hotkeys** (CGEvent tap, all ⌘⇧): O toggle overlay; ← / → previous/next card; = / - font size; ↑ / ↓ scroll; C click-through; P Protected Mode; ] / [ opacity; T timer start/pause/stop (`Services/HotkeyManager.swift:24-78`). Requires the Accessibility permission; the app prompts once per 12 hours and retries registration 12 times at 5-second intervals (`HotkeyManager.swift:101`, `AppDelegate.swift:98-117`).

**Settings and what they persist** (`Models/Settings.swift`): overlay opacity (clamped 0.3 to 1.0), font scale (0.5 to 2.0), overlay frame (absolute x/y/width/height), click-through, Protected Mode (default on), last opened deck, timer enabled/mode/total seconds/per-card seconds/pause button/apply mode/selected decks. There is no Settings window; everything is set from the status menu, the overlay footer, or hotkeys. There is no launch-at-login option (no `SMAppService` anywhere).

**Data it stores.** All local, no account, no network except the update check:

```
~/Library/Application Support/Prompter/
├── Decks/<deckId>.json     one file per deck, pretty-printed JSON
├── Assets/<uuid>.<ext>     imported images, renamed, full resolution
└── Settings.json
UserDefaults (com.tookes.Prompter): last Accessibility prompt time, legacy-migration flag, Sparkle keys
```

A one-time migration copies data from the pre-rename `PresenterOverlay` folder (`Services/PersistenceService.swift:85-148`).

**Update path.** Sparkle 2 (SPM, `upToNextMajorVersion` from 2.0.0) with automatic checks on; feed `https://michaeltookes.github.io/prompter/appcast.xml` served by GitHub Pages from `main`; EdDSA public key in `Info.plist`. Distribution is GitHub Releases (`Prompter.zip` for Sparkle, `Prompter.dmg` for people) and the cask `michaeltookes/tap/prompter`. Release is four local scripts: `build-release.sh` (archive, Developer ID sign), `notarize.sh` (keychain profile `Prompter-Notarize`), `create-dmg.sh`, `publish-release.sh` (Sparkle sign, edit `appcast.xml`, commit and push to `main`, create the GitHub Release).

### 2.2 State

| Item | Value | Evidence |
|---|---|---|
| Last release | v1.2.0, GitHub Release 2026-02-12 20:53 UTC; CHANGELOG says 2026-02-11 | `gh release list`; `CHANGELOG.md:9`; `appcast.xml:44` |
| Version / build | 1.2.0 / 4 | `Prompter/Prompter/Resources/Info.plist`, `project.pbxproj` |
| Deployment target | macOS 14.0 | `project.pbxproj:589,646,718,736` |
| Toolchain | Swift language mode 5.9, project last upgraded by Xcode 15 (`LastUpgradeCheck = 1500`), not yet built with the macOS 26 SDK | `project.pbxproj:408,678` |
| Bundle id / team | `com.tookes.Prompter`, Developer ID team in `project.pbxproj`; hardened runtime on, sandbox off | `project.pbxproj:663-675`; `Resources/Prompter.entitlements` |
| Dependencies | Sparkle 2.x only, unpinned (no `Package.resolved` committed; `.gitignore:12` ignores it) | `project.pbxproj:781-784` |
| Tests | 9 XCTest files (plus one mock), 134 test functions; no UI tests; no CI runs them | `Prompter/PrompterTests/` |
| Lint | `Prompter/.swiftlint.yml` exists; nothing runs it | |
| Workflows | `claude.yml`, `claude-code-review.yml` only | `.github/workflows/` |
| Shared Xcode scheme | none committed (`Prompter.xcodeproj` holds only `project.pbxproj`) | `git ls-files` |
| Branches | 16 remote branches besides `main`; every one is 0 commits ahead of `main` (fully merged), including `next-updates` and `phase-1`; `chore/add-backlog-sync-workflow` keeps only the Mission Control sync commits, which are obsolete | `git rev-list --count origin/main..origin/<b>` |
| Dead or unfinished code | `TestCaptureWindowController` is never used (the menu builds its own window); `DeckEditorPlaceholderView` and `TestCapturePlaceholderView` are leftovers; `PersistenceService.loadDeckMetadata`, `totalDataSize`, `clearAllData` and the `ioQueue` are unused; `AssetManager.deleteAsset` and `cleanupUnusedAssets` have no callers | F-09, F-14 |

### 2.2a Repo hygiene done by PRMT-007 (completed 2026-10-14; branch `prmt-007-clean-clone-build` at acf9f3e, PR #17)

Stories below do not redo these; they build on them.

- **Shared scheme:** `Prompter.xcodeproj/xcshareddata/xcschemes/Prompter.xcscheme` is committed with `PrompterTests` in its Test action (commit `6678889`).
- **Sparkle pinned:** the package requirement is `exactVersion 2.8.1`, the version v1.2.0 shipped with, and `Package.resolved` is tracked through `.gitignore` negations under `project.xcworkspace/xcshareddata/swiftpm/` (commit `3e6f2d2`). Release tooling (US-5) fetches the Sparkle 2.8.1 tools to match; a Sparkle upgrade is its own later PR.
- **Build output out of git:** the 80 files under `Prompter/dist/` (app, DMG, zip, logs, duplicate `ExportOptions.plist`) are removed and `dist/` stays ignored (commit `6807acd`).
- **Not done by PRMT-007 and still open:** running the unit tests anywhere is unsafe until US-25 lands (F-21); no workflow runs build, tests, or lint until US-2.

### 2.3 PM intake inputs (2026-10-14) and corrections

The project-manager's snapshot was taken as input. Confirmed: last release v1.2.0 (2026-02-12), deployment target 14.0, nine unit-test files, a hardcoded notarization keychain profile, no swift-ci, prowl-qa, or release workflow, the tap cask on the deprecated `depends_on macos:` string form (genkei-ops backlog 16b), no `docs/qa/`. Two corrections from the code: the release scripts live in `Prompter/scripts/` (not `Prompter/Prompter/scripts/`), and `Prompter/.swiftlint.yml` does exist; the gap is that no workflow runs it.

### 2.4 Gaps a user would notice

1. Pressing ⌘⇧← or ⌘⇧→ to select to the start or end of a line, ⌘⇧[ / ⌘⇧] to switch browser or Terminal tabs, ⌘⇧T to reopen a closed tab, ⌘⇧P for a command palette, or ⌘⇧C in a browser does nothing in any app while Prompter runs, even with the overlay hidden (F-01).
2. ⌘⇧↑ / ⌘⇧↓ do not scroll a long card, although the README and user guide promise they do (F-02).
3. After presenting on an external display and then unplugging it, the overlay can open where no screen is and appear to be gone (F-03).
4. If the Accessibility permission is granted more than a minute after first launch, hotkeys stay dead until the app is relaunched, with no sign in the menu (F-05).
5. Deleting a card is immediate, with no confirmation and no undo (F-08).
6. Only 10 decks are allowed (`AppState.swift:24`).
7. There is no Settings window, no list of hotkeys in the app, and no launch at login.
8. On macOS 26 the overlay, panels, and icon do not look like the rest of the system (Epic D).

### 2.5 Findings

Severity: **Critical** breaks the core promise for most users; **High** breaks a documented feature or another app's normal use; **Medium** loses data or blocks the factory process in a plausible case; **Low** hygiene, misleading text, or a rare case. Paths are under `Prompter/Prompter/` unless they start with `Prompter/`, `.github/`, or a repo-root file. "Verify" marks a finding that needs a device run before its severity is final.

| # | Severity | Finding | Evidence |
|---|---|---|---|
| F-01 | High | Every hotkey is consumed system-wide whenever the app runs, whether or not the overlay is visible: the tap returns `nil` for any ⌘⇧ + mapped key. The mapped combos are standard in other apps (text selection with ⌘⇧ arrows, tab switching with ⌘⇧[ ], reopen tab ⌘⇧T, command palette ⌘⇧P, element picker ⌘⇧C), so a presenter loses them in the very app they are demoing. | `Services/HotkeyManager.swift:41-52`, `:337-338` |
| F-02 | High | The scroll hotkeys change `AppState.overlayScrollOffset`, which no view reads; the overlay's `ScrollView` has no binding to it. ⌘⇧↑/↓ are a no-op (and, per F-01, still swallowed). | `App/AppState.swift:563-571`; `Windows/OverlayWindowController.swift:190-195`; no other reference to `overlayScrollOffset` outside `AppState` |
| F-03 | High | The overlay frame is restored from absolute saved coordinates with no check against the connected screens; nothing in the app references `NSScreen`. A frame saved on a display that is no longer attached opens off-screen. There is also no way to send the overlay to a chosen display. | `Windows/OverlayWindowController.swift:43`; `Models/Settings.swift:136-183` |
| F-04 | High (verify; Critical if confirmed) | Protected Mode relies only on `NSWindow.sharingType = .none`. Capture tools built on ScreenCaptureKit on recent macOS releases are reported not to honor it, which would make the overlay visible to the audience while the footer says it is protected. The app has no way to tell the user whether exclusion works on their machine; "Test Protected Mode" is instructions only. | `Windows/OverlayWindow.swift:59`, `:79-85`; `Views/TestCapture/TestCaptureView.swift`; `README.md:76` |
| F-05 | Medium | Hotkey registration retries 12 × 5 s after launch and then stops. Granting Accessibility after that leaves hotkeys dead until relaunch; revoking it later is never detected. The menu never says hotkeys are off. | `App/AppDelegate.swift:98-117`; `Services/HotkeyManager.swift:124-139` |
| F-06 | Medium | One deck debouncer serves all decks. Editing deck A, then creating, cloning, or editing deck B within 1 second cancels A's pending write; on quit only the current deck is flushed, so A's last edit never reaches disk. | `App/AppState.swift:119`, `:838-857`, `:254-259` |
| F-07 | Medium | Deck writes run as independent `Task.detached` jobs, so two writes of one deck can land out of order; the serial `ioQueue` meant for this is declared and unused. A deck file that fails to decode is skipped silently (the deck disappears from the list with no message and the file is left as is). | `Services/PersistenceService.swift:63`, `:207-242` |
| F-08 | Medium | Card delete has no confirmation and the app has no undo at all (no `UndoManager` use anywhere); deck delete has a confirmation. | `Views/DeckEditor/CardListSidebar.swift:354-357`; deck alert at `:115` |
| F-09 | Medium | Imported images are never deleted: replacing an image, deleting a card, or deleting a deck leaves its file in `Assets/`. The cleanup functions exist and have no callers. Clone shares asset references with the source deck, so any future cleanup must count references across decks. | `Services/AssetManager.swift:202-233`; `App/AppState.swift:265-289` |
| F-10 | Medium | CI cannot build the project from a clean clone as it stands: no shared scheme is committed and `Package.resolved` is ignored, so the Sparkle version is whatever resolves that day. | `Prompter/Prompter.xcodeproj/` contents; `.gitignore:12` |
| F-11 | Medium | 11 MB of build output (`Prompter.app`, `Prompter.dmg`, `Prompter.zip`, 74 files) is tracked in git under `Prompter/dist/` although `.gitignore:13` ignores `dist/`. The tracked binaries are stale the moment the next release is cut and can be mistaken for the release. | `git ls-files Prompter/dist`; commit `1a19861` |
| F-12 | Medium | The release path is manual and pushes straight to `main`: `publish-release.sh` commits `appcast.xml` and pushes to `main`, and deletes an existing GitHub Release of the same tag before recreating it. This conflicts with the factory rule that nothing commits to `main` outside `docs/`, and a re-run silently replaces a published release. | `Prompter/scripts/publish-release.sh:180-187`, `:198-200`; `Prompter/scripts/notarize.sh:13` |
| F-13 | Low | The cask uses the deprecated `depends_on macos: ">= :sonoma"` string form and lacks `auto_updates true`, although the app updates itself through Sparkle (so `brew outdated` and Sparkle disagree after a self-update). | `homebrew-tap/Casks/prompter.rb`; genkei-ops backlog 16b |
| F-14 | Low | Dead and deprecated code: unused `TestCaptureWindowController`, two placeholder views, unused persistence helpers, `NSApp.activate(ignoringOtherApps:)` (deprecated in macOS 14) in 7 places, a stale comment telling the reader to enable automatic checks that are already enabled. | `Windows/TestCaptureWindowController.swift`; `App/MenuBarController.swift:540-600`; `Services/PersistenceService.swift:294-333`; `Services/UpdateManager.swift:95-96` |
| F-15 | Low (verify) | The app declares a SwiftUI `WindowGroup` with an `EmptyView` as its only scene; SwiftUI opens a `WindowGroup` window at launch, so an accessory app may create a stray zero-size window. | `App/PrompterApp.swift:11-21` |
| F-16 | Low | The overlay's traffic-light controls are bare `Circle`s with `onTapGesture`: no button role, no label, not reachable by keyboard or VoiceOver, contradicting the v1.2.0 "full accessibility" claim. Two of the three are permanently disabled decoration. | `Windows/OverlayWindowController.swift:257-306` |
| F-17 | Low | The appcast's release notes are empty headings ("What's New in 1.2.0" with no content), so the Sparkle dialog shows users nothing about the update; the CHANGELOG date for 1.2.0 does not match the release. | `appcast.xml:9-11`, `:25-27`, `:41-43`; `CHANGELOG.md:9` |
| F-18 | Low | `CLAUDE.md` and `AGENTS.md` say the backlog is "maintained separately, not in repo"; it now lives at `docs/backlog.md`. `CLAUDE.md` also says the deck debounce is 0.5 s; it is 1.0 s. | `CLAUDE.md:15`, `AGENTS.md:13`; `App/AppState.swift:119` |
| F-19 | Low (verify) | The overlay sits at `.floating` window level. Whether it stays above Keynote's or PowerPoint's full-screen slideshow and above a Meet/Teams "share this window" picker has never been checked. | `Windows/OverlayWindow.swift:42` |
| F-20 | High | The owner's personal Apple ID email is hardcoded in a script of this **public** repository, and the Developer ID signing identity string is hardcoded in two more; any release path built on these scripts (local or CI) keeps publishing them. (Architect finding A-05.) The email is not a credential, so nothing needs rotating, but it is personal data the repo should not carry. | `Prompter/scripts/notarize.sh:6`; `Prompter/scripts/build-release.sh:4`; `Prompter/scripts/create-dmg.sh:4` |
| F-21 | High | The unit tests boot the full app (test host = `Prompter.app`): status item, Accessibility prompt, event tap, a Sparkle check against the live appcast, and the real deck store. `PersistenceServiceTests` uses the real `~/Library/Application Support/Prompter/` through the singleton, and `testSaveAndLoadSettings` overwrites the real `Settings.json` with a random `lastOpenedDeckId`. Running the suite on a developer Mac clobbers the user's settings; on Lucius' Mini it would clobber the QA baseline. (Architect findings A-01, A-02.) | `PrompterTests/PersistenceServiceTests.swift:17,44-60`; `App/AppDelegate.swift:40-77`; `Services/PersistenceService.swift:70-83` |
| F-22 | Medium | SwiftLint already reports one **error** with the repo's own config, so a lint gate fails on its first run: `type_body_length` 602 lines against the 600-line error threshold. 35 warnings besides. (Architect finding A-03.) | `App/AppState.swift:19`; `Prompter/.swiftlint.yml` |

Count: High 6 (one may become Critical), Medium 9, Low 7. Defects F-01 to F-09, F-14 to F-16 become Epic A stories; F-10 to F-13, F-17, F-20 (US-27), F-21 (US-25), and F-22 (US-2 task) are solved in Epic B; F-18 is fixed in passing by PRMT-020; F-19 is a Lucius check in Epic C. The architect's further findings (A-04 version in two places, A-06 cache eviction, A-07 timer re-render, A-08 Swift 6 readiness, A-09 Codable fragility, A-13 deprecated activate) are folded as tasks below or left in the design's section 2.3 as later items.

## 3. Goal and non-goals

**Goals**
1. Every pull request to `main` gets a build, the unit tests, SwiftLint, and prowl-qa (code review comes from the factory's pre-PR Codex review and the repo's bot reviewer; the Claude code-review workflow is dropped per the 2026-10-12 decision, see US-3), and a tagged release is built, signed, notarized, published, and reflected in the appcast and the cask without the owner's laptop (Epic B).
2. The defects in section 2.5 are fixed, each with a regression test or a Lucius check (Epic A).
3. Lucius proves every day that the released Prompter installs, launches, shows its overlay, answers its hotkeys, keeps its settings, and finds its updates, as he does for ContainerBar (Epic C).
4. On macOS 26 Prompter looks like a macOS 26 app, verified by screenshot, without breaking the overlay's one job: being readable to the presenter and absent from the shared screen (Epic D).

**Non-goals**
- New presenter features from the existing backlog (PRMT-002 export/import, PRMT-003 hotkey customization, PRMT-004 templates, PRMT-005 position presets). They stay ranked where they are; F-01's fix must not depend on PRMT-003.
- A Mac App Store build or sandboxing.
- Raising the 10-deck limit (listed as a gap; not a defect).
- Teleprompter auto-scroll, cloud sync, or accounts.

## 4. Users and roles

| Role | Who | What they need from this work |
|---|---|---|
| Presenter | Sales rep or solution architect sharing a screen in Meet or Teams, often with a second display | Hotkeys that work and do not break their demo app; an overlay that is where they expect and hidden from the share |
| Owner | Michael | Merges, approves releases, holds Developer ID and Sparkle keys, answers section 9 |
| Builder | `builder` agent | One story per branch, acceptance written as tests |
| Lucius | OpenClaw on the Agent Mac Mini | A recipe he can follow without improvising, fixture data that contains nothing real |
| Orchestrator | genkei-ops session | Inbox lines, release briefs, known-failure bookkeeping |

## 5. User stories and acceptance criteria

Conventions. "The QA deck" is the fictional fixture deck defined in US-audit-and-modernization-15 and the design's section 5.2 (all text invented, any address on `example.com`). "Text field" means a TextEdit window with the line `alpha beta gamma` and the caret after `beta`. Timings are wall-clock from the triggering action. Where a criterion depends on the deployment-target decision (Q1), it is written to hold for both options: **26-only** (deployment target 26.0) and **14+ with a 26 path** (deployment target 14.0, macOS 26 look behind availability checks).

### Epic B: CI/CD and QA parity with ContainerBar (build first)

Build order inside this epic (architect review 2026-10-14): US-1 (PRMT-007, done on its branch) → **US-25** (first after PRMT-007: until it lands the test target boots the app and overwrites the real `Settings.json`, F-21) → US-2, US-3, US-27 in parallel → US-26 and US-4 → US-5, US-6. Stories are numbered in the order they were written, not the order they are built.

#### US-audit-and-modernization-1: The project builds the same way on any clean machine
As a builder, I want a clean clone to build and test with one command so that CI and Lucius build exactly what I built.
- **AC1.** Given a fresh clone of `main` on a clean GitHub-hosted macOS runner with Xcode 26 (US-2's job; tests never run on the owner's MacBook or dev Mini), when `xcodebuild build-for-testing` and `test-without-building` run for scheme `Prompter`, then both exit 0 and all unit tests pass (134 or more). Verified by US-2's first run after US-25 lands, because before US-25 the suite writes the real Application Support folder (F-21).
- **AC2.** Given the repo, when `git ls-files` runs, then it lists a shared scheme `Prompter.xcodeproj/xcshareddata/xcschemes/Prompter.xcscheme` whose Test action includes `PrompterTests`, and a committed `Package.resolved` that pins Sparkle to one exact version.
- **AC3.** Given the repo, when `git ls-files Prompter/dist` runs, then it prints nothing, and `.gitignore` still ignores `dist/`.
- **AC4 (unhappy).** Given `Package.resolved` names a Sparkle version that cannot be fetched, when the build runs, then it fails at package resolution with an error naming Sparkle, not later with a missing-module error.
- **Done on PRMT-007's branch:** AC2 (shared scheme; Sparkle pinned exactly to 2.8.1 with `Package.resolved` tracked) and AC3 (`Prompter/dist/` removed). See 2.2a. AC1 and AC4 are proven by US-2's job.

#### US-audit-and-modernization-25: Build flavors with isolated storage, so tests and QA builds never touch a user's data (F-21)
As the owner, I want the unit tests, PR hunts, QA builds, and the released app each to keep their own data so that running any of them can never overwrite a presenter's decks or settings, or the QA baseline on Lucius' Mini. First story after PRMT-007; it blocks US-1's test run, US-2's Build & Test job, US-4, US-26, and the QA gate. Design: section 3.2.
- **AC1.** Given the four flavors `production`, `qa`, `hunt`, `unitTest`, when each is launched, then it uses exactly the bundle id and data root in the design's section 3.2 table (`com.tookes.Prompter` → `Application Support/Prompter/`; `com.tookes.Prompter.qa` → `Prompter-QA/`; `com.tookes.Prompter.hunt` → `Prompter-Hunt/`, wiped and re-seeded from the bundled fixtures on every launch; `unitTest` → none), and a unit test covers the resolution table.
- **AC2.** Given the test suite runs, when `~/Library/Application Support/Prompter/` and the `com.tookes.Prompter` defaults domain are hashed before and after, then both are unchanged; every persistence test uses `PersistenceService(rootURL:)` on a temporary directory it deletes in `tearDown`.
- **AC3.** Given the test host launches under XCTest, when `applicationDidFinishLaunching` runs, then no status item, Accessibility prompt, event tap, Sparkle updater, or storage access happens (the app returns right after setting the accessory policy).
- **AC4.** Given the `hunt` or `qa` flavor, when it runs, then Sparkle is never started and the status item's accessibility label names the flavor ("Prompter QA", "Prompter Hunt").
- **AC5 (unhappy).** Given a production (Release) build, when it is launched with `PROMPTER_HUNT_MODE=1` in its environment, then it still uses `Application Support/Prompter/` (the override is compiled into Debug builds only).
- **Technical tasks:** `App/AppEnvironment.swift`, `Services/StoragePaths.swift`; `PersistenceService` and `AssetManager` take `StoragePaths` in their initializers; `Info.plist` key `PrompterFlavor = $(PROMPTER_FLAVOR)` with project default `production`; the legacy `PresenterOverlay` migration runs only in `production`; the hunt build script copies `docs/qa/fixtures/` into `Contents/Resources/HuntSeed/` (fixtures come from US-15; until they exist the hunt seed is an empty deck folder).

#### US-audit-and-modernization-2: Every pull request is built, tested, and linted
As the owner, I want each PR to show build, test, and lint results so that I never merge a change nobody compiled.
- **AC1.** Given a PR to `main`, when it is opened or updated, then a `Swift CI` workflow runs two jobs, "Build & Test" and "SwiftLint", on a GitHub-hosted macOS runner with Xcode 26 selected the way ContainerBar's `swift-ci.yml` selects it, and both appear as checks on the PR.
- **AC2.** Given a PR that adds a failing assertion to any test, when CI runs, then "Build & Test" fails and its log names the failing test.
- **AC3.** Given a PR that adds a line longer than 200 characters to a Swift file, when CI runs, then "SwiftLint" fails, using a pinned SwiftLint version and `Prompter/.swiftlint.yml`.
- **AC4.** Given two pushes to the same PR within a minute, when the second starts, then the first run is cancelled (concurrency group per ref).
- **AC5 (unhappy).** Given the runner has no Xcode 26, when the select step runs, then the job fails with an error that lists the installed Xcode versions.
- **AC6.** Given the workflow file, when it is read, then every third-party action is pinned to a full commit SHA and `permissions` is `contents: read`.
- **AC7.** Given `main` before this story, when SwiftLint runs with `Prompter/.swiftlint.yml`, then it reports 0 errors (the existing error is cleared by this story's task below); warnings remain annotations, not failures.
- **Technical task (F-22).** Clear the pre-existing SwiftLint error `App/AppState.swift:19` `type_body_length` (602 lines, error threshold 600) in the same branch that adds the job. The builder chooses: **trim** (move the timer block `AppState.swift:579-721` and the auto-save sinks `:723-803` into `AppState+Timer.swift` and `AppState+AutoSave.swift` extensions; the rule counts each type declaration body separately) or **raise the threshold** in `.swiftlint.yml` with a comment naming this story. Note for the builder: Epic A adds code to `AppState` (US-7, US-9, US-11, US-12, US-13), so a raised threshold will be hit again within weeks; trimming is the durable choice.
- **Technical task.** The CI test build signs ad hoc with hardened runtime off for the test build only (`CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO`); library validation would otherwise refuse to load the ad-hoc test bundle (design 4.2). Depends on US-25 for a side-effect-free test run.

#### US-audit-and-modernization-3: Claude workflows and PR hygiene follow the factory's review model
As the owner, I want Prompter's PR automation to match the factory's current review model so that reviews come from the same places in every repo.

**Ruling (orchestrator, 2026-10-14):** the architect's design stands. Per the 2026-10-12 decision the Claude code-review workflow is dropped (reviews come from the orchestrator's pre-PR Codex review and the repo's bot reviewer); `claude.yml` (on-demand `@claude`) stays; `claude-pr-description.yml` is added.
- **AC1.** Given the repo after this story, when `.github/workflows/` is listed, then `claude-code-review.yml` is absent, `claude.yml` is present with its actions pinned to commit SHAs, and `claude-pr-description.yml` is a verbatim copy of ContainerBar's portable file; given a same-repo PR opened with an empty body, the PR-description workflow writes a suggested description to the workflow summary and never edits the PR body.
- **AC2.** Given a new PR or issue, when the form opens, then it uses a PR template and bug/feature issue templates adapted to Prompter (fields: macOS version, Prompter version, meeting app, display setup).
- **AC3 (unhappy).** Given a PR from a fork, when it is opened, then no workflow that uses a repository secret runs.

#### US-audit-and-modernization-4: prowl-qa runs on every pull request
As the owner, I want prowl-qa on Prompter PRs so that a change is exercised on a real Mac before merge.
- **AC1.** Given a same-repo PR to `main`, when it is opened or updated, then a `Prowl QA` workflow runs on the self-hosted macOS runner, with the pinned Prowl version used by ContainerBar, builds the PR's app, and reports a check result.
- **AC2.** Given the hunt build, when it is inspected, then its bundle id is `com.tookes.Prompter.hunt` and its data root is `~/Library/Application Support/Prompter-Hunt/` (US-25), so it never reads or writes the installed app's decks.
- **AC3 (unhappy).** Given the self-hosted runner is offline, when a PR is opened, then the check stays pending (GitHub keeps a job queued on an offline self-hosted runner for up to 24 hours; `timeout-minutes: 30` bounds only a job that has started) or fails, and never reports success; the merge checklist treats a pending check as not green.
- **AC4.** Given the run finished, when the Mini is inspected, then the hunt app is no longer running (the last step quits it with `osascript -e 'quit app id "com.tookes.Prompter.hunt"'`, no signals) and no hunt build is left in `/Applications`.
- **Preconditions (not builder work).** `homelab-it` registers a repository-scoped self-hosted runner for `michaeltookes/prompter` on Lucius' Mini (labels `self-hosted, macOS, ARM64`) and adds `repos/michaeltookes/prompter/actions/runners` to the Mini's CI-busy predicate; the **owner grants Accessibility once** to that runner's host process (Q7). Until then the workflow's Accessibility preflight fails with its error message.
- **Depends on:** US-25 (hunt flavor). Hunts and forbidden selectors: design 4.3 and 3.3.

#### US-audit-and-modernization-26: A QA build of any branch for the pre-PR QA gate
As the orchestrator, I want a signed QA build of a story's branch that Lucius can install beside the release so that the factory's QA gate can run the story's TC cases before the PR (design 4.4).
- **AC1.** Given a `workflow_dispatch` of `qa-build.yml` with input `ref`, when it finishes, then an artifact `Prompter-QA-<shortsha>.zip` (retention 3 days) holds `Prompter QA.app` with bundle id `com.tookes.Prompter.qa`, flavor `qa` (US-25), signed with the Developer ID certificate with hardened runtime, not notarized.
- **AC2.** Given two QA builds of different commits, when `codesign -d -r-` is compared, then the designated requirement is identical (so the one-time Accessibility grant for `com.tookes.Prompter.qa` survives every new build).
- **AC3.** Given the QA app is installed in `~/Applications/` on the Mini and launched, when the released `/Applications/Prompter.app` data is hashed before and after, then it is unchanged; the QA app uses `Application Support/Prompter-QA/` and never starts Sparkle.
- **AC4 (unhappy).** Given the certificate secret is missing or wrong, when the workflow runs, then it fails at the keychain import step with a message naming the secret, and no artifact is uploaded; the temporary keychain is deleted in every case.
- **Secrets (GitHub environment `qa-build`, created by `vendor-ops`):** `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID` (same values as Sentwise's release secrets; owner approval Q6).
- **Precondition:** the **owner grants Accessibility once** to `~/Applications/Prompter QA.app` on the Mini (Q7).

#### US-audit-and-modernization-27: No personal data or hardcoded identity in the release scripts (F-20)
As the owner, I want the release scripts in this public repo to read identity and credentials from the environment so that my personal Apple ID stops being published and CI and local releases run the same script.
- **AC1.** Given the repo after this story, when `git grep` searches the working tree for the owner's Apple ID email, the team-qualified Developer ID identity string, and the keychain profile name `Prompter-Notarize`, then nothing in `Prompter/scripts/` matches.
- **AC2.** Given the scripts, when they run, then they read `APPLE_ID`, `APPLE_TEAM_ID`, `SIGNING_IDENTITY`, and either `NOTARY_PROFILE` (a notarytool keychain profile; it wins when both are set) or `NOTARY_APP_SPECIFIC_PASSWORD` (which needs `APPLE_ID` and `APPLE_TEAM_ID`) from the environment; an optional gitignored `Prompter/scripts/.env.local` (with a committed `.env.example` of placeholders) is loaded by `release-env.sh`, and values already set in the shell win over it. The team id that remains in `project.pbxproj` is not a credential; removing it is backlog PRMT-035.
- **AC3 (unhappy).** Given a required variable is unset, when a script starts, then it exits non-zero naming the missing variable before running any build or notarization step.
- **Note.** The email stays in git history. It is not a credential, so nothing is rotated; rewriting public history is not part of this story (it would break every clone) and is the owner's call if ever wanted.
- **Folds into US-5's `release.sh`** (one script for CI and local); can run in parallel with US-2 and US-3 because it touches only `Prompter/scripts/`.

#### US-audit-and-modernization-5: A tag produces a signed, notarized, published release
As the owner, I want pushing a version tag to produce the complete release so that releases no longer depend on my laptop or on pushes to `main`.
- **AC1.** Given `Info.plist`, `project.pbxproj`, and `CHANGELOG.md` agree on version V and a tag `vV` is pushed, when the release workflow finishes, then the GitHub Release `vV` exists with `Prompter.zip`, `Prompter.dmg`, and `Prompter.dmg.sha256`, its notes are the CHANGELOG section for V, and the CHANGELOG date for V equals the tag's commit date in America/Chicago.
- **AC2.** Given the downloaded `Prompter.zip`, when `codesign --verify --deep --strict`, `spctl --assess --type execute`, and `xcrun stapler validate` run against the extracted app, then all three exit 0 and `codesign -dv` names the owner's Developer ID authority; the same holds for the app inside the DMG.
- **AC3.** Given the release succeeded, when `https://michaeltookes.github.io/prompter/appcast.xml` is fetched, then its newest item is V with a valid `sparkle:edSignature`, the zip's exact byte length, `minimumSystemVersion` equal to the deployment target, and non-empty release notes drawn from the CHANGELOG.
- **AC4.** Given the workflow, when its steps are read, then the appcast change is pushed to the `gh-pages` branch, which is the GitHub Pages source (same public URL), never to `main`; signing identities, the notarization credentials, and the Sparkle private key come from GitHub secrets and appear in no log.
- **AC5 (unhappy, mismatch).** Given the tag says V but `Info.plist` says another version, when the workflow starts, then it fails before building with a message naming both versions, and nothing is published.
- **AC6 (unhappy, rerun).** Given a release `vV` already exists, when the workflow runs again for `vV`, then it fails without deleting or replacing the existing release; a `workflow_dispatch` with `resume=publish-tail` for that tag only finishes the appcast and cask steps (each skipped if already done) and never modifies the release.
- **AC7 (unhappy, notarization).** Given notarization is rejected, when the step finishes, then the job fails with the notary log summary, and no GitHub Release, appcast change, or cask change is made.
- **AC8 (dry run).** Given a `workflow_dispatch` with `dry_run=true` and no secrets, when it runs, then version checks, the gate, an unsigned archive, the DMG layout, and the rendered appcast item (job summary) complete, and nothing is published.
- **Technical tasks:** one `Prompter/scripts/release.sh` used by CI and locally (absorbs the four scripts; US-27 makes it read the environment); `Prompter/scripts/validate-release.py` (`pre`, `appcast-item`, `appcast-check`) with stdlib tests in `Prompter/scripts/tests/` run by US-2's job; **version single source** (architect A-04): `Info.plist` `CFBundleShortVersionString = $(MARKETING_VERSION)` and `CFBundleVersion = $(CURRENT_PROJECT_VERSION)`; Sparkle `sign_update` comes from the Sparkle 2.8.1 release tarball, matching the pin (2.2a); `sparkle:minimumSystemVersion` is read from `MACOSX_DEPLOYMENT_TARGET`.
- **Secrets (GitHub environment `release`, deployment policy "tags matching `v*`", created by `vendor-ops`):** `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_ID`, `APPLE_TEAM_ID`, `NOTARY_APP_SPECIFIC_PASSWORD`, `SPARKLE_ED_PRIVATE_KEY`, `TAP_PUSH_TOKEN`. Names match Sentwise's `release.yml`; the certificate, Apple ID, team, and notary password values are re-used, while `SPARKLE_ED_PRIVATE_KEY` is Prompter's own key (Q6).
- **Preconditions (not builder work):** the **owner exports Prompter's Sparkle EdDSA private key** (`generate_keys -x`) into `SPARKLE_ED_PRIVATE_KEY` (Q6); `vendor-ops` moves the Pages source from `main /` to a new `gh-pages /` branch seeded byte-for-byte with today's `appcast.xml`, verifies the public URL serves the same bytes, and only then is `appcast.xml` deleted from `main` (design 4.5).

#### US-audit-and-modernization-6: The Homebrew cask is current and updated with each release
As a presenter who installs with Homebrew, I want the cask to install the latest signed build and not fight Sparkle.
- **AC1.** Given the tap's `Casks/prompter.rb` after this story, when `brew audit --cask --strict michaeltookes/tap/prompter` runs (last step of `release.yml`; it is a lint, not an app test), then it reports no deprecation for `depends_on`, and the cask declares `auto_updates true` and a `depends_on macos:` symbol form matching the deployment target.
- **AC2.** Given release V was published by US-5, when the tap is checked, then a tap change to `version` V with the DMG's `sha256` exists (as a tap PR or commit, as the architect decides for the tap repo), and `brew install --cask michaeltookes/tap/prompter` on a clean Mac installs V.
- **AC3 (unhappy).** Given the DMG checksum in the cask does not match the asset, when `brew install` runs, then it refuses with a checksum error (the release workflow computes the checksum from the uploaded asset, not from a local file).
- **Note.** The live tap's `depends_on` line and `auto_updates true` can be fixed now in a tap PR without a version change (genkei-ops backlog 16b); the cask template `Prompter/distribution/prompter.rb` (design 4.6) is synced whole by US-5's tap step. The tap push uses `TAP_PUSH_TOKEN` (US-5 environment `release`).

### Epic A: Audit fixes

#### US-audit-and-modernization-7: Prompter's hotkeys stop breaking other apps (F-01)
As a presenter, I want Prompter to take only the shortcuts it is using right now so that my demo app's own shortcuts keep working.
- **AC1.** Given Prompter is running with the overlay hidden, when the presenter presses ⌘⇧← in the text field, then the text from the caret to the line start is selected; the same holds for ⌘⇧→, ⌘⇧↑, ⌘⇧↓.
- **AC2.** Given the overlay is hidden and Safari has two tabs, when the presenter presses ⌘⇧], then Safari switches tab; ⌘⇧T, ⌘⇧P, ⌘⇧C, ⌘⇧[, ⌘⇧=, ⌘⇧- likewise reach the front app.
- **AC3.** Given the overlay is hidden, when the presenter presses the show-overlay hotkey, then the overlay appears; this one hotkey is always active.
- **AC4.** Given the overlay is visible, when the presenter presses the next-card hotkey, then the overlay advances one card and the front app receives nothing.
- **AC5.** Given the default bindings after the owner's answer to Q5, when the README's shortcut table and the in-app hotkey list are compared with the bindings in code, then all three agree.
- **AC6 (unhappy).** Given the overlay is visible but the current deck has one card, when the presenter presses next-card, then nothing changes, the key is still consumed (no stray keystroke reaches the demo app), and no error appears.

#### US-audit-and-modernization-8: Scroll hotkeys scroll the card (F-02)
As a presenter, I want ⌘⇧↓ and ⌘⇧↑ (or the bindings Q5 settles on) to scroll a long card so that I can read notes that overflow the overlay.
- **AC1.** Given the QA deck's card 3 (40 bullets, taller than the overlay) is shown, when the presenter presses scroll-down once, then the content moves up by one step (a fixed step the architect sets, at least 3 lines at font scale 1.0) and a screenshot differs from the one before.
- **AC2.** Given the card is scrolled to the bottom, when scroll-down is pressed again, then the content does not move past the last line.
- **AC3.** Given the card is scrolled, when next-card is pressed and then previous-card, then card 3 is shown from its top.
- **AC4 (unhappy).** Given a card shorter than the overlay, when scroll-down is pressed, then the content does not move.

#### US-audit-and-modernization-9: The overlay always opens on a screen I can see, and on the display I choose (F-03)
As a presenter with a second display, I want the overlay to come back on a visible screen after the display setup changes, and to be able to send it to a specific display.
- **AC1.** Given `Settings.json` holds an overlay frame whose rectangle intersects no connected screen (for example x = 10000, y = 10000), when Prompter launches and the overlay is shown, then the overlay is fully inside the visible frame of the main screen, at its saved size or smaller if it does not fit.
- **AC2.** Given the overlay is on display 2 and display 2 is disconnected while Prompter runs, when the screen change is processed, then within 2 seconds the overlay is fully inside a remaining screen.
- **AC3.** Given two displays are connected, when the presenter opens the status menu, then a "Move Overlay to" submenu lists each display by its system name, and choosing one moves the overlay fully onto that display; the choice survives relaunch while that display is attached.
- **AC4.** Given one display, when the presenter opens the status menu, then "Move Overlay to" is absent or disabled.
- **AC5 (unhappy).** Given an overlay frame partly off the right edge (one third visible), when Prompter launches, then the overlay is moved so that it is fully visible, not left partly hidden.

#### US-audit-and-modernization-10a: Measure whether Protected Mode hides the overlay on macOS 26 (F-04)
As the owner, I want to know, before any copy changes, which capture methods on macOS 26 still see the overlay. No app code: Lucius runs TC-PR-10 and the result is documented. Split from US-10 by the architect review because measurement and the in-app self-test are different branches of work.
- **AC1.** Given the overlay is visible with Protected Mode on, when Lucius captures the main display with `screencapture` and with Peekaboo's ScreenCaptureKit-based screen capture on macOS 26, then the report states, for each method, whether the overlay's text is present in the image. This result decides the remaining criteria and is recorded in `docs/qa/` and in `.claude/reference-docs/CAPTURE_PROTECTION.md`.
- **AC2.** Given the result, when it is recorded, then it names the macOS build, each method (`screencapture -x -D 1`, Peekaboo's ScreenCaptureKit capture, and in the weekly leg a Chrome `getDisplayMedia` preview of the whole screen from `docs/qa/fixtures/share-preview.html`), and for each "hidden" or "visible", with cropped evidence images.
- **Precondition:** for the weekly Chrome leg the **owner grants Screen Recording to Chrome once** on the Mini (Q7); without it that leg is SKIPPED.

#### US-audit-and-modernization-10b: Protected Mode tells the truth in the app (F-04)
As a presenter, I want the app to tell me whether the audience can see my notes so that I never rely on a protection that does not work on my macOS version. Starts after US-10a's result is recorded. Design 6.4.
- **AC2.** Given the recorded result says a capture method shows the overlay, when the presenter opens "Test Protected Mode…", then the window says in plain words which capture methods on this macOS version can still see the overlay, and the footer's protected indicator no longer claims protection without qualification.
- **AC3.** Given "Test Protected Mode…" is open **and the Screen Recording permission is already granted**, when the presenter clicks "Run Test", then within 5 seconds the window shows "Hidden from capture" or "Visible to capture" with the captured thumbnail (the app captures only its own overlay's rectangle with ScreenCaptureKit, once with the overlay shown and once hidden, compares them, and writes nothing to disk). Without the permission, the window first explains why it is needed, then requests it; on macOS 15 and later granting requires quitting and reopening Prompter, and the window says so.
- **AC4 (unhappy).** Given the presenter declines the Screen Recording permission, when "Run Test" finishes, then the window says the test could not run because permission was declined and how to grant it, and nothing else changes.
- **AC5.** Given Protected Mode is off, when the overlay is visible, then the footer shows the existing "Visible to capture" warning (unchanged behavior, regression check).
- **Copy constraint (binding):** before the system prompt the window says Prompter captures only its own overlay area to check whether it is hidden, keeps nothing, and sends nothing. Any change to the footer's "Protected" wording, the Test window's verdict text, or the README's Protected Mode claim is customer-facing and waits for the owner's approval before release.

#### US-audit-and-modernization-11: Hotkeys come alive when permission is granted, and the menu says when they are off (F-05)
As a presenter, I want hotkeys to start working as soon as I grant Accessibility so that I do not have to know to relaunch.
- **AC1.** Given Prompter has run for 5 minutes without the Accessibility permission, when the permission is granted in System Settings, then within 5 seconds the show-overlay hotkey works without relaunch.
- **AC2.** Given the permission is not granted, when the presenter opens the status menu, then its first item reads "Hotkeys off: grant Accessibility…" (wording may change in review) and choosing it opens the Accessibility pane of System Settings.
- **AC3 (unhappy).** Given the permission is revoked while Prompter runs, when the presenter next opens the status menu, then the item from AC2 is shown again and no hotkey is consumed.
- **AC4.** Given the permission is granted, when the menu opens, then the item from AC2 is absent.

#### US-audit-and-modernization-12: Edits are never lost and a broken deck is never hidden (F-06, F-07)
As a presenter, I want every edit to reach disk, in order, and to be told if a deck cannot be read.
- **AC1.** Given the presenter edits a card title in deck A and within 1 second creates a new deck B, when Prompter is quit from its menu and relaunched, then deck A shows the edited title.
- **AC2.** Given 20 edits to one deck in 2 seconds, when the app is quit and relaunched, then the deck shows the last edit (a unit test drives the same sequence through the persistence layer and asserts the final file content).
- **AC3 (unhappy).** Given a deck file in `Decks/` that is not valid JSON, when Prompter launches, then the file is moved to `Decks/Unreadable/` with its name unchanged, the Deck Editor shows a one-line notice "1 deck could not be opened and was set aside", and the other decks load.
- **AC4 (unhappy).** Given a write fails (the Decks folder is made read-only), when an edit is saved, then the editor shows a non-blocking "Could not save" notice naming the deck, and the in-memory edit is kept.

#### US-audit-and-modernization-13: Images no longer pile up, and deletes can be undone (F-08, F-09)
As a presenter, I want removed images to free their space and an accidental delete to be reversible.
- **AC1.** Given a card with an image that no other card in any deck (and no undo step) references, when the card is deleted, the image replaced, or the deck deleted, then within one save cycle the image's file is moved out of `Assets/` into `Assets/.Trash/`, and `Assets/.Trash/` is emptied at the next launch (this keeps AC3's undo able to restore the image during the session).
- **AC2.** Given a deck cloned from another, when the clone's card using image X is deleted, then X's file remains (the source deck still references it).
- **AC3.** Given the presenter deletes a card in the editor, when they press ⌘Z, then the card returns at its position with its content and images, and ⌘⇧Z deletes it again.
- **AC4 (unhappy).** Given an asset file referenced by a card is missing from `Assets/`, when the card is shown, then the image slot shows the empty-slot placeholder with "Image missing" and the app does not crash or delete the reference.

#### US-audit-and-modernization-14: Dead code is gone and the overlay controls are accessible (F-14, F-15, F-16, F-18)
As a builder, I want the code to contain only what runs so that the makeover touches the real surfaces.
- **AC1.** Given the repo, when it is searched, then `TestCaptureWindowController`, `DeckEditorPlaceholderView`, `TestCapturePlaceholderView`, the unused persistence helpers, and every `activate(ignoringOtherApps:)` call are gone, and the build has no deprecation warnings from Prompter's own sources.
- **AC2.** Given Prompter has just launched and nothing has been opened, when its windows are listed through the accessibility tree, then it owns no window other than the hidden overlay (no stray SwiftUI scene window).
- **AC3.** Given VoiceOver is on and the overlay is visible, when the presenter moves through the overlay, then the close control is announced as "Hide overlay, button" and activates with VoiceOver's press; decorative disabled circles are not announced.
- **AC4.** Given `CLAUDE.md` and `AGENTS.md`, when they are read, then they point to `docs/backlog.md` and state the actual deck debounce.

### Epic C: Lucius daily QA lane

The architect designs the lane (schedule, runner, lock, evidence paths, recipe file) in `docs/architecture/audit-and-modernization.md`; it follows ContainerBar's lane (`ContainerBar` `docs/requirements/lucius-daily-qa.md` on `req/containerbar-factory-intake`) wherever the app allows. These stories say what a daily pass must prove for a speaker-notes app.

#### US-audit-and-modernization-15: The app exposes stable handles for automation, and a fictional fixture deck exists
As Lucius, I want stable accessibility identifiers and a known deck so that the pass clicks the same elements every day and never shows real content.
- **AC1.** Given the released app, when the accessibility tree is read with Peekaboo, then the status item is found by the identifier `prompterStatusItem` and by the title or description "Prompter", and these identifiers exist: `menuToggleOverlay`, `menuOpenEditor`, `menuProtectedMode`, `menuClickThrough`, `menuCheckForUpdates`, `menuQuit`, `overlayWindow`, `overlayCardTitle`, `overlayCardCounter`, `overlayProtectedIndicator`, `overlayClose`, `editorDeckList`, `editorCardList` (the architect may rename; the recipe uses whatever ships).
- **AC2.** Given `docs/qa/seed-data.md`, when it is read, then it defines the QA deck: title "QA Demo Deck", 5 cards covering at least 3 layouts, card 1 titled "QA Card 1 - Opening", card 3 with 40 bullets for the scroll check, one image card using a generated test pattern, and no real company, person, or customer text (Q2).
- **AC3.** Given the fixture files, when Lucius installs them, then the procedure copies them into the installed app's `Decks/` and `Assets/` only while Prompter is quit, and a restore step puts the baseline `Settings.json` back.
- **AC4 (unhappy).** Given a release in which an identifier from AC1 is missing, when the pass reaches the step that needs it, then the step is `blocked` with the element list attached and the report names the recipe as stale; it does not improvise another click path.

#### US-audit-and-modernization-16: Install path and launch are proven every day
As the owner, I want to know each morning that the build people download is the one installed and that it starts.
- **AC1.** Given the latest GitHub release is V, when the pass reads `CFBundleShortVersionString` of `/Applications/Prompter.app`, then it prints V; otherwise the case is FAIL `stale-install` and the remaining cases run against the installed build.
- **AC2.** Given the installed app, when `codesign --verify --deep --strict`, `spctl --assess --type execute`, and `xcrun stapler validate` run, then all exit 0.
- **AC3.** Given Prompter is not running, when Lucius launches it with `open /Applications/Prompter.app`, then within 10 seconds `prompterStatusItem` is visible in the menu bar (screenshot `01-status-item.png`), `pgrep -x Prompter` prints one PID, and no Dock icon appears.
- **AC4 (release day).** Given release V+1 and the updated cask, when Lucius runs `brew upgrade --cask prompter`, then the installed version is V+1, AC2 and AC3 pass, and the QA deck and the baseline settings are unchanged.
- **AC5 (unhappy).** Given any of the three signature checks fails, when the check runs, then the run is FAIL with the tool output quoted, the Discord message starts `QA FAIL` and names the check, and Lucius does not launch that artifact.

#### US-audit-and-modernization-17: The overlay, its display placement, the hotkeys, and Protected Mode work every day
As the owner, I want the pass to prove the presenter's core loop: show notes, step through them, keep them off the shared screen.
- **AC1 (overlay).** Given the QA deck is current and the overlay hidden, when Lucius chooses Show Overlay from the status menu, then within 2 seconds `overlayWindow` is on screen showing "QA Card 1 - Opening" and the counter "1 / 5" (screenshot).
- **AC2 (hotkeys).** Given the overlay is visible and the Accessibility permission was granted to Prompter once by the owner (precondition in the recipe), when Lucius sends the next-card hotkey twice, then the counter reads "3 / 5"; previous-card once gives "2 / 5"; the toggle hotkey hides and shows the overlay; font-size up changes the rendered title size (two screenshots differ); scroll-down moves card 3's content (US-8 AC1).
- **AC3 (pass-through).** Given the overlay is hidden, when Lucius types `alpha beta gamma` in TextEdit, places the caret after `beta`, and sends ⌘⇧←, then `alpha beta` is selected (US-7 AC1 check; known failure until the release containing PRMT-013).
- **AC4 (display).** Given the Mini's display configuration (one display unless the owner attaches a second; assumption in section 9), when Lucius writes an off-screen overlay frame into `Settings.json` with Prompter quit and relaunches, then the overlay opens fully on a visible screen (US-9 AC1; known failure until PRMT-015 ships). If a second display is attached, "Move Overlay to" moves it there (screenshot of each display).
- **AC5 (Protected Mode).** Given the overlay is visible with Protected Mode on, when Lucius runs `screencapture -x` of the overlay's display and Peekaboo's ScreenCaptureKit screen capture (TC-PR-10), then the report records for each whether "QA Card 1 - Opening" is visible in the image; with Protected Mode off, both captures show it. A protected capture that shows the overlay is FAIL unless US-10a has recorded that method as unsupported on this macOS version, in which case it is a known limitation.
- **AC6 (click-through).** Given click-through is on, when Lucius clicks in the centre of the overlay over a TextEdit window, then TextEdit receives the click (caret moves) and the overlay does not become key.
- **AC7 (unhappy, permission missing).** Given Prompter lacks the Accessibility permission on the Mini (detected by `menuHotkeyStatus` once US-11 ships; before that, by the first hotkey leaving the overlay's accessibility value unchanged), when the hotkey case starts, then it is BLOCKED `tcc-accessibility` with a cropped screenshot of the status menu, Lucius does not open System Settings to grant it, and one line asks the owner to act.

#### US-audit-and-modernization-18: Settings persist and the update check works, every day
As the owner, I want proof that a presenter's settings survive a relaunch and that updates are found.
- **AC1.** Given baseline settings (opacity 85 %, font 100 %, Protected Mode on, click-through off), when Lucius sets opacity down twice and font up once by hotkey, turns click-through on from the menu, moves the overlay 200 points right, quits from "Quit Prompter", and relaunches, then the overlay shows at the moved position with the changed opacity and font, and the menu shows click-through checked.
- **AC2.** Given AC1 passed, when the baseline is restored through the UI and Prompter relaunched, then the baseline values are back; the report lists the restored values.
- **AC3.** Given the installed version equals the latest release, when Lucius chooses Check for Updates…, then Sparkle says Prompter is up to date.
- **AC4 (unhappy, newer exists).** Given the appcast advertises a newer version, when the check runs, then the report records `update-available <version>`, Lucius presses "Remind Me Later" (never "Install Update" or "Skip This Version"), and the case passes with a note.
- **AC5 (unhappy, appcast down).** Given `curl -sSfI https://michaeltookes.github.io/prompter/appcast.xml` fails, when the check runs, then the case is BLOCKED `appcast-unreachable` with the Sparkle dialog text quoted.

#### US-audit-and-modernization-19: The pass is scheduled, safe, reported, and leaves the Mini as it found it
As the orchestrator, I want the Prompter pass to share the desktop with the Sentwise and ContainerBar passes without collisions and to report in the same shape.
**Ruling (orchestrator, 2026-10-14):** the architect's design stands. Until a release containing PRMT-013 (US-7) is installed on the Mini, a running Prompter swallows ⌘⇧ shortcuts that the Sentwise and ContainerBar passes use on the same desktop, so the pass quits Prompter at the end and the hourly check asserts it is **not** running. After that release is installed, the pass leaves it running and the hourly check asserts it is.
- **AC1.** Given the daily schedule **08:15 America/Chicago** (after ContainerBar's 07:05 pass, before Sentwise's 09:35; design 5.4), when it fires, then one full pass runs; and an hourly zero-token launchd check (08:00–20:00, skipped while the desktop lock is held) verifies that the release tag, appcast top version, cask version, and installed version agree, that `spctl --assess` passes on the installed app, and that `pgrep -x Prompter` finds **no** process outside a pass (until the PRMT-013 release is installed) or exactly one (after it); it posts only on a change of state.
- **AC2.** Given CI is busy on the Mini (the factory's `Runner.Worker` and runners-API predicate) or another desktop brief holds the lock, when a pass is due, then it waits up to 10 minutes and then reports BLOCKED `ci-busy` or `desktop-busy`; it never runs concurrently with another desktop brief.
- **AC3.** Given a run ends for any reason, when the restore runs, then the baseline Application Support folder and defaults are back (manifest matches), no Sparkle, editor, or Test Protected Mode window is open, TextEdit is closed without saving, the desktop picture is restored, and Prompter is **quit** (until the PRMT-013 release is installed; after it: running with the overlay hidden).
- **Preconditions (one-time, owner):** grant Accessibility to `/Applications/Prompter.app` on the Mini (Q7); Lucius never grants a permission. Baseline seeding, recipe `PROMPTER_QA.md`, cron job, and launchd job are orchestrator work through a brief (design 5.1).
- **AC4.** Given a finished pass, when the orchestrator opens its `report.md`, then it has the Lucius brief template shape (header, per-case table, steps with asset paths, known failures keyed `{PRMT id, fixed-in version}`, defects and proposed backlog items, restore notes), and one Discord message starts `QA PASS` or `QA FAIL — Prompter <version>`.
- **AC5.** Given a run, when its command log is reviewed, then it contains no `kill`, `pkill`, or `killall`; Prompter is quit only through its Quit menu item or `osascript -e 'quit app "Prompter"'`.
- **AC6 (unhappy).** Given a system dialog the recipe does not cover (Keychain, TCC, Gatekeeper), when it appears, then Lucius does not grant or type anything, captures a cropped screenshot, marks the run BLOCKED, and asks the owner in one line.
- **AC7.** Given a report proposes a defect, when the BA processes it, then it becomes a new `PRMT-` item with repro steps and the evidence path, or is added as evidence to the item it duplicates.

### Epic D: Liquid Glass makeover for macOS 26

Scope is set by the architect. Every criterion below holds for both deployment-target options: under **26-only** the "earlier macOS" criteria are dropped; under **14+ with a 26 path** they apply to a macOS 14 or 15 machine running the same build. Screenshots are taken by Lucius on macOS 26 over the fixed QA backdrop (a high-contrast checkerboard wallpaper defined in `docs/qa/seed-data.md`) at 2× scale, overlay at its baseline frame, in Light and Dark appearance.

#### US-audit-and-modernization-20: Built on the macOS 26 SDK with the deployment-target decision applied
As a builder, I want the project on Xcode 26 and the macOS 26 SDK with the chosen deployment target so that the system's Liquid Glass components are available.
- **AC1.** Given the project, when CI builds it (US-2), then it builds with Xcode 26 and the macOS 26 SDK with zero warnings from Prompter's sources, and `MACOSX_DEPLOYMENT_TARGET`, the appcast's `minimumSystemVersion`, the cask's `depends_on macos:`, and the README all state the same minimum.
- **AC2 (14+ path).** Given the 14+ option, when the codebase is searched, then every Liquid Glass API call is inside an `if #available(macOS 26, *)` or `@available` scope, and the app launches on macOS 14, proven by the CI job **macOS 14 smoke** (design 4.2: the hunt-flavor build runs `--self-check` on a GitHub-hosted `macos-14` runner, renders each seed card and the editor with `ImageRenderer`, exits 0, and uploads the PNGs). If an interim release set `UIDesignRequiresCompatibility`, this story removes it.
- **AC3 (unhappy, 26-only).** Given the 26-only option, when a user on macOS 15 has Sparkle check for updates, then Sparkle does not offer the new version (because of `minimumSystemVersion`), and the cask refuses to install on macOS 15 with Homebrew's macOS-version message.

#### US-audit-and-modernization-21: The overlay surface is Liquid Glass on macOS 26 and stays readable
As a presenter on macOS 26, I want the overlay to use the system glass so that it matches the OS, without losing legibility.
- **AC1.** Given macOS 26 and the QA backdrop, when the overlay is screenshotted at opacity 100 %, then the checkerboard behind it is visibly blurred and tinted through the surface (no hard checker edges inside the overlay bounds), the surface has continuous rounded corners with no square corners or dark rectangular halo outside them, and no custom flat dark fill covers the glass.
- **AC2.** Given the same screenshot at the minimum opacity (30 %) and at 100 %, in Light and Dark appearance, when the title text colour is sampled against the surface directly behind it, then the contrast ratio is at least 4.5:1 for body text and 3:1 for the 26 pt title.
- **AC3.** Given Protected Mode on, when US-17 AC5 runs against the redesigned overlay, then the result is the same as before the redesign (the glass layer does not change capture behavior).
- **AC4 (earlier macOS, 14+ path).** Given macOS 14 or 15, when the overlay is screenshotted, then it shows the current frosted surface, pixel-comparable to a snapshot rendered from the last pre-Epic-D commit (same layout, corner radius, and colours; mean absolute pixel difference ≤ 2 % per image with the text frames masked; both images from the macOS 14 smoke job).
- **AC5 (unhappy, Reduce Transparency).** Given System Settings > Accessibility > Display > Reduce Transparency is on, when the overlay is screenshotted on macOS 26, then the surface is opaque or near-opaque (checkerboard not visible) and text still meets AC2.

#### US-audit-and-modernization-22: Overlay controls use system glass controls instead of fake chrome
As a presenter, I want the overlay's controls to look and behave like macOS 26 controls.
- **AC1.** Given macOS 26, when the overlay is screenshotted, then the top-left fake traffic lights (one red and two grey circles) are gone, replaced by the controls the architect specifies (at minimum a hide control), drawn as glass buttons grouped in one glass container.
- **AC2.** Given the footer, when it is screenshotted, then the card counter, timer, Protected Mode indicator, and click-through indicator appear as glass capsule controls (the footer has no opacity control today) consistent with the system, and the Protected Mode off warning is still visible in orange or red.
- **AC3.** Given VoiceOver, when the presenter moves through the overlay, then each control from AC1 and AC2 is announced with a label and role (US-14 AC3 still holds).
- **AC4 (unhappy, click-through).** Given click-through is on, when the presenter clicks a glass control, then the click passes to the app below (controls do not capture clicks while click-through is on), and the footer shows that click-through is on.

#### US-audit-and-modernization-23: The Deck Editor and panels adopt standard macOS 26 structure
As a presenter on macOS 26, I want the editor and dialogs to look native.
- **AC1.** Given macOS 26, when the Deck Editor is screenshotted, then its toolbar and sidebar render with the system Liquid Glass appearance (a floating glass sidebar and glass toolbar buttons, as standard SwiftUI/AppKit components draw them on macOS 26), with no custom opaque background behind the sidebar.
- **AC2.** Given the timer time panel and the deck picker panel, when each is screenshotted on macOS 26, then it shows a glass surface and system-style buttons instead of the current custom frosted panel.
- **AC3.** Given Light and Dark appearance, when the editor is screenshotted, then all text uses the adaptive editor tokens (no white-on-light or black-on-dark text; the existing Light/Dark rule in `CLAUDE.md` holds).
- **AC4 (unhappy, narrow window).** Given the editor at its minimum size, when it is screenshotted, then no control overlaps another and no text is clipped mid-glyph.

#### US-audit-and-modernization-24: A macOS 26 app icon and status item
As a presenter, I want the icon to match macOS 26 in the Dock-less places it appears (Finder, Launchpad, Sparkle dialog, About) and the status item to read well on a glass menu bar.
- **AC1.** Given macOS 26, when `/Applications` is shown in Finder in Default, Dark, Clear, and Tinted icon styles, then the Prompter icon renders in each style from an Icon Composer asset (no square legacy icon on a white plate).
- **AC2.** Given the menu bar on macOS 26 in Light and Dark appearance, when it is screenshotted, then the status item is a template symbol that renders legibly in both.
- **AC3 (earlier macOS, 14+ path).** Given macOS 14 or 15, when Finder shows the app, then a correctly sized icon appears (fallback asset), not a generic app icon.

## 6. Constraints

- **Platform.** macOS menu-bar app (`LSUIElement`), not sandboxed, hardened runtime, Developer ID distribution. Deployment target is the owner's decision (Q1); stories hold for both options.
- **Tier gating and billing.** None. Prompter is free and MIT-licensed; nothing here adds payment, licensing, or accounts.
- **Offline.** The app must work fully offline; the only network call is Sparkle's update check, and its failure must never block the overlay or hotkeys.
- **Permissions.** Accessibility (hotkeys) is required; Screen Recording may be requested only when the presenter runs the protection self-test (US-10b AC3), never at launch.
- **Factory rules.** Nothing commits to `main` except docs; no PRs unless the owner asks; every PR waits for all checks including prowl-qa; testing runs on Lucius' Mini or in CI, never on the owner's MacBook or dev Mini.
- **Prowl lane.** Prompter is a Genkei/Michael repo (not `prowl-tools/*`), so the anonymity rule does not apply inside it; prowl-qa runs as a consumer of the pinned Prowl release, as in ContainerBar.
- **Secrets.** Developer ID certificate, notarization credentials, and the Sparkle EdDSA private key live only in GitHub encrypted secrets (and the owner's keychain); none appears in the repo, a log, a QA asset, or this document.

## 7. Data and privacy notes

- **What leaves the device:** only Sparkle's update request to GitHub Pages (app version, macOS version, and the user agent Sparkle sends by default; system profiling is not enabled and must stay off). Decks, images, and settings never leave the Mac. No telemetry is added by this work.
- **What is stored:** decks, imported images, and settings under `~/Library/Application Support/Prompter/`; a few UserDefaults keys. US-12 adds a `Decks/Unreadable/` quarantine folder; US-13 deletes unreferenced images, which is a destructive change and must only remove files no deck references.
- **Consent copy:** the Screen Recording request (US-10b AC3) must say, before the system prompt, that Prompter captures only its own overlay to check whether it is hidden, keeps nothing, and sends nothing anywhere. The Accessibility prompt copy stays as is but the menu item from US-11 must explain what the permission is for ("so Prompter's shortcuts work while other apps are in front").
- **QA evidence:** the daily pass shows only the fictional QA deck; any screenshot that would show other windows (mail, chat, browser tabs) is cropped to the overlay or the app's own windows. No customer data is ever used as a fixture.
- **Capture claims are customer-facing:** any change to how the app describes Protected Mode (US-10b) is a customer-facing promise and goes to the owner for wording approval before release.

## 8. Out of scope

- PRMT-002 to PRMT-005 (export/import, hotkey customization, templates, position presets) beyond what F-01 and F-03 strictly need.
- A Settings window, launch at login, and raising the 10-deck limit (recorded as gaps in section 2.4 for a later intake).
- Mac App Store distribution, sandboxing, localization.
- The Mission Control backlog sync (PRMT-006, obsolete: Mission Control was retired 2026-10-06).
- Deleting the 16 merged remote branches (orchestrator housekeeping on the owner's approval; none holds unmerged work).

## 9. Open questions (with the assumption taken)

Status after the architect review (2026-10-14): Q1 stays open with the architect's recommendation (option B = 14+ with a 26 path, design 8.2). Q6 and Q7 are added from the design. The two conflicts the review found (US-3, US-19) were ruled by the orchestrator and are recorded in those stories.

1. **Deployment target: macOS 26 only, or keep 14+ with a macOS 26 path?** Assumed **14+ with a 26 path**: the cask and appcast already promise Sonoma, and presenters on managed corporate Macs often lag a major version. All Epic D stories hold either way.
2. **May the QA deck be fictional seed notes?** Assumed **yes**: an invented "QA Demo Deck" with `example.com` addresses and a generated test-pattern image; no real demo content on the Mini.
3. **Is the makeover a full redesign or an adoption pass?** Assumed an **adoption pass plus replacing custom chrome**: system glass on the overlay, controls, editor, panels, and icon; no new information architecture, no new screens.
4. **Distribution: direct download and cask, or cask only?** Assumed **both continue**, as the README documents today: GitHub Release DMG and zip (Sparkle needs the zip anyway) plus the tap cask.
5. **May the default hotkeys change?** F-01 cannot be fully fixed with the current defaults: while the overlay is visible during a demo, ⌘⇧[ / ] and ⌘⇧ arrows are still taken from the demo app. Assumed: **keep the documented ⌘⇧ defaults, consume them only while the overlay is visible** (US-7), and leave remapping to PRMT-003. If the owner prefers new defaults (for example ⌃⌥ + key), US-7 AC5 carries the change and the README is updated.
6. **Release credentials (design R-02).** Is Prompter's Sparkle EdDSA private key (the half of `SUPublicEDKey`) in the owner's login keychain, and may it be exported into the `SPARKLE_ED_PRIVATE_KEY` secret; may the Developer ID certificate, Apple ID, team, and notary app-specific password already used by Sentwise's release be re-used for Prompter's `release` and `qa-build` environments? Assumed **yes**. US-5 cannot publish until the key is in place; if the key is lost, users who update only through Sparkle stay on 1.2.0.
7. **One-time grants on Lucius' Mini.** The owner grants Accessibility to `/Applications/Prompter.app` (US-19), `~/Applications/Prompter QA.app` (US-26), and the new runner's host (US-4), and Screen Recording to Chrome (US-10a weekly leg). Assumed **yes, once, over Screen Sharing**; until then those cases are BLOCKED and prowl-qa fails its preflight.

Answered by research, not asked: the unfinished-looking branches `next-updates`, `phase-1`, and the 14 others are all 0 commits ahead of `main`; none holds wanted work. Assumed for the Lucius lane without asking: the Mini has one display, so the second-display case runs only when the owner attaches one (US-17 AC4), and the Accessibility permission for Prompter on the Mini is granted once by the owner.

## 10. Traceability

| Story | Epic | Backlog item | Findings | Test cases (planner fills) |
|---|---|---|---|---|
| US-audit-and-modernization-1 | B | PRMT-007 | F-10, F-11 | |
| US-audit-and-modernization-25 | B | PRMT-031 | F-21 | |
| US-audit-and-modernization-2 | B | PRMT-008 | F-22 | |
| US-audit-and-modernization-3 | B | PRMT-009 | | |
| US-audit-and-modernization-4 | B | PRMT-010 | | |
| US-audit-and-modernization-26 | B | PRMT-032 | | |
| US-audit-and-modernization-27 | B | PRMT-033 | F-20 | |
| US-audit-and-modernization-5 | B | PRMT-011 | F-12, F-17 | |
| US-audit-and-modernization-6 | B | PRMT-012 | F-13 | |
| US-audit-and-modernization-7 | A | PRMT-013 | F-01 | |
| US-audit-and-modernization-8 | A | PRMT-014 | F-02 | |
| US-audit-and-modernization-9 | A | PRMT-015 | F-03 | |
| US-audit-and-modernization-10a | A (Lucius, no code) | PRMT-016 | F-04 | TC-PR-10 |
| US-audit-and-modernization-10b | A | PRMT-034 | F-04 | |
| US-audit-and-modernization-11 | A | PRMT-017 | F-05 | |
| US-audit-and-modernization-12 | A | PRMT-018 | F-06, F-07 | |
| US-audit-and-modernization-13 | A | PRMT-019 | F-08, F-09 | |
| US-audit-and-modernization-14 | A | PRMT-020 | F-14, F-15, F-16, F-18 | |
| US-audit-and-modernization-15 | C | PRMT-021 | | |
| US-audit-and-modernization-16 | C | PRMT-022 | | |
| US-audit-and-modernization-17 | C | PRMT-023 | F-04, F-19 | |
| US-audit-and-modernization-18 | C | PRMT-024 | | |
| US-audit-and-modernization-19 | C | PRMT-025 | | |
| US-audit-and-modernization-20 | D | PRMT-026 | | |
| US-audit-and-modernization-21 | D | PRMT-027 | | |
| US-audit-and-modernization-22 | D | PRMT-028 | F-16 | |
| US-audit-and-modernization-23 | D | PRMT-029 | | |
| US-audit-and-modernization-24 | D | PRMT-030 | | |
