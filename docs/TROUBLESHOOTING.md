# Troubleshooting Guide

Common issues and solutions for the Android Build Container Image.

## Table of Contents

1. [Docker Build Issues](#docker-build-issues)
2. [Registry Authentication](#registry-authentication)
3. [Cloud Build Failures](#cloud-build-failures)
4. [Image Pull/Push Errors](#image-pullpush-errors)
5. [Runtime Issues](#runtime-issues)
6. [Performance Problems](#performance-problems)

---

## Docker Build Issues

### Build Fails on Docker CLI Installation

**Error:**
```
E: Unable to locate package docker-ce-cli
```

**Cause:** Dockerfile Docker CLI installation assumes Ubuntu. Fails on Debian base images.

**Solution:**

Use Ubuntu base image (default):
```bash
make build-local BASE_IMAGE=ubuntu:22.04
```

Or fix Dockerfile for Debian support:
```dockerfile
# Add conditional logic based on OS
RUN if grep -q "ubuntu" /etc/os-release; then \
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
    else \
      curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
    fi
```

### Android SDK Download Timeout

**Error:**
```
wget: unable to resolve host address 'dl.google.com'
```

**Causes:**
- Network connectivity issue
- DNS resolution failure
- Firewall blocking download

**Solutions:**

1. **Retry build** (temporary network issue):
   ```bash
   make build-local
   ```

2. **Check network connectivity:**
   ```bash
   docker run --rm ubuntu:22.04 ping -c 3 dl.google.com
   ```

3. **Use proxy** (if behind corporate firewall):
   ```bash
   docker build --build-arg HTTP_PROXY=http://proxy:port -t android-build-image .
   ```

4. **Pre-download SDK** and copy into image:
   ```dockerfile
   # In Dockerfile, replace wget with COPY
   COPY commandlinetools-linux-9477386_latest.zip /tmp/cmdline-tools.zip
   ```

### Out of Disk Space

**Error:**
```
no space left on device
```

**Solutions:**

1. **Clean Docker cache:**
   ```bash
   docker system prune -a --volumes
   ```

2. **Remove unused images:**
   ```bash
   docker image prune -a
   ```

3. **Increase Docker disk allocation** (Docker Desktop):
   - Settings → Resources → Disk image size → Increase

4. **Use multi-stage builds** (already implemented)

### Build Hangs on `sdkmanager --licenses`

**Symptom:** Build stops at license acceptance step.

**Cause:** `sdkmanager --licenses` expects interactive input.

**Solution:** Already fixed with `yes | sdkmanager --licenses || true` in Dockerfile.

If still hanging:
```bash
# Build with --no-cache to force re-run
docker build --no-cache -t android-build-image .
```

---

## Registry Authentication

### GCP Authentication Fails

**Error:**
```
Error response from daemon: Get https://us-central1-docker.pkg.dev: unauthorized
```

**Solutions:**

1. **Re-authenticate:**
   ```bash
   gcloud auth login
   gcloud auth configure-docker us-central1-docker.pkg.dev
   ```

2. **Check active account:**
   ```bash
   gcloud auth list
   # Switch account if needed
   gcloud config set account USER@DOMAIN.com
   ```

3. **Check project:**
   ```bash
   gcloud config get-value project
   # Set correct project
   gcloud config set project PROJECT_ID
   ```

4. **Check IAM permissions:**
   ```bash
   # Must have roles/artifactregistry.writer
   gcloud projects get-iam-policy PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:user:USER@DOMAIN.com"
   ```

### AWS ECR Authentication Expires

**Error:**
```
no basic auth credentials
```

**Cause:** ECR tokens expire after 12 hours.

**Solution:** Re-authenticate:
```bash
make aws-login AWS_REGION=us-east-1
```

**For CI/CD:** Authenticate before each deployment:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Azure ACR 401 Unauthorized

**Error:**
```
Error response from daemon: Get https://myregistry.azurecr.io: unauthorized
```

**Solutions:**

1. **Re-authenticate:**
   ```bash
   az login
   az acr login --name myregistry
   ```

2. **Check subscription:**
   ```bash
   az account show
   # Switch subscription
   az account set --subscription SUBSCRIPTION_ID
   ```

3. **Use admin credentials** (not recommended for production):
   ```bash
   az acr update --name myregistry --admin-enabled true
   az acr credential show --name myregistry
   docker login myregistry.azurecr.io --username USERNAME --password PASSWORD
   ```

### Docker Hub Rate Limits

**Error:**
```
toomanyrequests: You have reached your pull rate limit
```

**Cause:** Docker Hub limits unauthenticated pulls (100/6hr per IP).

**Solutions:**

1. **Authenticate:**
   ```bash
   docker login
   ```

2. **Use access token** (recommended):
   - Create token at https://hub.docker.com/settings/security
   - Use token as password

3. **Use paid plan** (removes rate limits):
   - Docker Pro: $7/month

---

## Cloud Build Failures

### Cloud Build: Permission Denied

**Error:**
```
ERROR: (gcloud.builds.submit) PERMISSION_DENIED: The caller does not have permission
```

**Solutions:**

1. **Enable Cloud Build API:**
   ```bash
   gcloud services enable cloudbuild.googleapis.com
   ```

2. **Grant permissions to Cloud Build service account:**
   ```bash
   PROJECT_NUMBER=$(gcloud projects describe PROJECT_ID --format="value(projectNumber)")

   # Grant Artifact Registry writer
   gcloud artifacts repositories add-iam-policy-binding REPO \
     --location=REGION \
     --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
     --role="roles/artifactregistry.writer"
   ```

3. **Check billing:** Cloud Build requires billing enabled on project.

### Cloud Build: Timeout

**Error:**
```
ERROR: build step 0 timed out after 600s
```

**Solutions:**

1. **Increase timeout in `cloudbuild.yaml`:**
   ```yaml
   timeout: '1800s'  # 30 minutes
   ```

2. **Use faster machine:**
   ```yaml
   options:
     machineType: 'N1_HIGHCPU_8'  # or E2_HIGHCPU_8
   ```

3. **Use cached layers:**
   ```yaml
   options:
     cacheFrom:
       - 'us-central1-docker.pkg.dev/PROJECT/REPO/IMAGE:latest'
   ```

### Cloud Build: Substitution Error

**Error:**
```
Invalid substitution variable: _BASE_IMAGE
```

**Cause:** Using bash default value syntax (`${_BASE_IMAGE:-ubuntu:22.04}`) in Cloud Build.

**Solution:** Use Cloud Build substitution defaults:
```yaml
substitutions:
  _BASE_IMAGE: 'ubuntu:22.04'  # Default value
```

Do NOT use `${_BASE_IMAGE:-ubuntu:22.04}` syntax in Cloud Build YAML.

---

## Image Pull/Push Errors

### Image Not Found After Push

**Symptom:** Push succeeds, but pull fails with "not found".

**Causes:**
1. Wrong registry URL
2. Wrong image name or tag
3. Wrong region (GCP)

**Solutions:**

1. **Verify image exists:**
   ```bash
   # GCP
   gcloud artifacts docker images list REGION-docker.pkg.dev/PROJECT/REPO

   # AWS
   aws ecr describe-images --repository-name REPO --region REGION

   # Azure
   az acr repository show-tags --name REGISTRY --repository IMAGE

   # Docker Hub
   curl https://hub.docker.com/v2/repositories/USERNAME/REPO/tags
   ```

2. **Use exact path from push:**
   ```bash
   # Copy exact image path from push output
   docker pull EXACT_PATH:TAG
   ```

### Large Image Size

**Symptom:** Image is larger than expected (>5GB).

**Causes:**
- Multiple layers with repeated files
- Not cleaning apt cache
- Unnecessary files copied

**Solutions:**

1. **Check layer sizes:**
   ```bash
   docker history android-build-image:latest
   ```

2. **Use multi-stage builds** (already implemented)

3. **Clean in same layer:**
   ```dockerfile
   RUN apt-get update && apt-get install -y package \
     && rm -rf /var/lib/apt/lists/*  # Same RUN
   ```

4. **Use `.dockerignore`** (already configured)

### Push Fails: Blob Upload Unknown

**Error:**
```
blob upload unknown
```

**Causes:**
- Network interruption
- Registry throttling
- Disk space issue

**Solutions:**

1. **Retry push:**
   ```bash
   docker push IMAGE:TAG
   ```

2. **Check disk space:**
   ```bash
   df -h
   docker system df
   ```

3. **Clean up:**
   ```bash
   docker system prune -a
   ```

---

## Runtime Issues

### Container Cannot Access Network

**Error:**
```
Could not resolve host: example.com
```

**Solutions:**

1. **Check Docker network:**
   ```bash
   docker run --rm android-build-image:latest ping -c 3 google.com
   ```

2. **Use custom DNS:**
   ```bash
   docker run --dns 8.8.8.8 --dns 8.8.4.4 android-build-image:latest
   ```

3. **Check Docker daemon DNS** (Docker Desktop):
   - Settings → Docker Engine → Add `"dns": ["8.8.8.8"]`

### Permission Denied Inside Container

**Error:**
```
Permission denied: /opt/android-sdk
```

**Cause:** Running as non-root user (`android-builder`).

**Solutions:**

1. **Install files as root, then switch user** (already done):
   ```dockerfile
   RUN mkdir -p /opt/android-sdk  # As root
   USER android-builder          # Switch after setup
   ```

2. **Use root user for debugging only:**
   ```bash
   docker run --rm --user root android-build-image:latest bash
   ```

3. **Check file ownership:**
   ```bash
   docker run --rm android-build-image:latest ls -la /opt/android-sdk
   ```

### Java Out of Memory

**Error:**
```
java.lang.OutOfMemoryError: Java heap space
```

**Solutions:**

1. **Increase heap size** (already set to 4GB in image):
   ```dockerfile
   ENV GRADLE_OPTS="-Xmx4096m"
   ```

2. **Override at runtime:**
   ```bash
   docker run --rm -e GRADLE_OPTS="-Xmx8192m" android-build-image:latest
   ```

3. **Increase Docker memory allocation** (Docker Desktop):
   - Settings → Resources → Memory → Increase

---

## Performance Problems

### Build is Slow

**Symptoms:** Docker build takes >30 minutes.

**Solutions:**

1. **Use build cache:**
   ```bash
   docker build -t android-build-image:latest .  # Uses cache
   ```

2. **Use faster machine:**
   - Local: Use Docker Desktop with more CPU/RAM
   - Cloud Build: Use `N1_HIGHCPU_8` or `E2_HIGHCPU_8`

3. **Parallelize downloads:**
   ```dockerfile
   RUN wget URL1 & wget URL2 & wait  # Download in parallel
   ```

4. **Pre-download large files** (Android SDK) and COPY instead of wget

5. **Use SSD for Docker storage**

### Container Runs Slowly

**Symptoms:** Builds inside container take much longer than expected.

**Solutions:**

1. **Allocate more resources** (Docker Desktop):
   - CPU: At least 4 cores
   - Memory: At least 8GB
   - Swap: 2GB

2. **Check resource usage:**
   ```bash
   docker stats
   ```

3. **Use volumes for node_modules** (if building apps):
   ```bash
   docker run -v node_modules:/app/node_modules android-build-image
   ```

4. **Optimize Gradle:**
   ```bash
   # Already set in image
   export GRADLE_OPTS="-Xmx4096m -XX:MaxMetaspaceSize=1024m"
   ```

---

## Environment & Tool Issues

### Tool Not Found in PATH

**Error:**
```
bash: sdkmanager: command not found
```

**Solutions:**

1. **Check PATH is set:**
   ```bash
   docker run --rm android-build-image:latest bash -c 'echo $PATH'
   ```

2. **Source profile:**
   ```bash
   docker run --rm android-build-image:latest bash -c 'source ~/.bashrc && sdkmanager --version'
   ```

3. **Use full path:**
   ```bash
   docker run --rm android-build-image:latest /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --version
   ```

### Wrong Java/Node Version

**Symptom:** Build requires different Java or Node version.

**Solutions:**

1. **Rebuild with custom versions:**
   ```bash
   docker build --build-arg JAVA_VERSION=11 --build-arg NODE_VERSION=18 -t android-build-image:custom .
   ```

2. **Check current versions:**
   ```bash
   docker run --rm android-build-image:latest bash -c 'java -version && node --version'
   ```

---

## CLI Tools Not Found

### gcloud/aws/az Command Not Found

**Error:**
```
bash: gcloud: command not found
```

**Cause:** CLI tools not installed or not in PATH.

**Solutions:**

1. **Restart terminal** after installation (PATH updated during install)

2. **Verify installation:**
   ```bash
   # Check if executable exists
   which gcloud  # or aws, or az
   ```

3. **Add to PATH manually** (if restart doesn't work):
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/gcloud/bin"
   source ~/.bashrc
   ```

4. **Reinstall CLI tool:**
   - GCP: https://cloud.google.com/sdk/docs/install
   - AWS: https://aws.amazon.com/cli/
   - Azure: https://learn.microsoft.com/cli/azure/install-azure-cli

---

## Getting Help

### Enable Debug Logging

**Docker Build:**
```bash
DOCKER_BUILDKIT=0 docker build --progress=plain --no-cache -t android-build-image .
```

**Cloud Build:**
```bash
gcloud builds submit --config cloudbuild.yaml --log-http .
```

**Docker Run:**
```bash
docker run --rm -it android-build-image:latest bash  # Interactive debugging
```

### Check Logs

**Docker logs:**
```bash
docker logs CONTAINER_ID
```

**Cloud Build logs:**
```bash
gcloud builds log BUILD_ID
# Or view in Cloud Console: https://console.cloud.google.com/cloud-build/builds
```

**GitHub Actions logs:**
- Go to repository → Actions → Select workflow run → View logs

### Common Diagnostic Commands

```bash
# Check Docker version
docker version

# Check Docker info
docker info

# Check image details
docker inspect android-build-image:latest

# Check registry connectivity
docker pull hello-world

# Test image
make test-image
```

---

## Still Having Issues?

1. **Check existing issues:** https://github.com/YOUR-REPO/issues
2. **Search documentation:** README, ENV_VARS.md, DEPLOYMENT.md, SECURITY.md
3. **Enable debug logging** and capture full output
4. **Open a new issue** with:
   - Operating system and Docker version
   - Full command used
   - Complete error message
   - Steps to reproduce

---

**Last Updated:** 2025-11-28
