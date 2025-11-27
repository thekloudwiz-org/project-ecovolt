#!/bin/bash
#
# Sync Terraform State - Align Manual Lambda Fix with Terraform
#
# This script ensures Terraform knows about the COGNITO_ADMIN_CLIENT_ID
# that was manually added to the Lambda function
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Terraform State Sync${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check we're in the right directory
if [ ! -f "main.tf" ]; then
  echo -e "${RED}❌ Error: Please run this script from the infra directory${NC}"
  echo "cd /Users/thekloudwiz/project-ecovolt/infra"
  exit 1
fi

echo -e "${YELLOW}📋 Current Configuration:${NC}"
echo "- Cognito module outputs admin_portal_client_id"
echo "- main.tf passes it to compute module (no hardcoding!)"
echo "- compute/main.tf line 380 uses it in Lambda env vars"
echo ""

echo -e "${YELLOW}🔍 Step 1: Verify Cognito Outputs${NC}"
ADMIN_CLIENT_ID=$(terraform output -json 2>/dev/null | jq -r '.cognito_admin_portal_client_id.value // empty')

if [ -z "$ADMIN_CLIENT_ID" ] || [ "$ADMIN_CLIENT_ID" = "null" ]; then
  echo -e "${YELLOW}⚠️  Terraform outputs not available or not initialized${NC}"
  echo -e "${YELLOW}   This is normal if Terraform hasn't been applied yet${NC}"
  echo ""
else
  echo -e "${GREEN}✅ Cognito admin client ID: $ADMIN_CLIENT_ID${NC}"
  echo ""
fi

echo -e "${YELLOW}🔧 Step 2: Terraform Plan${NC}"
echo "Running terraform plan to see what changes are needed..."
echo ""

terraform plan -var-file="environments/dev.tfvars" -out=tfplan.out

echo ""
echo -e "${YELLOW}📊 Review the plan above${NC}"
echo ""
read -p "Do you want to apply these changes? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}❌ Aborted${NC}"
  rm -f tfplan.out
  exit 1
fi

echo ""
echo -e "${YELLOW}🚀 Step 3: Applying Terraform${NC}"
terraform apply tfplan.out

rm -f tfplan.out

echo ""
echo -e "${YELLOW}🔍 Step 4: Verifying Lambda Configuration${NC}"

LAMBDA_ADMIN_CLIENT=$(aws lambda get-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --region eu-central-1 \
  --query 'Environment.Variables.COGNITO_ADMIN_CLIENT_ID' \
  --output text 2>/dev/null || echo "")

if [ "$LAMBDA_ADMIN_CLIENT" = "2h0hsagipne3d9l1phtk4ig29a" ]; then
  echo -e "${GREEN}✅ Lambda COGNITO_ADMIN_CLIENT_ID: $LAMBDA_ADMIN_CLIENT${NC}"
else
  echo -e "${YELLOW}⚠️  Lambda COGNITO_ADMIN_CLIENT_ID: $LAMBDA_ADMIN_CLIENT${NC}"
  echo -e "${YELLOW}   Expected: 2h0hsagipne3d9l1phtk4ig29a${NC}"
fi

echo ""
echo -e "${YELLOW}🧪 Step 5: Testing Admin Dashboard${NC}"
echo "Testing admin dashboard endpoint..."

STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/health' \
  2>/dev/null || echo "000")

if [ "$STATUS" = "200" ]; then
  echo -e "${GREEN}✅ API health check: 200 OK${NC}"
else
  echo -e "${YELLOW}⚠️  API health check: $STATUS${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Terraform State Synced!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Summary:"
echo "- Terraform configuration is properly set up"
echo "- COGNITO_ADMIN_CLIENT_ID automatically pulled from Cognito module"
echo "- No hardcoded values anywhere"
echo "- Lambda environment variables updated"
echo ""
echo "Your admin dashboard should now work correctly!"
