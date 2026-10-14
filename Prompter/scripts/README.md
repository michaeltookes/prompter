# Release scripts

The scripts in this folder build, sign, notarize, package, and publish Prompter. They carry no personal data: the signing identity, the Apple Developer team, the Apple ID, and the notarization credentials come from the environment.

| Script | Purpose | Requires |
|--------|---------|----------|
| `build-release.sh` | Archive, export, verify, zip | `SIGNING_IDENTITY`, `APPLE_TEAM_ID` |
| `notarize.sh` | Notarize and staple the app, re-zip | Notary credentials (below) |
| `create-dmg.sh` | Styled DMG, sign, notarize, staple | `SIGNING_IDENTITY`, notary credentials |
| `publish-release.sh` | Sparkle signature, appcast, GitHub Release | `gh` auth and the Sparkle key in the login keychain (no identity variables) |

Run them from `Prompter/` in order: `./scripts/build-release.sh`, `./scripts/notarize.sh`, `./scripts/create-dmg.sh`, `./scripts/publish-release.sh`.

## Flavor builds (no signing variables)

| Script | Purpose |
|--------|---------|
| `build-flavor-app.sh <hunt\|qa>` | Ad-hoc signed hunt (`com.tookes.Prompter.hunt`, Debug, seeded from `docs/qa/fixtures/`) or QA (`com.tookes.Prompter.qa`, Release) build. It always sets `PROMPTER_FLAVOR` and the matching bundle id together: a flavor under any other bundle id runs as production. Never installed to `/Applications`. |
| `build-hunt-app.sh` | `build-flavor-app.sh hunt` into `<repo>/.prowl/DerivedData` (prowl-qa entry point) |

These need no `release-env.sh` variables; the signed QA build for the pre-PR gate comes from CI.

## Variables

| Variable | Used for | Example value |
|----------|----------|---------------|
| `SIGNING_IDENTITY` | `codesign` / `CODE_SIGN_IDENTITY` | `Developer ID Application: <Your Name> (<TEAMID>)` |
| `APPLE_TEAM_ID` | `DEVELOPMENT_TEAM`, the export options `teamID`, the certificate check | `<TEAMID>` |
| `NOTARY_PROFILE` | Local notarization: name of a `notarytool` keychain profile | `<profile-name>` |
| `APPLE_ID` | Apple ID for notarization (CI), or to create the keychain profile the first time | `<apple-id-email>` |
| `NOTARY_APP_SPECIFIC_PASSWORD` | CI notarization: app-specific password for `APPLE_ID` | (secret) |

Notary credentials are one of:

- **Local:** `NOTARY_PROFILE`. If the profile does not exist yet, `notarize.sh` creates it interactively with `xcrun notarytool store-credentials`, which then also needs `APPLE_ID` and `APPLE_TEAM_ID`.
- **CI:** `NOTARY_APP_SPECIFIC_PASSWORD` with `APPLE_ID` and `APPLE_TEAM_ID` (the `release` environment secrets of the same names).

If both are set, `NOTARY_PROFILE` wins.

## Local runs

Export the variables in your shell, or copy `.env.example` to `.env.local` in this folder and fill it in. `.env.local` is gitignored; values already exported in the shell take precedence over it. Never commit real values.

If a required variable is missing, the script stops before building, signing, or notarizing anything, exits non-zero, and names the variable.

## Previously hardcoded values

Before this change, the owner's Apple ID email, the team-qualified Developer ID identity string, the team ID, and the keychain profile name were hardcoded in these scripts and in `ExportOptions.plist`. They remain in the public git history and must be treated as exposed. None is a credential (no password or key was ever committed), so nothing needs rotating. Rewriting the public history to remove them would break every clone and is the owner's decision; it has not been done.
