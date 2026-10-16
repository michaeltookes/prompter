# Prowl hunts for Prompter (macOS target)

End-to-end hunts that drive the real Prompter menu bar app through macOS
Accessibility with Prowl's `macos` target. CI runs them on pull requests
(`.github/workflows/prowl-qa.yml`; overview in `docs/qa/README.md`).

## The app under test

`.prowl/config.yml` points at `.prowl/DerivedData/Build/Products/Debug/Prompter.app`,
the **hunt flavor** (US-25): bundle id `com.tookes.Prompter.hunt`, data in
`~/Library/Application Support/Prompter-Hunt/`, wiped and re-seeded from
`Contents/Resources/HuntSeed/` on every launch, no event tap, no Sparkle, its
own defaults domain. It never reads or writes the installed app's decks.

In CI that bundle is built on a GitHub-hosted runner and unpacked here; the
config has no build command, so Prowl never runs `xcodebuild`. Locally,
`Prompter/scripts/build-hunt-app.sh` builds it in place.

## Local setup

1. Clone `prowl-tools/prowl` at the tag pinned in the workflow
   (`PROWL_VERSION`), then `npm install && npm run build && npm link`.
2. In that clone, `cd macdriver && swift build -c release`; set
   `PROWL_MACDRIVER_BIN` if the CLI cannot find the helper.
3. Grant **Accessibility** (and Screen Recording, for failure screenshots) to
   the terminal you run `prowl` from.
4. `Prompter/scripts/build-hunt-app.sh`

```bash
prowl list
prowl run status-item
prowl ci --junit        # the full suite, as CI runs it
osascript -e 'quit app id "com.tookes.Prompter.hunt"'
```

Run output lands in `.prowl/runs/` (gitignored).

## Selector dialect (Prowl 0.1.8)

- `statusItem`: press the app's status item and leave its menu open.
- `id=<identifier>`: accessibility identifier, exact. Identifiers per design
  3.3 arrive with PRMT-021.
- `role=<role>[name="..."]`: AX role plus a substring of the title,
  description, or **value**. Hunts use `role=menuitem[name="Open Deck Editor"]`
  for menu titles and `role=window[name="card=1/5;"]` to read the overlay's
  state string (design 3.3), since 0.1.8 has no value assertion and `text=` is
  forbidden.
- `label="..."`: exact label, click steps only (assertions become `text=`).
- `menu=` and `text=` are forbidden by `config.yml`.

## Writing hunts

Open-and-assert only. `config.yml` forbids Check for Updates, Test Protected
Mode, the capture-test run button (Screen Recording), deck deletion, and Quit.
Add an identifier to the view rather than matching visible text. Hunts that
need identifiers not yet in the app wait in `.prowl/pending-hunts/`.
