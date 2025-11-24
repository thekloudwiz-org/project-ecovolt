# CI/CD Pipeline Prerequisites

This document lists all the prerequisites needed for the EcoVolt CI/CD pipelines to work correctly.

## 1. AWS S3 Buckets

### Lambda Deployment Bucket
**Purpose:** Store Lambda deployment packages for versioning and deployment

**Bucket Name:** `ecovolt-deployments`

**Structure:**
```
ecovolt-deployments/
├── backend/
│   ├── dev/
│   │   └── lambda-{commit-sha}.zip
│   ├── staging/
│   │   └── lambda-{commit-sha}.zip
│   └── prod/
│       └── lambda-{commit-sha}.zip
├── admin-portal/
│   └── backups/
└── mobile/
    └── builds/
```

**Create the bucket:**
```bash
# Create the bucket
aws s3 mb s3://ecovolt-deployments --region us-east-1

# Enable versioning (recommended)
aws s3api put-bucket-versioning \
  --bucket ecovolt-deployments \
  --versioning-configuration Status=Enabled

# Add lifecycle policy to clean up old versions (optional)
cat > lifecycle-policy.json << 'EOF'
{
  "Rules": [
    {
      "Id": "DeleteOldLambdaPackages",
      "Status": "Enabled",
      "Prefix": "backend/",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 30
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket ecovolt-deployments \
  --lifecycle-configuration file://lifecycle-policy.json

# Block public access (security best practice)
aws s3api put-public-access-block \
  --bucket ecovolt-deployments \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### Admin Portal Buckets (if using S3 hosting)
```bash
# Dev
aws s3 mb s3://ecovolt-dev-admin-portal --region us-east-1

# Staging
aws s3 mb s3://ecovolt-staging-admin-portal --region us-east-1

# Prod
aws s3 mb s3://ecovolt-prod-admin-portal --region us-east-1

# Backup bucket
aws s3 mb s3://ecovolt-admin-portal-backups --region us-east-1
```

## 2. GitHub Secrets

### Required Secrets

Navigate to: **GitHub Repository → Settings → Secrets and variables → Actions**

#### AWS OIDC Role ARNs (Required)
```
AWS_ROLE_ARN_DEV
Value: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-EcoVolt-Dev

AWS_ROLE_ARN_STAGING
Value: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-EcoVolt-Staging

AWS_ROLE_ARN_PROD
Value: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-EcoVolt-Prod
```

#### Deployment Bucket (Required)
```
DEPLOYMENT_BUCKET
Value: ecovolt-deployment-bucket
(or whatever name you chose when creating the bucket)
```

#### Lambda Function Names (Optional but Recommended)

**Dev Environment:**
```
api_handler_dev_lambda
Value: ecovolt-dev-api-handler

iot_processor_dev_lambda
Value: ecovolt-dev-iot-processor
```

**Staging Environment:**
```
api_handler_staging_lambda
Value: ecovolt-staging-api-handler

iot_processor_staging_lambda
Value: ecovolt-staging-iot-processor
```

**Prod Environment:**
```
api_handler_prod_lambda
Value: ecovolt-prod-api-handler

iot_processor_prod_lambda
Value: ecovolt-prod-iot-processor
```

**Note:** 
- Only these 2 functions use the backend application code
- `stream_processor` and `data_transformer` are in the analytics module and have their own code
- The workflow will skip any functions that are not configured

#### CloudFront Distribution IDs (if using CloudFront)
```
DEV_CLOUDFRONT_DISTRIBUTION_ID
Value: E1234567890ABC

STAGING_CLOUDFRONT_DISTRIBUTION_ID
Value: E0987654321XYZ

PROD_CLOUDFRONT_DISTRIBUTION_ID
Value: EABCDEF123456
```

#### Mobile App Deployment (if deploying mobile apps)
```
FIREBASE_ANDROID_APP_ID
Value: 1:123456789:android:abcdef123456

FIREBASE_SERVICE_ACCOUNT
Value: { "type": "service_account", ... }

GOOGLE_PLAY_SERVICE_ACCOUNT
Value: { "type": "service_account", ... }

APPLE_ID
Value: your-apple-id@example.com

APPLE_APP_SPECIFIC_PASSWORD
Value: xxxx-xxxx-xxxx-xxxx
```

## 3. GitHub Variables (Optional)

Navigate to: **GitHub Repository → Settings → Secrets and variables → Actions → Variables**

```
AWS_REGION
Value: us-east-1

PYTHON_VERSION
Value: 3.11

NODE_VERSION
Value: 18

DEPLOYMENT_BUCKET
Value: ecovolt-deployments
```

## 4. GitHub Environments

Create these environments in: **GitHub Repository → Settings → Environments**

### Dev Environment
- **Name:** `dev`
- **Protection rules:** None (auto-deploy)
- **Environment secrets:** None (uses repository secrets)

### Staging Environment
- **Name:** `staging`
- **Protection rules:** 
  - ✅ Required reviewers (optional)
  - ✅ Wait timer: 5 minutes (optional)
- **Environment secrets:** None (uses repository secrets)

### Prod Environment
- **Name:** `prod`
- **Protection rules:**
  - ✅ Required reviewers (recommended: 1-2 reviewers)
  - ✅ Deployment branches: Only `main` branch
- **Environment secrets:** None (uses repository secrets)

## 5. AWS Lambda Functions

The Lambda functions should be created by Terraform, but verify they exist:

```bash
# List Lambda functions
aws lambda list-functions \
  --query 'Functions[?starts_with(FunctionName, `ecovolt`)].FunctionName' \
  --output table

