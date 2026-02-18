# Release Prep

Complete release preparation workflow for Prompter. Walks through every step from version bump to Homebrew cask update, ensuring nothing is skipped.

## Usage

```
/release-prep "1.2.0"
```

The argument is the new version number (e.g., "1.2.0"). The build number auto-increments.

---

## Workflow

### Phase 1: Branch & Version

#### 1.1 Create Release Branch

Create a new branch from main for all release prep work:

```bash
git checkout main && git pull
git checkout -b release-prep
```

#### 1.2 Version Bump

Two files must be updated in sync:

**`Prompter/Prompter/Resources/Info.plist`:**
- `CFBundleShortVersionString` -> new version (e.g., `1.2.0`)
- `CFBundleVersion` -> increment by 1 (e.g., `2` -> `3`)

**`Prompter/Prompter.xcodeproj/project.pbxproj`:**
- `MARKETING_VERSION` -> new version (4 occurrences: Debug/Release x app/test)
- `CURRENT_PROJECT_VERSION` -> same build number as Info.plist (4 occurrences)

Verify both files match after editing.

#### 1.3 Update CHANGELOG.md

- Rename `## [Unreleased]` section to `## [X.Y.Z] - YYYY-MM-DD` with today's date
- Add a new empty `## [Unreleased]` section above it
- Ensure all features, fixes, and changes for this release are documented

---

### Phase 2: Code Quality

#### 2.1 Final Code Changes

Complete any remaining feature work, bug fixes, or cleanup for this release.

#### 2.2 Verify Tests Pass

```bash
cd Prompter
xcodebuild test \
  -project Prompter.xcodeproj \
  -scheme Prompter \
  -destination 'platform=macOS' \
  -quiet
```

All tests must pass before proceeding.

#### 2.3 Verify Clean Build (Release)

```bash
cd Prompter
xcodebuild build \
  -project Prompter.xcodeproj \
  -scheme Prompter \
  -configuration Release \
  -quiet
```

#### 2.4 Smoke Test Built App

Launch the Release artifact and perform a quick manual smoke test:

```bash
open Prompter/build/Release/Prompter.app
```

Smoke test checklist:
- App launches without crash, hang, or immediate error dialogs
- Load a presentation/deck and confirm content appears
- Navigate cards (next/previous/jump) and verify state updates correctly
- Start/pause/stop timer and confirm countdown behavior is correct
- Confirm key UI surfaces render correctly (menu bar, overlay, deck editor/sidebar)
- Check Console for unexpected runtime warnings/errors during core flows

---

### Phase 3: Commit & Merge

#### 3.1 Commit Release Prep Changes

Stage and commit all release prep changes on the `release-prep` branch.

#### 3.2 Push & Create PR

```bash
git push origin release-prep
gh pr create --title "Release prep vX.Y.Z" --body "Version bump, changelog, and release prep for vX.Y.Z"
```

#### 3.3 Merge to Main

Merge the PR into main. The build pipeline must run from main because the appcast URL points to the main branch.

```bash
git checkout main && git pull
```

---

### Phase 4: Build & Publish

All scripts are in `Prompter/scripts/`. Run them in order from the `Prompter/` directory:

#### 4.1 Build Release Archive

```bash
cd Prompter
./scripts/build-release.sh
```

Creates `dist/Prompter.app` and `dist/Prompter.zip`. Signs with Developer ID.

#### 4.2 Notarize with Apple

```bash
./scripts/notarize.sh
```

Submits to Apple for notarization and staples the ticket. Wait for "Accepted" status.

#### 4.3 Create DMG

```bash
./scripts/create-dmg.sh
```

Creates `dist/Prompter.dmg` with styled installer. Also notarizes and staples the DMG.

#### 4.4 Publish Release

```bash
./scripts/publish-release.sh
```

This script:
1. Signs `dist/Prompter.zip` with Sparkle EdDSA key
2. Updates `appcast.xml` with new version entry (signature, length, download URL)
3. Commits and pushes appcast to main
4. Creates GitHub Release with Prompter.zip and Prompter.dmg attached

Verify the release is live: `https://github.com/michaeltookes/prompter/releases/tag/vX.Y.Z`

---

### Phase 5: Distribution

