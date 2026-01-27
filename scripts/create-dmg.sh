#!/bin/bash
#
# Coffee-Screen DMG Creation Script
# Creates a distributable DMG file with the app
#
# Usage:
#   ./scripts/create-dmg.sh [path/to/App.app]
#
# If no path is provided, uses build/export/Coffee-Screen.app
#

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_NAME="Coffee-Screen"
DMG_NAME="Coffee-Screen"

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

# Get app path
if [ -n "$1" ]; then
    APP_PATH="$1"
else
    APP_PATH="${BUILD_DIR}/export/${APP_NAME}.app"
fi

# Verify app exists
if [ ! -d "${APP_PATH}" ]; then
    echo_error "App not found at ${APP_PATH}"
    echo "Please build the app first: ./scripts/build.sh"
    exit 1
fi

# Get version from app
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "1.0.0")
DMG_FILENAME="${DMG_NAME}-${VERSION}.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_FILENAME}"

echo_step "Creating DMG for ${APP_NAME} v${VERSION}..."

# Clean up any existing DMG
rm -f "${DMG_PATH}"

# Create temporary directory for DMG contents
DMG_TEMP="${BUILD_DIR}/dmg-temp"
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"

# Copy app to temp directory
echo_step "Copying app..."
cp -R "${APP_PATH}" "${DMG_TEMP}/"

# Create Applications symlink
echo_step "Creating Applications symlink..."
ln -s /Applications "${DMG_TEMP}/Applications"

# Copy README if exists
if [ -f "${PROJECT_DIR}/README.md" ]; then
    echo_step "Copying README..."
    cp "${PROJECT_DIR}/README.md" "${DMG_TEMP}/"
fi

# Create DMG
echo_step "Creating DMG..."
hdiutil create -volname "${DMG_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# Clean up
rm -rf "${DMG_TEMP}"

# If app is notarized, staple the DMG too
if xcrun stapler validate "${APP_PATH}" 2>/dev/null; then
    echo_step "App is notarized, stapling DMG..."
    xcrun stapler staple "${DMG_PATH}" 2>/dev/null || echo_warning "Could not staple DMG (this is optional)"
fi

echo ""
echo_step "DMG created successfully!"
echo "  Path: ${DMG_PATH}"
echo "  Size: $(du -h "${DMG_PATH}" | cut -f1)"
echo ""
echo "To distribute:"
echo "  1. Upload to GitHub Releases"
echo "  2. Or share directly with users"
