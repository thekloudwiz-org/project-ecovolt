# CI/CD Setup Guide

This guide explains how to set up the GitHub Actions CI/CD pipeline with AWS OIDC authentication.

## Architecture Overview

The CI/CD pipeline uses:
- **OIDC (OpenID Connect)** for secure, keyless authentication to AWS
- **Reusable workflows** to avoid code duplication
- **Environment-specific workflows** for dev, staging, and prod
- **Branch-based deployment** strategy

## Workflow Structure

### Reusable Workflow
`.github/workflows/terraform-reusable.yml` - Contains all the common jobs:
- `terraform-init` - Initialize Terraform
- `terraform-validate` - Validate and format check
- `security-scan` - Run tfsec and Checkov
- `terraform-plan` - Create execution plan
- `terraform-apply` - Apply changes (conditional)

### Environment Workflows
- `.github/workflows/dev.yml` - Dev environment
- `.github/workflows/staging.yml` - Staging environment
- `.github/workflows/prod.yml` - Production environment

## Trigger Strategy

### Dev Branch
| Event | Jobs Run | Apply? |
|-------|----------|--------|
| Push to `dev` | init → validate → security → plan → **apply** | ✅ Yes |
| PR to `dev` | init → validate → security → plan | ❌ No |
| PR merged to `dev` | init → validate → security → plan → **apply** | ✅ Yes |

### Staging Branch
| Event | Jobs Run | Apply? |
|-------|----------|--------|
| PR to `staging` | init → validate → security → plan | ❌ No |
| PR merged to `staging` | init → validate → security → plan → **apply** | ✅ Yes |

### Main Branch (Production)
| Event | Jobs Run | Apply? |
|-------|----------|--------|
| PR to `main` | init → validate → security → plan | ❌ No |
| PR merged to `main` | init → validate → security → plan → **apply** | ✅ Yes |

## Prerequisites

### 1. AWS OIDC Identity Provider

Your AWS account should already have an OIDC identity provider configured. If not, create one:

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 2. IAM Roles for Each Environment

You mentioned the roles are already created. They should have:

**Trust Policy** (example for dev):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:thekloudwiz-org/YOUR_REPO_NAME:ref:refs/heads/dev"
        }
      }
    }
  ]
}
```

**Note**: Replace `YOUR_REPO_NAME` with your actual repository name.
```

**Permissions Policy** (attach appropriate policies):
- `AdministratorAccess` (for full infrastructure management)
- Or custom policy with specific permissions for your resources

### 3. GitHub Secrets

Add the following secrets to your GitHub repository:

#### Repository Secrets
Go to: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ROLE_ARN_DEV` | `arn:aws:iam::ACCOUNT_ID:role/github-actions-dev` | Dev environment role ARN |
| `AWS_ROLE_ARN_STAGING` | `arn:aws:iam::ACCOUNT_ID:role/github-actions-staging` | Staging environment role ARN |
| `AWS_ROLE_ARN_PROD` | `arn:aws:iam::ACCOUNT_ID:role/github-actions-prod` | Production environment role ARN |

**Note**: Replace `ACCOUNT_ID` with your AWS account ID.

### 4. GitHub Environments (Optional but Recommended)

Create GitHub environments for additional protection:

Go to: `Settings` → `Environments` → `New environment`

#### Dev Environment
- Name: `dev`
- Protection rules: None (auto-deploy)

#### Staging Environment
- Name: `staging`
- Protection rules:
  - ✅ Required reviewers: 1 reviewer
  - ✅ Wait timer: 0 minutes

#### Prod Environment
- Name: `prod`
- Protection rules:
  - ✅ Required reviewers: 2 reviewers
  - ✅ Wait timer: 5 minutes
  - ✅ Deployment branches: Only `main` branch

## Setup Steps

### Step 1: Get Your IAM Role ARNs

```bash
# List IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `github-actions`)].{Name:RoleName,ARN:Arn}' --output table

# Or get specific role ARN
aws iam get-role --role-name github-actions-dev --query 'Role.Arn' --output text
```

### Step 2: Add Secrets to GitHub

```bash
# Using GitHub CLI (recommended)
gh secret set AWS_ROLE_ARN_DEV --body "arn:aws:iam::123456789012:role/github-actions-dev"
gh secret set AWS_ROLE_ARN_STAGING --body "arn:aws:iam::123456789012:role/github-actions-staging"
gh secret set AWS_ROLE_ARN_PROD --body "arn:aws:iam::123456789012:role/github-actions-prod"

# Or manually via GitHub UI
# Settings → Secrets and variables → Actions → New repository secret
```

### Step 3: Create GitHub Environments

```bash
# Using GitHub CLI
gh api repos/:owner/:repo/environments/dev -X PUT
gh api repos/:owner/:repo/environments/staging -X PUT
gh api repos/:owner/:repo/environments/prod -X PUT

# Or manually via GitHub UI
# Settings → Environments → New environment
```

### Step 4: Configure Branch Protection (Optional)

```bash
# Protect main branch
gh api repos/:owner/:repo/branches/main/protection -X PUT -f required_pull_request_reviews[required_approving_review_count]=2

