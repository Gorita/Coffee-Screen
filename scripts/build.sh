#!/bin/bash
#
# Coffee-Screen Build Script
# Builds the app for distribution (unsigned)
#
# Usage:
#   ./scripts/build.sh
#

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_NAME="Coffee-Screen"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo_step() {
    echo -e "${GREEN}==>${NC} $1"
}

echo_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Clean build directory
echo_step "Cleaning build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Generate Xcode project (if using XcodeGen)
if [ -f "${PROJECT_DIR}/project.yml" ]; then
    echo_step "Generating Xcode project..."
    cd "${PROJECT_DIR}"
    xcodegen generate
fi

# Build
echo_step "Building application..."
xcodebuild -project "${PROJECT_DIR}/CoffeeScreen.xcodeproj" \
    -scheme "CoffeeScreen" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build

# Copy app to export directory
echo_step "Copying app..."
mkdir -p "${BUILD_DIR}/export"
cp -R "${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app" "${BUILD_DIR}/export/"

APP_PATH="${BUILD_DIR}/export/${APP_NAME}.app"

echo ""
echo_step "Build complete!"
echo "  App: ${APP_PATH}"
echo ""
echo "Next: ./scripts/create-dmg.sh"