# Expected functions:
# - ecovolt-dev-api-handler
# - ecovolt-dev-iot-processor
# - ecovolt-staging-api-handler
# - ecovolt-staging-iot-processor
# - ecovolt-prod-api-handler
# - ecovolt-prod-iot-processor
```

If they don't exist, Terraform will create them on first deployment.

## 6. IAM Permissions

Ensure the GitHub Actions IAM role has these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "LambdaDeployment",
      "Effect": "Allow",
      "Action": [
        "lambda:UpdateFunctionCode",
        "lambda:GetFunction",
        "lambda:PublishVersion",
        "lambda:UpdateAlias",
        "lambda:ListVersionsByFunction"
      ],
      "Resource": "arn:aws:lambda:*:*:function:ecovolt-*"
    },
    {
      "Sid": "S3Deployment",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::ecovolt-deployments",
        "arn:aws:s3:::ecovolt-deployments/*",
        "arn:aws:s3:::ecovolt-*-admin-portal",
        "arn:aws:s3:::ecovolt-*-admin-portal/*"
      ]
    },
    {
      "Sid": "CloudFrontInvalidation",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation"
      ],
      "Resource": "*"
    }
  ]
}
```

These are already included in the comprehensive IAM policy from `docs/IAM_PERMISSIONS_REQUIRED.md`.

## 7. Verification Checklist

Use this checklist to verify everything is set up:

### AWS Resources
- [ ] S3 bucket `ecovolt-deployments` exists
- [ ] S3 bucket has versioning enabled
- [ ] S3 bucket has lifecycle policy (optional)
- [ ] Lambda functions exist (or will be created by Terraform)
- [ ] IAM OIDC provider exists
- [ ] IAM roles exist with correct trust policies
- [ ] IAM roles have required permissions

### GitHub Configuration
- [ ] `AWS_ROLE_ARN_DEV` secret configured
- [ ] `AWS_ROLE_ARN_STAGING` secret configured
- [ ] `AWS_ROLE_ARN_PROD` secret configured
- [ ] GitHub environments created (dev, staging, prod)
- [ ] Prod environment has required reviewers (recommended)

### Optional (if using)
- [ ] CloudFront distribution IDs configured
- [ ] Mobile app deployment secrets configured
- [ ] Admin portal S3 buckets created

## 8. Quick Setup Script

Here's a script to create the essential S3 bucket:

```bash
#!/bin/bash
# Quick setup for EcoVolt CI/CD

set -e

BUCKET_NAME="ecovolt-deployments"
REGION="us-east-1"

echo "🚀 Setting up EcoVolt CI/CD prerequisites..."

# Create deployment bucket
echo "📦 Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $REGION || echo "Bucket already exists"

# Enable versioning
echo "🔄 Enabling versioning..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Block public access
echo "🔒 Blocking public access..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create folder structure
echo "📁 Creating folder structure..."
aws s3api put-object --bucket $BUCKET_NAME --key backend/dev/
aws s3api put-object --bucket $BUCKET_NAME --key backend/staging/
aws s3api put-object --bucket $BUCKET_NAME --key backend/prod/

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure GitHub secrets (AWS_ROLE_ARN_DEV, etc.)"
echo "2. Create GitHub environments (dev, staging, prod)"
echo "3. Push code to trigger deployment"
```

Save this as `scripts/setup-cicd.sh` and run:
```bash
chmod +x scripts/setup-cicd.sh
./scripts/setup-cicd.sh
```

## 9. Testing the Setup

After setup, test with a simple commit:

```bash
# Make a small change
echo "# Test" >> README.md
git add README.md
git commit -m "test: Trigger CI/CD pipeline"
git push origin dev
```

Watch the GitHub Actions tab for the workflow execution.

## 10. Troubleshooting

### Issue: "NoSuchBucket" error
**Solution:** Create the `ecovolt-deployments` bucket using the commands above.

### Issue: "Access Denied" when uploading to S3
**Solution:** Check IAM role permissions include `s3:PutObject` for the bucket.

### Issue: "Lambda function not found"
**Solution:** Run Terraform to create the Lambda functions first, or update the function names in the workflow.

### Issue: "Could not assume role"
**Solution:** Verify the IAM role trust policy allows the GitHub repository.

## 11. Cost Optimization

To minimize costs:

1. **Enable S3 lifecycle policies** to delete old Lambda packages after 30 days
2. **Use S3 Intelligent-Tiering** for the deployment bucket
3. **Set up CloudWatch alarms** for unexpected S3 usage
4. **Review and clean up** old deployments periodically

```bash
# List old Lambda packages
aws s3 ls s3://ecovolt-deployments/backend/dev/ --recursive

# Delete packages older than 30 days (be careful!)
aws s3 ls s3://ecovolt-deployments/backend/dev/ --recursive | \
  awk '{if ($1 < "'$(date -d '30 days ago' +%Y-%m-%d)'") print $4}' | \
  xargs -I {} aws s3 rm s3://ecovolt-deployments/{}
```

---

**Last Updated:** 2024-11-24  
**Status:** Ready for Setup  
**Estimated Setup Time:** 15-20 minutes