# Protect staging branch
gh api repos/:owner/:repo/branches/staging/protection -X PUT -f required_pull_request_reviews[required_approving_review_count]=1
```

### Step 5: Test the Pipeline

1. **Create a test branch from dev**:
   ```bash
   git checkout dev
   git checkout -b test-cicd
   ```

2. **Make a small change**:
   ```bash
   echo "# Test" >> README.md
   git add README.md
   git commit -m "test: CI/CD pipeline"
   git push origin test-cicd
   ```

3. **Create a PR to dev**:
   ```bash
   gh pr create --base dev --title "Test CI/CD" --body "Testing the pipeline"
   ```

4. **Check the workflow**:
   - Go to `Actions` tab in GitHub
   - You should see the workflow running
   - It should run: init → validate → security → plan
   - It should NOT run apply (because it's a PR)

5. **Merge the PR**:
   ```bash
   gh pr merge --merge
   ```

6. **Verify apply runs**:
   - Check the `Actions` tab again
   - The workflow should now run apply

## Workflow Features

### 1. Terraform Caching
- Caches `.terraform` directory and lock file
- Speeds up subsequent runs
- Cache key based on Terraform files hash

### 2. Plan Artifacts
- Saves plan output as artifact
- Available for 5 days
- Used by apply job

### 3. PR Comments
- Posts plan output as PR comment
- Shows format check failures
- Confirms successful apply

### 4. Security Scanning
- **tfsec**: Scans for security issues
- **Checkov**: Additional policy checks
- Results uploaded to GitHub Security tab

### 5. OIDC Authentication
- No long-lived credentials
- Temporary credentials per job
- Scoped to specific branches

## Troubleshooting

### Issue: "Error assuming role"

**Cause**: Trust policy doesn't allow the branch/repo

**Solution**: Update the IAM role trust policy:
```json
{
  "StringLike": {
    "token.actions.githubusercontent.com:sub": [
      "repo:thekloudwiz-org/YOUR_REPO_NAME:ref:refs/heads/dev",
      "repo:thekloudwiz-org/YOUR_REPO_NAME:ref:refs/heads/staging",
      "repo:thekloudwiz-org/YOUR_REPO_NAME:ref:refs/heads/main",
      "repo:thekloudwiz-org/YOUR_REPO_NAME:pull_request"
    ]
  }
}
```

### Issue: "Secret not found"

**Cause**: Secret name mismatch or not set

**Solution**: Verify secret names:
```bash
gh secret list
```

### Issue: "Terraform init failed"

**Cause**: Backend configuration issue

**Solution**: Check backend configuration in `backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "ecovolt-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "ecovolt-terraform-locks"
  }
}
```

### Issue: "Plan shows unexpected changes"

**Cause**: State drift or manual changes

**Solution**: 
1. Review the plan carefully
2. Run `terraform refresh` locally
3. Check for manual changes in AWS console

## Best Practices

### 1. Always Review Plans
- Never merge without reviewing the plan
- Check for unexpected resource deletions
- Verify resource counts

### 2. Use Feature Branches
```bash
# Good workflow
git checkout dev
git checkout -b feature/add-monitoring
# Make changes
git push origin feature/add-monitoring
gh pr create --base dev
```

### 3. Test in Dev First
- Always test changes in dev environment
- Promote to staging after validation
- Deploy to prod only after staging approval

### 4. Monitor Deployments
- Watch CloudWatch logs during apply
- Check resource creation in AWS console
- Verify application functionality

### 5. Rollback Strategy
```bash
# If deployment fails, revert the merge
git revert HEAD
git push origin dev

# Or manually apply previous state
terraform apply -var-file=environments/dev.tfvars
```

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐            │
│  │   Init   │───▶│ Validate │───▶│ Security │            │
│  └──────────┘    └──────────┘    └──────────┘            │
│                                         │                   │
│                                         ▼                   │
│                                   ┌──────────┐            │
│                                   │   Plan   │            │
│                                   └──────────┘            │
│                                         │                   │
│                    ┌────────────────────┴────────┐         │
│                    │                             │         │
│                    ▼                             ▼         │
│              ┌──────────┐                 ┌──────────┐    │
│              │ PR Only  │                 │  Merge   │    │
│              │  (Stop)  │                 │  (Apply) │    │
│              └──────────┘                 └──────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   AWS (OIDC)     │
                    │  eu-central-1    │
                    └──────────────────┘
```

## Security Considerations

1. **OIDC vs Access Keys**: OIDC is more secure (no long-lived credentials)
2. **Least Privilege**: IAM roles should have minimum required permissions
3. **Branch Protection**: Require reviews for staging/prod
4. **Environment Protection**: Use GitHub environments for additional gates
5. **Audit Logs**: Monitor CloudTrail for all API calls from GitHub Actions

## Cost Optimization

### GitHub Actions Minutes (Private Repo)
- **Free tier**: 2,000 minutes/month for private repos (Team plan)
- **Cost after free tier**: $0.008/minute
- **Typical workflow**: ~5-10 minutes per run
- **Estimated monthly runs**: 
  - Dev: ~100 runs = 500-1000 minutes
  - Staging: ~20 runs = 100-200 minutes
  - Prod: ~10 runs = 50-100 minutes
  - **Total**: ~650-1300 minutes/month (within free tier)

### Cost Reduction Tips
- Caching reduces execution time by ~30-50%
- Plan artifacts are small and cheap to store
- Use `concurrency` groups to cancel outdated runs
- Optimize Terraform init with backend caching

## Next Steps

1. ✅ Add IAM role ARNs to GitHub secrets
2. ✅ Create GitHub environments (optional)
3. ✅ Test with a small PR to dev
4. ✅ Verify plan output in PR comments
5. ✅ Merge and verify apply runs successfully
6. ✅ Repeat for staging and prod

## Support

For issues or questions:
- Check GitHub Actions logs
- Review AWS CloudTrail logs
- Check Terraform state in S3
- Contact DevOps team
