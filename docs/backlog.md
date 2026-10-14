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

Source: `docs/requirements/audit-and-modernization.md` (findings F-01 to F-19, stories `US-audit-and-modernization-1` to `-24`); design: `docs/architecture/audit-and-modernization.md` (solution-architect, `req/prompter-audit-arch`). Build order is top to bottom: Epic B first so every later PR has checks, then the defects (A), then the Lucius lane (C), then the makeover (D). Sizes: S up to half a day, M one to two days, L three days or more. Each item is one builder branch unless noted.

### Epic B: CI/CD and QA parity with ContainerBar

{PRMT-007} **Reproducible clean-clone build: shared scheme, pinned Sparkle, no tracked binaries** (Size S)
   Commit a shared `Prompter` scheme with `PrompterTests` in its Test action, commit `Package.resolved` with Sparkle pinned, stop ignoring it, and remove the tracked `Prompter/dist/` (74 files, 11 MB) from git. Findings F-10, F-11. Story US-audit-and-modernization-1.
   **Acceptance:** a fresh clone builds and tests with one `xcodebuild ... -scheme Prompter build test` on Xcode 26 (exit 0); `git ls-files Prompter/dist` is empty; the scheme and `Package.resolved` are tracked; an unfetchable Sparkle pin fails at package resolution.

{PRMT-008} **Swift CI on pull requests: build, unit tests, SwiftLint** (Size M, after PRMT-007)
   `.github/workflows/swift-ci.yml` modelled on ContainerBar's: Xcode 26 selection, xcodebuild build and test, pinned SwiftLint using `Prompter/.swiftlint.yml`, SHA-pinned actions, `contents: read`, per-ref concurrency. Story US-audit-and-modernization-2.
   **Acceptance:** both jobs show as checks on a PR; a failing test fails "Build & Test" naming the test; a 201-character line fails "SwiftLint"; a second push cancels the first run; a runner without Xcode 26 fails listing installed versions.

{PRMT-009} **Claude review, PR description, and PR/issue templates** (Size S)
   Bring `claude-code-review.yml` to ContainerBar's current version, add `claude-pr-description.yml`, a PR template, and bug/feature issue templates with macOS version, Prompter version, meeting app, and display setup fields. Story US-audit-and-modernization-3.
   **Acceptance:** a same-repo PR gets a Claude review and an auto-filled description; fork PRs run no secret-using workflow; templates appear on new PRs and issues.

{PRMT-010} **prowl-qa on pull requests** (Size M, after PRMT-008)
   `.github/workflows/prowl-qa.yml` on the self-hosted macOS runner with ContainerBar's pinned Prowl version; hunt build with its own bundle id and Application Support folder. Story US-audit-and-modernization-4.
   **Acceptance:** same-repo PRs get a Prowl QA check; the hunt build never touches the installed app's decks; an offline runner never reports success; the hunt app is gone from the Mini after the run.

{PRMT-011} **Tag-driven release workflow: sign, notarize, DMG and zip, Sparkle appcast, GitHub Release** (Size L, after PRMT-008)
   Replace the four local scripts as the release path (keep them as a documented fallback or retire them, per the architect): version-consistency gate, Developer ID signing and notarization from GitHub secrets, staple, DMG and zip, Sparkle EdDSA signature, appcast item with real release notes from the CHANGELOG, appcast change reaching `main` by PR (or a non-`main` Pages source), no deletion of an existing release. Findings F-12, F-17. Story US-audit-and-modernization-5. Owner action: add the signing, notarization, and Sparkle secrets.
   **Acceptance:** tag `vV` yields Release `vV` with both assets whose app passes `codesign --verify --deep --strict`, `spctl --assess`, `stapler validate`; the appcast's newest item is V with signature, length, minimum system version, and non-empty notes; tag/plist mismatch fails before build; a rerun for an existing release fails without touching it; a notarization rejection publishes nothing; no secret appears in logs.

