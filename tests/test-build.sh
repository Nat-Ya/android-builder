#!/bin/bash
# Test Android build image with sample project

set -e

IMAGE_NAME="${IMAGE_NAME:-android-build-image}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

echo "Testing Android build image: $IMAGE_NAME:$IMAGE_TAG"
echo ""

# Test Java version
echo "Testing Java installation..."
docker run --rm "$IMAGE_NAME:$IMAGE_TAG" java -version

# Test Node.js version
echo ""
echo "Testing Node.js installation..."
docker run --rm "$IMAGE_NAME:$IMAGE_TAG" node --version
docker run --rm "$IMAGE_NAME:$IMAGE_TAG" npm --version

# Test Android SDK
echo ""
echo "Testing Android SDK..."
docker run --rm "$IMAGE_NAME:$IMAGE_TAG" sdkmanager --version

# Test Gradle wrapper (if available)
echo ""
echo "Testing environment variables..."
docker run --rm -e GRADLE_OPTS="-Xmx2048m" "$IMAGE_NAME:$IMAGE_TAG" bash -c 'echo "GRADLE_OPTS: $GRADLE_OPTS"'

echo ""
echo "✅ All basic tests passed!"


