# AGENTS.md - AI Agent Guidelines

## Project Purpose

This repository contains a **Docker image** for building Android applications, specifically optimized for **React Native/Expo** projects. The image includes:

- Java 17 (OpenJDK LTS)
- Node.js 20 (LTS)
- Android SDK (Command Line Tools, Platform Tools, Build Tools 34.0.0, Platform API 34)
- Docker CLI for multi-stage builds
- Gradle support via wrapper

## Project Structure

```
android-builder/
├── Dockerfile              # Multi-stage Docker image definition
├── Makefile               # Build and deployment commands
├── cloudbuild.yaml        # GCP Cloud Build configuration
├── README.md              # Quick start documentation
├── .gitignore             # Git ignore patterns
├── .dockerignore          # Docker build context exclusions
├── .github/
│   └── workflows/
│       ├── ci.yml         # CI workflow (lint, build, test, security scan)
│       └── deploy.yml     # Deployment workflow (Docker Hub, GCP, AWS, Azure)
├── docs/
│   └── LESSONS_LEARNED.md # Lessons from Cloud Build setup
├── scripts/
│   ├── build.sh           # Local build script
│   ├── deploy-gcp.sh      # GCP Artifact Registry deployment
│   ├── deploy-aws.sh      # AWS ECR deployment
│   ├── deploy-azure.sh    # Azure ACR deployment
│   ├── deploy-dockerhub.sh # Docker Hub deployment
│   ├── security-scan.sh   # Trivy security scan
│   └── check-secrets.sh   # Cloud provider secrets check
└── tests/
    └── test-build.sh      # Image testing script
```

## Objectives

1. **Build Automation**: Provide a standardized, reproducible Android build environment
2. **Multi-Cloud Deployment**: Support deployment to GCP, AWS, Azure, and Docker Hub
3. **Security**: Include security scanning and follow container security best practices
4. **CI/CD Integration**: Work seamlessly with GitHub Actions and GCP Cloud Build

## Contribution Recommendations

### For Code Changes

1. **Dockerfile Changes**:
   - Maintain multi-stage build structure
   - Keep the image lean - remove unnecessary packages
   - Test with both Ubuntu and Debian base images
   - Run security scan after changes (`make scan-security`)

2. **Workflow Changes**:
   - Test workflows locally using [act](https://github.com/nektos/act) when possible
   - Ensure backward compatibility with existing secrets/variables
   - Add appropriate conditions for job execution

3. **Script Changes**:
   - Use `set -e` for error handling
   - Provide clear usage messages
   - Support environment variable configuration

### For Documentation

1. Keep README.md concise with quick start focus
2. Add detailed documentation to `docs/` directory
3. Update AGENTS.md when project structure changes

### Testing

1. Run `make test-image` after Docker changes
2. Verify all deployment targets work with `make check-secrets`
3. Run security scan before commits: `make scan-security`

### Required GitHub Secrets for Deployment

| Secret Name | Description | Required For |
|-------------|-------------|--------------|
| `DOCKERHUB_USERNAME` | Docker Hub username | Docker Hub deployment |
| `DOCKERHUB_PASSWORD` | Docker Hub password or access token | Docker Hub deployment |
| `GCP_PROJECT_ID` | GCP project ID | GCP deployment |
| `GCP_SA_KEY` | GCP service account JSON key | GCP deployment |
| `AWS_ACCESS_KEY_ID` | AWS access key | AWS ECR deployment |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | AWS ECR deployment |
| `AZURE_CREDENTIALS` | Azure service principal JSON | Azure ACR deployment |
| `AZURE_ACR_NAME` | Azure Container Registry name | Azure ACR deployment |

### Optional GitHub Variables

| Variable Name | Default | Description |
|---------------|---------|-------------|
| `GCP_REGION` | us-central1 | GCP region for Artifact Registry |
| `GCP_REGISTRY` | android-build-images | GCP Artifact Registry name |
| `AWS_REGION` | us-east-1 | AWS region for ECR |
| `AWS_ECR_REPO` | android-build-image | AWS ECR repository name |

## Agent Behavior Guidelines

When working with this repository:

1. **Prioritize minimal changes** - The Docker image should remain lean
2. **Maintain backward compatibility** - Don't break existing deployment scripts
3. **Security first** - Always run security scans on container changes
4. **Test thoroughly** - Use `make test-image` after changes
5. **Document changes** - Update relevant docs when modifying functionality