{PRMT-012} **Homebrew cask: modern `depends_on`, `auto_updates`, updated by the release** (Size S, after PRMT-011)
   Fix `michaeltookes/tap` `Casks/prompter.rb` (symbol form of `depends_on macos:`, `auto_updates true`) and have the release workflow propose the version and checksum bump computed from the uploaded DMG. Finding F-13; closes the Prompter half of genkei-ops backlog 16b. Story US-audit-and-modernization-6.
   **Acceptance:** `brew audit --cask --strict` reports no `depends_on` deprecation; a release produces a tap change with the right version and sha256; `brew install --cask michaeltookes/tap/prompter` on a clean Mac installs the release; a wrong checksum is refused.

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

{PRMT-016} **Protected Mode: verify on macOS 26 and tell the truth in the app** (Size M; device verification first)
   Lucius measures whether `screencapture` and a ScreenCaptureKit capture see the protected overlay on macOS 26; record the result; "Test Protected Mode" gains a Run Test self-check (Screen Recording requested only then) and honest copy; footer indicator qualified where needed. Finding F-04 (High, Critical if confirmed). Story US-audit-and-modernization-10. Owner approves any customer-facing wording.
   **Acceptance:** the measured result per capture method is recorded in `docs/qa/` and `CAPTURE_PROTECTION.md`; Run Test shows "Hidden from capture" or "Visible to capture" with a thumbnail within 5 seconds; declining Screen Recording shows how to grant it and changes nothing else.

{PRMT-017} **Hotkeys register when Accessibility is granted at any time; menu shows when they are off** (Size S)
   Watch for the Accessibility trust change instead of a 60-second retry window; add a first menu item while hotkeys are off that opens the Accessibility pane. Finding F-05. Story US-audit-and-modernization-11.
   **Acceptance:** granting permission after 5 minutes enables hotkeys within 5 seconds without relaunch; the menu item appears while off and disappears when on; revoking permission brings it back and stops consuming keys.

{PRMT-018} **Persistence integrity: per-deck saves in order, unreadable decks set aside with notice** (Size M)
   Per-deck debounce (or flush on deck switch and create), serial ordered writes, quarantine of undecodable deck files to `Decks/Unreadable/` with an editor notice, save-failure notice. Findings F-06, F-07. Story US-audit-and-modernization-12.
   **Acceptance:** edit deck A then create deck B within 1 second, quit and relaunch: A keeps the edit; 20 edits in 2 seconds persist the last; an invalid JSON deck is moved aside with a one-line notice while other decks load; a read-only Decks folder shows "Could not save" and keeps the edit in memory.

{PRMT-019} **Unreferenced images are deleted; card delete is undoable** (Size M)
   Reference-counted asset cleanup across all decks (clones share assets) after card delete, image replace, and deck delete; undo/redo for card delete in the editor; missing asset shows "Image missing". Findings F-08, F-09. Story US-audit-and-modernization-13.
   **Acceptance:** an image no deck references is removed from `Assets/` within one save cycle; a shared image survives deletion in a clone; ⌘Z restores a deleted card with content and images and ⌘⇧Z deletes it again; a missing file never crashes the app.

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

{PRMT-025} **Lane operations: schedule, hourly check, CI-busy and desktop lock, restore, report, Discord** (Size M, after PRMT-022)
   Staggered schedule from ContainerBar's, zero-token hourly version/process check, factory CI-busy predicate and shared desktop lock, restore to baseline, Lucius brief-template report with known failures keyed `{PRMT id, fixed-in version}`, Discord `QA PASS`/`QA FAIL`, inbox relay, defect intake to `PRMT-` items. Story US-audit-and-modernization-19.
   **Acceptance:** one pass per scheduled time and no overlap with other desktop briefs; busy CI or lock gives BLOCKED after 10 minutes; restore leaves Prompter running at baseline with the overlay hidden; no `kill`/`pkill`/`killall` in the run log; uncovered system dialogs are never acted on.

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
