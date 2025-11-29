# TODO - Deployment Automation & Documentation

This document tracks remaining tasks to complete the deployment automation via GitHub Actions and project documentation for AI agents.

## Priority 1: Core Documentation

### 1.1 Create AGENTS.md
- [ ] Document project structure and architecture
- [ ] Define project objectives and goals
- [ ] Add contribution guidelines for AI agents
- [ ] Reference required secrets for all deployment targets
- [ ] Include workflow interaction guide
- [ ] Add examples of common tasks

## Priority 2: GitHub Actions - CI Workflow Enhancements

### 2.1 Dockerfile Linting
- [ ] Add hadolint step to ci.yml
- [ ] Configure hadolint rules (.hadolint.yaml)
- [ ] Set severity levels for failures

### 2.2 Build Optimization
- [ ] Implement GitHub Actions caching for Docker layers
- [ ] Add build cache configuration to buildx
- [ ] Measure and document build time improvements

### 2.3 Security Hardening
- [ ] Add explicit permissions blocks to all jobs (least privilege)
- [ ] Pin Trivy action to version 0.28.0 (currently using @master)
- [ ] Add dependency review action
- [ ] Configure security scan schedules

## Priority 3: Multi-Registry Deployment

### 3.1 Create Separate Deploy Workflow
- [ ] Create .github/workflows/deploy.yml
- [ ] Add workflow_dispatch trigger with registry selection
- [ ] Add release trigger (published)
- [ ] Implement explicit permissions blocks

### 3.2 Google Cloud Platform (GCP)
- [ ] Add GCP Artifact Registry deployment job
- [ ] Configure authentication with GCP_SA_KEY
- [ ] Set up region configuration (GCP_PROJECT_ID)
- [ ] Add tagging strategy (version + latest)
- [ ] Document required IAM roles

### 3.3 Amazon Web Services (AWS)
- [ ] Add AWS ECR deployment job
- [ ] Configure authentication with AWS credentials
- [ ] Set up region and registry configuration
- [ ] Add ECR repository creation check
- [ ] Add tagging strategy (version + latest)
- [ ] Document required IAM policies

### 3.4 Microsoft Azure
- [ ] Add Azure ACR deployment job
- [ ] Configure authentication with AZURE_CREDENTIALS
- [ ] Set up ACR name and login server
- [ ] Add tagging strategy (version + latest)
- [ ] Document required Azure roles

### 3.5 Docker Hub (Migration)
- [ ] Move Docker Hub deployment from ci.yml to deploy.yml
- [ ] Ensure consistency with other registry deployments
- [ ] Verify DOCKERHUB_TOKEN is used (not DOCKERHUB_PASSWORD)

## Priority 4: Workflow Integration

### 4.1 Manual Dispatch Enhancement
- [ ] Add input parameter for target registry selection
  - [ ] all (default)
  - [ ] dockerhub
  - [ ] gcp
  - [ ] aws
  - [ ] azure
- [ ] Implement conditional job execution based on input
- [ ] Add dry-run option for testing

### 4.2 Release Automation
- [ ] Configure automatic deployment on release publish
- [ ] Add version extraction from git tags
- [ ] Implement multi-registry parallel deployment
- [ ] Add deployment status notifications

## Priority 5: Testing & Validation

### 5.1 Workflow Testing
- [ ] Test ci.yml workflow on feature branch
- [ ] Test deploy.yml with workflow_dispatch
- [ ] Validate all registry deployments
- [ ] Verify security scans upload to GitHub Security

### 5.2 Documentation Testing
- [ ] Validate all secret configurations
- [ ] Test manual deployment procedures
- [ ] Verify AI agent can follow AGENTS.md
- [ ] Update examples with real outputs

## Priority 6: Secrets Documentation

### 6.1 Repository Secrets Setup Guide
Create comprehensive guide for setting up GitHub repository secrets:

**Docker Hub**
- [ ] Document DOCKERHUB_USERNAME setup
- [ ] Document DOCKERHUB_TOKEN creation (not password)
- [ ] Add security best practices

**GCP Artifact Registry**
- [ ] Document GCP_PROJECT_ID configuration
- [ ] Document service account creation
- [ ] Document GCP_SA_KEY generation (JSON key)
- [ ] List required IAM roles

**AWS ECR**
- [ ] Document AWS_ACCESS_KEY_ID setup
- [ ] Document AWS_SECRET_ACCESS_KEY setup
- [ ] Document IAM user creation
- [ ] List required IAM policies

**Azure ACR**
- [ ] Document AZURE_CREDENTIALS creation
- [ ] Document AZURE_ACR_NAME configuration
- [ ] Document service principal setup
- [ ] List required Azure roles

## Priority 7: CI/CD Improvements

### 7.1 Smoke Tests Enhancement
- [ ] Add Gradle verification
- [ ] Add SDK build tools check
- [ ] Add platform tools verification
- [ ] Add build simulation test

### 7.2 Monitoring & Notifications
- [ ] Add workflow status badges to README.md
- [ ] Configure failure notifications
- [ ] Add deployment success confirmations
- [ ] Set up Slack/email notifications (optional)

## Implementation Order Recommendation

1. **Phase 1 - Foundation** (1-2 hours)
   - Create AGENTS.md
   - Add hadolint to ci.yml
   - Pin Trivy version
   - Add permissions blocks to ci.yml

2. **Phase 2 - Deploy Workflow** (2-3 hours)
   - Create deploy.yml structure
   - Move Docker Hub deployment
   - Add workflow_dispatch with inputs
   - Add permissions blocks

3. **Phase 3 - Multi-Registry** (3-4 hours)
   - Implement GCP deployment
   - Implement AWS deployment
   - Implement Azure deployment
   - Test each registry separately

4. **Phase 4 - Testing & Documentation** (1-2 hours)
   - Test all workflows
   - Document all secrets
   - Update AGENTS.md with examples
   - Add workflow badges

## Notes

- All workflows should follow the principle of least privilege
- Pin all GitHub Actions to specific versions for security
- Test workflows on feature branches before merging
- Document all required secrets before testing deployments
- Consider using environments for additional protection

## Related Documentation

- [DEPLOYMENT.md](./DEPLOYMENT.md) - Manual deployment procedures
- [SECURITY.md](./SECURITY.md) - Security guidelines
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues
- AGENTS.md - To be created

---

**Last Updated:** 2025-11-29
**Status:** Planning Phase
