#!/bin/bash

# Prompter Release Build Script
# This script builds, signs, and packages Prompter for distribution

set -e

# Configuration
APP_NAME="Prompter"
BUNDLE_ID="com.tookes.Prompter"

# Signing identity - Developer ID Application certificate
SIGNING_IDENTITY="Developer ID Application: MICHAEL ARRINGTON TOOKES (6739LM5834)"
TEAM_ID="6739LM5834"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XCODE_PROJECT="$PROJECT_ROOT/Prompter.xcodeproj"
BUILD_DIR="$PROJECT_ROOT/build"
OUTPUT_DIR="$PROJECT_ROOT/dist"
ARCHIVE_PATH="$BUILD_DIR/$APP_NAME.xcarchive"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"

# Read version from Info.plist
INFO_PLIST="$PROJECT_ROOT/Prompter/Resources/Info.plist"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_step() {
    echo -e "${GREEN}==>${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

echo_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Check for required tools
check_requirements() {
    echo_step "Checking requirements..."

    if ! command -v xcodebuild &> /dev/null; then
        echo_error "Xcode command line tools not installed"
        exit 1
    fi

    if ! command -v codesign &> /dev/null; then
        echo_error "codesign is not available"
        exit 1
    fi

    # Check if signing identity exists
    if ! security find-identity -v -p codesigning | grep -q "$TEAM_ID"; then
        echo_error "Developer ID Application certificate not found for team $TEAM_ID"
        echo "Please ensure you have created the certificate in Xcode:"
        echo "  1. Open Xcode → Settings → Accounts"
        echo "  2. Select your team and click 'Manage Certificates'"
        echo "  3. Click '+' and select 'Developer ID Application'"
        exit 1
    fi

    echo "  ✓ All requirements met"
}

# Clean previous builds
clean() {
    echo_step "Cleaning previous builds..."
    rm -rf "$BUILD_DIR"
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
    echo "  ✓ Cleaned"
}

# Build and archive the app
build() {
    echo_step "Building $APP_NAME in release mode..."

    xcodebuild archive \
        -project "$XCODE_PROJECT" \
        -scheme "$APP_NAME" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        DEVELOPMENT_TEAM="$TEAM_ID" \
        CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
        CODE_SIGN_STYLE=Manual \
        ENABLE_HARDENED_RUNTIME=YES \
        | grep -E "(BUILD|ARCHIVE|error:|warning:)" || true

    if [ ! -d "$ARCHIVE_PATH" ]; then
        echo_error "Archive failed"
        exit 1
    fi

    echo "  ✓ Archive complete"
}

# Export the archive to app bundle
export_archive() {
    echo_step "Exporting archive..."

    # Create ExportOptions.plist if it doesn't exist
    EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$OUTPUT_DIR" \
        -exportOptionsPlist "$EXPORT_OPTIONS" \
        | grep -E "(EXPORT|error:|warning:)" || true

    if [ ! -d "$APP_BUNDLE" ]; then
        echo_error "Export failed"
        exit 1
    fi

    echo "  ✓ Export complete"
}

# Verify the signature
verify() {
    echo_step "Verifying signature..."

    codesign --verify --verbose=2 "$APP_BUNDLE"
    echo ""
    codesign -dv --verbose=4 "$APP_BUNDLE" 2>&1 | grep -E "(Authority|TeamIdentifier|Signature)"

    echo "  ✓ Signature verified"
}

# Create a zip for notarization
create_zip() {
    echo_step "Creating zip for distribution..."

    cd "$OUTPUT_DIR"
    ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME.zip"

    echo "  ✓ Created: $OUTPUT_DIR/$APP_NAME.zip"
}

# Print summary
summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Build Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Output files:"
    echo "  App Bundle: $APP_BUNDLE"
    echo "  Zip File:   $OUTPUT_DIR/$APP_NAME.zip"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./scripts/notarize.sh"
    echo "  2. Wait for notarization to complete"
    echo "  3. Run: ./scripts/create-dmg.sh"
    echo "  4. Distribute the app!"
    echo ""
}

# Main
main() {
    echo ""
    echo "Prompter Release Build"
    echo "======================"
    echo "Version: $VERSION (Build $BUILD_NUMBER)"
    echo ""

    check_requirements
    clean
    build
    export_archive
    verify
    create_zip
    summary
}

main "$@"
