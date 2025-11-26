#!/usr/bin/env bash
# Script to set up GitHub secrets from Terraform outputs

set -e

ENVIRONMENT=${1:-dev}
ENVIRONMENT_UPPER=$(echo "$ENVIRONMENT" | tr '[:lower:]' '[:upper:]')

echo "🔐 Setting up GitHub secrets for $ENVIRONMENT environment..."
echo ""

# Change to infra directory
cd infra

# Get Terraform outputs
echo "📊 Fetching Terraform outputs..."
S3_BUCKET=$(terraform output -raw admin_portal_s3_bucket)
CLOUDFRONT_ID=$(terraform output -raw admin_portal_cloudfront_id)
API_URL=$(terraform output -raw api_gateway_url)
USER_POOL_ID=$(terraform output -raw user_pool_id)
USER_POOL_CLIENT_ID=$(terraform output -raw admin_portal_client_id)

echo "✅ Outputs retrieved:"
echo "  S3 Bucket: $S3_BUCKET"
echo "  CloudFront ID: $CLOUDFRONT_ID"
echo "  API URL: $API_URL"
echo "  User Pool ID: $USER_POOL_ID"
echo "  User Pool Client ID: $USER_POOL_CLIENT_ID"
echo ""

# Set GitHub secrets
echo "🔧 Setting GitHub secrets..."

# Admin Portal S3 Bucket
gh secret set ADMIN_PORTAL_S3_BUCKET_${ENVIRONMENT_UPPER} --body "$S3_BUCKET"
echo "  ✅ ADMIN_PORTAL_S3_BUCKET_${ENVIRONMENT_UPPER}"

# Admin Portal CloudFront Distribution ID
gh secret set ADMIN_PORTAL_CLOUDFRONT_ID_${ENVIRONMENT_UPPER} --body "$CLOUDFRONT_ID"
echo "  ✅ ADMIN_PORTAL_CLOUDFRONT_ID_${ENVIRONMENT_UPPER}"

# API URL
gh secret set API_URL_${ENVIRONMENT_UPPER} --body "$API_URL"
echo "  ✅ API_URL_${ENVIRONMENT_UPPER}"

# Cognito User Pool ID
gh secret set USER_POOL_ID_${ENVIRONMENT_UPPER} --body "$USER_POOL_ID"
echo "  ✅ USER_POOL_ID_${ENVIRONMENT_UPPER}"

# Cognito User Pool Client ID
gh secret set USER_POOL_CLIENT_ID_${ENVIRONMENT_UPPER} --body "$USER_POOL_CLIENT_ID"
echo "  ✅ USER_POOL_CLIENT_ID_${ENVIRONMENT_UPPER}"

# Backend Lambda Functions
gh secret set api_handler_${ENVIRONMENT}_lambda --body "ecovolt-${ENVIRONMENT}-api-handler"
echo "  ✅ api_handler_${ENVIRONMENT}_lambda"

gh secret set iot_processor_${ENVIRONMENT}_lambda --body "ecovolt-${ENVIRONMENT}-iot-processor"
echo "  ✅ iot_processor_${ENVIRONMENT}_lambda"

gh secret set auth_handler_${ENVIRONMENT}_lambda --body "ecovolt-${ENVIRONMENT}-auth-handler"
echo "  ✅ auth_handler_${ENVIRONMENT}_lambda"

gh secret set db_migrator_${ENVIRONMENT}_lambda --body "ecovolt-${ENVIRONMENT}-db-migrator"
echo "  ✅ db_migrator_${ENVIRONMENT}_lambda"

echo ""
echo "✅ GitHub secrets configured successfully!"
echo ""
echo "📋 Configured secrets:"
echo "  - ADMIN_PORTAL_S3_BUCKET_${ENVIRONMENT_UPPER}"
echo "  - ADMIN_PORTAL_CLOUDFRONT_ID_${ENVIRONMENT_UPPER}"
echo "  - API_URL_${ENVIRONMENT_UPPER}"
echo "  - USER_POOL_ID_${ENVIRONMENT_UPPER}"
echo "  - USER_POOL_CLIENT_ID_${ENVIRONMENT_UPPER}"
echo "  - api_handler_${ENVIRONMENT}_lambda"
echo "  - iot_processor_${ENVIRONMENT}_lambda"
echo "  - auth_handler_${ENVIRONMENT}_lambda"
echo "  - db_migrator_${ENVIRONMENT}_lambda"
echo ""
echo "🚀 Backend and admin portal workflows are now ready to deploy!"
