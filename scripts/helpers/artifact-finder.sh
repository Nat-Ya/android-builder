#!/bin/bash
# Find Android build artifacts (APK, AAB files)
# Usage: artifact-finder.sh [search-dir] [artifact-type]
#   search-dir: Directory to search (default: current directory)
#   artifact-type: 'apk', 'aab', or 'all' (default: 'all')

set -e

SEARCH_DIR="${1:-.}"
ARTIFACT_TYPE="${2:-all}"

echo "Searching for Android build artifacts in: $SEARCH_DIR"
echo "Artifact type: $ARTIFACT_TYPE"
echo ""

FOUND_ARTIFACTS=false

if [ "$ARTIFACT_TYPE" = "apk" ] || [ "$ARTIFACT_TYPE" = "all" ]; then
    APK_FILES=$(find "$SEARCH_DIR" -name "*.apk" -type f 2>/dev/null || true)
    if [ -n "$APK_FILES" ]; then
        echo "APK files found:"
        echo "$APK_FILES" | while read -r file; do
            if [ -n "$file" ]; then
                SIZE=$(du -h "$file" | cut -f1)
                echo "  $file ($SIZE)"
                FOUND_ARTIFACTS=true
            fi
        done
        echo ""
    fi
fi

if [ "$ARTIFACT_TYPE" = "aab" ] || [ "$ARTIFACT_TYPE" = "all" ]; then
    AAB_FILES=$(find "$SEARCH_DIR" -name "*.aab" -type f 2>/dev/null || true)
    if [ -n "$AAB_FILES" ]; then
        echo "AAB files found:"
        echo "$AAB_FILES" | while read -r file; do
            if [ -n "$file" ]; then
                SIZE=$(du -h "$file" | cut -f1)
                echo "  $file ($SIZE)"
                FOUND_ARTIFACTS=true
            fi
        done
        echo ""
    fi
fi

if [ "$FOUND_ARTIFACTS" = false ]; then
    echo "No artifacts found."
    exit 1
fi

exit 0

