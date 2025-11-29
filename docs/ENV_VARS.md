# Environment Variables Reference

## Build Configuration

### BASE_IMAGE
**Default:** `ubuntu:22.04`
**Options:** `ubuntu:22.04` | `debian:bullseye-slim`
Base Linux distribution for the container. Debian is ~50MB smaller.
**Recommendation:** Use `debian:bullseye-slim` for production to minimize image size.

### IMAGE_TAG
**Default:** `latest`
**Example:** `v1.0.0`, `2024-11-28`, `prod`
Version tag for the built image.

### IMAGE_NAME
**Default:** `android-build-image`
Local image name before registry tagging.

## Docker Build Arguments - Core Components

### JAVA_VERSION
**Default:** `17`
OpenJDK version. Change only if your project requires different Java version.

### JAVA_PACKAGE
**Default:** `openjdk-17-jdk-headless`
**Options:** `openjdk-17-jdk-headless` (smaller) | `openjdk-17-jdk` (full)
Java package to install. Headless variant is ~150MB smaller and sufficient for builds.

### NODE_VERSION
**Default:** `20`
Node.js LTS version for React Native/Expo builds.

### ANDROID_SDK_ROOT
**Default:** `/opt/android-sdk`
Installation path for Android SDK. Auto-configured in PATH.

### ANDROID_BUILD_TOOLS
**Default:** `34.0.0`
Android Build Tools version. Must match your project's requirements.

### ANDROID_PLATFORM
**Default:** `34`
Android API level. Set to your app's `targetSdkVersion`.

### ANDROID_CMAKE_VERSION
**Default:** `3.22.1`
CMake version for native builds (required for projects with native modules).

## Docker Build Arguments - Optional Components (Image Size Optimization)

### INSTALL_DOCKER_CLI
**Default:** `false`
**Options:** `true` | `false`
**Size Impact:** ~50MB
Whether to install Docker CLI. Only needed for Docker-in-Docker scenarios.
**Recommendation:** Keep disabled unless specifically needed.

### INSTALL_GCLOUD_SDK
**Default:** `false`
**Options:** `true` | `false`
**Size Impact:** ~400MB
Whether to install Google Cloud SDK (gcloud, gsutil).
**When to enable:** Only if using GCP Secret Manager or Google Cloud Storage.
**Recommendation:** Enable only for GCP-based CI/CD pipelines.

### INSTALL_CMAKE
**Default:** `false`
**Options:** `true` | `false`
**Size Impact:** ~100MB
Whether to install CMake for Android NDK.
**When to enable:** Only if your project has native C/C++ modules.
**Recommendation:** Enable only if needed. Most React Native projects don't require it.

### INSTALL_NDK
**Default:** `false`
**Options:** `true` | `false`
**Size Impact:** ~2GB
Whether to install Android NDK. Only enable if you need native modules.
**Recommendation:** Enable only for projects with extensive native code.

## Runtime Configuration - Performance Optimizations

### GRADLE_OPTS
**Default:** `-Xmx6144m -XX:MaxMetaspaceSize=2048m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8`
**Previous:** `-Xmx4096m -XX:MaxMetaspaceSize=1024m`
JVM options for Gradle builds. Increased to 6GB heap for better performance on large projects.
**Tuning:** Adjust based on available memory. For small projects, 4GB may suffice. For large monorepos, 8GB+ recommended.

### JAVA_OPTS
**Default:** `-Xmx6144m -XX:MaxMetaspaceSize=2048m`
**Previous:** `-Xmx4096m -XX:MaxMetaspaceSize=1024m`
General JVM options. Mirrors GRADLE_OPTS for consistency.

### ORG_GRADLE_PARALLEL
**Default:** `true`
**Previous:** Not set (disabled)
**Performance Impact:** 20-40% faster builds
Enables parallel execution of independent modules. Highly recommended for multi-module projects.

### ORG_GRADLE_CACHING
**Default:** `true`
**Previous:** Not set (disabled)
**Performance Impact:** 30-70% faster incremental builds
Enables Gradle build cache. Speeds up repeated builds significantly.

### ORG_GRADLE_DAEMON
**Default:** `true`
**Previous:** Not set (disabled by Cloud Build example with --no-daemon)
**Performance Impact:** 15-25% faster builds
Enables Gradle daemon for faster build startup.
**Note:** For CI/CD, you may still want to use `--no-daemon` flag to ensure clean builds.

### ORG_GRADLE_CONFIGUREONDEMAND
**Default:** `true`
**Previous:** Not set (disabled)
**Performance Impact:** 10-20% faster configuration phase
Configures only required modules instead of all modules.

### ORG_GRADLE_JVMARGS
**Default:** `-Xmx6144m -XX:MaxMetaspaceSize=2048m -XX:+HeapDumpOnOutOfMemoryError -XX:+UseParallelGC`
**Previous:** Not set
JVM arguments for Gradle daemon process. Uses parallel GC for better throughput.

### KOTLIN_DAEMON_JVMARGS
**Default:** `-Xmx2048m -XX:MaxMetaspaceSize=512m`
**Previous:** Not set
**Performance Impact:** 15-30% faster Kotlin compilation
JVM options for Kotlin compiler daemon. Improves Kotlin compilation speed.

### KOTLIN_INCREMENTAL
**Default:** `true`
**Previous:** Not set (disabled)
**Performance Impact:** 40-60% faster incremental Kotlin builds
Enables incremental Kotlin compilation.

