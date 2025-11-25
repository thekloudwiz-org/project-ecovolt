#!/bin/bash
# EcoVolt API End-to-End Test
# Tests the complete user registration and authentication flow

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

API_URL="https://vsxihe0ysi.execute-api.eu-central-1.amazonaws.com/v1"
TEST_EMAIL="test-user-$(date +%s)@example.com"
TEST_PASSWORD="TestPass123!"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}EcoVolt API End-to-End Test${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Test 1: Register User
echo -e "${BLUE}Test 1: Register User${NC}"
echo "Email: $TEST_EMAIL"
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${TEST_EMAIL}\", \"password\": \"${TEST_PASSWORD}\", \"name\": \"Test User\", \"phone\": \"+233201234567\"}")

HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -1)
BODY=$(echo "$REGISTER_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "201" ]; then
    echo -e "${GREEN}✓ Registration successful${NC}"
    echo "$BODY" | python3 -m json.tool
    USER_ID=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['user_id'])" 2>/dev/null)
    echo "User ID: $USER_ID"
else
    echo -e "${RED}✗ Registration failed${NC}"
    echo "Status: $HTTP_CODE"
    echo "$BODY"
    exit 1
fi
echo ""

# Test 2: Verify user in Cognito
echo -e "${BLUE}Test 2: Verify User in Cognito${NC}"
POOL_ID=$(aws cognito-idp list-user-pools --max-results 10 --query "UserPools[?contains(Name, 'ecovolt-dev')].Id" --output text)
USER_STATUS=$(aws cognito-idp list-users --user-pool-id "$POOL_ID" --filter "email=\"${TEST_EMAIL}\"" --query "Users[0].UserStatus" --output text)

if [ "$USER_STATUS" == "UNCONFIRMED" ]; then
    echo -e "${GREEN}✓ User found in Cognito (Status: UNCONFIRMED)${NC}"
else
    echo -e "${RED}✗ User not found or unexpected status: $USER_STATUS${NC}"
    exit 1
fi
echo ""

# Test 3: Confirm user
echo -e "${BLUE}Test 3: Confirm User${NC}"
aws cognito-idp admin-confirm-sign-up --user-pool-id "$POOL_ID" --username "$USER_ID" >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ User confirmed${NC}"
else
    echo -e "${RED}✗ Failed to confirm user${NC}"
    exit 1
fi
echo ""

# Test 4: Login
echo -e "${BLUE}Test 4: Login${NC}"
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"${TEST_EMAIL}\", \"password\": \"${TEST_PASSWORD}\"}")

HTTP_CODE=$(echo "$LOGIN_RESPONSE" | tail -1)
BODY=$(echo "$LOGIN_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Login successful${NC}"
    ACCESS_TOKEN=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null)
    echo "Access token received (length: ${#ACCESS_TOKEN})"
else
    echo -e "${RED}✗ Login failed${NC}"
    echo "Status: $HTTP_CODE"
    echo "$BODY"
    exit 1
fi
echo ""

# Test 5: Check Lambda logs
echo -e "${BLUE}Test 5: Check Lambda Logs${NC}"
echo "Recent logs:"
aws logs tail /aws/lambda/ecovolt-dev-api-handler --since 2m --format short 2>/dev/null | tail -5
echo ""

# Test 6: Check DynamoDB
echo -e "${BLUE}Test 6: Check DynamoDB User Profile${NC}"
PROFILE_COUNT=$(aws dynamodb scan --table-name ecovolt-dev-user-profiles --select COUNT --output json | python3 -c "import sys, json; print(json.load(sys.stdin)['Count'])")
echo "User profiles in DynamoDB: $PROFILE_COUNT"
echo ""

# Summary
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✓ User registration working${NC}"
echo -e "${GREEN}✓ Cognito integration working${NC}"
echo -e "${GREEN}✓ User confirmation working${NC}"
echo -e "${GREEN}✓ User login working${NC}"
echo -e "${GREEN}✓ JWT tokens being issued${NC}"
echo ""
echo -e "${YELLOW}Note: Check logs for any database connection issues${NC}"
echo ""
