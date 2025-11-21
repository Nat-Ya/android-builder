# Android Build Container Image

A lean, secure Docker image containing Android SDK, Java, Node.js, and Gradle pre-configured for React Native/Expo builds.

## Quick Start

### Build Locally

```bash
# Build with Ubuntu (default)
make build-local

# Build with Debian (smaller)
BASE_IMAGE=debian:bullseye-slim make build-local
```

### Build via Cloud Build

```bash
make build-gcp GCP_PROJECT_ID=your-project-id
```

### Deploy to Registry

```bash
# GCP Artifact Registry
make deploy-gcp GCP_PROJECT_ID=your-project GCP_REGION=us-central1

# AWS ECR
make deploy-aws AWS_REGION=us-east-1

# Azure ACR
make deploy-azure AZURE_RESOURCE_GROUP=rg-name AZURE_ACR_NAME=acr-name

# Docker Hub
make deploy-dockerhub DOCKERHUB_USERNAME=your-username
```

## What's Included

- **Java 17** (OpenJDK, LTS)
- **Node.js 20** (LTS)
- **Android SDK** (Command Line Tools, Platform Tools, Build Tools 34.0.0, Platform API 34)
- **Docker CLI** (for multi-stage builds)
- **Gradle** (via wrapper, project-specific)

## Base Images

Supports both Ubuntu and Debian:

- `ubuntu:22.04` (default, LTS, well-supported)
- `debian:bullseye-slim` (~50MB smaller)

## Customization

All values are configurable via environment variables or Makefile arguments. See `docs/ENV_VARS.md` for complete reference.

## Documentation

- [Quick Start](README.md) - This file
- [Environment Variables](docs/ENV_VARS.md) - Complete env var reference
- [Deployment Guide](docs/DEPLOYMENT.md) - Multi-registry deployment
- [Security Practices](docs/SECURITY.md) - Security scanning and practices
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues

## License

See LICENSE file.

