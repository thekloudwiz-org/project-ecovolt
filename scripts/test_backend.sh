#!/bin/bash
# Backend End-to-End Testing Script
# Tests all backend functionality before moving to frontend development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_URL="https://vsxihe0ysi.execute-api.eu-central-1.amazonaws.com/v1"
REGION="eu-central-1"
USER_POOL_ID="eu-central-1_E7M5G0pFZ"
TEST_EMAIL="test-rider@ecovolt.com"
TEST_PASSWORD="TestPassword123!"
ADMIN_EMAIL="admin@ecovolt.com"
ADMIN_PASSWORD="AdminPassword123!"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Function to print test results
print_test() {
    local test_name=$1
    local status=$2
    local message=$3
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ "$status" == "PASS" ]; then
        echo -e "${GREEN}✓${NC} Test $TESTS_TOTAL: $test_name - ${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test $TESTS_TOTAL: $test_name - ${RED}FAILED${NC}"
        if [ -n "$message" ]; then
            echo -e "  ${YELLOW}Error: $message${NC}"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to make API request with proper headers
api_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local token=$4
    
    local headers=(-H "Content-Type: application/json" -H "User-Agent: EcoVolt-Test-Suite/1.0")
    
    if [ -n "$token" ]; then
        headers+=(-H "Authorization: Bearer $token")
    fi
    
    if [ -n "$data" ]; then
        curl -s -X "$method" "${API_URL}${endpoint}" "${headers[@]}" -d "$data"
    else
        curl -s -X "$method" "${API_URL}${endpoint}" "${headers[@]}"
    fi
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EcoVolt Backend E2E Testing${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Test 1: Health Check
echo -e "${YELLOW}Testing: Health Check Endpoint${NC}"
HEALTH_RESPONSE=$(api_request "GET" "/health" "" "")
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    print_test "Health Check" "PASS"
else
    print_test "Health Check" "FAIL" "Response: $HEALTH_RESPONSE"
fi
echo ""

# Test 2: Database Connection (via migration Lambda)
echo -e "${YELLOW}Testing: Database Connection${NC}"
DB_TEST=$(aws lambda invoke \
    --function-name ecovolt-dev-db-migrator \
    --region $REGION \
    --cli-binary-format raw-in-base64-out \
    --payload '{"s3_bucket": "ecovolt-app-deployment-bucket", "s3_prefix": "migrations/dev/"}' \
    /tmp/db-test-response.json 2>&1)

if cat /tmp/db-test-response.json | grep -q "statusCode.*200"; then
    print_test "Database Connection" "PASS"
else
    print_test "Database Connection" "FAIL" "$(cat /tmp/db-test-response.json)"
fi
echo ""

# Test 3: List Stations (Public Endpoint)
echo -e "${YELLOW}Testing: List Stations (Public)${NC}"
STATIONS_RESPONSE=$(api_request "GET" "/stations" "" "")
if echo "$STATIONS_RESPONSE" | grep -q "stations\|data"; then
    print_test "List Stations" "PASS"
else
    print_test "List Stations" "FAIL" "Response: $STATIONS_RESPONSE"
fi
echo ""

# Test 4: Create Test User in Cognito
echo -e "${YELLOW}Testing: User Registration${NC}"
# First, check if user exists and delete if needed
aws cognito-idp admin-delete-user \
    --user-pool-id $USER_POOL_ID \
    --username $TEST_EMAIL \
    --region $REGION 2>/dev/null || true

# Register new user
REGISTER_RESPONSE=$(api_request "POST" "/auth/register" \
    "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"phone\":\"+233501234567\",\"name\":\"Test Rider\"}" \
    "")

if echo "$REGISTER_RESPONSE" | grep -q "user_id\|UserSub\|success"; then
    print_test "User Registration" "PASS"
    
    # Confirm user (admin action for testing)
    aws cognito-idp admin-confirm-sign-up \
        --user-pool-id $USER_POOL_ID \
        --username $TEST_EMAIL \
        --region $REGION 2>/dev/null || true
else
    print_test "User Registration" "FAIL" "Response: $REGISTER_RESPONSE"
fi
echo ""

# Test 5: User Login
echo -e "${YELLOW}Testing: User Login${NC}"
LOGIN_RESPONSE=$(api_request "POST" "/auth/login" \
    "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}" \
    "")

if echo "$LOGIN_RESPONSE" | grep -q "access_token\|AccessToken\|token"; then
    print_test "User Login" "PASS"
    # Extract token for subsequent tests
    ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token // .AccessToken // .token' 2>/dev/null || echo "")
else
    print_test "User Login" "FAIL" "Response: $LOGIN_RESPONSE"
    ACCESS_TOKEN=""
fi
echo ""

# Test 6: Get User Profile (Authenticated)
if [ -n "$ACCESS_TOKEN" ]; then
    echo -e "${YELLOW}Testing: Get User Profile (Authenticated)${NC}"
    PROFILE_RESPONSE=$(api_request "GET" "/profile" "" "$ACCESS_TOKEN")
    
    if echo "$PROFILE_RESPONSE" | grep -q "email\|user_id"; then
        print_test "Get User Profile" "PASS"
    else
        print_test "Get User Profile" "FAIL" "Response: $PROFILE_RESPONSE"
    fi
    echo ""
fi

# Test 7: Get Wallet (Authenticated)
if [ -n "$ACCESS_TOKEN" ]; then
    echo -e "${YELLOW}Testing: Get Wallet Balance${NC}"
    WALLET_RESPONSE=$(api_request "GET" "/wallet" "" "$ACCESS_TOKEN")
    
    if echo "$WALLET_RESPONSE" | grep -q "balance\|wallet"; then
        print_test "Get Wallet Balance" "PASS"
    else
        print_test "Get Wallet Balance" "FAIL" "Response: $WALLET_RESPONSE"
    fi
    echo ""
fi

# Test 8: Get Swap History (Authenticated)
if [ -n "$ACCESS_TOKEN" ]; then
    echo -e "${YELLOW}Testing: Get Swap History${NC}"
    HISTORY_RESPONSE=$(api_request "GET" "/swaps/history" "" "$ACCESS_TOKEN")
    
    if echo "$HISTORY_RESPONSE" | grep -q "swaps\|history\|data"; then
        print_test "Get Swap History" "PASS"
    else
        print_test "Get Swap History" "FAIL" "Response: $HISTORY_RESPONSE"
    fi
    echo ""
fi

# Test 9: Get Notifications (Authenticated)
if [ -n "$ACCESS_TOKEN" ]; then
    echo -e "${YELLOW}Testing: Get Notifications${NC}"
    NOTIF_RESPONSE=$(api_request "GET" "/notifications" "" "$ACCESS_TOKEN")
    
    if echo "$NOTIF_RESPONSE" | grep -q "notifications\|data\|\[\]"; then
        print_test "Get Notifications" "PASS"
    else
        print_test "Get Notifications" "FAIL" "Response: $NOTIF_RESPONSE"
    fi
    echo ""
fi

# Test 10: Test Authentication Required
echo -e "${YELLOW}Testing: Authentication Required for Protected Endpoints${NC}"
UNAUTH_RESPONSE=$(api_request "GET" "/profile" "" "")

if echo "$UNAUTH_RESPONSE" | grep -q "Unauthorized\|Missing authorization\|401"; then
    print_test "Authentication Required" "PASS"
else
    print_test "Authentication Required" "FAIL" "Should require auth but got: $UNAUTH_RESPONSE"
fi
echo ""

# Test 11: IoT Processor Lambda
echo -e "${YELLOW}Testing: IoT Telemetry Processor${NC}"
IOT_TEST=$(aws lambda invoke \
    --function-name ecovolt-dev-iot-processor \
    --region $REGION \
    --cli-binary-format raw-in-base64-out \
    --payload '{"topic":"dev/telemetry/bike/TEST001","payload":{"battery_level":85,"location":{"lat":5.6037,"lon":-0.1870}}}' \
    /tmp/iot-test-response.json 2>&1)

if cat /tmp/iot-test-response.json | grep -q "statusCode.*200\|success"; then
    print_test "IoT Telemetry Processor" "PASS"
else
    print_test "IoT Telemetry Processor" "FAIL" "$(cat /tmp/iot-test-response.json)"
fi
echo ""

# Test 12: VPC Endpoints Connectivity
echo -e "${YELLOW}Testing: VPC Endpoints (Secrets Manager & S3)${NC}"
VPC_TEST=$(aws lambda invoke \
    --function-name ecovolt-dev-db-migrator \
    --region $REGION \
    --log-type Tail \
    --cli-binary-format raw-in-base64-out \
    --payload '{"s3_bucket": "ecovolt-app-deployment-bucket", "s3_prefix": "migrations/dev/"}' \
    /tmp/vpc-test-response.json 2>&1 | grep -o "Duration: [0-9.]* ms")

if [ -n "$VPC_TEST" ]; then
    print_test "VPC Endpoints Connectivity" "PASS" "$VPC_TEST"
else
    print_test "VPC Endpoints Connectivity" "FAIL"
fi
echo ""

# Test 13: DynamoDB Access
echo -e "${YELLOW}Testing: DynamoDB Access${NC}"
DYNAMODB_TEST=$(aws dynamodb describe-table \
    --table-name ecovolt-dev-battery-inventory \
    --region $REGION 2>&1)

if echo "$DYNAMODB_TEST" | grep -q "TableStatus.*ACTIVE"; then
    print_test "DynamoDB Tables" "PASS"
else
    print_test "DynamoDB Tables" "FAIL"
fi
echo ""

# Test 14: RDS Database Access
echo -e "${YELLOW}Testing: RDS Database Access${NC}"
# This is tested via the migration Lambda above, so we'll check if migrations table exists
DB_CHECK=$(aws lambda invoke \
    --function-name ecovolt-dev-db-migrator \
    --region $REGION \
    --cli-binary-format raw-in-base64-out \
    --payload '{"s3_bucket": "ecovolt-app-deployment-bucket", "s3_prefix": "migrations/dev/"}' \
    /tmp/db-check-response.json 2>&1)

if cat /tmp/db-check-response.json | grep -q "already applied\|Skipped"; then
    print_test "RDS Database Access" "PASS"
else
    print_test "RDS Database Access" "FAIL"
fi
echo ""

# Print Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total Tests: ${BLUE}$TESTS_TOTAL${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Backend is ready for frontend development.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Please review the errors above.${NC}"
    exit 1
fi
