# Changelog

All notable changes to the Android Build Container Image project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial Dockerfile with multi-stage build support
- Support for both Ubuntu 22.04 and Debian bullseye-slim base images
- Java 17 (OpenJDK) installation
- Node.js 20 LTS installation
- Android SDK with Command Line Tools, Platform Tools, Build Tools 34.0.0, Platform API 34
- CMake 3.22.1 for native builds
- Optional NDK installation support
- Docker CLI for multi-stage builds
- Google Cloud SDK (gcloud and gsutil) for Secret Manager and GCS operations
- Helper scripts:
  - `artifact-finder.sh` - Find APK/AAB build artifacts
  - `memory-checker.sh` - Check and recommend memory settings
  - `build-validator.sh` - Validate build environment
- Comprehensive test suite (`tests/test-build.sh`)
- Cloud Build configuration (`cloudbuild.yaml`)
- Multi-registry deployment scripts (GCP, AWS, Azure, Docker Hub)
- Security scanning with Trivy
- Complete documentation:
  - `README.md` - Quick start guide
  - `docs/INITIAL_SPEC.md` - Project specification
  - `docs/LESSONS_LEARNED.md` - Key learnings from Cloud Build setup
  - `docs/ENV_VARS.md` - Environment variables reference
  - `docs/DEPLOYMENT.md` - Multi-registry deployment guide
  - `docs/SECURITY.md` - Security practices
  - `docs/TROUBLESHOOTING.md` - Common issues and solutions
- Example Cloud Build configurations:
  - `examples/cloudbuild-android-app.yaml` - Complete Android app build config
  - `examples/cloudbuild-substitution-example.sh` - Proper substitution handling patterns
- Makefile with build and deploy commands
- `.dockerignore` for optimized builds
- GCP quota checker script for free tier tracking

### Changed
- N/A (initial release)

### Deprecated
- N/A (initial release)

### Removed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Security
- Non-root user execution (`android-builder`)
- Security scanning integrated into build pipeline
- Minimal base image surface area
- Regular security updates via base image updates

## [1.0.0] - TBD

### Added
- First stable release
- All features from Unreleased section

