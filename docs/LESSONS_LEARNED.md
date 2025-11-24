# Lessons Learned from Cloud Build Android Build Setup

This document captures key learnings from setting up Android builds on Google Cloud Build that should be applied to the Android builder image.

## Key Learnings

### 1. Cloud Build Substitution Handling

**Issue**: Cloud Build expands substitutions `${_VAR:-default}` before bash evaluates them, causing default values to always be used.

**Solution**: 
- Use direct substitution access: `GRADLE_TASK="${_BUILD_TARGET}"`
- Use explicit if-checks for defaults instead of bash default syntax:
  ```bash
  if [ -z "$GRADLE_TASK" ]; then
    GRADLE_TASK="assembleRelease"
  fi
  ```

**Application to Builder Image**: The builder image Dockerfile should document this pattern for users who use Cloud Build substitutions.

### 2. Working Directory in Cloud Build

**Issue**: Cloud Build runs from the uploaded source directory root. Each step starts fresh from that root.

**Solution**:
- Remove redundant `cd app || cd .` commands - they're unnecessary if Cloud Build already runs from the project root
- Document the actual working directory structure clearly
- Use absolute or relative paths consistently

**Application to Builder Image**: The builder image should work from a predictable working directory and document where artifacts are generated relative to that directory.

### 3. Artifact Path Resolution

**Issue**: Artifacts generated in subdirectories (e.g., `android/app/build/...`) need correct path resolution in subsequent steps.

**Solution**:
- When a build step runs from `android/`, artifacts are at `app/build/outputs/...` relative to that directory
- From project root, artifacts are at `android/app/build/outputs/...`
- Use consistent path resolution logic

**Application to Builder Image**: Document expected artifact locations and provide helper scripts or examples for artifact discovery.

### 4. Memory Configuration for Gradle

**Learnings**:
- Default Gradle heap: 4GB works well for most builds
- MaxMetaspaceSize: 1GB is sufficient
- Cloud Build N1_HIGHCPU_8: 7.5GB total RAM, so 4GB heap leaves room for system
- Use `--no-daemon --max-workers=1 --no-parallel` in Cloud Build for predictable memory usage

**Application to Builder Image**: 
- Default `GRADLE_OPTS` should be: `-Xmx4096m -XX:MaxMetaspaceSize=1024m`
- Make it configurable via environment variables
- Document memory tuning for different machine types

### 5. Build Target Substitution

**Issue**: Makefile variable expansion and Cloud Build substitutions need careful handling.

**Solution**:
- Use `$(or $(_BUILD_TARGET),$(BUILD_TARGET),default)` in Makefiles
- Pass substitutions as `_BUILD_TARGET=value` (underscore prefix for Cloud Build)
- Quote substitution values: `--substitutions="_BUILD_TARGET=$$BUILD_TARGET_VAL"`

**Application to Builder Image**: Provide example Cloud Build configs that demonstrate proper substitution usage.

### 6. Node.js and npm Setup

**Learnings**:
- Node.js 20 LTS is required for React Native/Expo
- Use NodeSource repository for reliable installation
- `npm ci` should be used in CI/CD for reproducible builds

**Application to Builder Image**: Already included, ensure Node.js 20 is the default.

### 7. Android SDK Installation

**Learnings**:
- Command Line Tools version: `commandlinetools-linux-9477386_latest.zip`
- Platform API 34 and Build Tools 34.0.0 are current
- License acceptance should be automated: `yes | sdkmanager --licenses || true`
- SDK location: `/opt/android-sdk` works well

**Application to Builder Image**: Already correctly configured, document the versions.

### 8. Keystore Management

**Learnings**:
- Store keystore passwords in Secret Manager, not in code
- Keystore files can be in GCS or in repository
- Use environment variables for keystore paths and passwords
- `gradle.properties` should use environment variable placeholders

**Application to Builder Image**: Document best practices for keystore handling in CI/CD.

### 9. Build Artifact Upload

**Learnings**:
- Use `${BUILD_ID}` in artifact names for uniqueness
- Upload to GCS bucket: `gs://bucket-name/builds/artifact-${BUILD_ID}.ext`
- Verify artifact exists before upload
- Use `gsutil cp` for reliable uploads

**Application to Builder Image**: Provide example scripts for artifact upload patterns.

### 10. Error Handling and Debugging

**Best Practices**:
- Add debug output: `echo "Current directory: $(pwd)"`
- List directories when debugging path issues: `ls -la`
- Use `find . -name "*.aab"` to locate artifacts
- Check Cloud Build logs with: `gcloud builds log <BUILD_ID>`

**Application to Builder Image**: Include debugging utilities or helper scripts in the image.

## Recommendations for Android Builder Image

1. **Documentation**: Create clear examples showing:
   - Cloud Build substitution usage
   - Artifact path patterns
   - Memory configuration
   - Keystore management

2. **Helper Scripts**: Consider including:
   - Artifact finder script
   - Memory checker script
   - Build target validator

3. **Environment Variables**: Document all configurable vars:
   - `GRADLE_OPTS`
   - `JAVA_OPTS`
   - `ANDROID_SDK_ROOT`
   - `JAVA_HOME`

4. **Testing**: Include test cases that verify:
   - Substitution handling
   - Artifact generation paths
   - Memory settings

5. **Multi-stage Builds**: The Dockerfile should be optimized for caching while remaining flexible.

## Build Success Metrics

After applying these learnings:
- ✅ APK builds successfully in Cloud Build
- ✅ AAB builds successfully in Cloud Build
- ✅ Artifacts correctly uploaded to GCS
- ✅ Build time reasonable (14-20 minutes)
- ✅ Memory usage predictable and within limits

