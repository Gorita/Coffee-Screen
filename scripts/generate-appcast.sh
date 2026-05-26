#!/bin/bash
#
# Generate appcast.xml from .dmg files in build directory using Sparkle.
# Signs each release with the EdDSA private key stored in macOS Keychain.
#
# Usage:
#   ./scripts/generate-appcast.sh [release-dir]
#
# Default release-dir is ./build/

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="${1:-${PROJECT_DIR}/build}"

# Sparkle SwiftPM artifact path (DerivedData)
SPARKLE_BIN=$(find ~/Library/Developer/Xcode/DerivedData -path "*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast" 2>/dev/null | head -n 1)

if [ -z "${SPARKLE_BIN}" ]; then
    echo "Error: generate_appcast not found." >&2
    echo "Open the project in Xcode once so SwiftPM downloads Sparkle artifacts." >&2
    exit 1
fi

if [ ! -d "${RELEASE_DIR}" ]; then
    echo "Error: release directory not found: ${RELEASE_DIR}" >&2
    exit 1
fi

echo "Generating appcast in: ${RELEASE_DIR}"
"${SPARKLE_BIN}" "${RELEASE_DIR}"

echo ""
echo "Done. Output: ${RELEASE_DIR}/appcast.xml"
