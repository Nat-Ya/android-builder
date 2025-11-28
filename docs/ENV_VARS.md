# Environment Variables Reference

## Build Configuration

### BASE_IMAGE
**Default:** `ubuntu:22.04`
**Options:** `ubuntu:22.04` | `debian:bullseye-slim`
Base Linux distribution for the container. Debian is ~50MB smaller.

### IMAGE_TAG
**Default:** `latest`
**Example:** `v1.0.0`, `2024-11-28`, `prod`
Version tag for the built image.

### IMAGE_NAME
**Default:** `android-build-image`
Local image name before registry tagging.

## Docker Build Arguments

### JAVA_VERSION
**Default:** `17`
OpenJDK version. Change only if your project requires different Java version.

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

### INSTALL_NDK
**Default:** `false`
**Options:** `true` | `false`
Whether to install Android NDK. Only enable if you need native modules.
**Note:** Installing NDK significantly increases image size (~2GB).

## Runtime Configuration

### GRADLE_OPTS
**Default:** `-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8`
JVM options for Gradle builds. 4GB heap recommended for Android builds.

### JAVA_OPTS
**Default:** `-Xmx4096m -XX:MaxMetaspaceSize=1024m`
General JVM options. Mirrors GRADLE_OPTS for consistency.

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

**Minimal GCP deployment:**
```bash
GCP_PROJECT_ID=my-project make deploy-gcp
```

**Custom build with Debian base:**
```bash
BASE_IMAGE=debian:bullseye-slim IMAGE_TAG=v1.0.0 make build-local
```

**AWS deployment with specific region:**
```bash
AWS_REGION=eu-west-1 AWS_ECR_REPO=my-android-builder make deploy-aws
```

**Override Android SDK version:**
```bash
docker build --build-arg ANDROID_PLATFORM=33 --build-arg ANDROID_BUILD_TOOLS=33.0.2 -t android-build-image:api33 .
```

**Build with NDK for native modules:**
```bash
docker build --build-arg INSTALL_NDK=true -t android-build-image:ndk .
```
