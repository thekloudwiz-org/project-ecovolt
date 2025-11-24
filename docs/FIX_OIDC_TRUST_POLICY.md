# Fix OIDC Trust Policy for Application Workflows

## Issue
The backend CI/CD workflow is getting this error:
```
Error: Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

## Root Cause
The IAM role's trust policy is likely too restrictive. It may only allow specific workflows or branches, but the backend workflow needs access too.

## Solution

### Option 1: Update Trust Policy to Allow All Workflows (Recommended)

Update your IAM role trust policy to allow **any workflow** from your repository:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:thekloudwiz-org/project-ecovolt:*"
        }
      }
    }
  ]
}
```

The key part is: `"token.actions.githubusercontent.com:sub": "repo:thekloudwiz-org/project-ecovolt:*"`

The `*` wildcard allows:
- ✅ Any branch (dev, staging, main)
- ✅ Any workflow file
- ✅ Pull requests
- ✅ All GitHub Actions from this repository

### Option 2: Restrict by Branch (More Secure)

If you want to restrict to specific branches:

**For Dev Role:**
```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": [
        "repo:thekloudwiz-org/project-ecovolt:ref:refs/heads/dev",
        "repo:thekloudwiz-org/project-ecovolt:pull_request"
      ]
    }
  }
}
```

**For Staging Role:**
```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": [
        "repo:thekloudwiz-org/project-ecovolt:ref:refs/heads/staging",
        "repo:thekloudwiz-org/project-ecovolt:pull_request"
      ]
    }
  }
}
```

**For Prod Role:**
```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:thekloudwiz-org/project-ecovolt:ref:refs/heads/main"
    }
  }
}
```

## How to Apply the Fix

### Using AWS Console

1. Go to **IAM** → **Roles**
2. Find your role (e.g., `GitHubActions-EcoVolt-Dev`)
3. Click on **Trust relationships** tab
4. Click **Edit trust policy**
5. Update the JSON with the policy above
6. Click **Update policy**

### Using AWS CLI

```bash
# Save the trust policy to a file
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:thekloudwiz-org/project-ecovolt:*"
        }
      }
    }
  ]
}
EOF

# Update the role
aws iam update-assume-role-policy \
  --role-name GitHubActions-EcoVolt-Dev \
  --policy-document file://trust-policy.json
```

### Using Terraform

If you're managing the IAM role with Terraform (recommended), update the `assume_role_policy` in your Terraform configuration:

```hcl
resource "aws_iam_role" "github_actions_dev" {
  name = "GitHubActions-EcoVolt-Dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:thekloudwiz-org/project-ecovolt:*"
          }
        }
      }
    ]
  })
}
```

Then apply:
```bash
terraform apply
```

## Verification

After updating the trust policy, test the workflow:

```bash
# Trigger the backend workflow
git add .
git commit -m "test: Trigger backend workflow"
git push origin dev
```

Check the GitHub Actions logs. The "Configure AWS credentials" step should now succeed.

## Common Issues

### Issue: "No OpenID Connect provider found"
**Solution:** You need to create the OIDC provider first. See `docs/github-actions-iam-role.tf` for the configuration.

### Issue: "Role ARN not found"
**Solution:** Make sure the GitHub secret `AWS_ROLE_ARN_DEV` contains the correct role ARN:
```
arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-EcoVolt-Dev
```

### Issue: Still getting "Not authorized"
**Solution:** Check that:
1. The OIDC provider exists in your AWS account
2. The role ARN in GitHub secrets is correct
3. The trust policy uses the correct repository name
4. The `id-token: write` permission is set in the workflow

## Security Best Practices

1. **Use separate roles per environment** (dev, staging, prod)
2. **Restrict prod role to main branch only**
3. **Use least privilege permissions** for each role
4. **Enable CloudTrail** to audit role assumptions
5. **Set up alerts** for unexpected role usage

## Reference

- [GitHub Actions OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)

---

**Last Updated:** 2024-11-24  
**Status:** Action Required - Update IAM role trust policy
