#!/bin/bash

# Builds the hunt flavor into <repo>/.prowl/DerivedData for Prowl hunts (prowl-qa).
# See build-flavor-app.sh.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/build-flavor-app.sh" hunt "$@"
