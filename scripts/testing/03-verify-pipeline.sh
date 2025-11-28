#!/bin/bash
# EcoVolt IoT Pipeline Verification Script
# This script verifies the end-to-end data flow from IoT Core through Kinesis

set -e

# Configuration
REGION="eu-central-1"
ENVIRONMENT="dev"
PROJECT="ecovolt"
KINESIS_STREAM="${PROJECT}-${ENVIRONMENT}-telemetry-stream"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}EcoVolt Pipeline Verification${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Function to check component status
check_component() {
    local component=$1
    local status=$2
    if [ "$status" == "OK" ]; then
        echo -e "${GREEN}✓${NC} ${component}"
    else
        echo -e "${RED}✗${NC} ${component}: ${status}"
    fi
}

# 1. Verify IoT Core endpoint
echo -e "${BLUE}[1/6] Checking IoT Core endpoint...${NC}"
IOT_ENDPOINT=$(aws iot describe-endpoint \
    --endpoint-type iot:Data-ATS \
    --region "${REGION}" \
    --output json 2>&1 | jq -r '.endpointAddress')

if [ -n "$IOT_ENDPOINT" ] && [ "$IOT_ENDPOINT" != "null" ]; then
    check_component "IoT Core Endpoint" "OK"
    echo -e "   Endpoint: ${IOT_ENDPOINT}"
else
    check_component "IoT Core Endpoint" "FAILED"
    exit 1
fi
echo ""

# 2. Verify IoT Rules
echo -e "${BLUE}[2/6] Checking IoT Rules...${NC}"
RULES=$(aws iot list-topic-rules --region "${REGION}" --output json | \
    jq -r --arg proj "$PROJECT" --arg env "$ENVIRONMENT" \
    '.rules[] | select(.ruleName | contains("\($proj)_\($env)")) | .ruleName')

RULE_COUNT=$(echo "$RULES" | wc -l)
if [ $RULE_COUNT -ge 3 ]; then
    check_component "IoT Rules" "OK (${RULE_COUNT} rules found)"
    echo "$RULES" | while read rule; do
        STATUS=$(aws iot list-topic-rules --region "${REGION}" | \
            jq -r --arg r "$rule" '.rules[] | select(.ruleName == $r) | .ruleDisabled')
        if [ "$STATUS" == "false" ]; then
            echo -e "   ${GREEN}✓${NC} ${rule} (enabled)"
        else
            echo -e "   ${RED}✗${NC} ${rule} (disabled)"
        fi
    done
else
    check_component "IoT Rules" "FAILED (expected 3, found ${RULE_COUNT})"
fi
echo ""

# 3. Verify Kinesis Stream
echo -e "${BLUE}[3/6] Checking Kinesis Stream...${NC}"
STREAM_STATUS=$(aws kinesis describe-stream-summary \
    --stream-name "${KINESIS_STREAM}" \
    --region "${REGION}" \
    --output json 2>&1 | jq -r '.StreamDescriptionSummary.StreamStatus')

if [ "$STREAM_STATUS" == "ACTIVE" ]; then
    check_component "Kinesis Stream" "OK"

    # Get stream details
    SHARD_COUNT=$(aws kinesis describe-stream-summary \
        --stream-name "${KINESIS_STREAM}" \
        --region "${REGION}" | jq -r '.StreamDescriptionSummary.OpenShardCount')
    echo -e "   Stream: ${KINESIS_STREAM}"
    echo -e "   Status: ${STREAM_STATUS}"
    echo -e "   Shards: ${SHARD_COUNT}"
else
    check_component "Kinesis Stream" "FAILED (Status: ${STREAM_STATUS})"
fi
echo ""

# 4. Check for data in Kinesis
echo -e "${BLUE}[4/6] Checking for data in Kinesis...${NC}"
SHARD_ITERATOR=$(aws kinesis get-shard-iterator \
    --stream-name "${KINESIS_STREAM}" \
    --shard-id shardId-000000000000 \
    --shard-iterator-type TRIM_HORIZON \
    --region "${REGION}" | jq -r '.ShardIterator')

RECORDS=$(aws kinesis get-records \
    --shard-iterator "$SHARD_ITERATOR" \
    --region "${REGION}" | jq '.Records')

RECORD_COUNT=$(echo "$RECORDS" | jq 'length')

if [ $RECORD_COUNT -gt 0 ]; then
    check_component "Kinesis Data" "OK (${RECORD_COUNT} records found)"

    # Show sample record
    echo ""
    echo -e "   ${YELLOW}Sample record:${NC}"
    echo "$RECORDS" | jq -r '.[0].Data' | base64 -d | jq '.' | head -10
    echo ""
else
    check_component "Kinesis Data" "No records found"
    echo -e "   ${YELLOW}Note: This is normal if you haven't published any data yet${NC}"
fi
echo ""

# 5. Verify Lambda Stream Processor
echo -e "${BLUE}[5/6] Checking Lambda Stream Processor...${NC}"
LAMBDA_NAME="${PROJECT}-${ENVIRONMENT}-stream-processor"
LAMBDA_STATUS=$(aws lambda get-function \
    --function-name "${LAMBDA_NAME}" \
    --region "${REGION}" 2>&1 | jq -r '.Configuration.State // "NOT_FOUND"')

if [ "$LAMBDA_STATUS" == "Active" ]; then
    check_component "Lambda Stream Processor" "OK"

    # Check event source mapping
    MAPPING=$(aws lambda list-event-source-mappings \
        --function-name "${LAMBDA_NAME}" \
        --region "${REGION}" | jq -r '.EventSourceMappings[0]')

    MAPPING_STATE=$(echo "$MAPPING" | jq -r '.State')
    LAST_RESULT=$(echo "$MAPPING" | jq -r '.LastProcessingResult')

    echo -e "   Function: ${LAMBDA_NAME}"
    echo -e "   State: ${MAPPING_STATE}"
    echo -e "   Last Processing Result: ${LAST_RESULT}"

    # Check Lambda logs
    echo -e "   ${YELLOW}Checking recent Lambda logs...${NC}"
    LOGS=$(aws logs tail "/aws/lambda/${LAMBDA_NAME}" \
        --since 1h \
        --format short \
        --region "${REGION}" 2>&1 | tail -5)

    if [ -n "$LOGS" ]; then
        echo "$LOGS" | while read line; do
            echo -e "   ${line}"
        done
    else
        echo -e "   No recent logs found"
    fi
else
    check_component "Lambda Stream Processor" "FAILED (State: ${LAMBDA_STATUS})"
fi
echo ""

# 6. Check DynamoDB Tables
echo -e "${BLUE}[6/6] Checking DynamoDB Tables...${NC}"
TABLES=$(aws dynamodb list-tables --region "${REGION}" | \
    jq -r --arg proj "$PROJECT" --arg env "$ENVIRONMENT" \
    '.TableNames[] | select(contains("\($proj)-\($env)"))')

TABLE_COUNT=$(echo "$TABLES" | wc -l)
if [ $TABLE_COUNT -ge 3 ]; then
    check_component "DynamoDB Tables" "OK (${TABLE_COUNT} tables found)"
    echo "$TABLES" | while read table; do
        ITEM_COUNT=$(aws dynamodb describe-table \
            --table-name "$table" \
            --region "${REGION}" | jq -r '.Table.ItemCount')
        echo -e "   ${GREEN}✓${NC} ${table} (${ITEM_COUNT} items)"
    done
else
    check_component "DynamoDB Tables" "WARNING (expected 5+, found ${TABLE_COUNT})"
fi
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Pipeline Verification Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Provide recommendations
if [ $RECORD_COUNT -eq 0 ]; then
    echo -e "${YELLOW}Recommendations:${NC}"
    echo "1. No data found in Kinesis - publish test data using ./02-publish-test-data.sh"
    echo "2. After publishing, wait 10-30 seconds and run this script again"
    echo ""
fi

if [ "$LAMBDA_STATUS" == "Active" ] && [ "$LAST_RESULT" == "No records processed" ]; then
    echo -e "${YELLOW}Note:${NC}"
    echo "Lambda processor is active but hasn't processed any records yet"
    echo "This is expected if no data has been published"
    echo ""
fi