#### 5.1 Update Homebrew Cask

The Homebrew tap lives at `~/Desktop/Current Projects/homebrew-tap/` (repo: `michaeltookes/homebrew-tap`).

1. Get the SHA256 of the new DMG:
   ```bash
   shasum -a 256 Prompter/dist/Prompter.dmg
   ```

2. Update `Casks/prompter.rb`:
   - `version` -> new version string
   - `sha256` -> new hash from step 1

3. Commit and push:
   ```bash
   cd ~/Desktop/"Current Projects"/homebrew-tap
   git add Casks/prompter.rb
   git commit -m "Update Prompter cask to vX.Y.Z"
   git push origin main
   ```

4. Verify: `brew info michaeltookes/tap/prompter` should show the new version.

#### 5.2 Verify Sparkle Appcast

```bash
curl -s https://michaeltookes.github.io/prompter/appcast.xml | head -30
```

Confirm the latest `<item>` entry has the correct version, signature, and download URL.

#### 5.3 Verify GitHub Release

```bash
gh release view vX.Y.Z
```

Confirm both Prompter.zip and Prompter.dmg are attached.

---

### Phase 6: Post-Release

#### 6.1 Update Documentation

Review and update docs that reference features, hotkeys, or behavior changed in this release:

**High priority (user-facing):**
- `README.md`
- `docs/05-user-guide/getting-started.md`
- `docs/05-user-guide/presenting.md`
- `docs/05-user-guide/troubleshooting.md`
- `docs/01-overview/key-features.md`

**Architecture/reference (if applicable):**
- `docs/02-architecture/component-diagram.md`
- `docs/03-decisions/decision-log.md`
- `docs/04-build-log/phase-3-polish.md`
- `docs/glossary.md`
- `.claude/reference-docs/UI_SPEC.md`
- `.claude/reference-docs/OVERLAY_UI_SPEC.md`

Create a branch for doc updates, commit, PR, and merge.

#### 6.2 Notify Users

For users on versions before Sparkle was configured (pre-v1.1.0), they must be manually notified to upgrade. Users on v1.1.0+ will receive updates automatically via Sparkle.

Share the release link and/or Homebrew install command:
```
brew tap michaeltookes/tap
brew upgrade --cask prompter
```

---

## Release Checklist

Use this checklist to verify every step is complete:

- [ ] Release branch created from latest main
- [ ] Version bumped in Info.plist (CFBundleShortVersionString + CFBundleVersion)
- [ ] Version bumped in project.pbxproj (MARKETING_VERSION + CURRENT_PROJECT_VERSION, 4 each)
- [ ] CHANGELOG.md updated with version and date
- [ ] All tests passing
- [ ] Clean Release build
- [ ] PR created, reviewed, and merged to main
- [ ] `build-release.sh` completed successfully
- [ ] `notarize.sh` completed (Apple accepted)
- [ ] `create-dmg.sh` completed (DMG notarized + stapled)
- [ ] `publish-release.sh` completed (appcast + GitHub Release)
- [ ] Homebrew cask updated (version + SHA256) and pushed
- [ ] Appcast accessible at raw GitHub URL
- [ ] GitHub Release has both .zip and .dmg assets
- [ ] Documentation updated for new features
- [ ] Users notified (if needed)

## Prerequisites

These must be set up before running the release pipeline:

- **Xcode**: Installed with the Prompter project buildable
- **Developer ID certificate**: Valid "Developer ID Application" certificate in Keychain
- **Apple notarization credentials**: Stored in Keychain (`notarytool` profile)
- **Sparkle EdDSA keypair**: Private key in login Keychain (generated via `generate_keys`)
- **gh CLI**: Authenticated (`gh auth status`)
- **Homebrew tap repo**: Cloned to `~/Desktop/Current Projects/homebrew-tap/`

## Important Notes

- The appcast URL points to `main` branch, so the PR **must be merged before** running `publish-release.sh`
- Sparkle signs the `.zip` file (not the `.dmg`). Both are uploaded to the GitHub Release, but only the zip is referenced in the appcast
- The EdDSA private key lives in the macOS login Keychain. A backup should be stored securely (not in the repo)
- Build numbers must always increment (never reuse a previous build number)
