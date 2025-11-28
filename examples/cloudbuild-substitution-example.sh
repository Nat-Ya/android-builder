#!/bin/bash
# Example script demonstrating proper Cloud Build substitution handling
#
# This script shows the correct way to handle Cloud Build substitutions
# based on lessons learned from Android build setup.

set -e

# ❌ WRONG: Cloud Build expands ${_VAR:-default} before bash evaluates it
# This will always use the default value
# GRADLE_TASK="${_BUILD_TARGET:-assembleRelease}"

# ✅ CORRECT: Use direct substitution access
GRADLE_TASK="${_BUILD_TARGET}"

# ✅ CORRECT: Use explicit if-check for defaults
if [ -z "$GRADLE_TASK" ]; then
  GRADLE_TASK="assembleRelease"
fi

echo "Using Gradle task: $GRADLE_TASK"

# Example: Memory configuration with substitution
GRADLE_OPTS="${_GRADLE_OPTS}"
if [ -z "$GRADLE_OPTS" ]; then
  GRADLE_OPTS="-Xmx4096m -XX:MaxMetaspaceSize=1024m"
fi

echo "Using GRADLE_OPTS: $GRADLE_OPTS"

# Example: App directory with substitution
APP_DIR="${_APP_DIR}"
if [ -z "$APP_DIR" ]; then
  APP_DIR="app"
fi

echo "Using app directory: $APP_DIR"

# Example: Configure signing (keystore agnostic - can be in repo or GCS)
if [ -n "${_KEYSTORE_SECRET_NAME}" ]; then
  KEYSTORE_PASSWORD=$(gcloud secrets versions access latest --secret="${_KEYSTORE_SECRET_NAME}")
  printf '%s\n' \
    "MYAPP_RELEASE_STORE_FILE=${_KEYSTORE_FILE:-app-release.keystore}" \
    "MYAPP_RELEASE_KEY_ALIAS=${_KEY_ALIAS:-app-release-key}" \
    "MYAPP_RELEASE_STORE_PASSWORD=$KEYSTORE_PASSWORD" \
    "MYAPP_RELEASE_KEY_PASSWORD=$KEYSTORE_PASSWORD" >> android/gradle.properties
fi

# Download keystore from GCS if specified (optional)
if [ -n "${_KEYSTORE_GCS_PATH}" ]; then
  gsutil cp "${_KEYSTORE_GCS_PATH}" "android/app/${_KEYSTORE_FILE:-app-release.keystore}" || \
    echo "Keystore not in GCS, using repo version if available"
fi

# Example: Build command
# NOTE: Cloud Build runs from project root, cd into android/ subdirectory
cd "$APP_DIR/android"
./gradlew "$GRADLE_TASK" \
  --no-daemon \
  --max-workers=1 \
  --no-parallel

# Example: Find artifacts
echo "Searching for artifacts..."
artifact-finder.sh . all

