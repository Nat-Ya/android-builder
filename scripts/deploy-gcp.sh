#!/bin/bash
# Deploy to GCP Artifact Registry

set -e

if [ $# -lt 4 ]; then
  echo "Usage: $0 <project-id> <region> <registry-name> <image-tag>"
  exit 1
fi

GCP_PROJECT_ID="$1"
GCP_REGION="$2"
GCP_REGISTRY_NAME="$3"
IMAGE_TAG="$4"
IMAGE_NAME="${IMAGE_NAME:-android-build-image}"

REGISTRY_URL="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${GCP_REGISTRY_NAME}"

echo "Deploying to GCP Artifact Registry..."
echo "Registry: $REGISTRY_URL"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"

# Authenticate
gcloud auth configure-docker "${GCP_REGION}-docker.pkg.dev"

# Tag image
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY_URL}/${IMAGE_NAME}:latest"

# Push
docker push "${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
docker push "${REGISTRY_URL}/${IMAGE_NAME}:latest"

echo "✅ Deployed to ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

