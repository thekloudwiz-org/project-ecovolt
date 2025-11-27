#!/bin/bash
#
# Fetch Cognito JWK Keys for Lambda Environment Injection
#
# This script fetches the public JWK keys from your Cognito User Pool
# and formats them for injection into Lambda environment variables.
#
# Usage:
#   ./scripts/fetch_cognito_jwk_keys.sh <aws-region> <user-pool-id>
#
# Example:
#   ./scripts/fetch_cognito_jwk_keys.sh eu-central-1 eu-central-1_abc123
#
# The script outputs a JSON string that should be injected as the
# COGNITO_JWK_KEYS environment variable in your Lambda function.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -ne 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo ""
    echo "Usage: $0 <aws-region> <user-pool-id>"
    echo ""
    echo "Example:"
    echo "  $0 eu-central-1 eu-central-1_abc123"
    echo ""
    exit 1
fi

AWS_REGION=$1
USER_POOL_ID=$2

echo -e "${YELLOW}Fetching JWK keys from Cognito User Pool...${NC}"
echo "Region: $AWS_REGION"
echo "User Pool ID: $USER_POOL_ID"
echo ""

# Construct JWK URL
JWK_URL="https://cognito-idp.${AWS_REGION}.amazonaws.com/${USER_POOL_ID}/.well-known/jwks.json"

echo "Fetching from: $JWK_URL"
echo ""

# Fetch JWK keys
JWK_KEYS=$(curl -s "$JWK_URL")

# Check if curl was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to fetch JWK keys${NC}"
    exit 1
fi

# Check if response is valid JSON
if ! echo "$JWK_KEYS" | jq . >/dev/null 2>&1; then
    echo -e "${RED}Error: Invalid JSON response${NC}"
    echo "Response: $JWK_KEYS"
    exit 1
fi

# Check if keys array exists
KEY_COUNT=$(echo "$JWK_KEYS" | jq '.keys | length')

if [ "$KEY_COUNT" -eq 0 ]; then
    echo -e "${RED}Error: No keys found in JWK response${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Successfully fetched $KEY_COUNT JWK key(s)${NC}"
echo ""

# Output formatted for Terraform
echo "================================================"
echo "COGNITO JWK KEYS (for Terraform)"
echo "================================================"
echo ""
echo "Add this to your Terraform Lambda environment variables:"
echo ""
echo "environment {"
echo "  variables = {"
echo "    COGNITO_JWK_KEYS = <<-EOT"
echo "$JWK_KEYS" | jq -c .
echo "EOT"
echo "  }"
echo "}"
echo ""

# Output for .env file
echo "================================================"
echo "FOR LOCAL TESTING (.env file)"
echo "================================================"
echo ""
echo "Add this to your .env file:"
echo ""
echo "COGNITO_JWK_KEYS='$(echo $JWK_KEYS | jq -c .)'"
echo ""

# Save to file
OUTPUT_FILE="cognito_jwk_keys.json"
echo "$JWK_KEYS" | jq . > "$OUTPUT_FILE"
echo -e "${GREEN}✅ JWK keys saved to: $OUTPUT_FILE${NC}"
echo ""

# Show key details
echo "================================================"
echo "KEY DETAILS"
echo "================================================"
echo ""
echo "$JWK_KEYS" | jq -r '.keys[] | "Key ID: \(.kid)\nAlgorithm: \(.alg)\nKey Type: \(.kty)\nUse: \(.use)\n"'

echo -e "${GREEN}Done!${NC}"
