#!/bin/bash
# Deploy to Docker Hub

set -e

if [ $# -lt 3 ]; then
  echo "Usage: $0 <username> <repo-name> <image-tag>"
  exit 1
fi

DOCKERHUB_USERNAME="$1"
DOCKERHUB_REPO="$2"
IMAGE_TAG="$3"
IMAGE_NAME="${IMAGE_NAME:-android-build-image}"

REGISTRY_URL="docker.io"

echo "Deploying to Docker Hub..."
echo "Registry: $REGISTRY_URL"
echo "Repository: $DOCKERHUB_USERNAME/$DOCKERHUB_REPO"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"

# Authenticate (expects DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD env vars)
if [ -z "$DOCKERHUB_PASSWORD" ]; then
  echo "Error: DOCKERHUB_PASSWORD environment variable must be set"
  exit 1
fi

echo "$DOCKERHUB_PASSWORD" | docker login --username "$DOCKERHUB_USERNAME" --password-stdin

# Tag image
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG}"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:latest"

# Push
docker push "${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG}"
docker push "${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:latest"

echo "✅ Deployed to ${DOCKERHUB_USERNAME}/${DOCKERHUB_REPO}:${IMAGE_TAG}"


