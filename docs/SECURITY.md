# Security Policy & Procedures

Security practices and policies for the Android Build Container Image.

## Reporting Security Vulnerabilities

If you discover a security vulnerability:

1. **Create a private security advisory** in the GitHub repository
2. **DO NOT** open a public issue
3. Include:
   - Vulnerability description
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if known)

We will respond within 48 hours and provide updates within 7 days.

---

## Security Philosophy

This project follows **shift-left security** and **zero trust** principles:

- **Shift-Left**: Security integrated early in development (CI/CD scanning)
- **Zero Trust**: No implicit trust for dependencies or external resources
- **Minimal Attack Surface**: Minimal packages, container isolation
- **Ephemeral Execution**: Build containers are destroyed after use
- **Free-First**: Prioritize free security tools

---

## Container Security

### Base Image Security

**Official Images Only:**
- Ubuntu 22.04 LTS (official, supported until 2027)
- Debian Bullseye (official, stable release)
- No third-party or unverified base images

**Regular Updates:**
```bash
# Rebuild with latest base image patches
docker build --no-cache --pull -t android-build-image:latest .
```

### Root User for Build Containers

This container runs as **root** (UID 0) for CI/CD compatibility.

**Why root for build containers?**
- ✅ **Standard practice** - Official build images (gcr.io/cloud-builders/*, docker:*, node:*) run as root
- ✅ **CI/CD compatibility** - No permission issues with mounted volumes in GitHub Actions, Cloud Build, etc.
- ✅ **Ephemeral execution** - Build containers run only during builds, then are destroyed
- ✅ **Container isolation** - Security maintained through namespaces, cgroups, and read-only filesystems

**Security is still maintained:**
- Container isolation (Linux namespaces and cgroups)
- No privileged mode required
- Ephemeral execution (containers destroyed after build)
- Base image security and vulnerability scanning
- No persistent data or long-running processes

**Note:** Running as root in a build container is different from production containers. Build containers are tools, not services.

### Minimal Package Installation

- Only essential packages installed
- `apt-get clean` and `rm -rf /var/lib/apt/lists/*` after each install
- No unnecessary tools (editors, debugging tools, etc.)

### Multi-Stage Builds

Use multi-stage builds to reduce final image size and attack surface:

```dockerfile
FROM ubuntu:22.04 AS base
# Build dependencies
FROM base AS builder
# Only copy necessary artifacts to final stage
FROM base AS final
```

---

## Vulnerability Scanning

### Trivy Security Scanner

**Automated Scanning:**

Trivy scans for:
- OS package vulnerabilities (apt packages)
- Application dependencies (if any)
- Misconfigurations (Dockerfile best practices)
- Exposed secrets

**Run Locally:**
```bash
make scan-security

# Or manually
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image android-build-image:latest
```

**Severity Levels:**
- **CRITICAL**: Immediate action required
- **HIGH**: Fix as soon as possible
- **MEDIUM**: Fix in next release
- **LOW**: Monitor and fix when convenient
- **UNKNOWN**: Review manually

### CI/CD Scanning

**GitHub Actions** (`.github/workflows/ci.yml`):
- Scans every PR and push
- Uploads results to GitHub Security tab
- Blocks deployment on CRITICAL/HIGH vulnerabilities
- Free for public repositories

**Cloud Build** (`cloudbuild.yaml`):
- Scans after build, before push
- Non-blocking (logs warnings)
- Can be made blocking by removing `|| echo ...`

### GitHub Security Features

**Free for Public Repos:**
- Dependabot alerts (not applicable - no app dependencies)
- Secret scanning (detects committed secrets)
- Code scanning with CodeQL (not applicable - no application code)
- Security advisories

---

## Secrets Management

### Never Commit Secrets

**Protected by `.gitignore`:**
```
.env
.env.*
*.key
*.jks
*.keystore
credentials.json
```

**Pre-Commit Checks:**
- GitHub secret scanning (automatic)
- Git hooks (optional, can be added)

### GCP Secret Manager

**Store sensitive values:**
```bash
# Store secret
echo -n "secret-value" | gcloud secrets create my-secret --data-file=-

# Grant access
gcloud secrets add-iam-policy-binding my-secret \
  --member="serviceAccount:SERVICE_ACCOUNT" \
  --role="roles/secretmanager.secretAccessor"

# Use in Cloud Build
gcloud secrets versions access latest --secret=my-secret
```

**Best Practices:**
- Use Secret Manager for passwords, tokens, API keys
- Enable audit logging
- Rotate secrets regularly
- Use automatic rotation when available
- Never log secret values

### Environment Variables

**For Local Development Only:**
```bash
# Use .env file (NEVER commit)
export DOCKERHUB_PASSWORD="token"
export AWS_SECRET_KEY="key"
```

**For CI/CD:**
- GitHub Secrets (encrypted at rest)
- Cloud Build substitutions (for non-sensitive config)
- Secret Manager (for sensitive values)

---

## Registry Security

### Access Control

**GCP Artifact Registry:**
```bash
# Grant specific permissions
gcloud artifacts repositories add-iam-policy-binding REPO \
  --member="serviceAccount:SA" \
  --role="roles/artifactregistry.reader"  # or .writer
```

**AWS ECR:**
```bash
# Set repository policy
aws ecr set-repository-policy \
  --repository-name REPO \
  --policy-text file://policy.json
```

**Azure ACR:**
```bash
# Assign RBAC role
az role assignment create \
  --assignee SERVICE_PRINCIPAL \
  --role AcrPull \
  --scope /subscriptions/SUB/resourceGroups/RG/providers/Microsoft.ContainerRegistry/registries/ACR
```

**Docker Hub:**
- Use access tokens (NOT passwords)
- Enable 2FA on account
- Limit token scope (read/write/delete)
- Rotate tokens regularly

### Encryption

**At Rest:**
- All registries encrypt images at rest by default
- GCP: Google-managed encryption keys
- AWS: AES256 encryption
- Azure: Automatic encryption

**In Transit:**
- All registry communication uses TLS/HTTPS
- No unencrypted HTTP allowed

### Registry Scanning

**Enable vulnerability scanning:**

**GCP:**
```bash
# Enable scanning on push
gcloud artifacts repositories update REPO \
  --location=REGION \
  --enable-vulnerability-scanning
```

**AWS:**
```bash
# Enable scan on push
aws ecr put-image-scanning-configuration \
  --repository-name REPO \
  --image-scanning-configuration scanOnPush=true
```

**Azure:**
```bash
# Requires Azure Defender (paid)
az security pricing create \
  --name ContainerRegistry \
  --tier Standard
```

**Docker Hub:**
- Vulnerability scanning available (free for Pro accounts)
- Enable in repository settings

---

## Build Security

### Dockerfile Best Practices

**1. Pin Base Image Versions:**
```dockerfile
# Good: Pinned version
FROM ubuntu:22.04

# Avoid: Latest tag (unpredictable)
FROM ubuntu:latest
```

**2. Verify Downloads:**
```dockerfile
# Add checksum verification
RUN wget -q https://example.com/file.tar.gz \
  && echo "EXPECTED_SHA256  file.tar.gz" | sha256sum -c - \
  && tar xzf file.tar.gz
```

**3. Clean Up in Same Layer:**
```dockerfile
RUN apt-get update && apt-get install -y package \
  && rm -rf /var/lib/apt/lists/*  # Same RUN command
```

**4. Minimize Layers:**
- Combine related commands
- Use multi-stage builds
- Remove temporary files in same layer

### CI/CD Security

**GitHub Actions:**
- Store secrets in GitHub Secrets
- Use OIDC for cloud authentication (no long-lived tokens)
- Pin action versions (`actions/checkout@v4`, not `@main`)
- Review third-party actions carefully
- Limit workflow permissions: `permissions: contents: read`

**Cloud Build:**
- Use service accounts with least privilege
- Enable audit logging
- Store secrets in Secret Manager
- Review build logs for sensitive data leaks
- Use private workers for sensitive builds (paid feature)

---

## Monitoring & Incident Response

### Monitoring

**Free Options:**
- GitHub Security tab (vulnerability alerts)
- GitHub Actions logs (build failures)
- Docker Hub scan results
- Registry access logs (GCP/AWS/Azure)

**Paid Options:**
- Azure Defender for Container Registries
- AWS GuardDuty for ECS/EKS
- GCP Security Command Center

### Incident Response

**If vulnerability discovered:**

1. **Identify**: Determine affected versions and severity
2. **Contain**: Stop using affected image, roll back if needed
3. **Eradicate**: Build new image with patched packages
4. **Recover**: Deploy patched image, verify fix
5. **Learn**: Document incident, improve processes

**Steps:**
```bash
# 1. Check vulnerability details
make scan-security

# 2. Update base image or packages
docker build --no-cache --pull -t android-build-image:patched .

# 3. Verify fix
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image android-build-image:patched

# 4. Deploy patched version
make deploy-gcp IMAGE_TAG=patched

# 5. Update latest tag
docker tag android-build-image:patched android-build-image:latest
make deploy-gcp IMAGE_TAG=latest
```

---

## Compliance & Best Practices

### Security Checklist

**Before Each Release:**
- [ ] Trivy scan passes (no CRITICAL/HIGH)
- [ ] Base image is up-to-date
- [ ] No secrets in image or logs
- [ ] Non-root user configured
- [ ] Unnecessary packages removed
- [ ] GitHub Actions workflow passes
- [ ] Image size optimized

**Ongoing:**
- [ ] Monitor security advisories
- [ ] Rebuild monthly (even if no changes)
- [ ] Rotate access tokens quarterly
- [ ] Review IAM permissions monthly
- [ ] Update documentation

### Security Headers (Not Applicable)

This is a build container, not a web service. Security headers (CSP, HSTS, etc.) are not relevant.

### Privacy & Data

**No Data Collection:**
- Container does not collect or transmit data
- No analytics or telemetry
- Builds run entirely in CI/CD environment
- No user-facing services

---

## Security Tools

### Free Tools (Used)

- **Trivy**: Vulnerability scanning (free, open-source)
- **GitHub Actions**: CI/CD with security scanning (2000 min/month free)
- **GitHub Secret Scanning**: Detects committed secrets (free)
- **Docker Hub Scanning**: Vulnerability scanning (free tier limited)

### Paid Tools (Available, NOT Used)

- **Snyk**: Advanced vulnerability scanning (~$99/month)
- **Aqua Security**: Runtime protection (~$1000+/month)
- **Sysdig**: Container security platform (~$2000+/month)
- **Azure Defender**: Container registry protection (~$15/registry/month)

---

## Security Updates

**Rebuilding Images:**

Rebuild monthly or when:
- Base image security update released
- Android SDK/tools updated
- Vulnerability discovered
- Major version changes

```bash
# Rebuild with latest patches
docker build --no-cache --pull -t android-build-image:$(date +%Y%m%d) .

# Scan for vulnerabilities
make scan-security

# Deploy if clean
make deploy-gcp IMAGE_TAG=$(date +%Y%m%d)
```

---

## Contact

For security concerns, use GitHub Security Advisories or contact maintainers privately.

---

**Last Updated:** 2025-11-28
