#!/bin/bash
#
# Coffee-Screen Release Script
# Build and create DMG for distribution (unsigned)
#
# Usage:
#   ./scripts/release.sh
#

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${PROJECT_DIR}/scripts"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

echo_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

echo_step() {
    echo -e "${GREEN}==>${NC} $1"
}

echo_header "Coffee-Screen Release (Unsigned)"

# Step 1: Build
echo_header "Step 1: Build"
"${SCRIPTS_DIR}/build.sh"

# Step 2: Create DMG
echo_header "Step 2: Create DMG"
"${SCRIPTS_DIR}/create-dmg.sh"

# Done
echo_header "Release Complete!"

APP_PATH="${PROJECT_DIR}/build/export/Coffee-Screen.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "1.0.0")

echo "Version: ${VERSION}"
echo "DMG:     build/Coffee-Screen-${VERSION}.dmg"
echo ""
echo "Note: This app is unsigned. Users will need to:"
echo "  1. Right-click the app → Open"
echo "  2. Or allow in System Settings → Privacy & Security"
