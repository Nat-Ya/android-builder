# Deployment Guide - Android Build Container Image

Multi-cloud deployment guide for the Android build container image.

## Table of Contents

1. [GCP Artifact Registry](#gcp-artifact-registry)
2. [AWS ECR](#aws-ecr)
3. [Azure ACR](#azure-acr)
4. [Docker Hub](#docker-hub)
5. [Security Best Practices](#security-best-practices)

---

## Prerequisites

- Docker installed locally (for testing)
- Cloud CLI tools installed:
  - GCP: `gcloud` CLI
  - AWS: `aws` CLI
  - Azure: `az` CLI
- Appropriate cloud account permissions
- Secrets stored securely (never commit to Git)

---

## GCP Artifact Registry

### Initial Setup

**1. Create Artifact Registry Repository (First Time Only)**

```bash
gcloud artifacts repositories create android-build-images \
  --repository-format=docker \
  --location=us-central1 \
  --description="Android build container images"
```

**2. Grant Cloud Build Access**

```bash
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")

gcloud artifacts repositories add-iam-policy-binding android-build-images \
  --location=us-central1 \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

### Local Build & Deploy

**Authenticate:**
```bash
make gcp-login
# OR manually:
gcloud auth configure-docker us-central1-docker.pkg.dev
```

**Build & Deploy:**
```bash
# Build locally
make build-local IMAGE_TAG=v1.0.0

# Deploy to GCP Artifact Registry
make deploy-gcp \
  GCP_PROJECT_ID=my-project \
  GCP_REGION=us-central1 \
  IMAGE_TAG=v1.0.0
```

### Cloud Build Deployment

**Build via Cloud Build:**
```bash
make build-gcp \
  GCP_PROJECT_ID=my-project \
  GCP_REGION=us-central1 \
  IMAGE_TAG=v1.0.0
```

**Cloud Build Configuration** (`cloudbuild.yaml`):
- Builds Docker image with custom base
- Runs Trivy security scan
- Pushes to Artifact Registry with version tag + latest
- Machine: N1_HIGHCPU_8 (optimized for build)
- Timeout: 30 minutes

### Image Storage Best Practices

**Remote State & Artifacts:**
- Store build artifacts in GCS bucket (`gs://your-builds/`)
- Use versioning for rollback capability
- Enable encryption at rest (default on GCS)
- Configure lifecycle policies for old images

**Security:**
- Use IAM for granular access control
- Enable audit logging for GCS access
- Store credentials in Secret Manager (not env vars)
- Use service accounts with least privilege

---

## AWS ECR

### Initial Setup

ECR repository is **auto-created** by the deploy script if it doesn't exist.

### Authentication

```bash
make aws-login AWS_REGION=us-east-1
# OR manually:
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Build & Deploy

```bash
# Build locally
make build-local IMAGE_TAG=v1.0.0

# Deploy to AWS ECR
make deploy-aws \
  AWS_REGION=us-east-1 \
  AWS_ECR_REPO=android-build-image \
  IMAGE_TAG=v1.0.0
```

**Features:**
- Auto-detects AWS account ID via `aws sts get-caller-identity`
- Creates repository if missing
- Tags with version + latest
- Pushes both tags automatically

### Manual Repository Creation (Optional)

```bash
aws ecr create-repository \
  --repository-name android-build-image \
  --region us-east-1 \
  --encryption-configuration encryptionType=AES256
```

---

## Azure ACR

### Initial Setup

**1. Create Resource Group:**
```bash
az group create \
  --name rg-android-builds \
  --location eastus
```

**2. Create Container Registry:**
```bash
az acr create \
  --resource-group rg-android-builds \
  --name myandroidregistry \
  --sku Basic \
  --location eastus
```

### Authentication

```bash
make azure-login AZURE_ACR_NAME=myandroidregistry
# OR manually:
az acr login --name myandroidregistry
```

### Build & Deploy

```bash
# Build locally
make build-local IMAGE_TAG=v1.0.0

# Deploy to Azure ACR
make deploy-azure \
  AZURE_RESOURCE_GROUP=rg-android-builds \
  AZURE_ACR_NAME=myandroidregistry \
  IMAGE_TAG=v1.0.0
```

---

## Docker Hub

### Initial Setup

**1. Create Access Token** (recommended over password):
- Go to [Docker Hub Security](https://hub.docker.com/settings/security)
- Click "New Access Token"
- Name: "android-builder-deploy"
- Permissions: Read, Write, Delete
- Save token securely

**2. Store Token Securely:**
```bash
# Set as environment variable (do NOT commit)
export DOCKERHUB_PASSWORD="your-access-token"
```

### Authentication

```bash
make dockerhub-login
# OR manually:
docker login --username your-username
```

### Build & Deploy

```bash
# Build locally
make build-local IMAGE_TAG=v1.0.0

# Deploy to Docker Hub
DOCKERHUB_PASSWORD="your-token" make deploy-dockerhub \
  DOCKERHUB_USERNAME=your-username \
  DOCKERHUB_REPO=android-build-image \
  IMAGE_TAG=v1.0.0
```

**GitHub Actions Deployment:**

On release creation, GitHub Actions automatically deploys to Docker Hub using secrets:
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Access token (NOT password)

See `.github/workflows/ci.yml` for automated deployment configuration.

---

## Security Best Practices

### Secrets Management

**Never commit secrets to Git!**

**GCP Secret Manager (Recommended):**
```bash
# Store secret
echo -n "my-secret-value" | gcloud secrets create my-secret --data-file=-

# Grant Cloud Build access
gcloud secrets add-iam-policy-binding my-secret \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"

# Use in Cloud Build
gcloud secrets versions access latest --secret=my-secret
```

**Environment Variables (Local Development Only):**
```bash
# Use .env file (NEVER commit)
export DOCKERHUB_PASSWORD="token"
export AWS_ACCOUNT_ID="123456789"
```

### Image Security

**1. Base Image Selection:**
- Use official Ubuntu/Debian images
- Prefer LTS versions (Ubuntu 22.04, Debian Bullseye)
- Regularly update base images

**2. Vulnerability Scanning:**
```bash
# Scan image with Trivy
make scan-security

# Or manually:
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image android-build-image:latest
```

**3. Multi-Stage Builds:**
- Use multi-stage Dockerfile to reduce final image size
- Copy only necessary artifacts to final stage
- Remove build-time dependencies

**4. Non-Root User:**
- Image runs as `android-builder` user (UID 1000)
- Never run containers as root in production

### Registry Security

**Access Control:**
- Use IAM roles for GCP Artifact Registry
- Use IAM policies for AWS ECR
- Use RBAC for Azure ACR
- Use access tokens (not passwords) for Docker Hub

**Encryption:**
- All registries encrypt at rest by default
- Use TLS/HTTPS for all registry communication
- Enable vulnerability scanning in registry (available on all platforms)

**Audit Logging:**
- Enable audit logs for registry access
- Monitor for unauthorized pull/push attempts
- Set up alerts for security events

### CI/CD Security

**GitHub Actions:**
- Store credentials in GitHub Secrets (encrypted)
- Use OIDC for cloud authentication (no long-lived tokens)
- Limit workflow permissions to minimum required
- Review PRs from external contributors carefully

**Cloud Build:**
- Use service accounts with least privilege
- Store secrets in Secret Manager
- Enable audit logging for builds
- Review build logs for sensitive data leaks

---

## Verification & Testing

### Verify Deployed Image

**Pull and test:**
```bash
# GCP
docker pull us-central1-docker.pkg.dev/PROJECT/android-build-images/android-build-image:v1.0.0

# AWS
docker pull 123456789.dkr.ecr.us-east-1.amazonaws.com/android-build-image:v1.0.0

# Azure
docker pull myandroidregistry.azurecr.io/android-build-image:v1.0.0

# Docker Hub
docker pull your-username/android-build-image:v1.0.0

# Test image
docker run --rm <image> bash -c "java -version && node --version && sdkmanager --version"
```

### Image Sizes

Expected sizes:
- **Ubuntu-based**: ~2.5-3GB
- **Debian-based**: ~2-2.5GB (50-500MB smaller)

---

## Troubleshooting

### Authentication Failures

**GCP:**
```bash
# Re-authenticate
gcloud auth login
gcloud auth configure-docker us-central1-docker.pkg.dev

# Check credentials
gcloud auth list
```

**AWS:**
```bash
# Check credentials
aws sts get-caller-identity

# Re-authenticate
aws configure
```

**Azure:**
```bash
# Re-authenticate
az login
az acr login --name myandroidregistry

# Check credentials
az account show
```

### Push/Pull Failures

**Check registry exists:**
```bash
# GCP
gcloud artifacts repositories list --location=us-central1

# AWS
aws ecr describe-repositories --region us-east-1

# Azure
az acr list --resource-group rg-android-builds
```

**Check permissions:**
- Ensure service account has write permissions
- Verify IAM policies are correctly configured
- Check firewall/network rules

### Build Failures

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed debugging steps.

---

## Cost Management

### Free Tiers

**GCP Artifact Registry:**
- 0.5 GB storage free per month
- Network egress: 1GB free per month (within same region)
- After free tier: ~$0.10/GB/month storage

**AWS ECR:**
- 500 MB storage free per month (first 12 months)
- After free tier: ~$0.10/GB/month storage

**Azure ACR:**
- Basic tier: ~$5/month (10 GB storage included)
- Storage: ~$0.10/GB/month after 10GB

**Docker Hub:**
- Free tier: Unlimited public repositories
- 6-month retention for free accounts (images deleted after 6 months of inactivity)
- Paid: $7/month for Pro (unlimited private repos, no retention policy)

### Cost Optimization

1. **Use lifecycle policies** to delete old/unused images
2. **Compress layers** in Dockerfile
3. **Share base layers** across multiple images
4. **Choose region closest to CI/CD** to minimize egress costs
5. **Use Docker Hub for public images** (free, no storage costs)

---

## Quick Reference

**Build:**
```bash
make build-local IMAGE_TAG=v1.0.0
```

**Deploy to all registries:**
```bash
# GCP
make deploy-gcp GCP_PROJECT_ID=my-project IMAGE_TAG=v1.0.0

# AWS
make deploy-aws AWS_REGION=us-east-1 IMAGE_TAG=v1.0.0

# Azure
make deploy-azure AZURE_RESOURCE_GROUP=rg AZURE_ACR_NAME=acr IMAGE_TAG=v1.0.0

# Docker Hub
DOCKERHUB_PASSWORD="token" make deploy-dockerhub DOCKERHUB_USERNAME=user IMAGE_TAG=v1.0.0
```

**Test:**
```bash
make test-image
```

**Security scan:**
```bash
make scan-security
```

---

**Last Updated:** 2025-11-28
