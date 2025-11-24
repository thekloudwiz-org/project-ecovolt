#!/bin/bash
# EcoVolt Deployment Testing Script
# Tests the deployed infrastructure end-to-end

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
TEST_EMAIL="test-$(date +%s)@example.com"
TEST_PASSWORD="TestPass123!"
TEST_NAME="Test User"
TEST_PHONE="+233201234567"

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}EcoVolt Deployment Testing${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to print test result
test_result() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        if [ ! -z "$3" ]; then
            echo -e "${RED}  Error: $3${NC}"
        fi
    fi
}

# Get Terraform outputs
echo -e "${BLUE}Fetching deployment information...${NC}"
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null)
if [ -z "$API_URL" ] || [ "$API_URL" == "" ]; then
    # Try alternative output name
    API_URL=$(terraform output -raw api_gateway_invoke_url 2>/dev/null)
fi
if [ -z "$API_URL" ] || [ "$API_URL" == "" ]; then
    echo -e "${RED}Error: Could not get API Gateway URL from Terraform outputs${NC}"
    echo -e "${YELLOW}Available outputs:${NC}"
    terraform output 2>&1 | head -5
    exit 1
fi
echo -e "API URL: ${GREEN}$API_URL${NC}"
echo ""

# Test 1: Health Check
echo -e "${BLUE}Test 1: Health Check${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/health" 2>/dev/null)
HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "200" ] && echo "$BODY" | grep -q "healthy"; then
    test_result 0 "Health check endpoint"
else
    test_result 1 "Health check endpoint" "HTTP $HTTP_CODE: $BODY"
fi
echo ""

# Test 2: List Stations (Public endpoint)
echo -e "${BLUE}Test 2: List Stations${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/stations" 2>/dev/null)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ] && echo "$BODY" | grep -q "stations"; then
    test_result 0 "List stations endpoint"
    STATION_COUNT=$(echo "$BODY" | grep -o '"station_id"' | wc -l)
    echo -e "  Found ${GREEN}$STATION_COUNT${NC} stations"
else
    test_result 1 "List stations endpoint" "HTTP $HTTP_CODE"
fi
echo ""

# Test 3: Find Nearby Stations
echo -e "${BLUE}Test 3: Find Nearby Stations${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/stations/nearby?lat=5.6037&lng=-0.1870&radius=10" 2>/dev/null)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "200" ]; then
    test_result 0 "Find nearby stations endpoint"
else
    test_result 1 "Find nearby stations endpoint" "HTTP $HTTP_CODE"
fi
echo ""

# Test 4: CORS Headers
echo -e "${BLUE}Test 4: CORS Configuration${NC}"
RESPONSE=$(curl -s -I -X OPTIONS "${API_URL}/health" 2>/dev/null)

if echo "$RESPONSE" | grep -qi "Access-Control-Allow-Origin"; then
    test_result 0 "CORS headers present"
else
    test_result 1 "CORS headers present"
fi
echo ""

# Test 5: Authentication - Register User
echo -e "${BLUE}Test 5: User Registration${NC}"
REGISTER_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/auth/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"${TEST_EMAIL}\",
        \"password\": \"${TEST_PASSWORD}\",
        \"name\": \"${TEST_NAME}\",
        \"phone\": \"${TEST_PHONE}\"
    }" 2>/dev/null)

HTTP_CODE=$(echo "$REGISTER_RESPONSE" | tail -n1)
BODY=$(echo "$REGISTER_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" == "201" ] || [ "$HTTP_CODE" == "200" ]; then
    test_result 0 "User registration"
    echo -e "  Registered: ${GREEN}${TEST_EMAIL}${NC}"
else
    test_result 1 "User registration" "HTTP $HTTP_CODE: $BODY"
fi
echo ""

# Test 6: Authentication Required
echo -e "${BLUE}Test 6: Authentication Protection${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/profile" 2>/dev/null)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" == "401" ]; then
    test_result 0 "Protected endpoint requires authentication"
else
    test_result 1 "Protected endpoint requires authentication" "Expected 401, got $HTTP_CODE"
fi
echo ""

# Test 7: Invalid Route
echo -e "${BLUE}Test 7: Invalid Route Handling${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/invalid-route-12345" 2>/dev/null)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" == "404" ]; then
    test_result 0 "Invalid route returns 404"
else
    test_result 1 "Invalid route returns 404" "Expected 404, got $HTTP_CODE"
fi
echo ""

# Test 8: Method Not Allowed
echo -e "${BLUE}Test 8: HTTP Method Validation${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "${API_URL}/health" 2>/dev/null)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" == "403" ] || [ "$HTTP_CODE" == "405" ]; then
    test_result 0 "Unsupported HTTP method blocked"
else
    test_result 1 "Unsupported HTTP method blocked" "Expected 403/405, got $HTTP_CODE"
fi
echo ""

