#!/bin/bash

# Prompter Flavor Build Script
# Builds the hunt or QA flavor of Prompter, ad-hoc signed, for CI hunts and
# local QA. Each flavor has its own bundle id and data folder, so it never
# reads or writes the released app's decks or settings (US-25).
#
#   hunt  com.tookes.Prompter.hunt  ~/Library/Application Support/Prompter-Hunt/
#         Debug, no event tap, no Sparkle. Data is wiped and re-seeded from
#         Contents/Resources/HuntSeed/ (copied from docs/qa/fixtures/) on every launch.
#   qa    com.tookes.Prompter.qa    ~/Library/Application Support/Prompter-QA/
#         Release, no Sparkle. The gate's signed build comes from CI (qa-build.yml);
#         this ad-hoc build is for local checks only.
#
# Usage: build-flavor-app.sh <hunt|qa> [derived-data-path]
# Default derived data: <repo>/.prowl/DerivedData (hunt) or <repo>/.qa/DerivedData (qa).
# The app is never copied to /Applications.

set -euo pipefail

FLAVOR="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$PROJECT_ROOT")"
XCODE_PROJECT="$PROJECT_ROOT/Prompter.xcodeproj"
FIXTURES_DIR="$REPO_ROOT/docs/qa/fixtures"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

case "$FLAVOR" in
    hunt)
        CONFIGURATION="Debug"
        BUNDLE_ID="com.tookes.Prompter.hunt"
        PRODUCT_NAME="Prompter"
        DERIVED_DATA="${2:-$REPO_ROOT/.prowl/DerivedData}"
        ;;
    qa)
        CONFIGURATION="Release"
        BUNDLE_ID="com.tookes.Prompter.qa"
        PRODUCT_NAME="Prompter QA"
        DERIVED_DATA="${2:-$REPO_ROOT/.qa/DerivedData}"
        ;;
    *)
        echo "Usage: $(basename "$0") <hunt|qa> [derived-data-path]" >&2
        exit 2
        ;;
esac

echo "==> Building $FLAVOR flavor ($BUNDLE_ID, $CONFIGURATION)"
xcodebuild build \
    -project "$XCODE_PROJECT" \
    -scheme Prompter \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA" \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    PRODUCT_NAME="$PRODUCT_NAME" \
    PROMPTER_FLAVOR="$FLAVOR" \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM= \
    | tail -n 20

APP_PATH="$DERIVED_DATA/Build/Products/$CONFIGURATION/$PRODUCT_NAME.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Build output not found: $APP_PATH" >&2
    exit 1
fi

if [ "$FLAVOR" = "hunt" ]; then
    SEED_DIR="$APP_PATH/Contents/Resources/HuntSeed"
    rm -rf "$SEED_DIR"
    if [ -d "$FIXTURES_DIR" ]; then
        echo "==> Copying hunt seed from docs/qa/fixtures/"
        cp -R "$FIXTURES_DIR" "$SEED_DIR"
    else
        # Fixtures arrive with US-15; until then the hunt starts from an empty deck folder.
        echo "==> No docs/qa/fixtures/ yet; hunt seed is an empty deck folder"
        mkdir -p "$SEED_DIR/Decks"
    fi
fi

echo "==> Re-signing ad hoc"
codesign --force --deep --sign - "$APP_PATH"

"$LSREGISTER" -f "$APP_PATH"

FLAVOR_IN_PLIST=$(/usr/libexec/PlistBuddy -c "Print :PrompterFlavor" "$APP_PATH/Contents/Info.plist")
BUNDLE_IN_PLIST=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Contents/Info.plist")
echo "==> Built $APP_PATH"
echo "    CFBundleIdentifier=$BUNDLE_IN_PLIST PrompterFlavor=$FLAVOR_IN_PLIST"
