# Copilot Custom Instructions for Android Build Container Image

## Project Overview

This repository provides a lean, secure Docker container image for Android SDK, Java, Node.js, and Gradle, pre-configured for React Native/Expo builds. The image supports both Ubuntu and Debian base images and can be deployed to GCP Artifact Registry, AWS ECR, Azure ACR, or Docker Hub.

## Technology Stack

- **Docker**: Multi-stage Dockerfile for building the container image
- **Bash Scripts**: Helper scripts and deployment automation
- **Makefile**: Build and deployment commands
- **GitHub Actions**: CI/CD workflows
- **Google Cloud Build**: Alternative cloud-based build system

## Key Components

- `Dockerfile`: Multi-stage build for the Android build container
- `Makefile`: Entry point for build, test, and deployment commands
- `scripts/`: Deployment scripts and utilities
- `scripts/helpers/`: Helper scripts included in the container image (artifact-finder.sh, build-validator.sh, memory-checker.sh)
- `tests/`: Test scripts for validating the image
- `.github/workflows/`: CI/CD pipeline configuration

## Code Style Guidelines

### Shell Scripts
- Use `#!/bin/bash` shebang for all scripts
- Include `set -e` for error handling where appropriate
- Use meaningful variable names in UPPER_CASE for environment variables
- Add comments for complex logic
- Follow existing script patterns in `scripts/` directory
- Use `shellcheck` recommendations for best practices

### Dockerfile
- Minimize layers by combining related commands
- Clean up package manager caches after installs (`rm -rf /var/lib/apt/lists/*`)
- Use ARG for build-time variables and ENV for runtime variables
- Include descriptive comments for each major section
- Follow multi-stage build patterns when applicable

### Makefile
- Use `.PHONY` targets appropriately
- Include meaningful help text for each target
- Use consistent variable naming with `?=` for defaults
- Provide clear error messages when required variables are missing

## Testing Approach

- Test Docker image builds for both Ubuntu and Debian base images
- Verify all included tools (Java, Node.js, Android SDK) are accessible
- Use `tests/test-build.sh` for local testing
- CI runs automated tests on push and pull requests

## Environment Variables

All configuration values should be customizable via environment variables. See `docs/ENV_VARS.md` for the complete reference. Common patterns:
- `GCP_PROJECT_ID`: Google Cloud project identifier
- `AWS_REGION`, `AZURE_*`: Cloud provider configuration
- `GRADLE_OPTS`, `JAVA_OPTS`: JVM configuration

## Security Considerations

- Avoid hardcoding secrets or credentials
- Use Trivy for security scanning
- Follow least-privilege principles in container design
- Clean up sensitive data during image builds
- Reference `docs/SECURITY.md` for detailed security practices

## Documentation

When adding new features:
- Update relevant documentation in `docs/`
- Keep `README.md` concise with links to detailed docs
- Update `CHANGELOG.md` for user-facing changes
