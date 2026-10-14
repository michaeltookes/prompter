# Backlog

Prioritized list of planned features, improvements, and technical debt.

**Latest release: v1.2.0** (Feb 11, 2026) — Full accessibility support (VoiceOver, keyboard navigation, Dynamic Type), "Presenter Overlay" → "Prompter" rename throughout UI.

## High Priority

1. ~~**Add Sparkle auto-update framework**~~  **DONE**
   Integrated Sparkle 2.x via SPM. UpdateManager service, "Check for Updates..." menu item, Info.plist placeholders for appcast URL and EdDSA key. Release infrastructure (key generation, appcast hosting) still needed before first shipped update.

{PRMT-001} **Adopt macOS 26 Liquid Glass design**
   Apply Apple's Liquid Glass material to the overlay and editor UI using `.glassEffect()` (SwiftUI) and `NSGlassEffectView` (AppKit). Must use `#available(macOS 26.0, *)` checks to keep macOS 14 as minimum target. Key areas: overlay background (replace `.ultraThinMaterial`), traffic light buttons, footer controls, deck editor toolbar. Note: standard components (toolbars, sidebars, sheets) get Liquid Glass automatically when compiled with Xcode 26 — custom views need explicit adoption. Limit to 5-10 glass views for performance. Use `GlassEffectContainer` when grouping multiple glass elements.
   *Superseded 2026-10-14 by Epic D (PRMT-026 to PRMT-030), which splits this item into buildable stories; see `docs/requirements/audit-and-modernization.md`.*

3. ~~**Replace NSAlert dialogs with custom NSPanel**~~  **DONE**
   Replaced NSAlert with ThemedPanelWindow (NSPanel subclass) + SwiftUI views (TimeInputPanelView, DeckPickerPanelView) for consistent themed styling.

4. ~~**Migrate from Carbon hotkeys to CGEvent tap**~~  **DONE**
   Replaced Carbon Event Manager with CGEvent tap. Added AXIsProcessTrustedWithOptions for accessibility permission prompting and auto-retry on first launch.

## Medium Priority

5. ~~**Add unit tests for timer logic**~~  **DONE**
   Added 33 tests in TimerTests.swift covering configuration, state machine, toggle cycle, card navigation, and real-time tick behavior.

6. ~~**Accessibility audit**~~  **DONE**
   Full audit completed Feb 2026. All four implementation phases completed:

   ~~**Phase 1 — Accessibility announcements (Critical)**~~ **DONE**
   Added `postAccessibilityAnnouncement()` helper to AppState. All hotkey-driven state changes announced. Window accessibility roles/titles added to OverlayWindow, EditorWindow, ThemedPanelWindow, and TestCaptureWindow.

   ~~**Phase 2 — VoiceOver labels (High)**~~ **DONE**
   Added `.accessibilityLabel()` and `.accessibilityHint()` to all icon buttons, image drop zones, sliders, toggles, and text fields across all editor and overlay views. Added `accessibilityDescription` to `LayoutType` and `accessibilitySummary` to `Card`. Labeled menu items with `.accessibilityHelp()`.

   ~~**Phase 3 — Keyboard navigation (Medium)**~~ **DONE**
   Added Browse button (fileImporter) to ImageDropZone, Move Up/Down context menu items for card reordering, bullet move buttons replacing drag handles in TitleBulletsEditorView, and @FocusState auto-focus for new bullet fields.

   ~~**Phase 4 — Dynamic Type (Medium)**~~ **DONE**
   Replaced hardcoded font sizes in CardListSidebar and OverlayFooterView with Dynamic Type equivalents (`.caption2`, `.footnote`, `.callout`, etc.). Overlay renderers kept as-is with `fontScale` multiplier.

{PRMT-002} **Export/import decks**
   Allow users to share decks as `.prompter` files (JSON + bundled assets).

## Low Priority

{PRMT-003} **Keyboard shortcut customization**
   Let users rebind global hotkeys from a settings panel.

{PRMT-004} **Deck templates**
   Pre-built deck templates for common presentation scenarios.