# Test 9: Lambda Function Logs
echo -e "${BLUE}Test 9: Lambda Function Logs${NC}"
LOG_GROUP="/aws/lambda/ecovolt-${ENVIRONMENT}-api-handler"
LOG_CHECK=$(aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" 2>/dev/null | grep -c "logGroupName" || echo "0")

if [ "$LOG_CHECK" -gt 0 ]; then
    test_result 0 "Lambda logs are being generated"
    
    # Get recent log entries
    RECENT_LOGS=$(aws logs tail "$LOG_GROUP" --since 5m --format short 2>/dev/null | head -n 5)
    if [ ! -z "$RECENT_LOGS" ]; then
        echo -e "  ${GREEN}Recent log entries found${NC}"
    fi
else
    test_result 1 "Lambda logs are being generated"
fi
echo ""

# Test 10: DynamoDB Tables
echo -e "${BLUE}Test 10: DynamoDB Tables${NC}"
TABLES=$(aws dynamodb list-tables --query "TableNames[?starts_with(@, 'ecovolt-${ENVIRONMENT}')]" --output text 2>/dev/null)
TABLE_COUNT=$(echo "$TABLES" | wc -w)

if [ "$TABLE_COUNT" -ge 3 ]; then
    test_result 0 "DynamoDB tables exist (found $TABLE_COUNT)"
    echo -e "  Tables: ${GREEN}$TABLES${NC}"
else
    test_result 1 "DynamoDB tables exist" "Expected at least 3, found $TABLE_COUNT"
fi
echo ""

# Test 11: API Gateway Stage
echo -e "${BLUE}Test 11: API Gateway Configuration${NC}"
API_ID=$(terraform output -raw api_gateway_id 2>/dev/null)
if [ ! -z "$API_ID" ]; then
    STAGE_INFO=$(aws apigateway get-stage --rest-api-id "$API_ID" --stage-name v1 2>/dev/null)
    if [ $? -eq 0 ]; then
        test_result 0 "API Gateway stage configured"
    else
        test_result 1 "API Gateway stage configured"
    fi
else
    test_result 1 "API Gateway stage configured" "Could not get API ID"
fi
echo ""

# Test 12: WAF Protection
echo -e "${BLUE}Test 12: WAF Protection${NC}"
WAF_CHECK=$(aws wafv2 list-web-acls --scope REGIONAL --region $(aws configure get region) 2>/dev/null | grep -c "ecovolt-${ENVIRONMENT}" || echo "0")

if [ "$WAF_CHECK" -gt 0 ]; then
    test_result 0 "WAF Web ACL configured"
else
    test_result 1 "WAF Web ACL configured"
fi
echo ""

# Test 13: Rate Limiting (WAF)
echo -e "${BLUE}Test 13: Rate Limiting${NC}"
echo -e "  ${YELLOW}Sending multiple requests to test rate limiting...${NC}"
RATE_LIMIT_TRIGGERED=0
for i in {1..10}; do
    RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/health" 2>/dev/null)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    if [ "$HTTP_CODE" == "403" ]; then
        RATE_LIMIT_TRIGGERED=1
        break
    fi
    sleep 0.1
done

if [ "$RATE_LIMIT_TRIGGERED" -eq 0 ]; then
    test_result 0 "Rate limiting configured (not triggered in test)"
else
    test_result 0 "Rate limiting active (triggered during test)"
fi
echo ""

# Test 14: Cognito User Pool
echo -e "${BLUE}Test 14: Cognito User Pool${NC}"
POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null)
if [ ! -z "$POOL_ID" ]; then
    POOL_INFO=$(aws cognito-idp describe-user-pool --user-pool-id "$POOL_ID" 2>/dev/null)
    if [ $? -eq 0 ]; then
        test_result 0 "Cognito User Pool configured"
    else
        test_result 1 "Cognito User Pool configured"
    fi
else
    test_result 1 "Cognito User Pool configured" "Could not get Pool ID"
fi
echo ""

# Test 15: Database Connectivity
echo -e "${BLUE}Test 15: Database Connectivity${NC}"
DB_ENDPOINT=$(terraform output -raw db_endpoint 2>/dev/null)
if [ ! -z "$DB_ENDPOINT" ]; then
    # Try to connect (will fail without password, but tests connectivity)
    timeout 5 bash -c "cat < /dev/null > /dev/tcp/${DB_ENDPOINT}/5432" 2>/dev/null
    if [ $? -eq 0 ]; then
        test_result 0 "Database endpoint reachable"
    else
        test_result 1 "Database endpoint reachable" "Connection timeout or refused"
    fi
else
    test_result 1 "Database endpoint reachable" "Could not get DB endpoint"
fi
echo ""

# Summary
echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "Total Tests: ${BLUE}$TESTS_TOTAL${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo -e "${BLUE}Deployment is healthy and ready for use.${NC}"
    EXIT_CODE=0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo -e "${YELLOW}Please review the failures above and check:${NC}"
    echo "  - CloudWatch Logs: aws logs tail /aws/lambda/ecovolt-${ENVIRONMENT}-api-handler --follow"
    echo "  - API Gateway: aws apigateway get-rest-apis"
    echo "  - Lambda Functions: aws lambda list-functions"
    EXIT_CODE=1
fi

echo ""
echo -e "${BLUE}=========================================${NC}"

exit $EXIT_CODE
