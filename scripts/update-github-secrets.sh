#!/bin/bash
#
# Update GitHub Secrets from Terraform Outputs
# This script reads Terraform outputs and updates GitHub repository secrets
# so that frontend CI/CD workflows always have current infrastructure values
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
  echo -e "${RED}Error: GITHUB_TOKEN environment variable is required${NC}"
  exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
  echo -e "${RED}Error: GITHUB_REPOSITORY environment variable is required${NC}"
  exit 1
fi

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR=${2:-infra}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Updating GitHub Secrets from Terraform${NC}"
echo -e "${GREEN}========================================${NC}"
echo "Environment: $ENVIRONMENT"
echo "Repository: $GITHUB_REPOSITORY"
echo ""

# Change to terraform directory
cd "$TERRAFORM_DIR"

# Get Terraform outputs as JSON
echo -e "${YELLOW}Reading Terraform outputs...${NC}"
if ! terraform output -json > /tmp/tf-outputs.json; then
  echo -e "${RED}Failed to read Terraform outputs${NC}"
  exit 1
fi

# Extract values from Terraform outputs
API_URL=$(jq -r '.api_gateway_url.value // empty' /tmp/tf-outputs.json)
USER_POOL_ID=$(jq -r '.user_pool_id.value // empty' /tmp/tf-outputs.json)
ADMIN_CLIENT_ID=$(jq -r '.admin_portal_client_id.value // empty' /tmp/tf-outputs.json)
MOBILE_CLIENT_ID=$(jq -r '.mobile_app_client_id.value // empty' /tmp/tf-outputs.json)
S3_BUCKET=$(jq -r '.admin_portal_s3_bucket.value // empty' /tmp/tf-outputs.json)
CLOUDFRONT_ID=$(jq -r '.admin_portal_cloudfront_id.value // empty' /tmp/tf-outputs.json)
AWS_REGION=$(jq -r '.aws_region.value // "eu-central-1"' /tmp/tf-outputs.json)

echo -e "${YELLOW}Terraform Outputs:${NC}"
echo "  AWS Region: $AWS_REGION"
echo "  API URL: ${API_URL:0:50}..."
echo "  User Pool ID: $USER_POOL_ID"
echo "  Admin Client ID: $ADMIN_CLIENT_ID"
echo "  Mobile Client ID: $MOBILE_CLIENT_ID"
echo "  S3 Bucket: $S3_BUCKET"
echo "  CloudFront ID: $CLOUDFRONT_ID"
echo ""

# Function to update a GitHub secret
update_secret() {
  local secret_name=$1
  local secret_value=$2
  local env_name=$3

  if [ -z "$secret_value" ]; then
    echo -e "${YELLOW}⚠️  Skipping $secret_name (empty value)${NC}"
    return
  fi

  # Use GitHub CLI (preferred method)
  if command -v gh &> /dev/null; then
    # Use GitHub CLI (preferred method)
    if [ -n "$env_name" ]; then
      # Environment secret
      echo "$secret_value" | gh secret set "$secret_name" \
        --repo "$GITHUB_REPOSITORY" \
        --env "$env_name" \
        --body - &> /dev/null && \
        echo -e "${GREEN}✓${NC} Updated $secret_name (environment: $env_name)" || \
        echo -e "${RED}✗${NC} Failed to update $secret_name"
    else
      # Repository secret
      echo "$secret_value" | gh secret set "$secret_name" \
        --repo "$GITHUB_REPOSITORY" \
        --body - &> /dev/null && \
        echo -e "${GREEN}✓${NC} Updated $secret_name" || \
        echo -e "${RED}✗${NC} Failed to update $secret_name"
    fi
  else
    echo -e "${YELLOW}⚠️  GitHub CLI not found, skipping $secret_name${NC}"
    echo -e "${YELLOW}   Install with: brew install gh (macOS) or see https://cli.github.com${NC}"
  fi
}

# Update repository-level secrets (used by workflows)
echo -e "${GREEN}Updating repository secrets...${NC}"
update_secret "API_URL_${ENVIRONMENT^^}" "$API_URL"
update_secret "USER_POOL_ID_${ENVIRONMENT^^}" "$USER_POOL_ID"
update_secret "USER_POOL_CLIENT_ID_${ENVIRONMENT^^}" "$ADMIN_CLIENT_ID"
update_secret "MOBILE_APP_CLIENT_ID_${ENVIRONMENT^^}" "$MOBILE_CLIENT_ID"
update_secret "ADMIN_PORTAL_S3_BUCKET_${ENVIRONMENT^^}" "$S3_BUCKET"
update_secret "ADMIN_PORTAL_CLOUDFRONT_ID_${ENVIRONMENT^^}" "$CLOUDFRONT_ID"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ GitHub secrets update complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Frontend workflows will use these secrets automatically"
echo "2. No manual updates needed"
echo "3. Run frontend deployment to use new values"

# Cleanup
rm -f /tmp/tf-outputs.json
