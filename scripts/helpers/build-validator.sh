#!/bin/bash
# Validate build target and environment for Android builds
# Usage: build-validator.sh [gradle-task]

set -e

GRADLE_TASK="${1:-assembleRelease}"

echo "=== Build Environment Validation ==="
echo ""

# Check Java
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "✓ Java: $JAVA_VERSION"
    
    # Verify Java 17+
    JAVA_MAJOR=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    if [ "$JAVA_MAJOR" -lt 17 ]; then
        echo "  ⚠️  Warning: Java 17+ required for Android Gradle Plugin 8+"
    fi
else
    echo "✗ Java: not found"
    exit 1
fi

echo ""

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js: $NODE_VERSION"
    
    # Verify Node 20+
    NODE_MAJOR=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_MAJOR" -lt 20 ]; then
        echo "  ⚠️  Warning: Node.js 20+ recommended for React Native/Expo"
    fi
else
    echo "✗ Node.js: not found"
    exit 1
fi

echo ""

# Check Android SDK
if [ -n "$ANDROID_SDK_ROOT" ]; then
    echo "✓ ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"
    if [ -d "$ANDROID_SDK_ROOT" ]; then
        echo "  ✓ SDK directory exists"
    else
        echo "  ✗ SDK directory not found"
        exit 1
    fi
else
    echo "✗ ANDROID_SDK_ROOT: not set"
    exit 1
fi

if command -v sdkmanager &> /dev/null; then
    echo "  ✓ sdkmanager available"
else
    echo "  ✗ sdkmanager not found"
    exit 1
fi

echo ""

# Check Gradle wrapper
if [ -f "./gradlew" ]; then
    echo "✓ Gradle wrapper found"
    chmod +x ./gradlew 2>/dev/null || true
elif [ -f "./android/gradlew" ]; then
    echo "✓ Gradle wrapper found (in android/)"
    chmod +x ./android/gradlew 2>/dev/null || true
else
    echo "⚠️  Gradle wrapper not found (will need to install Gradle)"
fi

echo ""

# Validate build task
VALID_TASKS=("assembleRelease" "assembleDebug" "bundleRelease" "bundleDebug" "clean")
if [[ " ${VALID_TASKS[@]} " =~ " ${GRADLE_TASK} " ]]; then
    echo "✓ Build task: $GRADLE_TASK (valid)"
else
    echo "⚠️  Build task: $GRADLE_TASK (not in common tasks list)"
    echo "  Common tasks: ${VALID_TASKS[*]}"
fi

echo ""

# Check memory settings
if [ -n "$GRADLE_OPTS" ]; then
    echo "✓ GRADLE_OPTS: $GRADLE_OPTS"
else
    echo "⚠️  GRADLE_OPTS: not set (using defaults)"
fi

echo ""
echo "=== Validation Complete ==="

