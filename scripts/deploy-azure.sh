#!/bin/bash
# Deploy to Azure ACR

set -e

if [ $# -lt 3 ]; then
  echo "Usage: $0 <resource-group> <acr-name> <image-tag>"
  exit 1
fi

AZURE_RESOURCE_GROUP="$1"
AZURE_ACR_NAME="$2"
IMAGE_TAG="$3"
IMAGE_NAME="${IMAGE_NAME:-android-build-image}"

REGISTRY_URL="${AZURE_ACR_NAME}.azurecr.io"

echo "Deploying to Azure ACR..."
echo "Registry: $REGISTRY_URL"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"

# Authenticate
az acr login --name "$AZURE_ACR_NAME"

# Tag image
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY_URL}/${IMAGE_NAME}:latest"

# Push
docker push "${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
docker push "${REGISTRY_URL}/${IMAGE_NAME}:latest"

echo "✅ Deployed to ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

