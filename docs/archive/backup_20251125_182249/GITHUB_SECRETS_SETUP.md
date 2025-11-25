# GitHub Secrets Setup - Quick Reference

## Required Secrets

You need to add **3 secrets** to your GitHub repository for the CI/CD pipeline to work.

### How to Add Secrets

1. Go to your GitHub repository
2. Click `Settings` → `Secrets and variables` → `Actions`
3. Click `New repository secret`
4. Add each secret below

## Secrets to Add

### 1. AWS_ROLE_ARN_DEV
**Name**: `AWS_ROLE_ARN_DEV`  
**Value**: `arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_DEV_ROLE_NAME`

Example:
```
arn:aws:iam::123456789012:role/github-actions-dev
```

### 2. AWS_ROLE_ARN_STAGING
**Name**: `AWS_ROLE_ARN_STAGING`  
**Value**: `arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_STAGING_ROLE_NAME`

Example:
```
arn:aws:iam::123456789012:role/github-actions-staging
```

### 3. AWS_ROLE_ARN_PROD
**Name**: `AWS_ROLE_ARN_PROD`  
**Value**: `arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_PROD_ROLE_NAME`

Example:
```
arn:aws:iam::123456789012:role/github-actions-prod
```

## How to Get Your Role ARNs

### Option 1: AWS Console
1. Go to IAM → Roles
2. Search for your GitHub Actions roles
3. Click on the role
4. Copy the ARN from the top

### Option 2: AWS CLI
```bash
# List all roles with "github" in the name
aws iam list-roles --query 'Roles[?contains(RoleName, `github`)].{Name:RoleName,ARN:Arn}' --output table

# Get specific role ARN
aws iam get-role --role-name github-actions-dev --query 'Role.Arn' --output text
aws iam get-role --role-name github-actions-staging --query 'Role.Arn' --output text
aws iam get-role --role-name github-actions-prod --query 'Role.Arn' --output text
```

### Option 3: GitHub CLI
```bash
# Add secrets using GitHub CLI
gh secret set AWS_ROLE_ARN_DEV --body "arn:aws:iam::123456789012:role/github-actions-dev"
gh secret set AWS_ROLE_ARN_STAGING --body "arn:aws:iam::123456789012:role/github-actions-staging"
gh secret set AWS_ROLE_ARN_PROD --body "arn:aws:iam::123456789012:role/github-actions-prod"
```

## Verify Secrets

After adding secrets, verify they're set:

```bash
# Using GitHub CLI
gh secret list

# Expected output:
# AWS_ROLE_ARN_DEV      Updated 2024-01-15
# AWS_ROLE_ARN_STAGING  Updated 2024-01-15
# AWS_ROLE_ARN_PROD     Updated 2024-01-15
```

## IAM Role Requirements

Your IAM roles should have:

### Trust Policy
The role must trust GitHub's OIDC provider:

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
          "token.actions.githubusercontent.com:sub": "repo:thekloudwiz-org/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

**Important**: Replace `YOUR_REPO_NAME` with your actual repository name (e.g., `ecovolt-infrastructure`).
```

### Permissions Policy
The role needs permissions to manage your infrastructure. Common options:

**Option 1: Full Access (Simplest)**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
```

**Option 2: Managed Policies (Recommended)**
Attach these AWS managed policies:
- `AdministratorAccess` (for full control)
- Or specific policies like:
  - `AmazonEC2FullAccess`
  - `AmazonS3FullAccess`
  - `AmazonRDSFullAccess`
  - `AWSIoTFullAccess`
  - etc.

**Option 3: Custom Policy (Most Secure)**
Create a custom policy with only the permissions needed for your infrastructure.

## Testing

After adding secrets, test the pipeline:

```bash
# 1. Create a test branch
git checkout dev
git checkout -b test-secrets

# 2. Make a small change
echo "# Test" >> README.md
git add README.md
git commit -m "test: verify secrets"
git push origin test-secrets

# 3. Create a PR
gh pr create --base dev --title "Test Secrets" --body "Testing OIDC authentication"

# 4. Check the Actions tab
# - Go to your repo → Actions
# - You should see the workflow running
# - If it fails with "Error assuming role", check your trust policy
# - If it succeeds, your secrets are configured correctly!
```

## Troubleshooting

### Error: "Secret not found"
- Check the secret name exactly matches (case-sensitive)
- Verify you added it to the correct repository
- Try removing and re-adding the secret

### Error: "Error assuming role"
- Verify the role ARN is correct
- Check the IAM role trust policy includes your repository
- Ensure the OIDC provider exists in your AWS account

### Error: "Access denied"
- Check the IAM role has sufficient permissions
- Verify the role can access the S3 backend bucket
- Check the role can create/modify resources

## Security Best Practices

1. ✅ **Use OIDC** (not access keys) - More secure, no long-lived credentials
2. ✅ **Separate roles per environment** - Limit blast radius
3. ✅ **Least privilege** - Only grant necessary permissions
4. ✅ **Audit regularly** - Review CloudTrail logs for GitHub Actions activity
5. ✅ **Rotate if compromised** - Easy to rotate role ARNs

## Next Steps

After adding secrets:
1. ✅ Test with a PR to dev branch
2. ✅ Verify plan runs successfully
3. ✅ Merge and verify apply works
4. ✅ Repeat for staging and prod

## Quick Command Reference

```bash
# Add secrets
gh secret set AWS_ROLE_ARN_DEV --body "YOUR_ARN"
gh secret set AWS_ROLE_ARN_STAGING --body "YOUR_ARN"
gh secret set AWS_ROLE_ARN_PROD --body "YOUR_ARN"

# List secrets
gh secret list

# Delete a secret (if needed)
gh secret delete AWS_ROLE_ARN_DEV

# Get role ARN
aws iam get-role --role-name YOUR_ROLE_NAME --query 'Role.Arn' --output text
```

## Support

If you encounter issues:
1. Check the Actions logs in GitHub
2. Review AWS CloudTrail for authentication attempts
3. Verify IAM role trust policy
4. Check IAM role permissions
5. See [docs/CICD_SETUP.md](./CICD_SETUP.md) for detailed troubleshooting
