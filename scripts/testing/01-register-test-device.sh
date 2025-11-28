#!/bin/bash
# EcoVolt IoT Device Registration Script
# This script registers a test IoT device (bike, station, or battery) with AWS IoT Core

set -e

# Configuration
REGION="eu-central-1"
ENVIRONMENT="dev"
PROJECT="ecovolt"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse command line arguments
DEVICE_TYPE=${1:-bike}  # bike, station, or battery
DEVICE_ID=${2:-test-001}

if [[ ! "$DEVICE_TYPE" =~ ^(bike|station|battery)$ ]]; then
    echo -e "${RED}Error: Device type must be 'bike', 'station', or 'battery'${NC}"
    echo "Usage: $0 <device-type> <device-id>"
    echo "Example: $0 bike test-bike-001"
    exit 1
fi

# Full device name
DEVICE_NAME="${DEVICE_TYPE}-${DEVICE_ID}"
THING_TYPE="${PROJECT}-${ENVIRONMENT}-${DEVICE_TYPE}"
IOT_POLICY="${PROJECT}-${ENVIRONMENT}-iot-policy"

# Create certs directory
CERTS_DIR="./certs/${DEVICE_NAME}"
mkdir -p "$CERTS_DIR"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}EcoVolt IoT Device Registration${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "Device Name:  ${GREEN}${DEVICE_NAME}${NC}"
echo -e "Device Type:  ${GREEN}${DEVICE_TYPE}${NC}"
echo -e "Thing Type:   ${GREEN}${THING_TYPE}${NC}"
echo -e "Region:       ${GREEN}${REGION}${NC}"
echo ""

# Step 1: Create IoT Thing
echo -e "${YELLOW}[1/5] Creating IoT Thing...${NC}"
THING_ARN=$(aws iot create-thing \
    --thing-name "${DEVICE_NAME}" \
    --thing-type-name "${THING_TYPE}" \
    --attribute-payload "{\"attributes\":{\"deviceId\":\"${DEVICE_ID}\",\"type\":\"${DEVICE_TYPE}\",\"manufacturer\":\"EcoVolt\",\"test\":\"true\"}}" \
    --region "${REGION}" \
    --output json | jq -r '.thingArn')

if [ -z "$THING_ARN" ]; then
    echo -e "${RED}Failed to create IoT Thing${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Thing created: ${THING_ARN}${NC}"

# Step 2: Create certificates
echo -e "${YELLOW}[2/5] Creating device certificates...${NC}"
CERT_OUTPUT=$(aws iot create-keys-and-certificate \
    --set-as-active \
    --certificate-pem-outfile "${CERTS_DIR}/certificate.pem" \
    --public-key-outfile "${CERTS_DIR}/public.key" \
    --private-key-outfile "${CERTS_DIR}/private.key" \
    --region "${REGION}" \
    --output json)

CERT_ARN=$(echo "$CERT_OUTPUT" | jq -r '.certificateArn')
CERT_ID=$(echo "$CERT_OUTPUT" | jq -r '.certificateId')

if [ -z "$CERT_ARN" ]; then
    echo -e "${RED}Failed to create certificates${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Certificates created${NC}"
echo -e "  Certificate ARN: ${CERT_ARN}"
echo -e "  Certificate ID:  ${CERT_ID}"

# Download AWS IoT Root CA
echo -e "${YELLOW}[3/5] Downloading AWS IoT Root CA...${NC}"
curl -s https://www.amazontrust.com/repository/AmazonRootCA1.pem -o "${CERTS_DIR}/AmazonRootCA1.pem"
echo -e "${GREEN}✓ Root CA downloaded${NC}"

# Step 3: Attach policy to certificate
echo -e "${YELLOW}[4/5] Attaching IoT policy to certificate...${NC}"
aws iot attach-policy \
    --policy-name "${IOT_POLICY}" \
    --target "${CERT_ARN}" \
    --region "${REGION}"
echo -e "${GREEN}✓ Policy attached${NC}"

# Step 4: Attach certificate to thing
echo -e "${YELLOW}[5/5] Attaching certificate to thing...${NC}"
aws iot attach-thing-principal \
    --thing-name "${DEVICE_NAME}" \
    --principal "${CERT_ARN}" \
    --region "${REGION}"
echo -e "${GREEN}✓ Certificate attached to thing${NC}"

# Get IoT endpoint
IOT_ENDPOINT=$(aws iot describe-endpoint \
    --endpoint-type iot:Data-ATS \
    --region "${REGION}" \
    --output json | jq -r '.endpointAddress')

# Save device info
cat > "${CERTS_DIR}/device-info.json" <<EOF
{
  "deviceName": "${DEVICE_NAME}",
  "deviceType": "${DEVICE_TYPE}",
  "deviceId": "${DEVICE_ID}",
  "thingArn": "${THING_ARN}",
  "certificateArn": "${CERT_ARN}",
  "certificateId": "${CERT_ID}",
  "iotEndpoint": "${IOT_ENDPOINT}",
  "region": "${REGION}",
  "mqttTopic": "ecovolt/${DEVICE_TYPE}s/${DEVICE_NAME}/telemetry",
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Device registration complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Device certificates saved to: ${GREEN}${CERTS_DIR}/${NC}"
echo -e "IoT Endpoint: ${GREEN}${IOT_ENDPOINT}${NC}"
echo -e "MQTT Topic:   ${GREEN}ecovolt/${DEVICE_TYPE}s/${DEVICE_NAME}/telemetry${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review device-info.json for connection details"
echo "2. Use ./02-publish-test-data.sh to send test telemetry"
echo "3. Use ./03-verify-pipeline.sh to check data flow"
echo ""
