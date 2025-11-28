# Android Build Container Image - Initial Specification

## Overview

A lean, secure, multi-registry-compatible Docker image containing Android SDK, Java, Node.js, and Gradle pre-configured for React Native/Expo builds. Built via Cloud Build with shift-left security practices and deployable to GCP Artifact Registry, AWS ECR, Azure ACR, Docker Hub, and other public registries.

## Key Principles

- **Lean**: Minimal image size, only essential tools
- **Secure**: Shift-left security scanning, vulnerability management
- **Multi-registry**: Deploy to any registry without code changes
- **Customizable**: All hardcoded values configurable via environment variables
- **Simple docs**: Quick start focus, avoid overwhelming documentation

## Base Images

Support both base images via `BASE_IMAGE` environment variable:

- **Ubuntu**: `ubuntu:22.04` (default, LTS, well-supported)
- **Debian**: `debian:bullseye-slim` (smaller footprint, ~50MB smaller)

Selection: `BASE_IMAGE=debian:bullseye-slim` to use Debian instead of Ubuntu.

## Components

### Required Tools

1. **Java**: OpenJDK 17 (LTS, required for Android Gradle Plugin 8+)
2. **Node.js**: Version 20.x (LTS, required for React Native/Expo)
3. **Android SDK**:
   - Command Line Tools (latest)
   - Platform tools
   - Build tools 34.0.0
   - Platform API 34
   - CMake 3.22.1
   - NDK (optional, for native modules)
4. **Gradle**: Via wrapper (not pre-installed, project-specific)
5. **Docker CLI**: Required for multi-stage builds, better caching, concept separation
6. **Utilities**: wget, unzip, curl, git, python3

### Memory Configuration

- **Default Gradle JVM**: `-Xmx4096m -XX:MaxMetaspaceSize=1024m`
- **Configurable via**: `GRADLE_OPTS`, `JAVA_OPTS` environment variables
- **Documentation**: Include memory tuning guide for different scenarios

## Environment Variables

All customizable values documented in `ENV_VARS.md`. Key variables:

- `BASE_IMAGE`: Base image selection (ubuntu:22.04 or debian:bullseye-slim)
- `JAVA_VERSION`: Java version (default: 17)
- `NODE_VERSION`: Node.js version (default: 20)
- `ANDROID_SDK_VERSION`: Android SDK version (default: latest)
- `GRADLE_OPTS`: Gradle JVM options
- `JAVA_OPTS`: Java options

See `ENV_VARS.md` for complete reference.

## Project Structure

```
android-build-image/
├── Dockerfile                 # Multi-stage Dockerfile
├── cloudbuild.yaml           # GCP Cloud Build config
├── Makefile                  # Build/deploy commands
├── scripts/
│   ├── build.sh             # Local build script
│   ├── deploy-gcp.sh        # Deploy to GCP Artifact Registry
│   ├── deploy-aws.sh        # Deploy to AWS ECR
│   ├── deploy-azure.sh      # Deploy to Azure ACR
│   ├── deploy-dockerhub.sh  # Deploy to Docker Hub
│   └── security-scan.sh     # Security scanning (Trivy)
├── tests/
│   └── test-build.sh        # Test image with sample project
└── docs/
    ├── README.md            # Quick start guide
    ├── INITIAL_SPEC.md      # This file
    ├── ENV_VARS.md          # Environment variables reference
    ├── DEPLOYMENT.md        # Deployment guides
    ├── SECURITY.md          # Security practices
    └── TROUBLESHOOTING.md   # Common issues
```


