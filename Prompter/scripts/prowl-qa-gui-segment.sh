#!/bin/bash

# Prowl QA GUI segment (prowl-qa.yml, design 4.3, US-4 AC4/AC5).
#
# Runs inside one device_lock.py call on the self-hosted Mini runner: the hunts
# and the hunt-app quit both happen while the host-wide desktop lock is held.
# The hunt app is never launched outside this script.
#
#   1. prowl ci --junit against the prebuilt hunt bundle (.prowl/config.yml)
#   2. whatever the result, quit the hunt app through Apple Events (no signals)
#      and wait up to 10 s for it to exit
#   3. exit with the hunt result
#
# device_lock.py reserves exit 75 (busy) and 124 (timeout) and passes the
# command's own code through, so a hunt result of 75 or 124 is mapped to 1:
# the caller's retry loop must never mistake a failed hunt for a busy desktop.
#
# Usage: prowl-qa-gui-segment.sh <log-dir>

set -uo pipefail

LOG_DIR="${1:?usage: prowl-qa-gui-segment.sh <log-dir>}"
HUNT_BUNDLE_ID="com.tookes.Prompter.hunt"
mkdir -p "$LOG_DIR"

echo "==> Desktop lock held; running hunts"
prowl ci --junit 2>&1 | tee "$LOG_DIR/prowl-ci.log"
status=${PIPESTATUS[0]}
echo "==> prowl ci exited $status"

echo "==> Quitting the hunt app ($HUNT_BUNDLE_ID)"
# Only send the quit when the app is running, so osascript never launches it.
if osascript -e "application id \"$HUNT_BUNDLE_ID\" is running" 2>/dev/null | grep -q true; then
    osascript -e "quit app id \"$HUNT_BUNDLE_ID\"" >>"$LOG_DIR/quit.log" 2>&1 || true
    for _ in $(seq 1 10); do
        if ! osascript -e "application id \"$HUNT_BUNDLE_ID\" is running" 2>/dev/null | grep -q true; then
            break
        fi
        sleep 1
    done
    if osascript -e "application id \"$HUNT_BUNDLE_ID\" is running" 2>/dev/null | grep -q true; then
        echo "::warning::The hunt app ($HUNT_BUNDLE_ID) is still running 10 s after quit. It is not signalled; check the runner."
    else
        echo "==> Hunt app quit"
    fi
else
    echo "==> Hunt app not running (Prowl already quit it)"
fi

if [ "$status" -eq 75 ] || [ "$status" -eq 124 ]; then
    echo "==> Mapping hunt exit $status to 1 (75 and 124 are reserved by device_lock.py)"
    status=1
fi
exit "$status"