{PRMT-005} **Overlay position presets**
    Quick-select overlay positions (top-right, bottom-left, etc.) instead of manual drag.

## Obsolete

{PRMT-006} **Add Mission Control backlog sync workflow** — **OBSOLETE (2026-10-14)**
   Defined on the unmerged branch `chore/add-backlog-sync-workflow`. Mission Control was retired 2026-10-06, so the sync workflow will not be merged. The id stays reserved and is never reused.

## Audit and modernization (2026-10-14 intake)

Source: `docs/requirements/audit-and-modernization.md` (findings F-01 to F-19, stories `US-audit-and-modernization-1` to `-27`, with `-10` split into `-10a` and `-10b`); design: `docs/architecture/audit-and-modernization.md` (solution-architect, `req/prompter-audit-arch`). Build order is top to bottom: Epic B first so every later PR has checks, then the defects (A), then the Lucius lane (C), then the makeover (D). Story ids added by the architect review: US-25 → PRMT-031, US-26 → PRMT-032, US-27 → PRMT-033, US-10a → PRMT-016, US-10b → PRMT-034; PRMT-035 is a Low follow-up to US-27. Sizes: S up to half a day, M one to two days, L three days or more. Each item is one builder branch unless noted.

### Epic B: CI/CD and QA parity with ContainerBar

