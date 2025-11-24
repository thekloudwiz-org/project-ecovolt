# GitHub Actions Workflows

This directory contains the CI/CD workflows for the EcoVolt infrastructure.

## Workflow Files

### Reusable Workflow
- **`terraform-reusable.yml`** - Core workflow with all jobs (init, validate, security, plan, apply)

### Environment Workflows
- **`dev.yml`** - Dev environment (auto-deploys on push to `dev` branch)
- **`staging.yml`** - Staging environment (deploys on merge to `staging` branch)
- **`prod.yml`** - Production environment (deploys on merge to `main` branch)

## Quick Start

### 1. Add GitHub Secrets

Add these secrets to your repository (`Settings` → `Secrets and variables` → `Actions`):

```
AWS_ROLE_ARN_DEV      = arn:aws:iam::ACCOUNT_ID:role/github-actions-dev
AWS_ROLE_ARN_STAGING  = arn:aws:iam::ACCOUNT_ID:role/github-actions-staging
AWS_ROLE_ARN_PROD     = arn:aws:iam::ACCOUNT_ID:role/github-actions-prod
```

### 2. Test the Pipeline

```bash
# Create a test branch
git checkout dev
git checkout -b test-pipeline

# Make a change
echo "# Test" >> README.md
git add README.md
git commit -m "test: pipeline"
git push origin test-pipeline

# Create PR
gh pr create --base dev --title "Test Pipeline" --body "Testing CI/CD"

# Check Actions tab - should run plan but NOT apply

# Merge PR
gh pr merge --merge

# Check Actions tab - should now run apply
```

## Workflow Behavior

### Dev Branch
| Action | Trigger | Jobs | Apply? |
|--------|---------|------|--------|
| Push to dev | Direct push | init → validate → security → plan → apply | ✅ |
| PR to dev | Pull request | init → validate → security → plan | ❌ |
| Merge PR to dev | PR merge | init → validate → security → plan → apply | ✅ |

### Staging Branch
| Action | Trigger | Jobs | Apply? |
|--------|---------|------|--------|
| PR to staging | Pull request | init → validate → security → plan | ❌ |
| Merge PR to staging | PR merge | init → validate → security → plan → apply | ✅ |

### Main Branch (Production)
| Action | Trigger | Jobs | Apply? |
|--------|---------|------|--------|
| PR to main | Pull request | init → validate → security → plan | ❌ |
| Merge PR to main | PR merge | init → validate → security → plan → apply | ✅ |

## Features

### ✅ OIDC Authentication
- No long-lived AWS credentials
- Temporary credentials per job
- More secure than access keys

### ✅ Terraform Caching
- Caches `.terraform` directory
- Speeds up subsequent runs
- Cache key based on file hashes

### ✅ PR Comments
- Posts plan output to PR
- Shows format check failures
- Confirms successful applies

### ✅ Security Scanning
- **tfsec** - Infrastructure security scan
- **Checkov** - Policy compliance check
- Results in GitHub Security tab

### ✅ Artifact Storage
- Plan files saved for 5 days
- Outputs saved for 30 days
- Easy to review and audit

## Customization

### Change Terraform Version

Edit the workflow file:
```yaml
with:
  terraform_version: '1.6'  # Change version here
```

### Change AWS Region

Edit the workflow file:
```yaml
with:
  aws_region: 'eu-west-1'  # Change region here
```

### Add Manual Approval

Add to environment settings in GitHub:
1. Go to `Settings` → `Environments`
2. Select environment (e.g., `prod`)
3. Enable "Required reviewers"
4. Add reviewer usernames

## Troubleshooting

### "Error assuming role"
- Check IAM role trust policy includes your repo
- Verify secret name matches workflow
- Ensure OIDC provider is configured

### "Terraform init failed"
- Check backend configuration in `backend.tf`
- Verify S3 bucket and DynamoDB table exist
- Check IAM permissions

### "Plan shows unexpected changes"
- Review plan output carefully
- Check for manual changes in AWS
- Run `terraform refresh` locally

## Documentation

See [docs/CICD_SETUP.md](../../docs/CICD_SETUP.md) for detailed setup instructions.

## Workflow Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  GitHub Repository                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  dev branch ──────▶ dev.yml ──────▶ AWS Dev           │
│                                                         │
│  staging branch ──▶ staging.yml ──▶ AWS Staging       │
│                                                         │
│  main branch ─────▶ prod.yml ──────▶ AWS Production   │
│                                                         │
│                         │                               │
│                         ▼                               │
│              terraform-reusable.yml                     │
│              (shared workflow logic)                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```
