#!/bin/bash
# Deploy to AWS ECR

set -e

if [ $# -lt 3 ]; then
  echo "Usage: $0 <aws-region> <ecr-repo> <image-tag>"
  exit 1
fi

AWS_REGION="$1"
AWS_ECR_REPO="$2"
IMAGE_TAG="$3"
IMAGE_NAME="${IMAGE_NAME:-android-build-image}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"

if [ -z "$AWS_ACCOUNT_ID" ]; then
  # Try to get AWS account ID from AWS CLI
  AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
  if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "Error: AWS_ACCOUNT_ID must be set or AWS credentials must be configured"
    exit 1
  fi
fi

REGISTRY_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Deploying to AWS ECR..."
echo "Registry: $REGISTRY_URL"
echo "Repository: $AWS_ECR_REPO"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"

# Authenticate
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$REGISTRY_URL"

# Create repository if it doesn't exist
aws ecr describe-repositories --repository-names "$AWS_ECR_REPO" --region "$AWS_REGION" 2>/dev/null || \
  aws ecr create-repository --repository-name "$AWS_ECR_REPO" --region "$AWS_REGION"

# Tag image
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY_URL}/${AWS_ECR_REPO}:${IMAGE_TAG}"
docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY_URL}/${AWS_ECR_REPO}:latest"

# Push
docker push "${REGISTRY_URL}/${AWS_ECR_REPO}:${IMAGE_TAG}"
docker push "${REGISTRY_URL}/${AWS_ECR_REPO}:latest"

echo "✅ Deployed to ${REGISTRY_URL}/${AWS_ECR_REPO}:${IMAGE_TAG}"

