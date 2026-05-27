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

# ─────────────────────────────────────────────────────────────
# Pre-flight checks
# Abort if the git state would produce an inconsistent release
# (e.g. tag pointing at a commit that doesn't match the built binary).
# ─────────────────────────────────────────────────────────────
echo_header "Pre-flight checks"

cd "${PROJECT_DIR}"

# 1. Branch must be main
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "${BRANCH}" != "main" ]; then
    echo -e "${RED}Error:${NC} not on main branch (current: ${BRANCH})." >&2
    echo "Switch to main before releasing." >&2
    exit 1
fi
echo_step "On main branch."

# 2. Working tree must be clean
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}Error:${NC} working tree has uncommitted changes:" >&2
    git status --short >&2
    echo "" >&2
    echo "Commit or stash before releasing." >&2
    exit 1
fi
echo_step "Working tree clean."

# 3. Local main must match origin/main (no unpushed commits, no fall-behind)
git fetch origin main --quiet
LOCAL_HEAD=$(git rev-parse HEAD)
REMOTE_HEAD=$(git rev-parse origin/main)
if [ "${LOCAL_HEAD}" != "${REMOTE_HEAD}" ]; then
    echo -e "${RED}Error:${NC} local main is not in sync with origin/main." >&2
    echo "  Local:  ${LOCAL_HEAD}" >&2
    echo "  Remote: ${REMOTE_HEAD}" >&2
    echo "" >&2
    echo "Push (or pull) before releasing — otherwise a tag/release " >&2
    echo "created here will point at an unpublished commit." >&2
    exit 1
fi
echo_step "Local main in sync with origin/main."

# 4. Version sanity: the latest commit message should mention the
#    MARKETING_VERSION about to be released. This catches the case
#    where project.yml was bumped but not committed.
VERSION=$(grep -E '^[[:space:]]+MARKETING_VERSION:' project.yml | sed -E 's/.*"([^"]+)".*/\1/' | head -n 1)
if [ -z "${VERSION}" ]; then
    echo -e "${RED}Error:${NC} could not read MARKETING_VERSION from project.yml" >&2
    exit 1
fi

LAST_COMMIT_MSG=$(git log -1 --format=%s)
if [[ "${LAST_COMMIT_MSG}" != *"${VERSION}"* ]]; then
    echo -e "${RED}Warning:${NC} latest commit doesn't mention version ${VERSION}." >&2
    echo "  Latest commit: ${LAST_COMMIT_MSG}" >&2
    echo "" >&2
    echo "If you're releasing ${VERSION}, the bump commit is missing." >&2
    echo "Create a 'chore: bump version to ${VERSION}' commit and push, then retry." >&2
    read -r -p "Continue anyway? [y/N] " ans
    [[ "${ans}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
fi
echo_step "Version sanity OK (releasing ${VERSION})."

# Step 1: Build
echo_header "Step 1: Build"
"${SCRIPTS_DIR}/build.sh"

# Step 2: Create DMG
echo_header "Step 2: Create DMG"
"${SCRIPTS_DIR}/create-dmg.sh"

# Step 3: Generate Appcast
echo_header "Step 3: Generate Appcast"
"${SCRIPTS_DIR}/generate-appcast.sh"

# Done
echo_header "Release Complete!"

APP_PATH="${PROJECT_DIR}/build/export/Coffee-Screen.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "1.0.0")

echo "Version: ${VERSION}"
echo "DMG:     build/Coffee-Screen-${VERSION}.dmg"
echo "Appcast: build/appcast.xml"
echo ""
echo "Note: This app is unsigned. Users will need to:"
echo "  1. Right-click the app → Open"
echo "  2. Or allow in System Settings → Privacy & Security"
echo ""
echo "To publish to GitHub Releases:"
echo "  gh release create v${VERSION} build/Coffee-Screen-${VERSION}.dmg build/appcast.xml --title \"v${VERSION}\" --notes \"Release notes here\""
