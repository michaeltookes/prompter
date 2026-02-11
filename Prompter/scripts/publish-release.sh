#!/bin/bash

# Prompter Publish Release Script
# Signs the update with Sparkle, updates appcast, creates GitHub Release
#
# Prerequisites:
#   1. Run build-release.sh, notarize.sh, and create-dmg.sh first
#   2. EdDSA keypair must exist in the login keychain (run generate_keys once)
#   3. gh CLI must be authenticated

set -e

# Configuration
APP_NAME="Prompter"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$PROJECT_ROOT")"
OUTPUT_DIR="$PROJECT_ROOT/dist"
ZIP_FILE="$OUTPUT_DIR/$APP_NAME.zip"
DMG_FILE="$OUTPUT_DIR/$APP_NAME.dmg"
APPCAST_FILE="$REPO_ROOT/appcast.xml"
INFO_PLIST="$PROJECT_ROOT/Prompter/Resources/Info.plist"

# Read version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")

# Colors
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

# Locate Sparkle tools
find_sparkle_bin() {
    local sparkle_bin
    sparkle_bin="$(find ~/Library/Developer/Xcode/DerivedData -path "*/Prompter-*/SourcePackages/artifacts/sparkle/Sparkle/bin" -type d 2>/dev/null | head -1)"

    if [ -z "$sparkle_bin" ]; then
        echo_error "Sparkle tools not found in DerivedData."
        echo "Build the project in Xcode first to download the Sparkle SPM package."
        exit 1
    fi

    echo "$sparkle_bin"
}

# Check requirements
check_requirements() {
    echo_step "Checking requirements..."

    if [ ! -f "$ZIP_FILE" ]; then
        echo_error "Zip file not found: $ZIP_FILE"
        echo "Run build-release.sh, notarize.sh, and create-dmg.sh first"
        exit 1
    fi

    if [ ! -f "$DMG_FILE" ]; then
        echo_error "DMG file not found: $DMG_FILE"
        echo "Run create-dmg.sh first"
        exit 1
    fi

    if ! command -v gh &> /dev/null; then
        echo_error "gh CLI not installed. Install with: brew install gh"
        exit 1
    fi

    if ! gh auth status &> /dev/null 2>&1; then
        echo_error "gh CLI not authenticated. Run: gh auth login"
        exit 1
    fi

    echo "  ✓ Requirements met"
}

# Sign the zip with Sparkle's EdDSA key
sign_update() {
    echo_step "Signing update with Sparkle EdDSA key..."

    local sparkle_bin
    sparkle_bin="$(find_sparkle_bin)"

    SIGN_OUTPUT=$("$sparkle_bin/sign_update" "$ZIP_FILE" 2>&1)

    # Extract signature and length
    ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | sed 's/sparkle:edSignature="//;s/"//')
    FILE_LENGTH=$(echo "$SIGN_OUTPUT" | grep -o 'length="[^"]*"' | sed 's/length="//;s/"//')

    if [ -z "$ED_SIGNATURE" ] || [ -z "$FILE_LENGTH" ]; then
        echo_error "Failed to sign update. Output:"
        echo "$SIGN_OUTPUT"
        exit 1
    fi

    echo "  ✓ Signed (signature: ${ED_SIGNATURE:0:20}...)"
}

# Update the appcast.xml
update_appcast() {
    echo_step "Updating appcast.xml..."

    local pub_date
    pub_date="$(date -R)"
    local download_url="https://github.com/michaeltookes/prompter/releases/download/v${VERSION}/${APP_NAME}.zip"

    # Prepare a release notes header (CHANGELOG.md is not parsed here)
    local release_notes="<h2>What's New in ${VERSION}</h2>"

    # Build the new item XML
    local new_item="    <item>
      <title>Version ${VERSION}</title>
      <description><![CDATA[
        ${release_notes}
      ]]></description>
      <pubDate>${pub_date}</pubDate>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure
        url=\"${download_url}\"
        type=\"application/octet-stream\"
        sparkle:version=\"${BUILD_NUMBER}\"
        sparkle:shortVersionString=\"${VERSION}\"
        sparkle:edSignature=\"${ED_SIGNATURE}\"
        length=\"${FILE_LENGTH}\"
      />
    </item>"

    # Write the new item to a temp file, then insert before </channel>
    local item_file
    item_file="$(mktemp)"
    echo "$new_item" > "$item_file"

    local temp_file
    temp_file="$(mktemp)"

    while IFS= read -r line; do
        if [[ "$line" == *"</channel>"* ]]; then
            cat "$item_file"
        fi
        echo "$line"
    done < "$APPCAST_FILE" > "$temp_file"

    mv "$temp_file" "$APPCAST_FILE"
    rm -f "$item_file"

    echo "  ✓ Appcast updated for v${VERSION}"
}

# Commit and push the appcast
push_appcast() {
    echo_step "Committing and pushing appcast..."

    cd "$REPO_ROOT"

    # Ensure we're on main for the appcast
    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD)"

    if [ "$current_branch" != "main" ]; then
        echo_warning "Not on main branch (currently on '$current_branch')."
        echo "  The appcast must be on main for the raw GitHub URL to work."
        echo "  Skipping appcast commit — manually merge to main and push."
        return
    fi

    git add appcast.xml
    if git diff --cached --quiet; then
        echo "  ✓ No appcast changes to commit"
        return
    fi

    git commit -m "Update appcast for v${VERSION}"
    git push origin main

    echo "  ✓ Appcast pushed to main"
}

# Create GitHub Release
create_release() {
    echo_step "Creating GitHub Release v${VERSION}..."

    cd "$REPO_ROOT"

    if gh release view "v${VERSION}" >/dev/null 2>&1; then
        echo_warning "Release v${VERSION} already exists. Deleting it before recreate..."
        gh release delete "v${VERSION}" --yes
    fi

    gh release create "v${VERSION}" \
        --title "Prompter v${VERSION}" \
        --notes "See [CHANGELOG.md](CHANGELOG.md) for details." \
        "$ZIP_FILE" \
        "$DMG_FILE"

    echo "  ✓ GitHub Release created"
}

# Verify the appcast is accessible
verify() {
    echo_step "Verifying appcast accessibility..."

    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "https://michaeltookes.github.io/prompter/appcast.xml")

    if [ "$status_code" = "200" ]; then
        echo "  ✓ Appcast is accessible (HTTP $status_code)"
    else
        echo_warning "Appcast returned HTTP $status_code — it may take a few minutes to propagate"
    fi
}

# Print summary
summary() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Release Published!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Version: $VERSION (Build $BUILD_NUMBER)"
    echo ""
    echo "Assets:"
    echo "  Zip: $ZIP_FILE"
    echo "  DMG: $DMG_FILE"
    echo ""
    echo "Appcast: $APPCAST_FILE"
    echo "GitHub Release: https://github.com/michaeltookes/prompter/releases/tag/v${VERSION}"
    echo ""
    echo "Important: If you generated Sparkle keys with generate_keys, ensure your private key is stored securely."
    echo ""
}

# Main
main() {
    echo ""
    echo "Prompter Release Publisher"
    echo "========================="
    echo "Version: $VERSION (Build $BUILD_NUMBER)"
    echo ""

    check_requirements
    sign_update
    update_appcast
    push_appcast
    create_release
    verify
    summary
}

main "$@"
