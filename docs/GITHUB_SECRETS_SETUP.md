# GitHub Secrets Automation Setup

## Overview

The Terraform workflow automatically updates GitHub repository secrets after successful deployments. This ensures frontend applications always have the latest infrastructure values (API URLs, Cognito IDs, etc.).

## Current Status

⚠️ **Secrets update is currently failing** because the default `GITHUB_TOKEN` doesn't have permission to write secrets.

## Why It Fails

The default `GITHUB_TOKEN` provided by GitHub Actions has these limitations:
- ✅ Can read repository content
- ✅ Can write comments on PRs
- ❌ **Cannot write repository secrets** (security restriction)

## Solution: Create a Personal Access Token (PAT)

### Step 1: Create a Personal Access Token

1. Go to GitHub Settings: https://github.com/settings/tokens
2. Click **"Generate new token"** → **"Generate new token (classic)"**
3. Give it a descriptive name: `EcoVolt Secrets Automation`
4. Set expiration: **90 days** (or longer)
5. Select scopes:
   - ✅ **`repo`** (Full control of private repositories)
     - This includes `repo:status`, `repo_deployment`, `public_repo`, `repo:invite`, `security_events`
6. Click **"Generate token"**
7. **Copy the token immediately** (you won't see it again!)

### Step 2: Add PAT as Repository Secret

1. Go to your repository: https://github.com/thekloudwiz-org/project-ecovolt
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Name: `PAT_TOKEN`
5. Value: Paste the token you copied
6. Click **"Add secret"**

### Step 3: Verify Setup

After adding the `PAT_TOKEN` secret:

1. Push a change to `infra/**/*.tf` files
2. The Terraform workflow will run
3. Check the "Update GitHub Secrets" step in the workflow logs
4. You should see: `✓ Updated API_URL_DEV` (instead of `✗ Failed`)

## What Gets Updated

The workflow updates these secrets automatically:

| Secret Name | Description | Used By |
|-------------|-------------|---------|
| `API_URL_DEV` | API Gateway URL (dev) | Admin Portal, Mobile App |
| `API_URL_STAGING` | API Gateway URL (staging) | Admin Portal, Mobile App |
| `API_URL_PROD` | API Gateway URL (prod) | Admin Portal, Mobile App |
| `USER_POOL_ID_DEV` | Cognito User Pool ID (dev) | Admin Portal, Mobile App |
| `USER_POOL_ID_STAGING` | Cognito User Pool ID (staging) | Admin Portal, Mobile App |
| `USER_POOL_ID_PROD` | Cognito User Pool ID (prod) | Admin Portal, Mobile App |
| `USER_POOL_CLIENT_ID_DEV` | Cognito Client ID (dev) | Admin Portal |
| `USER_POOL_CLIENT_ID_STAGING` | Cognito Client ID (staging) | Admin Portal |
| `USER_POOL_CLIENT_ID_PROD` | Cognito Client ID (prod) | Admin Portal |
| `MOBILE_APP_CLIENT_ID_DEV` | Cognito Client ID (dev) | Mobile App |
| `MOBILE_APP_CLIENT_ID_STAGING` | Cognito Client ID (staging) | Mobile App |
| `MOBILE_APP_CLIENT_ID_PROD` | Cognito Client ID (prod) | Mobile App |
| `ADMIN_PORTAL_S3_BUCKET_DEV` | S3 bucket name (dev) | Admin Portal deployment |
| `ADMIN_PORTAL_S3_BUCKET_STAGING` | S3 bucket name (staging) | Admin Portal deployment |
| `ADMIN_PORTAL_S3_BUCKET_PROD` | S3 bucket name (prod) | Admin Portal deployment |
| `ADMIN_PORTAL_CLOUDFRONT_ID_DEV` | CloudFront distribution ID (dev) | Admin Portal deployment |
| `ADMIN_PORTAL_CLOUDFRONT_ID_STAGING` | CloudFront distribution ID (staging) | Admin Portal deployment |
| `ADMIN_PORTAL_CLOUDFRONT_ID_PROD` | CloudFront distribution ID (prod) | Admin Portal deployment |

## Alternative: Manual Secret Updates

If you prefer not to use automatic updates, you can manually update secrets after each Terraform deployment:

```bash
# 1. Get Terraform outputs
cd infra
terraform output -json > outputs.json

# 2. Extract values
API_URL=$(jq -r '.api_gateway_url.value' outputs.json)
USER_POOL_ID=$(jq -r '.user_pool_id.value' outputs.json)
# ... etc

# 3. Update secrets via GitHub CLI
gh secret set API_URL_DEV --body "$API_URL" --repo thekloudwiz-org/project-ecovolt
gh secret set USER_POOL_ID_DEV --body "$USER_POOL_ID" --repo thekloudwiz-org/project-ecovolt
# ... etc
```

Or via GitHub UI:
1. Go to repository Settings → Secrets and variables → Actions
2. Click on each secret and update the value
3. Get values from Terraform outputs: `terraform output`

## Security Considerations

### PAT Token Security

- ✅ **Store securely:** Never commit PAT to code
- ✅ **Rotate regularly:** Set expiration and rotate every 90 days
- ✅ **Minimal scope:** Only grant `repo` scope (no admin or delete permissions)
- ✅ **Monitor usage:** Check GitHub audit log for token usage
- ✅ **Revoke if compromised:** Immediately revoke and create new token

### Why This Is Safe

1. **Token is encrypted:** GitHub encrypts all secrets at rest
2. **Limited scope:** Token only has `repo` access, not admin
3. **Audit trail:** All secret updates are logged in GitHub audit log
4. **Workflow-only:** Token is only accessible to GitHub Actions workflows
5. **No exposure:** Token is never printed in logs or outputs

## Troubleshooting

### Issue: "Failed to update" messages

**Cause:** Default `GITHUB_TOKEN` doesn't have secrets write permission

**Solution:** Create and add `PAT_TOKEN` as described above

### Issue: "GitHub CLI not authenticated"

**Cause:** `gh` CLI can't authenticate with provided token

**Solution:** 
1. Verify `PAT_TOKEN` secret exists
2. Verify token has `repo` scope
3. Check token hasn't expired

### Issue: "Failed to get public key"

**Cause:** Old script version trying to use API directly

**Solution:** Update to latest script version (uses `gh` CLI)

### Issue: Secrets update succeeds but frontend still uses old values

**Cause:** Frontend workflows cache environment variables

**Solution:** 
1. Re-run frontend deployment workflow
2. Or manually trigger frontend build
3. Secrets are only loaded at workflow start

## Workflow Integration

The secrets update happens automatically in the Terraform workflow:

```yaml
- name: Update GitHub Secrets
  env:
    GITHUB_TOKEN: ${{ secrets.PAT_TOKEN || secrets.GITHUB_TOKEN }}
    GH_TOKEN: ${{ secrets.PAT_TOKEN || secrets.GITHUB_TOKEN }}
  run: |
    chmod +x scripts/update-github-secrets.sh
    ./scripts/update-github-secrets.sh ${{ inputs.environment }} ${{ inputs.working_directory }}
  continue-on-error: true
```

**Note:** `continue-on-error: true` means deployment won't fail if secrets update fails. This is intentional - infrastructure deployment is more critical than secret updates.

## Benefits of Automation

✅ **No manual updates:** Secrets update automatically after Terraform apply
✅ **Always in sync:** Frontend always has latest infrastructure values
✅ **Fewer errors:** No copy-paste mistakes
✅ **Faster deployments:** No waiting for manual secret updates
✅ **Audit trail:** All updates logged in GitHub audit log

## Next Steps

1. ✅ Create PAT with `repo` scope
2. ✅ Add as `PAT_TOKEN` repository secret
3. ✅ Push a change to trigger workflow
4. ✅ Verify secrets update successfully
5. ✅ Frontend deployments will use new values automatically

---

**Questions?** Check the workflow logs or contact the DevOps team.