### ANDROID_BUILDER_SDKLOADER_CACHEDIR
**Default:** `${ANDROID_SDK_ROOT}/.android-sdk-cache`
**Previous:** Not set
Cache directory for Android SDK loader. Improves SDK access performance.

### ANDROID_R8_MAX_WORKERS
**Default:** `4`
**Previous:** Not set (uses single worker)
**Performance Impact:** 20-40% faster R8/ProGuard processing
Maximum number of workers for R8 code optimization. Set based on available CPU cores.

### GRADLE_USER_HOME
**Default:** `/root/.gradle`
**Previous:** Not set (defaults to user home)
Gradle home directory for caches and configuration.

## GCP Deployment

### GCP_PROJECT_ID
**Required:** Yes
**Example:** `my-android-builds`
Your Google Cloud project ID.

### GCP_REGION
**Default:** `us-central1`
**Options:** `us-central1`, `europe-west1`, `asia-southeast1`
Artifact Registry region. Choose closest to your CI/CD runners.

### GCP_REGISTRY_NAME
**Default:** `android-build-images`
Artifact Registry repository name. Created automatically by Cloud Build.

## AWS Deployment

### AWS_REGION
**Default:** `us-east-1`
**Example:** `us-west-2`, `eu-central-1`
ECR repository region.

### AWS_ECR_REPO
**Default:** `android-build-image`
ECR repository name. Auto-created if missing.

### AWS_ACCOUNT_ID
**Optional** (auto-detected via `aws sts get-caller-identity`)
AWS account ID. Only needed if AWS CLI isn't configured.

## Azure Deployment

### AZURE_RESOURCE_GROUP
**Required:** Yes
**Example:** `rg-android-builds`
Azure resource group containing your ACR.

### AZURE_ACR_NAME
**Required:** Yes
**Example:** `myandroidregistry`
Azure Container Registry name (lowercase, alphanumeric only).

## Docker Hub Deployment

### DOCKERHUB_USERNAME
**Required:** Yes
**Example:** `yourname`
Docker Hub username.

### DOCKERHUB_REPO
**Default:** `android-build-image`
Repository name under your Docker Hub account.

### DOCKERHUB_PASSWORD
**Required:** Yes (sensitive)
**Source:** Environment variable or CI/CD secret
Docker Hub password or access token. **Never commit this value.**

## Quick Reference

### Optimized Builds (Smaller Image Size)

**Minimal build for standard React Native apps (no native modules, no GCP):**
```bash
# ~1.5GB smaller than default (no Docker CLI, GCloud SDK, or CMake)
docker build \
  --build-arg BASE_IMAGE=debian:bullseye-slim \
  --build-arg INSTALL_DOCKER_CLI=false \
  --build-arg INSTALL_GCLOUD_SDK=false \
  --build-arg INSTALL_CMAKE=false \
  -t android-build-image:minimal .
```

**GCP Cloud Build optimized (with GCloud SDK for Secret Manager/GCS):**
```bash
docker build \
  --build-arg BASE_IMAGE=debian:bullseye-slim \
  --build-arg INSTALL_GCLOUD_SDK=true \
  --build-arg INSTALL_DOCKER_CLI=false \
  --build-arg INSTALL_CMAKE=false \
  -t android-build-image:gcp-optimized .
```

**Full-featured build with native modules:**
```bash
docker build \
  --build-arg INSTALL_CMAKE=true \
  --build-arg INSTALL_NDK=true \
  --build-arg INSTALL_GCLOUD_SDK=true \
  -t android-build-image:full .
```

### Deployment Examples

**Minimal GCP deployment:**
```bash
GCP_PROJECT_ID=my-project make deploy-gcp
```

**AWS deployment with specific region:**
```bash
AWS_REGION=eu-west-1 AWS_ECR_REPO=my-android-builder make deploy-aws
```

### Performance Tuning

**Override Android SDK version:**
```bash
docker build --build-arg ANDROID_PLATFORM=33 --build-arg ANDROID_BUILD_TOOLS=33.0.2 -t android-build-image:api33 .
```

**Adjust memory for large projects (8GB heap):**
```bash
docker run -e GRADLE_OPTS="-Xmx8192m -XX:MaxMetaspaceSize=2048m" \
  android-build-image:latest ./gradlew assembleRelease
```

**Maximize parallelism (adjust based on CPU cores):**
```bash
docker run -e ANDROID_R8_MAX_WORKERS=8 \
  android-build-image:latest ./gradlew assembleRelease --max-workers=8
```

## Size Comparison

| Configuration | Approximate Size | Use Case |
|--------------|------------------|----------|
| **Minimal** (Debian + no optional tools) | ~1.8GB | Standard React Native apps |
| **Default** (Ubuntu + optional tools disabled) | ~2.0GB | General use |
| **GCP Optimized** (Debian + GCloud SDK) | ~2.2GB | GCP Cloud Build |
| **Full** (All tools + NDK) | ~4.5GB | Native module development |

## Performance Impact Summary

| Optimization | Impact | When to Use |
|-------------|---------|-------------|
| **ORG_GRADLE_PARALLEL=true** | 20-40% faster | Multi-module projects |
| **ORG_GRADLE_CACHING=true** | 30-70% faster (incremental) | Repeated builds |
| **KOTLIN_INCREMENTAL=true** | 40-60% faster (Kotlin) | Kotlin-based projects |
| **Increased heap (6GB)** | 15-25% faster | Large projects |
| **ANDROID_R8_MAX_WORKERS=4+** | 20-40% faster (R8) | Release builds |
