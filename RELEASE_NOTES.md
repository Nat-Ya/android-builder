# Release Notes

## Version 1.0.0 (Initial Release)

### Overview

The Android Build Container Image is a lean, secure Docker image containing Android SDK, Java, Node.js, and Gradle pre-configured for React Native/Expo builds. This first version includes everything needed to build Android applications in CI/CD environments, particularly Google Cloud Build.

### Key Features

#### Core Components
- **Java 17** (OpenJDK LTS) - Required for Android Gradle Plugin 8+
- **Node.js 20** (LTS) - Required for React Native/Expo
- **Android SDK** - Complete SDK with:
  - Command Line Tools (latest)
  - Platform Tools
  - Build Tools 34.0.0
  - Platform API 34
  - CMake 3.22.1
  - Optional NDK support
- **Docker CLI** - For multi-stage builds
- **Google Cloud SDK** - gcloud and gsutil for Secret Manager and GCS operations

#### Base Image Support
- **Ubuntu 22.04** (default, LTS, well-supported)
- **Debian bullseye-slim** (~50MB smaller)

#### Helper Scripts
- `artifact-finder.sh` - Automatically find APK/AAB build artifacts
- `memory-checker.sh` - Check memory configuration and get recommendations
- `build-validator.sh` - Validate build environment before building

#### Security
- Non-root user execution
- Shift-left security scanning with Trivy
- Minimal attack surface
- Regular security updates

#### Multi-Registry Support
- Deploy to GCP Artifact Registry
- Deploy to AWS ECR
- Deploy to Azure ACR
- Deploy to Docker Hub

### Configuration

All values are configurable via environment variables:
- Base image selection
- Java/Node.js versions
- Android SDK components
- Memory settings (Gradle JVM options)
- NDK installation

See `docs/ENV_VARS.md` for complete reference.

### Documentation

Comprehensive documentation included:
- Quick start guide
- Environment variables reference
- Deployment guides for all registries
- Security practices
- Troubleshooting guide
- Example Cloud Build configurations

### Example Usage

#### Local Build
```bash
make build-local
```

#### Cloud Build
```bash
make build-gcp GCP_PROJECT_ID=your-project
```

#### Using in Cloud Build
```yaml
steps:
  - name: 'us-central1-docker.pkg.dev/project/repo/android-build-image:latest'
    args: ['./gradlew', 'assembleRelease']
```

### Lessons Learned Integration

This release incorporates key learnings from real-world Cloud Build Android setup:
- Proper Cloud Build substitution handling
- Correct artifact path resolution
- Optimal memory configuration (4GB heap default)
- Keystore management best practices
- Working directory patterns

See `docs/LESSONS_LEARNED.md` for details.

### Build Success Metrics

- ✅ APK builds successfully
- ✅ AAB builds successfully
- ✅ Artifacts correctly uploaded to GCS
- ✅ Build time reasonable (14-20 minutes)
- ✅ Memory usage predictable and within limits

### Next Steps

1. Test locally: `make build-local`
2. Deploy to registry: `make deploy-gcp GCP_PROJECT_ID=your-project`
3. Use in Cloud Build: See `examples/cloudbuild-android-app.yaml`
4. Customize: See `docs/ENV_VARS.md`

### Support

- Documentation: See `docs/` directory
- Troubleshooting: See `docs/TROUBLESHOOTING.md`
- Examples: See `examples/` directory

