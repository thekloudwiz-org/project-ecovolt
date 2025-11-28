#!/bin/bash
# Build all Lambda function deployment packages
# This script packages Lambda functions with their dependencies

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Lambda Function Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="${PROJECT_ROOT}/infra"

# Counter for built functions
BUILT_COUNT=0
FAILED_COUNT=0

# Function to build a Lambda package
build_lambda() {
    local lambda_dir=$1
    local lambda_name=$2
    local has_requirements=$3

    echo -e "${YELLOW}Building ${lambda_name}...${NC}"

    cd "$lambda_dir"

    # Clean up old artifacts
    rm -rf package
    rm -f *.zip

    if [ "$has_requirements" = "true" ] && [ -f "requirements.txt" ]; then
        echo "  Installing dependencies..."
        mkdir -p package

        # Install dependencies to package directory
        pip3 install --target ./package -r requirements.txt --quiet

        # Copy Lambda code to package
        cp *.py package/ 2>/dev/null || true

        # Create ZIP from package
        cd package
        zip -r ../${lambda_name}.zip . -q
        cd ..

        # Clean up package directory
        rm -rf package
    else
        # No dependencies, just zip the Python files
        zip -j ${lambda_name}.zip *.py -q
    fi

    # Check if ZIP was created
    if [ -f "${lambda_name}.zip" ]; then
        local size=$(du -h "${lambda_name}.zip" | cut -f1)
        echo -e "  ${GREEN}✓ Built ${lambda_name}.zip (${size})${NC}"
        BUILT_COUNT=$((BUILT_COUNT + 1))
        return 0
    else
        echo -e "  ${RED}✗ Failed to build ${lambda_name}.zip${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# Build Analytics Lambda Functions
echo -e "\n${BLUE}=== Analytics Module ===${NC}"

build_lambda \
    "${INFRA_DIR}/modules/analytics/lambda" \
    "stream_processor" \
    "true"

build_lambda \
    "${INFRA_DIR}/modules/analytics/lambda" \
    "data_transformer" \
    "false"

# Build Compute Lambda Functions
echo -e "\n${BLUE}=== Compute Module ===${NC}"

build_lambda \
    "${INFRA_DIR}/modules/compute/lambda" \
    "api_handler" \
    "false"

build_lambda \
    "${INFRA_DIR}/modules/compute/lambda" \
    "stream_processor_compute" \
    "false"

# Build Database Lambda Functions
echo -e "\n${BLUE}=== Database Module ===${NC}"

build_lambda \
    "${INFRA_DIR}/modules/database/lambda" \
    "rotate_secret" \
    "false"

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}Build Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Built:  ${GREEN}${BUILT_COUNT}${NC}"
echo -e "Failed: ${RED}${FAILED_COUNT}${NC}"
echo ""

if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "${RED}Some Lambda functions failed to build!${NC}"
    exit 1
else
    echo -e "${GREEN}All Lambda functions built successfully!${NC}"
    exit 0
fi
