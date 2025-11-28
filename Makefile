# Android Build Container Image - Makefile
# Build and deploy commands for the Android build container image

.PHONY: help build-local build-gcp test-image scan-security deploy-gcp deploy-aws deploy-azure deploy-dockerhub gcp-login aws-login azure-login dockerhub-login check-secrets quota-check quota-report

# Default values (all customizable)
BASE_IMAGE ?= ubuntu:22.04
IMAGE_TAG ?= latest
GCP_PROJECT_ID ?= general-476320
GCP_REGION ?= west-europe
GCP_REGISTRY_NAME ?= android-build-images
AWS_REGION ?= us-east-1
AWS_ECR_REPO ?= android-build-image
AZURE_RESOURCE_GROUP ?=
AZURE_ACR_NAME ?=
DOCKERHUB_USERNAME ?=
DOCKERHUB_REPO ?= android-build-image

help:
	@echo "Android Build Container Image - Build & Deploy Commands"
	@echo ""
	@echo "Build:"
	@echo "  make build-local          - Build image locally"
	@echo "  make build-gcp            - Build via GCP Cloud Build"
	@echo "  make test-image           - Test image with sample project"
	@echo "  make scan-security        - Run security scans"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy-gcp           - Deploy to GCP Artifact Registry"
	@echo "  make deploy-aws           - Deploy to AWS ECR"
	@echo "  make deploy-azure         - Deploy to Azure ACR"
	@echo "  make deploy-dockerhub     - Deploy to Docker Hub"
	@echo ""
	@echo "Authentication:"
	@echo "  make gcp-login            - Authenticate to GCP"
	@echo "  make aws-login            - Authenticate to AWS"
	@echo "  make azure-login          - Authenticate to Azure"
	@echo "  make dockerhub-login      - Authenticate to Docker Hub"
	@echo ""
	@echo "Utilities:"
	@echo "  make check-secrets        - Verify secrets exist"
	@echo "  make quota-check          - Check GCP Cloud Build quota usage"
	@echo "  make quota-report         - Generate detailed quota report"
	@echo ""
	@echo "Customization:"
	@echo "  BASE_IMAGE=debian:bullseye-slim make build-local"
	@echo "  IMAGE_TAG=v1.0.0 make deploy-gcp"
	@echo "  NON_INTERACTIVE=true make build-gcp  - Auto-fallback to local if quota exceeded"

# Build locally
build-local:
	@echo "Building Android build image locally..."
	docker build \
		--build-arg BASE_IMAGE=$(BASE_IMAGE) \
		-t android-build-image:$(IMAGE_TAG) \
		.

# Build via GCP Cloud Build
build-gcp:
	@echo "Building via GCP Cloud Build..."
	@if [ -z "$(GCP_PROJECT_ID)" ]; then \
		echo "Error: GCP_PROJECT_ID must be set"; \
		exit 1; \
	fi
	@echo "Checking GCP quota before build..."
	@NON_INTERACTIVE_FLAG=""; \
	if [ "$(NON_INTERACTIVE)" = "true" ] || [ "$(NON_INTERACTIVE)" = "1" ]; then \
		NON_INTERACTIVE_FLAG="--non-interactive"; \
	fi; \
	bash scripts/gcp-quota-checker.sh before --project $(GCP_PROJECT_ID) $$NON_INTERACTIVE_FLAG || \
		(echo ""; echo "💡 Tip: Use 'make build-local' for local builds (no cost)"; exit 1)
	@echo ""
	@echo "Starting Cloud Build..."
	@gcloud builds submit . \
		--config cloudbuild.yaml \
		--substitutions=_BASE_IMAGE=$(BASE_IMAGE),_IMAGE_TAG=$(IMAGE_TAG),_GCP_PROJECT_ID=$(GCP_PROJECT_ID),_GCP_REGION=$(GCP_REGION),_GCP_REGISTRY_NAME=$(GCP_REGISTRY_NAME)
	@echo ""
	@echo "Generating post-build usage report..."
	@bash scripts/gcp-quota-checker.sh after --project $(GCP_PROJECT_ID) || true

# Test image with sample project
test-image:
	@echo "Testing image with sample project..."
	@bash scripts/test-build.sh

# Security scan
scan-security:
	@echo "Running security scan..."
	@bash scripts/security-scan.sh

# Deploy to GCP Artifact Registry
deploy-gcp:
	@echo "Deploying to GCP Artifact Registry..."
	@bash scripts/deploy-gcp.sh $(GCP_PROJECT_ID) $(GCP_REGION) $(GCP_REGISTRY_NAME) $(IMAGE_TAG)

# Deploy to AWS ECR
deploy-aws:
	@echo "Deploying to AWS ECR..."
	@bash scripts/deploy-aws.sh $(AWS_REGION) $(AWS_ECR_REPO) $(IMAGE_TAG)

# Deploy to Azure ACR
deploy-azure:
	@echo "Deploying to Azure ACR..."
	@bash scripts/deploy-azure.sh $(AZURE_RESOURCE_GROUP) $(AZURE_ACR_NAME) $(IMAGE_TAG)

# Deploy to Docker Hub
deploy-dockerhub:
	@echo "Deploying to Docker Hub..."
	@bash scripts/deploy-dockerhub.sh $(DOCKERHUB_USERNAME) $(DOCKERHUB_REPO) $(IMAGE_TAG)

# Authentication commands
gcp-login:
	@echo "Authenticating to GCP..."
	gcloud auth configure-docker $(GCP_REGION)-docker.pkg.dev

aws-login:
	@echo "Authenticating to AWS ECR..."
	@bash scripts/aws-login.sh $(AWS_REGION)

azure-login:
	@echo "Authenticating to Azure ACR..."
	az acr login --name $(AZURE_ACR_NAME)

dockerhub-login:
	@echo "Authenticating to Docker Hub..."
	docker login

# Check secrets
check-secrets:
	@echo "Checking available secrets..."
	@bash scripts/check-secrets.sh

# Check GCP quota usage
quota-check:
	@bash scripts/gcp-quota-checker.sh check --project $(GCP_PROJECT_ID) || \
		bash scripts/gcp-quota-checker.sh check

# Generate quota report
quota-report:
	@bash scripts/gcp-quota-checker.sh report --project $(GCP_PROJECT_ID) || \
		bash scripts/gcp-quota-checker.sh report

