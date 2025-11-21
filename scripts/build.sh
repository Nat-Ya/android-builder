#!/bin/bash
# Local build script for Android build image

set -e

BASE_IMAGE="${BASE_IMAGE:-ubuntu:22.04}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
IMAGE_NAME="${IMAGE_NAME:-android-build-image}"

echo "Building Android build image..."
echo "Base image: $BASE_IMAGE"
echo "Image tag: $IMAGE_TAG"

docker build \
  --build-arg BASE_IMAGE="$BASE_IMAGE" \
  -t "$IMAGE_NAME:$IMAGE_TAG" \
  -t "$IMAGE_NAME:latest" \
  .

echo "✅ Build complete!"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"

