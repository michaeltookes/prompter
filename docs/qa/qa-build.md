# QA build: fetch and run Prompter QA.app

`.github/workflows/qa-build.yml` builds the **qa flavor** of any branch on a GitHub-hosted macOS runner for the pre-PR QA gate (PRMT-032, design 4.4). Nothing is built on the QA Mini.

| What | Value |
|---|---|
| App | `Prompter QA.app` |
| Bundle id | `com.tookes.Prompter.qa` |
| Flavor | `qa` (`PrompterFlavor` in `Info.plist`) |
| Data folder | `~/Library/Application Support/Prompter-QA/` (the released app's `Prompter/` folder is never read or written) |
| Sparkle | never started; the status item reads "Prompter QA" |
| Workflow / job | `qa-build.yml` / `qa-build` |
| Artifact | `prompter-qa-build`, kept 3 days |
| Artifact contents | `Prompter-QA-<shortsha>.zip`, `BUILD_INFO.txt`, and `UNSIGNED-QA-BUILD.txt` when ad hoc signed |

`BUILD_INFO.txt` records the ref, the full commit sha, the QA build number (the run number), the app version, the signing mode, the zip's sha256, and the designated requirement. The same commit, build number, and signing mode are stamped into the app's `Info.plist` as `PrompterGitCommit`, `PrompterQABuildNumber`, and `PrompterQASigning`.

## Start a build

```sh
gh workflow run qa-build.yml -R michaeltookes/prompter --ref <branch> -f ref=<branch>
gh run list -R michaeltookes/prompter --workflow qa-build.yml --limit 1
gh run watch <run-id> -R michaeltookes/prompter --exit-status
```

Inputs: `ref` (branch, tag, or sha; empty builds the ref the run was started on) and `require_signed` (default `false`; `true` fails the run when the signing secrets are missing instead of producing an ad-hoc build).

## Fetch and install (QA Mini)

```sh
mkdir -p ~/work/prompter-qa && cd ~/work/prompter-qa || exit 1
gh run download <run-id> -R michaeltookes/prompter -n prompter-qa-build
cat BUILD_INFO.txt
ditto -x -k Prompter-QA-*.zip ~/Applications/
```

- Install to `~/Applications/Prompter QA.app` only, never `/Applications` (that is the released app).
- `gh run download` sets no quarantine attribute, so the un-notarized app opens without a Gatekeeper prompt.
- Launch with `open -b com.tookes.Prompter.qa`; quit with `osascript -e 'quit app id "com.tookes.Prompter.qa"'` (no signals).
- Check the build before a gate run: `/usr/libexec/PlistBuddy -c 'Print :PrompterGitCommit' ~/Applications/Prompter\ QA.app/Contents/Info.plist` must match the branch head under test.

## Signed vs unsigned builds

| Mode | When | Signature | Accessibility grant |
|---|---|---|---|
| `signed` | the `qa-build` environment holds the certificate secrets | Apple Development identity (preferred) or Developer ID Application, hardened runtime, not notarized | granted once by the owner; survives every later build because the designated requirement stays the same |
| `adhoc` | the secrets are missing (today, until PRMT-011) | ad hoc, hardened runtime off | changes every build; macOS asks again. Marked **UNSIGNED QA BUILD** in the run summary, a warning annotation, `BUILD_INFO.txt`, and `UNSIGNED-QA-BUILD.txt` |

A missing secret never fails the job (unless `require_signed` is set). A secret that is present but wrong fails the job before anything is uploaded, naming the secret: bad base64 or a wrong password names `MACOS_CERTIFICATE_P12` / `MACOS_CERTIFICATE_PASSWORD`; a certificate from another team than `APPLE_TEAM_ID` names both. The temporary keychain is deleted in every case.

### Secrets (GitHub environment `qa-build`, placed by vendor-ops)

| Secret | Holds |
|---|---|
| `MACOS_CERTIFICATE_P12` | base64 of the `.p12` export of the signing certificate and its private key (owner's personal Apple Developer account) |
| `MACOS_CERTIFICATE_PASSWORD` | the password of that `.p12` |
| `APPLE_TEAM_ID` | that account's team id; optional for the build, used to check the certificate's team |

Same names as Sentwise's `release.yml` and Prompter's planned `release` environment (design 4.5), with Prompter's own values. ContainerBar's CB-116 lane signs on the Mini from a local keychain and has no CI secrets, so no names overlap there.

## Reuse from another workflow (prowl-qa, PRMT-010)

```yaml
jobs:
  qa-build:
    uses: ./.github/workflows/qa-build.yml
    with:
      ref: ${{ github.event.pull_request.head.sha }}
  hunt:
    needs: qa-build
    runs-on: [self-hosted, macOS]
    steps:
      - uses: actions/download-artifact@v4   # pin to a sha
        with:
          name: ${{ needs.qa-build.outputs.artifact-name }}   # prompter-qa-build
```

Outputs: `artifact-name`, `zip-name`, `sha`, `build-number`, `signing` (`signed` or `adhoc`). The environment's secrets reach the called job directly (the job declares `environment: qa-build`); callers pass no secrets. Pull requests from forks get no environment secrets and therefore an ad-hoc build.
