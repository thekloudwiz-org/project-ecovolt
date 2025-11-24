#!/bin/bash
# EcoVolt Backend Test Runner

set -e

echo "========================================="
echo "EcoVolt Backend Test Suite"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Virtual environment not found. Creating...${NC}"
    python3 -m venv venv
fi

# Activate virtual environment
echo -e "${GREEN}Activating virtual environment...${NC}"
source venv/bin/activate

# Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
pip install -q -r requirements.txt

echo ""
echo "========================================="
echo "Running Syntax Checks"
echo "========================================="

# Check Python syntax
echo -e "${GREEN}Checking Python syntax...${NC}"
python3 -m py_compile api/*.py 2>/dev/null && echo "✓ API modules syntax OK" || echo "✗ API modules have syntax errors"
python3 -m py_compile functions/*.py 2>/dev/null && echo "✓ Functions syntax OK" || echo "✗ Functions have syntax errors"
python3 -m py_compile models/*.py 2>/dev/null && echo "✓ Models syntax OK" || echo "✗ Models have syntax errors"
python3 -m py_compile utils/*.py 2>/dev/null && echo "✓ Utils syntax OK" || echo "✗ Utils have syntax errors"

echo ""
echo "========================================="
echo "Running Unit Tests"
echo "========================================="

# Run pytest
pytest tests/ -v --tb=short

TEST_EXIT_CODE=$?

echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
else
    echo -e "${RED}✗ Some tests failed${NC}"
fi

echo ""
echo "========================================="
echo "Code Structure Verification"
echo "========================================="

# Count files
API_COUNT=$(ls -1 api/*.py 2>/dev/null | wc -l)
FUNCTION_COUNT=$(ls -1 functions/*.py 2>/dev/null | wc -l)
MODEL_COUNT=$(ls -1 models/*.py 2>/dev/null | wc -l)
UTIL_COUNT=$(ls -1 utils/*.py 2>/dev/null | wc -l)
TEST_COUNT=$(ls -1 tests/test_*.py 2>/dev/null | wc -l)

echo "API Endpoints: $API_COUNT files"
echo "Lambda Functions: $FUNCTION_COUNT files"
echo "Data Models: $MODEL_COUNT files"
echo "Utilities: $UTIL_COUNT files"
echo "Test Files: $TEST_COUNT files"

echo ""
echo "========================================="

exit $TEST_EXIT_CODE
