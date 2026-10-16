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
# The quit also runs from a trap on TERM, INT, and EXIT. device_lock.py sends
# SIGTERM to this process group when its --timeout expires or the job is
# cancelled; the hunt app is launched through Launch Services, outside this
# process group, so without the trap it would keep running after the lock is
# released. The caller passes --grace long enough for the quit and its wait.
#
# device_lock.py reserves exit 75 (busy) and 124 (timeout) and passes the
# command's own code through, so a hunt result of 75 or 124 is mapped to 1:
# the caller's retry loop must never mistake a failed hunt for a busy desktop.
#
# Usage: prowl-qa-gui-segment.sh <log-dir>

set -uo pipefail

LOG_DIR="${1:?usage: prowl-qa-gui-segment.sh <log-dir>}"
HUNT_BUNDLE_ID="com.tookes.Prompter.hunt"
QUIT_WAIT_SECONDS=10
mkdir -p "$LOG_DIR"

hunt_app_running() {
    # "is running" never launches the app.
    osascript -e "application id \"$HUNT_BUNDLE_ID\" is running" 2>/dev/null | grep -q true
}

quit_done=0
quit_hunt_app() {
    [ "$quit_done" -eq 1 ] && return 0
    quit_done=1
    echo "==> Quitting the hunt app ($HUNT_BUNDLE_ID)"
    if ! hunt_app_running; then
        echo "==> Hunt app not running (Prowl already quit it)"
        return 0
    fi
    osascript -e "quit app id \"$HUNT_BUNDLE_ID\"" >>"$LOG_DIR/quit.log" 2>&1 || true
    for _ in $(seq 1 "$QUIT_WAIT_SECONDS"); do
        hunt_app_running || break
        sleep 1
    done
    if hunt_app_running; then
        echo "::warning::The hunt app ($HUNT_BUNDLE_ID) is still running ${QUIT_WAIT_SECONDS} s after quit. It is not signalled; check the runner."
    else
        echo "==> Hunt app quit"
    fi
}

# shellcheck disable=SC2329  # invoked from the traps below
on_terminate() {
    echo "==> Segment interrupted ($1); quitting the hunt app before the lock is released"
    [ -n "${hunt_pid:-}" ] && wait "$hunt_pid" 2>/dev/null
    quit_hunt_app
    exit 1
}
trap 'on_terminate TERM' TERM
trap 'on_terminate INT' INT
trap 'quit_hunt_app' EXIT

echo "==> Desktop lock held; running hunts"
# In the background so `wait` returns as soon as a trapped signal arrives.
( prowl ci --junit 2>&1 | tee "$LOG_DIR/prowl-ci.log"; exit "${PIPESTATUS[0]}" ) &
hunt_pid=$!
wait "$hunt_pid"
status=$?
hunt_pid=""
echo "==> prowl ci exited $status"

quit_hunt_app

if [ "$status" -eq 75 ] || [ "$status" -eq 124 ]; then
    echo "==> Mapping hunt exit $status to 1 (75 and 124 are reserved by device_lock.py)"
    status=1
fi
exit "$status"
