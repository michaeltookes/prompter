#!/bin/bash

# Prompter DMG Creation Script
# Creates a styled DMG with app icon and Applications folder shortcut

set -e

# Configuration
APP_NAME="Prompter"
SIGNING_IDENTITY="Developer ID Application: MICHAEL ARRINGTON TOOKES (6739LM5834)"
KEYCHAIN_PROFILE="Prompter-Notarize"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/dist"
APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
DMG_OUTPUT="$OUTPUT_DIR/$APP_NAME.dmg"
BACKGROUND_IMG="$OUTPUT_DIR/dmg-background.png"
ICON_FILE="$PROJECT_ROOT/Prompter/Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512.png"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_step() {
    echo -e "${GREEN}==>${NC} $1"
}

echo_error() {
    echo -e "${RED}Error:${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Check requirements
check_requirements() {
    echo_step "Checking requirements..."

    if ! command -v create-dmg &> /dev/null; then
        echo_error "create-dmg is not installed."
        echo "Install with: brew install create-dmg"
        exit 1
    fi

    if [ ! -d "$APP_BUNDLE" ]; then
        echo_error "App bundle not found at $APP_BUNDLE"
        echo "Run ./scripts/build-release.sh and ./scripts/notarize.sh first"
        exit 1
    fi

    echo "  ✓ Requirements met"
}

# Generate DMG background image
generate_background() {
    echo_step "Generating DMG background..."

    # Check if the Swift script exists and Swift is available, otherwise generate with Python
    if [ -f "$SCRIPT_DIR/generate-dmg-background.swift" ] && command -v swift >/dev/null 2>&1; then
        swift "$SCRIPT_DIR/generate-dmg-background.swift"
    else
        # Simple Python fallback to create background
        BACKGROUND_IMG="$BACKGROUND_IMG" python3 << 'EOF'
import os
from PIL import Image, ImageDraw

# Read output path from environment
output_path = os.environ.get("BACKGROUND_IMG")
if not output_path:
    raise RuntimeError("BACKGROUND_IMG is not set")

# Create 660x400 background
width, height = 660, 400
img = Image.new('RGB', (width, height), (245, 245, 245))
draw = ImageDraw.Draw(img)

# Draw arrow from app icon position to Applications folder
# App at (170, 190), Applications at (490, 190)
arrow_y = 280
arrow_start_x = 220
arrow_end_x = 440

# Draw arrow line
draw.line([(arrow_start_x, arrow_y), (arrow_end_x - 15, arrow_y)], fill=(100, 100, 100), width=3)

# Draw arrow head
draw.polygon([
    (arrow_end_x, arrow_y),
    (arrow_end_x - 15, arrow_y - 10),
    (arrow_end_x - 15, arrow_y + 10)
], fill=(100, 100, 100))

img.save(output_path)
print("Background generated")
EOF
    fi

    echo "  ✓ Background generated"
}

# Create styled DMG
create_styled_dmg() {
    echo_step "Creating styled DMG..."

    # Remove existing DMG
    rm -f "$DMG_OUTPUT"

    # Create the DMG with create-dmg
    create-dmg \
        --volname "$APP_NAME" \
        --volicon "$ICON_FILE" \
        --background "$BACKGROUND_IMG" \
        --window-pos 200 120 \
        --window-size 660 400 \
        --icon-size 128 \
        --icon "$APP_NAME.app" 170 190 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 490 190 \
        "$DMG_OUTPUT" \
        "$APP_BUNDLE" \
        || true  # create-dmg returns non-zero even on success sometimes

    if [ ! -f "$DMG_OUTPUT" ]; then
        echo_error "Failed to create DMG"
        exit 1
    fi

    echo "  ✓ DMG created"
}

# Sign the DMG
sign_dmg() {
    echo_step "Signing DMG..."

    codesign --force --sign "$SIGNING_IDENTITY" "$DMG_OUTPUT"

    echo "  ✓ DMG signed"
}

# Notarize the DMG
notarize_dmg() {
    echo_step "Notarizing DMG..."
    echo "  This may take several minutes..."

    xcrun notarytool submit "$DMG_OUTPUT" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait

    echo "  ✓ DMG notarized"
}

# Staple the DMG
staple_dmg() {
    echo_step "Stapling notarization ticket to DMG..."

    xcrun stapler staple "$DMG_OUTPUT"

    echo "  ✓ DMG stapled"
}

# Verify DMG
verify_dmg() {
    echo_step "Verifying DMG..."

    spctl --assess --type open --context context:primary-signature "$DMG_OUTPUT" 2>&1 || true
    codesign --verify --verbose "$DMG_OUTPUT"

    echo "  ✓ DMG verified"
}

# Print summary
summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}DMG Created Successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Output: $DMG_OUTPUT"
    echo ""
    echo "The DMG is signed, notarized, and ready for distribution!"
    echo ""
    echo "Next steps:"
    echo "  1. Open the DMG to verify it looks correct"
    echo "  2. Create a GitHub release with the DMG and ZIP"
    echo ""
}

# Main
main() {
    echo ""
    echo "Prompter DMG Creation"
    echo "====================="
    echo ""

    check_requirements
    generate_background
    create_styled_dmg
    sign_dmg
    notarize_dmg
    staple_dmg
    verify_dmg
    summary
}

main "$@"
