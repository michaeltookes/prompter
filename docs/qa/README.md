# QA for Prompter

Three layers check a change before and after it merges. This page covers the
first one that drives the real app, Prowl QA on pull requests, and points at the
others.

| Layer | Where | What | Status |
|---|---|---|---|
| Swift CI (`swift-ci.yml`) | GitHub-hosted macOS | Build & Test (unit tests), SwiftLint | live (PRMT-008) |
| Prowl QA (`prowl-qa.yml`) | hosted build + self-hosted runner on the QA Mini | Prowl hunts against the hunt flavor | live (PRMT-010) |
| QA build (`qa-build.yml`) | GitHub-hosted macOS | Developer-ID-signed `qa` flavor for the pre-PR QA gate | PRMT-032 |
| Daily pass | QA Mini, scheduled agent | the TC-PR cases against the installed release | PRMT-022 to PRMT-025 |

## Prowl QA on pull requests

`.github/workflows/prowl-qa.yml` runs on every pull request to `main` whose head
branch is in this repository and on `workflow_dispatch` once the file is on
`main`.

### Security boundary for the Mini (SEC-007)

Fork code is untrusted input for a persistent self-hosted GUI runner. The
workflow's same-repo `if:` conditions are **not** the boundary: a
`pull_request` run uses the PR's own copy of the workflow, so a fork PR can
remove them. The boundary is two settings outside the PR's control:

1. **The `mini-runner` environment** on the `hunt` job (created by vendor-ops
   with a required reviewer and a branch policy). A run reaches the Mini only
   after a reviewer approves it, unless it comes from a same-repo branch the
   branch policy covers. GitHub holds the job before handing it to any runner,
   so nothing runs on the Mini before the gate, including PR-controlled files
   such as `Prompter/scripts/prowl-qa-gui-segment.sh` and `.prowl/`; the job's
   first step only runs after it.
2. **The repository setting "require approval for all outside
   collaborators"** for fork pull request workflows.

The `if:` conditions stay as defence in depth.

### Jobs

1. **Build hunt app** (`build-hunt`, GitHub-hosted `macos-15`, the same Xcode
   pin as Swift CI). Runs `Prompter/scripts/build-hunt-app.sh`, which builds the
   Debug app with `PRODUCT_BUNDLE_IDENTIFIER=com.tookes.Prompter.hunt` and
   `PROMPTER_FLAVOR=hunt`, copies `docs/qa/fixtures/` into
   `Contents/Resources/HuntSeed/` (an empty deck folder until PRMT-021), and
   signs it ad hoc. The job checks the bundle id and flavor, then uploads
   `Prompter-Hunt-<shortsha>.zip` (kept 3 days).
2. **Prowl hunts** (`hunt`, environment `mini-runner`, the self-hosted runner
   `lucius-mac-mini-prompter`, labels `self-hosted, macOS, ARM64`). In order:
   - fails at once, naming the variable, if `QA_DEVICE_LOCK_DIR` or
     `QA_DEVICE_LOCK_TOOL` is unset in the runner's environment;
   - checks out Prowl at `PROWL_VERSION` (ContainerBar's pin, 0.1.8), builds and
     links the CLI, builds the `prowl-macdriver` helper;
   - Accessibility preflight (`prowl-macdriver check`);
   - downloads the hunt app into `.prowl/DerivedData/Build/Products/Debug/`,
     checks its bundle id, clears quarantine, registers it with Launch
     Services. It is never copied to `/Applications`;
   - **GUI segment under the desktop lock**: one `device_lock.py` call runs
     `Prompter/scripts/prowl-qa-gui-segment.sh`, which runs `prowl ci --junit`
     and then, whatever the result, quits the hunt app with
     an `osascript` quit bounded by a 5 s AppleScript timeout and a 5 s poll,
     then waits up to 5 s for the app to exit (no signals; cleanup stays under
     15 s, inside the lock call's 20 s grace). While another desktop pass or hourly check holds the
     lock (exit 75) the step retries every 30 s for up to 20 minutes, then
     fails with `desktop-busy`. The segment itself is limited to 25 minutes;
     if the lock tool stops it (timeout or a cancelled job), the script's
     TERM/INT/EXIT trap still quits the hunt app before the lock is released
     (`--grace 20` leaves time for the quit);
   - read-only checks after the segment: warns if the hunt app is still
     running, fails if a hunt build is in `/Applications`;
   - moves every `screenshots/` folder to `~/prowl-qa-screenshots/prompter/<run>-<attempt>/`
     on the runner (kept 14 days) and uploads the rest of `.prowl/runs/` (run
     reports, JUnit, `ci-logs/prowl-ci.log`) as `prowl-runs-<run>-<attempt>`,
     kept 14 days. Screenshots are not uploaded because this repo is public and
     the macOS target falls back to a full-screen capture of the runner's
     desktop when the app has no window.
3. **Prowl QA** (`gate`, ubuntu). The required check. It runs whatever happened
   above and passes only when both jobs succeeded: GitHub counts a skipped job
   as satisfied for a required check, and a failed build skips `hunt`, so
   branch protection requires this job, not the other two.

### What counts as green

Only a completed, successful **Prowl QA** (gate) check. A queued check (the Mini's
runner offline: GitHub keeps the job pending for up to 24 hours), a cancelled
run, `desktop-busy`, a failed hunt build, or a missing artifact is not green,
and the merge checklist treats it as not green.

### Overlap with other users of the Mini

- Runs for the same PR share a concurrency group without cancelling, so a new
  push waits for the running hunt rather than interrupting it inside the lock.
- The runner is repository-scoped and takes one job at a time.
- The desktop lock serializes Prompter's hunts with the Sentwise and
  ContainerBar passes and hourly checks; the hourly monitors skip while it is
  held.

### Hunts

Hunts live in `.prowl/hunts/` and are open-and-assert; `.prowl/config.yml`
forbids selectors that would request Screen Recording, reach the network,
delete, or quit (see `.prowl/README.md`).

| Hunt | Checks | Runs |
|---|---|---|
| `status-item` | the status item exists; its menu opens with Open Deck Editor…, Protected Mode, Presentation Timer (exact labels) | now |
| `editor-opens-seed` | the editor opens on the five-card fixture deck | after PRMT-021 |
| `overlay-toggle` | Show Overlay opens the overlay on `card=1/5` | after PRMT-021 |
| `card-select` | selecting `editorCardRow-2` moves the overlay to `card=3/5` | after PRMT-021 |
| `protected-toggle` | Protected Mode goes `off` and back `on` | after PRMT-021 |

The four later hunts wait in `.prowl/pending-hunts/` (Prowl only reads
`.prowl/hunts/`) because they need the accessibility identifiers, the overlay
state string, and the fixture deck that PRMT-021 adds. The PRMT-021 branch moves
them into `.prowl/hunts/`.

### Runner preconditions (in place as of 2026-10-16)

- `lucius-mac-mini-prompter` registered for `michaeltookes/prompter` on the QA
  Mini, with `QA_DEVICE_LOCK_DIR` and `QA_DEVICE_LOCK_TOOL` in its `.env`.
- Accessibility granted to the runner's host process (the runner service's
  bundled `node`). If it is ever revoked, the preflight step fails with a
  message and nothing is launched.

### Running the hunts locally

See `.prowl/README.md`. Hunts are tests: per the factory rule they run on the
QA Mini or in CI, not on a developer Mac. The hunt flavor cannot touch an
installed app's data either way.