**Build order after the architect review (2026-10-14).** PRMT-007 is done (PR #17). First wave, in parallel now (builders dispatched 2026-10-14 evening): PRMT-031 (US-25 build flavors), PRMT-009 (US-3 Claude workflows), PRMT-033 (US-27 scripts). Then PRMT-008 (US-2 Swift CI, after PRMT-031). Then PRMT-032 (US-26 QA build) and PRMT-010 (US-4 prowl-qa). Then PRMT-011 (US-5 release) and PRMT-012 (US-6 cask). Items below keep their ids; read this paragraph for the order.

{PRMT-007} **Reproducible clean-clone build: shared scheme, pinned Sparkle, no tracked binaries** (completed: 2026-10-14)
   Shared `Prompter` scheme (PrompterTests in its Test action), Sparkle pinned to exactly 2.8.1 with `Package.resolved` tracked, and the 74 build-output files under `Prompter/dist/` removed from git. Branch `prmt-007-clean-clone-build` (acf9f3e), PR #17. Findings F-10, F-11. Story US-audit-and-modernization-1 (AC2, AC3 done; AC1 and AC4 are proven by PRMT-008's first run after PRMT-031).
   *This entry replaces the completed PRMT-007 line the builder added at the end of Medium Priority on that branch; keep only this one after both merge.*

{PRMT-031} **Build flavors with isolated storage: tests, hunts, and QA builds never touch user data** (in progress) (Size M; first after PRMT-007; blocks PRMT-007's test run, PRMT-008's Build & Test job, PRMT-010, PRMT-032, and the pre-PR QA gate)
   Four flavors per design 3.2: `production` (`com.tookes.Prompter`, `Application Support/Prompter/`), `qa` (`com.tookes.Prompter.qa`, `Prompter-QA/`), `hunt` (`com.tookes.Prompter.hunt`, `Prompter-Hunt/`, wiped and re-seeded from bundled fixtures each launch), `unitTest` (no storage). Tasks: `App/AppEnvironment.swift`, `Services/StoragePaths.swift`; `PersistenceService` and `AssetManager` take `StoragePaths`; `Info.plist` `PrompterFlavor = $(PROMPTER_FLAVOR)` defaulting to `production`; legacy `PresenterOverlay` migration only in `production`; hunt build copies `docs/qa/fixtures/` into `Contents/Resources/HuntSeed/` (empty deck folder until PRMT-021). Finding F-21 (High). Story US-audit-and-modernization-25.
   **Acceptance:** each flavor uses exactly its bundle id and data root, covered by a unit test of the resolution table; the suite leaves `Application Support/Prompter/` and the `com.tookes.Prompter` defaults byte-identical (persistence tests use `PersistenceService(rootURL:)` on a temp dir removed in `tearDown`); under XCTest the app creates no status item, prompt, event tap, Sparkle updater, or storage access; `qa`/`hunt` never start Sparkle and label the status item "Prompter QA"/"Prompter Hunt"; a Release build with `PROMPTER_HUNT_MODE=1` still uses the production root.

{PRMT-008} **Swift CI on pull requests: build, unit tests, SwiftLint** (Size M, after PRMT-031)
   `.github/workflows/swift-ci.yml` modelled on ContainerBar's: Xcode 26 selection, `xcodebuild build-for-testing` and `test-without-building` for scheme `Prompter` on a GitHub-hosted runner, pinned SwiftLint using `Prompter/.swiftlint.yml`, SHA-pinned actions, `contents: read`, per-ref concurrency; also runs `Prompter/scripts/tests/` once PRMT-011 adds them. Story US-audit-and-modernization-2.
   Task (F-22): clear the existing SwiftLint error `App/AppState.swift:19` `type_body_length` (602 vs 600) in this branch. Preferred: trim by moving the timer block (`AppState.swift:579-721`) and auto-save sinks (`:723-803`) into `AppState+Timer.swift` and `AppState+AutoSave.swift`; raising the threshold is allowed only with a comment naming this item, and Epic A will hit it again.
   Task: the CI test build signs ad hoc with hardened runtime off for the test build only (`CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= ENABLE_HARDENED_RUNTIME=NO`), design 4.2.
   **Acceptance:** both jobs show as checks on a PR; a failing test fails "Build & Test" naming the test; a 201-character line fails "SwiftLint"; `main` lints with 0 errors (warnings stay annotations); a second push cancels the first run; a runner without Xcode 26 fails listing installed versions; first green run also proves US-1 AC1 and AC4.

{PRMT-032} **`qa-build.yml`: signed QA build of any branch for the pre-PR QA gate** (Size M, after PRMT-031 and PRMT-008)
   `workflow_dispatch` with input `ref` produces artifact `Prompter-QA-<shortsha>.zip` (retention 3 days) holding `Prompter QA.app` (`com.tookes.Prompter.qa`, flavor `qa`), Developer ID signed with hardened runtime, not notarized; temporary keychain deleted in every case. Design 4.4. Story US-audit-and-modernization-26.
   Secrets (GitHub environment `qa-build`, created by `vendor-ops`, owner approval Q6): `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`.
   Precondition (owner, once, Q7): grant Accessibility to `~/Applications/Prompter QA.app` on Lucius' Mini.
   **Acceptance:** the artifact contains the QA app with the right bundle id and flavor; two builds of different commits have an identical designated requirement (`codesign -d -r-`); installed beside the release on the Mini it leaves the release's data byte-identical, uses `Prompter-QA/`, and never starts Sparkle; a missing or wrong certificate secret fails at keychain import naming the secret and uploads nothing.

{PRMT-009} **Claude workflows per the factory review model; PR and issue templates** (Size S; first wave) (in review: branch `us-3-review-workflows`, 1548a39)
   Orchestrator ruling 2026-10-14 (decision of 2026-10-12): remove `claude-code-review.yml` (reviews come from the pre-PR Codex review and the repo's bot reviewer); keep `claude.yml` (on-demand `@claude`) with its actions pinned to commit SHAs; add `claude-pr-description.yml` as a verbatim copy of ContainerBar's portable file; add a PR template and bug/feature issue templates with macOS version, Prompter version, meeting app, and display setup fields. Story US-audit-and-modernization-3.
   **Acceptance:** `.github/workflows/` has no `claude-code-review.yml`, a SHA-pinned `claude.yml`, and `claude-pr-description.yml`; a same-repo PR with an empty body gets a suggested description in the workflow summary and its body is never edited; fork PRs run no secret-using workflow; templates appear on new PRs and issues.

{PRMT-033} **Release scripts read identity and credentials from the environment (no personal Apple ID in the repo)** (Size S; first wave; touches only `Prompter/scripts/`) (in review: branch `us-27-scripts-no-personal-data`, 2b109d1)
   Remove the owner's Apple ID email (`notarize.sh:6`), the team-qualified Developer ID identity string (`build-release.sh:4`, `create-dmg.sh:4`), and the hardcoded keychain profile `Prompter-Notarize`; scripts read `APPLE_ID`, `APPLE_TEAM_ID`, `SIGNING_IDENTITY`, and either `NOTARY_PROFILE` (keychain profile; wins when both are set) or `NOTARY_APP_SPECIFIC_PASSWORD` (needs `APPLE_ID` and `APPLE_TEAM_ID`); an optional gitignored `Prompter/scripts/.env.local` is loaded by `release-env.sh`, with values already set in the shell winning, and a committed placeholder `.env.example`. History is not rewritten (owner's call). Folds into PRMT-011's `release.sh`. Finding F-20 (High). Story US-audit-and-modernization-27.
   **Acceptance:** `git grep` finds none of the three values under `Prompter/scripts/`; each script exits non-zero naming any missing variable before building or notarizing.
   Note: the Apple team id stays in `Prompter/Prompter.xcodeproj/project.pbxproj` (`DEVELOPMENT_TEAM`); it is not a credential and is out of scope here. Its removal is PRMT-035.

{PRMT-010} **prowl-qa on pull requests** (Size M, after PRMT-031 and PRMT-008)
   `.github/workflows/prowl-qa.yml` on the self-hosted macOS runner with ContainerBar's pinned Prowl version; hunt flavor from PRMT-031 (`com.tookes.Prompter.hunt`, `Application Support/Prompter-Hunt/`); last step quits the hunt app with `osascript -e 'quit app id "com.tookes.Prompter.hunt"'` (no signals). Design 4.3 and 3.3. Story US-audit-and-modernization-4.
   Preconditions (not builder work): `homelab-it` registers a repository-scoped runner for `michaeltookes/prompter` on Lucius' Mini (`self-hosted, macOS, ARM64`) and adds it to the Mini's CI-busy predicate; the owner grants Accessibility once to that runner's host process (Q7). Until then the Accessibility preflight fails with its message.
   **Acceptance:** same-repo PRs get a Prowl QA check; the hunt build never touches the installed app's decks; with the runner offline the check stays pending (or fails) and never reports success, and the merge checklist treats pending as not green; after the run the hunt app is not running and nothing is left in `/Applications`.

{PRMT-011} **Tag-driven release workflow: sign, notarize, DMG and zip, Sparkle appcast on `gh-pages`, GitHub Release** (Size L, after PRMT-008 and PRMT-033)
   Tasks: one `Prompter/scripts/release.sh` for CI and local runs (absorbs the four scripts; reads the environment per PRMT-033); `Prompter/scripts/validate-release.py` (`pre`, `appcast-item`, `appcast-check`) with stdlib tests in `Prompter/scripts/tests/` run by PRMT-008's job; version single source (`Info.plist` `CFBundleShortVersionString = $(MARKETING_VERSION)`, `CFBundleVersion = $(CURRENT_PROJECT_VERSION)`); Sparkle `sign_update` from the Sparkle 2.8.1 release tarball matching the pin; `minimumSystemVersion` read from `MACOSX_DEPLOYMENT_TARGET`; appcast pushed to `gh-pages` (Pages source), never `main`; `dry_run` and `resume=publish-tail` inputs. Findings F-12, F-17. Story US-audit-and-modernization-5.
   Secrets (GitHub environment `release`, deployment policy tags `v*`, created by `vendor-ops`; names match Sentwise's `release.yml`): `MACOS_CERTIFICATE_P12`, `MACOS_CERTIFICATE_PASSWORD`, `APPLE_ID`, `APPLE_TEAM_ID`, `NOTARY_APP_SPECIFIC_PASSWORD`, `SPARKLE_ED_PRIVATE_KEY` (Prompter's own key), `TAP_PUSH_TOKEN`.
   Preconditions (not builder work): owner exports Prompter's Sparkle EdDSA private key (`generate_keys -x`) into `SPARKLE_ED_PRIVATE_KEY` (Q6); `vendor-ops` moves the Pages source to a new `gh-pages` branch seeded byte-for-byte with today's `appcast.xml`, verifies the public URL serves the same bytes, and only then is `appcast.xml` deleted from `main`.
   **Acceptance:** tag `vV` yields Release `vV` with `Prompter.zip`, `Prompter.dmg`, `Prompter.dmg.sha256`, notes from the CHANGELOG, and the CHANGELOG date equal to the tag's commit date in America/Chicago; both artifacts' app passes `codesign --verify --deep --strict`, `spctl --assess`, `stapler validate` with the owner's Developer ID authority; the appcast's newest item is V with signature, exact length, minimum system version, and non-empty notes; tag/plist mismatch fails before build; a rerun for an existing release fails without touching it, and `resume=publish-tail` only finishes appcast and cask steps; notarization rejection publishes nothing; `dry_run=true` with no secrets completes checks, unsigned archive, DMG layout, and rendered appcast item and publishes nothing; no secret appears in logs.

{PRMT-012} **Homebrew cask: modern `depends_on`, `auto_updates`, updated by the release** (Size S, after PRMT-011; the live-tap line fix can ship now)
   Fix `michaeltookes/tap` `Casks/prompter.rb` now in a tap PR without a version change (symbol form of `depends_on macos:`, `auto_updates true`; genkei-ops backlog 16b). Add cask template `Prompter/distribution/prompter.rb` (design 4.6), synced whole by PRMT-011's tap step using `TAP_PUSH_TOKEN` with version and sha256 computed from the uploaded DMG; `brew audit --cask --strict` is the last step of `release.yml` (a lint, not an app test). Finding F-13. Story US-audit-and-modernization-6.
   **Acceptance:** `brew audit --cask --strict michaeltookes/tap/prompter` reports no `depends_on` deprecation and the cask has `auto_updates true`; a release produces a tap change with the right version and sha256; `brew install --cask michaeltookes/tap/prompter` on a clean Mac installs the release; a wrong checksum is refused.

{PRMT-035} **Remove the hardcoded Apple team id from the project file** (Size S, Low; after PRMT-033)
   `project.pbxproj` sets `DEVELOPMENT_TEAM` to the owner's team id in all four build configurations; move it to an untracked or environment-supplied setting (for example a gitignored `.xcconfig` with a committed placeholder, or `DEVELOPMENT_TEAM` passed by `release.sh` and `qa-build.yml`) so the public repo names no team. The tracked build output under `Prompter/dist/` that also embeds it is already untracked by PRMT-007. Not a credential; no rotation. Follow-up to F-20 / US-audit-and-modernization-27.
   **Acceptance:** `git grep` for the team id finds nothing in tracked files; a clean clone still builds unsigned in CI (PRMT-008) and the release and QA builds still sign with the owner's Developer ID when the team id comes from the environment; with the team id unset, a signed build fails with a message naming `DEVELOPMENT_TEAM` (or the variable `release.sh` reads).

### Epic A: Audit fixes

{PRMT-013} **Hotkeys only consume keys while they are in use** (Size M)
   Pass every mapped combo through to the front app while the overlay is hidden, except the show-overlay hotkey; consume only while the overlay is visible. Defaults per owner answer Q5. Finding F-01 (High). Story US-audit-and-modernization-7.
   **Acceptance:** with the overlay hidden, ⌘⇧← selects to line start in TextEdit and ⌘⇧] switches Safari tabs; the show hotkey still works; with the overlay visible, next-card advances and the front app gets nothing; README, in-app list, and code agree.

