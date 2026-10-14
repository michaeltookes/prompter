#!/bin/bash
# shellcheck shell=bash disable=SC2034 # NOTARY_AUTH_ARGS is read by the sourcing scripts

# Shared release environment for the Prompter release scripts.
#
# Sourced (not executed) by build-release.sh, notarize.sh, and create-dmg.sh.
# Identity and credentials come from the environment only; nothing personal
# is committed. See Prompter/scripts/README.md for the variables to export.
#
# Local runs may put the exports in Prompter/scripts/.env.local (gitignored;
# copy .env.example). Variables already set in the environment win over it.

RELEASE_ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env.local if present, without overriding variables already exported.
load_release_env() {
    local env_file="$RELEASE_ENV_DIR/.env.local"
    [ -f "$env_file" ] || return 0

    local line key value
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line#export }"
        case "$line" in
            ''|'#'*) continue ;;
        esac
        key="${line%%=*}"
        value="${line#*=}"
        [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
        # Strip one level of matching surrounding quotes.
        if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
            value="${BASH_REMATCH[1]}"
        fi
        if [ -z "${!key:-}" ]; then
            export "$key=$value"
        fi
    done < "$env_file"
}

release_env_fail() {
    echo -e "\033[0;31mError:\033[0m $1" >&2
    echo "See Prompter/scripts/README.md for the variables to export (or put them in Prompter/scripts/.env.local)." >&2
    exit 1
}

# require_env VAR... — exit non-zero naming every unset or empty variable.
require_env() {
    local missing=()
    local name
    for name in "$@"; do
        if [ -z "${!name:-}" ]; then
            missing+=("$name")
        fi
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        release_env_fail "missing required environment variable(s): ${missing[*]}"
    fi
}

# require_notary_env — notarytool needs either a keychain profile (local) or
# an Apple ID + team + app-specific password (CI). Sets NOTARY_AUTH_ARGS.
NOTARY_AUTH_ARGS=()
require_notary_env() {
    if [ -n "${NOTARY_PROFILE:-}" ]; then
        NOTARY_AUTH_ARGS=(--keychain-profile "$NOTARY_PROFILE")
    elif [ -n "${NOTARY_APP_SPECIFIC_PASSWORD:-}" ]; then
        require_env APPLE_ID APPLE_TEAM_ID
        NOTARY_AUTH_ARGS=(--apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$NOTARY_APP_SPECIFIC_PASSWORD")
    else
        release_env_fail "missing notarization credentials: set NOTARY_PROFILE (keychain profile, local) or NOTARY_APP_SPECIFIC_PASSWORD with APPLE_ID and APPLE_TEAM_ID (CI)"
    fi
}

load_release_env
