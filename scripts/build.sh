#!/bin/bash
# Local build script for Android build image
# Friendly, non-verbose build script

set -e

BASE_IMAGE="${BASE_IMAGE:-ubuntu:22.04}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
IMAGE_NAME="${IMAGE_NAME:-android-build-image}"

echo "🔨 Building Android build image..."
echo "   Base: $BASE_IMAGE"
echo "   Tag: $IMAGE_TAG"
echo ""

# Build with reduced verbosity (show step progress but filter verbose output)
docker build \
  --build-arg BASE_IMAGE="$BASE_IMAGE" \
  --progress=plain \
  -t "$IMAGE_NAME:$IMAGE_TAG" \
  -t "$IMAGE_NAME:latest" \
  . 2>&1 | grep -E "(^#|^Step|^Successfully|^ERROR|^Error|^WARNING|^Warning)" || true

# Check if build succeeded
if ! docker images "$IMAGE_NAME:$IMAGE_TAG" --format "{{.Repository}}:{{.Tag}}" | grep -q "$IMAGE_NAME:$IMAGE_TAG"; then
  echo ""
  echo "❌ Build failed. Running with full output for debugging..."
  docker build \
    --build-arg BASE_IMAGE="$BASE_IMAGE" \
    -t "$IMAGE_NAME:$IMAGE_TAG" \
    -t "$IMAGE_NAME:latest" \
    .
fi

echo ""
echo "✅ Build complete!"
echo "   Image: $IMAGE_NAME:$IMAGE_TAG"
echo ""
echo "💡 Next steps:"
echo "   Test: make test-image"
echo "   Deploy: make deploy-gcp GCP_PROJECT_ID=your-project"

