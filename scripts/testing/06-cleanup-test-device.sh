#!/bin/bash
# EcoVolt IoT Device Cleanup Script
# This script removes a test IoT device and its certificates

set -e

# Configuration
REGION="eu-central-1"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse command line arguments
DEVICE_TYPE=${1:-bike}
DEVICE_ID=${2:-test-001}

DEVICE_NAME="${DEVICE_TYPE}-${DEVICE_ID}"
CERTS_DIR="./certs/${DEVICE_NAME}"

# Check if device exists
if [ ! -f "${CERTS_DIR}/device-info.json" ]; then
    echo -e "${RED}Error: Device ${DEVICE_NAME} not found${NC}"
    echo "No cleanup needed"
    exit 0
fi

# Load device info
DEVICE_INFO=$(cat "${CERTS_DIR}/device-info.json")
THING_ARN=$(echo "$DEVICE_INFO" | jq -r '.thingArn')
CERT_ARN=$(echo "$DEVICE_INFO" | jq -r '.certificateArn')
CERT_ID=$(echo "$DEVICE_INFO" | jq -r '.certificateId')

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}EcoVolt IoT Device Cleanup${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "Device:       ${GREEN}${DEVICE_NAME}${NC}"
echo -e "Thing ARN:    ${THING_ARN}"
echo -e "Cert ARN:     ${CERT_ARN}"
echo ""

read -p "Are you sure you want to delete this device? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled"
    exit 0
fi

echo ""

# Step 1: Detach certificate from thing
echo -e "${YELLOW}[1/5] Detaching certificate from thing...${NC}"
aws iot detach-thing-principal \
    --thing-name "${DEVICE_NAME}" \
    --principal "${CERT_ARN}" \
    --region "${REGION}" 2>/dev/null || echo "  (already detached)"
echo -e "${GREEN}✓ Certificate detached${NC}"

# Step 2: Detach policy from certificate
echo -e "${YELLOW}[2/5] Detaching policies from certificate...${NC}"
POLICIES=$(aws iot list-principal-policies \
    --principal "${CERT_ARN}" \
    --region "${REGION}" | jq -r '.policies[].policyName')

if [ -n "$POLICIES" ]; then
    echo "$POLICIES" | while read policy; do
        aws iot detach-policy \
            --policy-name "$policy" \
            --target "${CERT_ARN}" \
            --region "${REGION}"
        echo -e "  Detached policy: $policy"
    done
else
    echo -e "  No policies attached"
fi
echo -e "${GREEN}✓ Policies detached${NC}"

# Step 3: Deactivate certificate
echo -e "${YELLOW}[3/5] Deactivating certificate...${NC}"
aws iot update-certificate \
    --certificate-id "${CERT_ID}" \
    --new-status INACTIVE \
    --region "${REGION}"
echo -e "${GREEN}✓ Certificate deactivated${NC}"

# Step 4: Delete certificate
echo -e "${YELLOW}[4/5] Deleting certificate...${NC}"
aws iot delete-certificate \
    --certificate-id "${CERT_ID}" \
    --force-delete \
    --region "${REGION}"
echo -e "${GREEN}✓ Certificate deleted${NC}"

# Step 5: Delete thing
echo -e "${YELLOW}[5/5] Deleting IoT thing...${NC}"
aws iot delete-thing \
    --thing-name "${DEVICE_NAME}" \
    --region "${REGION}"
echo -e "${GREEN}✓ Thing deleted${NC}"

# Remove local certificates
echo ""
echo -e "${YELLOW}Removing local certificates...${NC}"
rm -rf "${CERTS_DIR}"
echo -e "${GREEN}✓ Local certificates removed${NC}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
