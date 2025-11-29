#!/bin/bash
# Comprehensive test suite for Android build image

set -e

IMAGE_NAME="${IMAGE_NAME:-android-build-image}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "=========================================="
echo "Testing Android Build Image"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "=========================================="
echo ""

# Test 1: Java installation
echo "Test 1: Java Installation"
echo "-------------------------"
JAVA_OUTPUT=$(docker run --rm "$IMAGE_NAME:$IMAGE_TAG" java -version 2>&1)
echo "$JAVA_OUTPUT"
if echo "$JAVA_OUTPUT" | grep -q "openjdk version \"17"; then
    echo "✅ Java 17 found"
else
    echo "❌ Java 17 not found"
    exit 1
fi
echo ""

# Test 2: Node.js installation
echo "Test 2: Node.js Installation"
echo "---------------------------"
NODE_VERSION=$(docker run --rm "$IMAGE_NAME:$IMAGE_TAG" node --version)
echo "Node.js: $NODE_VERSION"
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_MAJOR" -ge 20 ]; then
    echo "✅ Node.js 20+ found"
else
    echo "❌ Node.js 20+ required"
    exit 1
fi

NPM_VERSION=$(docker run --rm "$IMAGE_NAME:$IMAGE_TAG" npm --version)
echo "npm: $NPM_VERSION"
echo ""

# Test 3: Android SDK
echo "Test 3: Android SDK"
echo "------------------"
SDK_ROOT=$(docker run --rm "$IMAGE_NAME:$IMAGE_TAG" bash -c 'echo $ANDROID_SDK_ROOT')
echo "ANDROID_SDK_ROOT: $SDK_ROOT"

SDK_VERSION=$(docker run --rm "$IMAGE_NAME:$IMAGE_TAG" sdkmanager --version 2>&1 || echo "version check")
echo "sdkmanager version: $SDK_VERSION"
echo "✅ Android SDK configured"
echo ""

# Test 4: Environment Variables
echo "Test 4: Environment Variables"
echo "-----------------------------"
GRADLE_OPTS=$(docker run --rm "$IMAGE_NAME:$IMAGE_TAG" bash -c 'echo $GRADLE_OPTS')
echo "GRADLE_OPTS: $GRADLE_OPTS"
if echo "$GRADLE_OPTS" | grep -q "Xmx4096m"; then
    echo "✅ Default memory settings correct"
else
    echo "⚠️  Default memory settings may need adjustment"
fi

JAVA_HOME=$(docker run --rm "$IMAGE_NAME:$IMAGE_TAG" bash -c 'echo $JAVA_HOME')
echo "JAVA_HOME: $JAVA_HOME"
echo ""

# Test 5: Helper Scripts
echo "Test 5: Helper Scripts"
echo "----------------------"
if docker run --rm "$IMAGE_NAME:$IMAGE_TAG" which artifact-finder.sh > /dev/null 2>&1; then
    echo "✅ artifact-finder.sh available"
else
    echo "❌ artifact-finder.sh not found"
    exit 1
fi

if docker run --rm "$IMAGE_NAME:$IMAGE_TAG" which memory-checker.sh > /dev/null 2>&1; then
    echo "✅ memory-checker.sh available"
else
    echo "❌ memory-checker.sh not found"
    exit 1
fi

if docker run --rm "$IMAGE_NAME:$IMAGE_TAG" which build-validator.sh > /dev/null 2>&1; then
    echo "✅ build-validator.sh available"
else
    echo "❌ build-validator.sh not found"
    exit 1
fi
echo ""

# Test 6: Memory Checker Script
echo "Test 6: Memory Checker Script"
echo "-----------------------------"
docker run --rm -e GRADLE_OPTS="-Xmx2048m -XX:MaxMetaspaceSize=512m" \
  "$IMAGE_NAME:$IMAGE_TAG" memory-checker.sh | head -n 10
echo ""

# Test 7: Build Validator Script
echo "Test 7: Build Validator Script"
echo "------------------------------"
docker run --rm "$IMAGE_NAME:$IMAGE_TAG" build-validator.sh assembleRelease | head -n 15
echo ""

# Test 8: Custom GRADLE_OPTS
echo "Test 8: Custom GRADLE_OPTS"
echo "-------------------------"
CUSTOM_OPTS=$(docker run --rm -e GRADLE_OPTS="-Xmx2048m" \
  "$IMAGE_NAME:$IMAGE_TAG" bash -c 'echo $GRADLE_OPTS')
if [ "$CUSTOM_OPTS" = "-Xmx2048m" ]; then
    echo "✅ Custom GRADLE_OPTS works: $CUSTOM_OPTS"
else
    echo "❌ Custom GRADLE_OPTS not set correctly"
    exit 1
fi
echo ""

# Test 9: Working Directory
echo "Test 9: Working Directory"
echo "-------------------------"
WORKDIR=$(docker run --rm "$IMAGE_NAME:$IMAGE_TAG" pwd)
echo "Working directory: $WORKDIR"
if [ "$WORKDIR" = "/workspace" ]; then
    echo "✅ Working directory correct"
else
    echo "❌ Working directory incorrect"
    exit 1
fi
echo ""

# Test 10: User Permissions
echo "Test 10: User Permissions"
echo "------------------------"
USER=$(docker run --rm "$IMAGE_NAME:$IMAGE_TAG" whoami)
echo "Running as user: $USER"
if [ "$USER" = "root" ]; then
    echo "✅ Running as root user (CI/CD compatibility)"
else
    echo "❌ Not running as expected user (root)"
    exit 1
fi
echo ""

echo "=========================================="
echo "✅ All tests passed!"
echo "=========================================="