{PRMT-014} **Overlay scroll hotkeys scroll the card** (Size S)
   Bind the overlay's scroll position to the scroll hotkeys, clamp at the content end, reset on card change. Finding F-02 (High). Story US-audit-and-modernization-8.
   **Acceptance:** on the QA deck's 40-bullet card, scroll-down moves content by at least 3 lines and stops at the end; returning to the card starts at its top; short cards do not move.

{PRMT-015} **Overlay stays on a visible screen; Move Overlay to display** (Size M)
   Clamp the restored frame to connected screens at launch and on screen-configuration changes; add a "Move Overlay to" submenu listing displays by name. Finding F-03 (High). Story US-audit-and-modernization-9.
   **Acceptance:** an off-screen saved frame opens fully on the main screen; unplugging the overlay's display moves it within 2 seconds; a partly visible frame becomes fully visible; the submenu moves the overlay and the choice persists while that display is attached.

{PRMT-016} **Protected Mode measurement on macOS 26 (Lucius, no app code)** (Size S; split 2026-10-14: this id is US-10a, the in-app part is PRMT-034)
   Lucius runs TC-PR-10: with the overlay visible and Protected Mode on, capture with `screencapture -x -D 1` and Peekaboo's ScreenCaptureKit capture, plus a weekly Chrome `getDisplayMedia` whole-screen preview from `docs/qa/fixtures/share-preview.html`; record per method "hidden" or "visible" with the macOS build and cropped evidence in `docs/qa/` and `.claude/reference-docs/CAPTURE_PROTECTION.md`. Finding F-04 (High, Critical if confirmed). Story US-audit-and-modernization-10a.
   Precondition (owner, once, Q7): grant Screen Recording to Chrome on Lucius' Mini; without it the Chrome leg is SKIPPED.
   **Acceptance:** the recorded result names the macOS build and each method with hidden/visible and evidence images; it is in both documents before PRMT-034 starts.

