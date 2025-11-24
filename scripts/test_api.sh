#!/bin/bash
# Simple API Testing Script
# Tests the deployed EcoVolt API

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get API URL
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null)

if [ -z "$API_URL" ]; then
    echo -e "${RED}Error: Could not get API URL${NC}"
    exit 1
fi

echo -e "${BLUE}Testing EcoVolt API${NC}"
echo -e "API URL: ${GREEN}$API_URL${NC}"
echo ""

# Test 1: Health Check
echo -e "${BLUE}1. Health Check${NC}"
curl -s "${API_URL}/health" | python3 -m json.tool
echo ""

# Test 2: List Stations
echo -e "${BLUE}2. List Stations${NC}"
curl -s "${API_URL}/stations" | python3 -m json.tool | head -30
echo ""

# Test 3: Find Nearby Stations
echo -e "${BLUE}3. Find Nearby Stations (Accra)${NC}"
curl -s "${API_URL}/stations/nearby?lat=5.6037&lng=-0.1870&radius=10" | python3 -m json.tool | head -30
echo ""

# Test 4: Test Authentication Required
echo -e "${BLUE}4. Test Authentication (should fail)${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/profile")
if [ "$HTTP_CODE" == "401" ]; then
    echo -e "${GREEN}✓ Authentication required (401)${NC}"
else
    echo -e "${RED}✗ Expected 401, got $HTTP_CODE${NC}"
fi
echo ""

# Test 5: Test Invalid Route
echo -e "${BLUE}5. Test Invalid Route${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${API_URL}/invalid-route")
if [ "$HTTP_CODE" == "404" ]; then
    echo -e "${GREEN}✓ Invalid route returns 404${NC}"
else
    echo -e "${RED}✗ Expected 404, got $HTTP_CODE${NC}"
fi
echo ""

# Test 6: CORS Check
echo -e "${BLUE}6. CORS Headers${NC}"
curl -s -I -X OPTIONS "${API_URL}/health" | grep -i "access-control"
echo ""

echo -e "${GREEN}API Testing Complete!${NC}"
