#!/bin/bash
#
# Fix Admin Client ID - Add Missing Environment Variable to Lambda
#
# This script adds the COGNITO_ADMIN_CLIENT_ID environment variable
# to the ecovolt-dev-api-handler Lambda function
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

FUNCTION_NAME="ecovolt-dev-api-handler"
REGION="eu-central-1"
ADMIN_CLIENT_ID="2h0hsagipne3d9l1phtk4ig29a"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Fix Admin Client ID${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "Function: $FUNCTION_NAME"
echo "Region: $REGION"
echo "Admin Client ID to add: $ADMIN_CLIENT_ID"
echo ""

# Get current environment variables
echo -e "${YELLOW}📥 Fetching current environment variables...${NC}"
CURRENT_ENV=$(aws lambda get-function-configuration \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION" \
  --query 'Environment.Variables' \
  --output json)

# Check if COGNITO_ADMIN_CLIENT_ID already exists
if echo "$CURRENT_ENV" | jq -e '.COGNITO_ADMIN_CLIENT_ID' > /dev/null 2>&1; then
  EXISTING_VALUE=$(echo "$CURRENT_ENV" | jq -r '.COGNITO_ADMIN_CLIENT_ID')
  echo -e "${YELLOW}⚠️  COGNITO_ADMIN_CLIENT_ID already exists with value: $EXISTING_VALUE${NC}"
  read -p "Do you want to update it to $ADMIN_CLIENT_ID? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Aborted${NC}"
    exit 1
  fi
fi

# Add COGNITO_ADMIN_CLIENT_ID to the environment variables
echo -e "${YELLOW}➕ Adding COGNITO_ADMIN_CLIENT_ID...${NC}"
NEW_ENV=$(echo "$CURRENT_ENV" | jq --arg admin_id "$ADMIN_CLIENT_ID" '. + {COGNITO_ADMIN_CLIENT_ID: $admin_id}')

# Update Lambda function
echo -e "${YELLOW}🔄 Updating Lambda function...${NC}"
aws lambda update-function-configuration \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION" \
  --environment "Variables=$(echo $NEW_ENV | jq -c .)" \
  > /dev/null

echo -e "${GREEN}✅ Lambda function updated successfully!${NC}"
echo ""

# Verify the update
echo -e "${YELLOW}🔍 Verifying update...${NC}"
UPDATED_ENV=$(aws lambda get-function-configuration \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION" \
  --query 'Environment.Variables' \
  --output json)

UPDATED_VALUE=$(echo "$UPDATED_ENV" | jq -r '.COGNITO_ADMIN_CLIENT_ID')

if [ "$UPDATED_VALUE" == "$ADMIN_CLIENT_ID" ]; then
  echo -e "${GREEN}✅ Verification successful!${NC}"
  echo ""
  echo "Environment variables:"
  echo "$UPDATED_ENV" | jq '{COGNITO_APP_CLIENT_ID, COGNITO_ADMIN_CLIENT_ID, COGNITO_USER_POOL_ID}'
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}Fix Applied Successfully!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo "You can now test your admin dashboard:"
  echo ""
  echo "curl 'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/admin/dashboard' \\"
  echo "  -H 'Authorization: Bearer YOUR_JWT_TOKEN'"
  echo ""
else
  echo -e "${RED}❌ Verification failed!${NC}"
  echo "Expected: $ADMIN_CLIENT_ID"
  echo "Got: $UPDATED_VALUE"
  exit 1
fi
