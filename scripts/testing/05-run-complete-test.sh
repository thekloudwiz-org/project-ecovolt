#!/bin/bash
# EcoVolt Complete IoT Pipeline Test
# This script runs a complete end-to-end test of the IoT infrastructure

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DEVICE_TYPE=${1:-bike}
DEVICE_ID=${2:-test-001}
NUM_MESSAGES=${3:-5}

DEVICE_NAME="${DEVICE_TYPE}-${DEVICE_ID}"
CERTS_DIR="./certs/${DEVICE_NAME}"

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  EcoVolt Complete Pipeline Test       ║${NC}"
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo ""
echo -e "Device Type:  ${GREEN}${DEVICE_TYPE}${NC}"
echo -e "Device ID:    ${GREEN}${DEVICE_ID}${NC}"
echo -e "Messages:     ${GREEN}${NUM_MESSAGES}${NC}"
echo ""

# Step 1: Check if device exists, register if not
if [ ! -f "${CERTS_DIR}/device-info.json" ]; then
    echo -e "${YELLOW}[STEP 1/5] Registering test device...${NC}"
    ./01-register-test-device.sh "$DEVICE_TYPE" "$DEVICE_ID"
    echo ""
else
    echo -e "${GREEN}[STEP 1/5] Device already registered ✓${NC}"
    echo ""
fi

# Step 2: Verify pipeline before publishing
echo -e "${YELLOW}[STEP 2/5] Verifying pipeline components...${NC}"
./03-verify-pipeline.sh > /tmp/pipeline-before.log 2>&1
PIPELINE_STATUS=$?

if [ $PIPELINE_STATUS -eq 0 ]; then
    echo -e "${GREEN}✓ Pipeline verified${NC}"
else
    echo -e "${RED}✗ Pipeline verification failed${NC}"
    echo "Check /tmp/pipeline-before.log for details"
    exit 1
fi
echo ""

# Step 3: Publish test data
echo -e "${YELLOW}[STEP 3/5] Publishing ${NUM_MESSAGES} test messages...${NC}"
./02-publish-test-data.sh "$DEVICE_TYPE" "$DEVICE_ID" "$NUM_MESSAGES" 1
echo ""

# Step 4: Wait for data to propagate
echo -e "${YELLOW}[STEP 4/5] Waiting 15 seconds for data to propagate...${NC}"
for i in {15..1}; do
    echo -ne "\r  Time remaining: ${i}s "
    sleep 1
done
echo ""
echo -e "${GREEN}✓ Wait complete${NC}"
echo ""

# Step 5: Verify data flow
echo -e "${YELLOW}[STEP 5/5] Verifying data flow...${NC}"
./03-verify-pipeline.sh > /tmp/pipeline-after.log 2>&1
echo ""

# Compare before and after
echo -e "${BLUE}═══ Test Results ═══${NC}"
echo ""

# Check Kinesis for records
REGION="eu-central-1"
STREAM_NAME="ecovolt-dev-telemetry-stream"

SHARD_ITERATOR=$(aws kinesis get-shard-iterator \
    --stream-name "${STREAM_NAME}" \
    --shard-id shardId-000000000000 \
    --shard-iterator-type TRIM_HORIZON \
    --region "${REGION}" | jq -r '.ShardIterator')

RECORDS=$(aws kinesis get-records \
    --shard-iterator "$SHARD_ITERATOR" \
    --region "${REGION}" | jq '.Records')

RECORD_COUNT=$(echo "$RECORDS" | jq 'length')

echo -e "Messages Published:     ${GREEN}${NUM_MESSAGES}${NC}"
echo -e "Records in Kinesis:     ${GREEN}${RECORD_COUNT}${NC}"

if [ $RECORD_COUNT -ge $NUM_MESSAGES ]; then
    echo -e "Status:                 ${GREEN}✓ SUCCESS${NC}"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  Test PASSED - Data flowing correctly ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
else
    echo -e "Status:                 ${YELLOW}⚠ PARTIAL${NC}"
    echo ""
    echo -e "${YELLOW}Some messages may not have propagated yet.${NC}"
    echo "Wait a bit longer and run ./03-verify-pipeline.sh"
fi

echo ""

# Show sample data
if [ $RECORD_COUNT -gt 0 ]; then
    echo -e "${BLUE}═══ Sample Record ═══${NC}"
    echo ""
    echo "$RECORDS" | jq -r '.[0].Data' | base64 -d | jq '.'
    echo ""
fi

# Show next steps
echo -e "${CYAN}Next Steps:${NC}"
echo "1. View real-time metrics:  ./04-monitor-metrics.sh"
echo "2. View detailed logs:      aws logs tail /aws/lambda/ecovolt-dev-stream-processor --follow"
echo "3. Publish more data:       ./02-publish-test-data.sh $DEVICE_TYPE $DEVICE_ID 10"
echo "4. Cleanup test device:     ./06-cleanup-test-device.sh $DEVICE_TYPE $DEVICE_ID"
echo ""
