#!/bin/bash
# Test Runner Script for EcoVolt Infrastructure Tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EcoVolt Infrastructure Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: Go is not installed${NC}"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

# Parse command line arguments
TEST_TYPE="${1:-all}"
TEST_TIMEOUT="${2:-30m}"

# Run tests based on type
case "$TEST_TYPE" in
    "unit")
        echo -e "${BLUE}Running Unit Tests...${NC}"
        go test -v ./unit -timeout $TEST_TIMEOUT
        ;;
    "properties")
        echo -e "${BLUE}Running Property-Based Tests...${NC}"
        go test -v ./properties -timeout $TEST_TIMEOUT
        ;;
    "cognito")
        echo -e "${BLUE}Running Cognito Tests...${NC}"
        go test -v ./unit -run TestCognito -timeout $TEST_TIMEOUT
        ;;
    "dynamodb")
        echo -e "${BLUE}Running DynamoDB Tests...${NC}"
        go test -v ./unit -run TestDynamoDB -timeout $TEST_TIMEOUT
        ;;
    "waf")
        echo -e "${BLUE}Running WAF Tests...${NC}"
        go test -v ./unit -run TestWAF -timeout $TEST_TIMEOUT
        ;;
    "elasticache")
        echo -e "${BLUE}Running ElastiCache Tests...${NC}"
        go test -v ./unit -run TestElastiCache -timeout $TEST_TIMEOUT
        ;;
    "new-modules")
        echo -e "${BLUE}Running Tests for New Modules...${NC}"
        go test -v ./unit -run "TestCognito|TestDynamoDB|TestWAF|TestElastiCache" -timeout $TEST_TIMEOUT
        ;;
    "all")
        echo -e "${BLUE}Running All Tests...${NC}"
        go test -v ./unit ./properties -timeout $TEST_TIMEOUT
        ;;
    *)
        echo -e "${RED}Error: Unknown test type '$TEST_TYPE'${NC}"
        echo ""
        echo "Usage: $0 [test-type] [timeout]"
        echo ""
        echo "Test types:"
        echo "  unit         - Run all unit tests"
        echo "  properties   - Run all property-based tests"
        echo "  cognito      - Run Cognito tests only"
        echo "  dynamodb     - Run DynamoDB tests only"
        echo "  waf          - Run WAF tests only"
        echo "  elasticache  - Run ElastiCache tests only"
        echo "  new-modules  - Run tests for newly added modules"
        echo "  all          - Run all tests (default)"
        echo ""
        echo "Timeout: default is 30m (e.g., 10m, 1h)"
        exit 1
        ;;
esac

# Check test results
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Some tests failed${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