{PRMT-034} **Protected Mode tells the truth in the app: Run Test self-check and honest copy** (Size M, after PRMT-016's result is recorded)
   "Test Protected Mode…" gains a Run Test that captures only the overlay's own rectangle with ScreenCaptureKit (shown and hidden, compared, nothing written to disk) and plain-language results; the footer indicator is qualified where PRMT-016 found a method that sees the overlay. Design 6.4. Finding F-04. Story US-audit-and-modernization-10b.
   Copy constraint (binding): before the system prompt the window says Prompter captures only its own overlay area to check whether it is hidden, keeps nothing, and sends nothing. Any change to the footer's "Protected" wording, the verdict text, or the README's Protected Mode claim is customer-facing and waits for the owner's approval before release.
   **Acceptance:** with Screen Recording granted, Run Test shows "Hidden from capture" or "Visible to capture" with a thumbnail within 5 seconds; without it the window explains, then requests, and says that on macOS 15+ Prompter must be reopened after granting; declining shows how to grant and changes nothing else; where a method sees the overlay the window names it and the footer no longer claims protection unqualified; with Protected Mode off the "Visible to capture" warning still shows.

{PRMT-017} **Hotkeys register when Accessibility is granted at any time; menu shows when they are off** (Size S)
   Watch for the Accessibility trust change instead of a 60-second retry window; add a first menu item while hotkeys are off that opens the Accessibility pane. Finding F-05. Story US-audit-and-modernization-11.
   **Acceptance:** granting permission after 5 minutes enables hotkeys within 5 seconds without relaunch; the menu item appears while off and disappears when on; revoking permission brings it back and stops consuming keys.

{PRMT-018} **Persistence integrity: per-deck saves in order, unreadable decks set aside with notice** (Size M)
   Per-deck debounce (or flush on deck switch and create), serial ordered writes, quarantine of undecodable deck files to `Decks/Unreadable/` with an editor notice, save-failure notice. Findings F-06, F-07. Story US-audit-and-modernization-12.
   **Acceptance:** edit deck A then create deck B within 1 second, quit and relaunch: A keeps the edit; 20 edits in 2 seconds persist the last; an invalid JSON deck is moved aside with a one-line notice while other decks load; a read-only Decks folder shows "Could not save" and keeps the edit in memory.

{PRMT-019} **Unreferenced images are trashed and purged; card delete is undoable** (Size M)
   Reference-counted asset cleanup across all decks and undo steps (clones share assets) after card delete, image replace, and deck delete: unreferenced files move to `Assets/.Trash/` within one save cycle and the trash is emptied at next launch, so undo can restore images during the session; undo/redo for card delete; a missing asset shows "Image missing". Findings F-08, F-09. Story US-audit-and-modernization-13.
   **Acceptance:** an image no deck or undo step references leaves `Assets/` for `Assets/.Trash/` within one save cycle and is gone after relaunch; a shared image survives deletion in a clone; ⌘Z restores a deleted card with content and images and ⌘⇧Z deletes it again; a missing file never crashes the app.

{PRMT-020} **Remove dead and deprecated code; accessible overlay close control; doc corrections** (Size S)
   Delete `TestCaptureWindowController`, placeholder views, unused persistence helpers; replace `activate(ignoringOtherApps:)`; drop the stray SwiftUI `WindowGroup` scene; make the overlay close control a labelled button and hide decorative circles from VoiceOver; update `CLAUDE.md`/`AGENTS.md` (backlog location, debounce). Findings F-14, F-15, F-16, F-18. Story US-audit-and-modernization-14.
   **Acceptance:** none of the named symbols remain and Prompter's own sources build without deprecation warnings; after launch the app owns no window but the hidden overlay; VoiceOver announces "Hide overlay, button"; the grounding docs point to `docs/backlog.md`.

### Epic C: Lucius daily QA lane

{PRMT-021} **QA hooks and fixture deck: accessibility identifiers, `docs/qa/seed-data.md`, QA backdrop** (Size M; can run in parallel with Epic A)
   Stable identifiers on the status item, menu items, overlay, and editor; fictional "QA Demo Deck" (5 cards, 3+ layouts, a 40-bullet card, a generated test-pattern image) and the checkerboard backdrop for Epic D screenshots; install and restore procedure for fixtures. Story US-audit-and-modernization-15.
   **Acceptance:** Peekaboo finds `prompterStatusItem` and the listed identifiers in a release build; seed data contains no real names or companies; fixtures are copied only while Prompter is quit and the baseline `Settings.json` is restorable; a missing identifier blocks the step with the element list.

{PRMT-022} **Lucius recipe and daily pass: install integrity and launch** (Size M, after PRMT-011 and PRMT-021)
   `PROMPTER_QA.md` in Lucius' workspace (architect designs location, schedule, evidence root); cases for installed version vs latest release, signature checks, launch and status item, release-day `brew upgrade --cask`. Story US-audit-and-modernization-16.
   **Acceptance:** version mismatch is FAIL `stale-install`; `codesign`/`spctl`/`stapler` all exit 0; status item visible within 10 seconds with one `Prompter` PID and no Dock icon; a failed signature check stops the launch and posts `QA FAIL`.

{PRMT-023} **Daily pass: overlay, hotkeys, display placement, Protected Mode capture, click-through** (Size M, after PRMT-022)
   Cases for show overlay, next/previous/toggle/font/scroll hotkeys, hidden-overlay pass-through, off-screen frame recovery (and second display when attached), `screencapture` plus ScreenCaptureKit capture with Protected Mode on and off, click-through. Known failures keyed to PRMT-013, -014, -015 until released. Findings F-04, F-19 (window level check). Story US-audit-and-modernization-17.
   **Acceptance:** counter reads "3 / 5" after two next-card hotkeys; pass-through selects text in TextEdit (known failure until PRMT-013 ships); protected captures do not show "QA Card 1 - Opening" unless recorded as an unsupported method; missing Accessibility on the Mini is BLOCKED `tcc-accessibility`, never self-granted.

{PRMT-024} **Daily pass: settings persistence and update check** (Size S, after PRMT-022)
   Change opacity, font, click-through, and position; quit from the menu; relaunch; verify; restore. Check for Updates up-to-date, newer-available (Remind Me Later only), appcast-unreachable. Story US-audit-and-modernization-18.
   **Acceptance:** changed values survive relaunch and the baseline is restored; Sparkle reports up to date when versions match; a newer version is recorded and never installed; an unreachable appcast is BLOCKED with the dialog text.

{PRMT-025} **Lane operations: 08:15 CT schedule, hourly check, CI-busy and desktop lock, restore, report, Discord** (Size M, after PRMT-022)
   Daily pass at 08:15 America/Chicago (after ContainerBar 07:05, before Sentwise 09:35; design 5.4); zero-token launchd hourly check 08:00–20:00 (skipped while the desktop lock is held) for release tag, appcast, cask, and installed version agreement and `spctl --assess`. Orchestrator ruling 2026-10-14: until a release containing PRMT-013 is installed on the Mini, the pass quits Prompter at the end and the hourly check asserts it is not running (a running Prompter swallows ⌘⇧ shortcuts the other passes use); after that release, it stays running with the overlay hidden and the check asserts one process. Factory CI-busy predicate and shared desktop lock; restore to the baseline manifest; brief-template report with known failures keyed `{PRMT id, fixed-in version}`; Discord `QA PASS`/`QA FAIL`; inbox relay; defect intake to `PRMT-` items. Baseline seeding, `PROMPTER_QA.md`, cron and launchd jobs are orchestrator work via a brief (design 5.1). Story US-audit-and-modernization-19.
   Precondition (owner, once, Q7): grant Accessibility to `/Applications/Prompter.app` on Lucius' Mini; Lucius never grants a permission.
   **Acceptance:** one pass per day at 08:15 CT with no overlap with other desktop briefs; busy CI or lock gives BLOCKED after 10 minutes; restore puts the baseline data and defaults back, closes Sparkle/editor/Test windows and TextEdit unsaved, restores the desktop picture, and quits Prompter (until the PRMT-013 release); the hourly check posts only on state change; no `kill`/`pkill`/`killall` in the run log; uncovered system dialogs are never acted on.

### Epic D: Liquid Glass makeover for macOS 26

{PRMT-026} **Xcode 26 / macOS 26 SDK and the deployment-target decision** (Size S, needs owner answer Q1)
   Build on the macOS 26 SDK with zero warnings; apply the chosen deployment target consistently to the project, appcast minimum, cask, and README; gate all Liquid Glass APIs behind availability checks on the 14+ path. Story US-audit-and-modernization-20.
   **Acceptance:** CI builds warning-free on Xcode 26; the four places state one minimum; on the 14+ path every glass API is availability-gated and the app launches on macOS 14; on the 26-only path Sparkle and the cask refuse macOS 15.

{PRMT-027} **Overlay surface in Liquid Glass, readable at every opacity** (Size M, after PRMT-026)
   Replace the `.ultraThinMaterial` plus dark fill with system glass on macOS 26; keep the current surface on earlier macOS; honour Reduce Transparency. Story US-audit-and-modernization-21.
   **Acceptance:** macOS 26 screenshot over the QA backdrop shows blurred, tinted checkerboard and continuous rounded corners with no square halo; text contrast at least 4.5:1 (body) and 3:1 (title) at 30 % and 100 % opacity in Light and Dark; Protected Mode capture result unchanged; macOS 14/15 screenshot matches v1.2.0; Reduce Transparency gives an opaque surface.

{PRMT-028} **Overlay controls as system glass controls (no fake traffic lights)** (Size M, after PRMT-027)
   Replace the three drawn circles and the footer controls with glass buttons in one glass container; labelled for VoiceOver; respect click-through. Finding F-16 (completes it visually). Story US-audit-and-modernization-22.
   **Acceptance:** macOS 26 screenshot shows no red/grey circles and glass capsule controls; the Protected Mode off warning remains visibly orange/red; every control has a VoiceOver label and role; with click-through on, clicks pass to the app below.

{PRMT-029} **Deck Editor and panels adopt standard macOS 26 structure** (Size L, after PRMT-026)
   Standard sidebar and toolbar so the system draws Liquid Glass; replace the custom frosted panels for timer time and deck picker; keep adaptive editor colour tokens. Story US-audit-and-modernization-23.
   **Acceptance:** macOS 26 screenshots show a floating glass sidebar and glass toolbar with no custom opaque sidebar background; both panels show glass surfaces and system buttons; no illegible text in Light or Dark; no overlap or clipping at minimum window size.

{PRMT-030} **macOS 26 app icon (Icon Composer) and status item** (Size S, after PRMT-026)
   Icon Composer asset with Default, Dark, Clear, and Tinted renderings and a fallback for earlier macOS; status item stays a template symbol legible on the glass menu bar. Story US-audit-and-modernization-24.
   **Acceptance:** Finder on macOS 26 shows the icon correctly in all four styles; the status item reads in Light and Dark menu bars; earlier macOS shows a correctly sized icon, never the generic one.
