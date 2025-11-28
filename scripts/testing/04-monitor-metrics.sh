#!/bin/bash
# EcoVolt IoT Metrics Monitoring Script
# This script displays real-time metrics for the IoT pipeline

set -e

# Configuration
REGION="eu-central-1"
ENVIRONMENT="dev"
PROJECT="ecovolt"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Time range (last 1 hour)
START_TIME=$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u -v-1H +%Y-%m-%dT%H:%M:%S)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%S)

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}EcoVolt IoT Metrics Dashboard${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "Time Range: ${CYAN}${START_TIME}${NC} to ${CYAN}${END_TIME}${NC}"
echo ""

# Function to get CloudWatch metric
get_metric() {
    local namespace=$1
    local metric_name=$2
    local dimensions=$3
    local statistic=${4:-Sum}

    aws cloudwatch get-metric-statistics \
        --namespace "${namespace}" \
        --metric-name "${metric_name}" \
        --dimensions ${dimensions} \
        --start-time "${START_TIME}" \
        --end-time "${END_TIME}" \
        --period 3600 \
        --statistics ${statistic} \
        --region "${REGION}" \
        --output json | jq -r ".Datapoints[0].${statistic} // 0"
}

# 1. IoT Core Metrics
echo -e "${BLUE}═══ IoT Core Metrics ═══${NC}"
echo ""

# Rules executed
for rule in "bike_telemetry" "station_energy" "station_swap"; do
    FULL_RULE_NAME="${PROJECT}_${ENVIRONMENT}_${rule}"
    RULES_EXECUTED=$(get_metric "AWS/IoT" "RulesExecuted" "Name=RuleName,Value=${FULL_RULE_NAME}")
    echo -e "  ${rule}:"
    echo -e "    Rules Executed: ${GREEN}${RULES_EXECUTED}${NC}"
done

# Messages published
MESSAGES_PUBLISHED=$(get_metric "AWS/IoT" "PublishIn.Success" "")
echo -e ""
echo -e "  Total Messages Published: ${GREEN}${MESSAGES_PUBLISHED}${NC}"
echo ""

# 2. Kinesis Stream Metrics
echo -e "${BLUE}═══ Kinesis Stream Metrics ═══${NC}"
echo ""

STREAM_NAME="${PROJECT}-${ENVIRONMENT}-telemetry-stream"

# Incoming records
INCOMING_RECORDS=$(get_metric "AWS/Kinesis" "IncomingRecords" "Name=StreamName,Value=${STREAM_NAME}")
echo -e "  Incoming Records: ${GREEN}${INCOMING_RECORDS}${NC}"

# Incoming bytes
INCOMING_BYTES=$(get_metric "AWS/Kinesis" "IncomingBytes" "Name=StreamName,Value=${STREAM_NAME}")
INCOMING_KB=$(awk "BEGIN {printf \"%.2f\", ${INCOMING_BYTES}/1024}")
echo -e "  Incoming Data: ${GREEN}${INCOMING_KB} KB${NC}"

# Get records success
GET_RECORDS=$(get_metric "AWS/Kinesis" "GetRecords.Success" "Name=StreamName,Value=${STREAM_NAME}")
echo -e "  Records Retrieved: ${GREEN}${GET_RECORDS}${NC}"

# Iterator age
ITERATOR_AGE=$(get_metric "AWS/Kinesis" "GetRecords.IteratorAgeMilliseconds" "Name=StreamName,Value=${STREAM_NAME}" "Maximum")
ITERATOR_AGE_SEC=$(awk "BEGIN {printf \"%.2f\", ${ITERATOR_AGE}/1000}")
echo -e "  Iterator Age: ${GREEN}${ITERATOR_AGE_SEC}s${NC}"
echo ""

# 3. Lambda Metrics
echo -e "${BLUE}═══ Lambda Stream Processor Metrics ═══${NC}"
echo ""

LAMBDA_NAME="${PROJECT}-${ENVIRONMENT}-stream-processor"

# Invocations
INVOCATIONS=$(get_metric "AWS/Lambda" "Invocations" "Name=FunctionName,Value=${LAMBDA_NAME}")
echo -e "  Invocations: ${GREEN}${INVOCATIONS}${NC}"

# Errors
ERRORS=$(get_metric "AWS/Lambda" "Errors" "Name=FunctionName,Value=${LAMBDA_NAME}")
if [ "$ERRORS" == "0" ]; then
    echo -e "  Errors: ${GREEN}${ERRORS}${NC}"
else
    echo -e "  Errors: ${RED}${ERRORS}${NC}"
fi

# Throttles
THROTTLES=$(get_metric "AWS/Lambda" "Throttles" "Name=FunctionName,Value=${LAMBDA_NAME}")
if [ "$THROTTLES" == "0" ]; then
    echo -e "  Throttles: ${GREEN}${THROTTLES}${NC}"
else
    echo -e "  Throttles: ${RED}${THROTTLES}${NC}"
fi

# Duration
DURATION=$(get_metric "AWS/Lambda" "Duration" "Name=FunctionName,Value=${LAMBDA_NAME}" "Average")
echo -e "  Avg Duration: ${GREEN}${DURATION}ms${NC}"

# Concurrent executions
CONCURRENT=$(get_metric "AWS/Lambda" "ConcurrentExecutions" "Name=FunctionName,Value=${LAMBDA_NAME}" "Maximum")
echo -e "  Concurrent Executions: ${GREEN}${CONCURRENT}${NC}"
echo ""

# 4. DynamoDB Metrics (sample from bike-status table)
echo -e "${BLUE}═══ DynamoDB Metrics (Sample) ═══${NC}"
echo ""

TABLE_NAME="${PROJECT}-${ENVIRONMENT}-bike-status"

# Item count (from describe-table, not CloudWatch)
ITEM_COUNT=$(aws dynamodb describe-table \
    --table-name "${TABLE_NAME}" \
    --region "${REGION}" | jq -r '.Table.ItemCount')
echo -e "  ${TABLE_NAME}:"
echo -e "    Item Count: ${GREEN}${ITEM_COUNT}${NC}"

# User errors
USER_ERRORS=$(get_metric "AWS/DynamoDB" "UserErrors" "Name=TableName,Value=${TABLE_NAME}")
if [ "$USER_ERRORS" == "0" ]; then
    echo -e "    User Errors: ${GREEN}${USER_ERRORS}${NC}"
else
    echo -e "    User Errors: ${RED}${USER_ERRORS}${NC}"
fi

# System errors
SYSTEM_ERRORS=$(get_metric "AWS/DynamoDB" "SystemErrors" "Name=TableName,Value=${TABLE_NAME}")
if [ "$SYSTEM_ERRORS" == "0" ]; then
    echo -e "    System Errors: ${GREEN}${SYSTEM_ERRORS}${NC}"
else
    echo -e "    System Errors: ${RED}${SYSTEM_ERRORS}${NC}"
fi
echo ""

# 5. Recent Lambda Logs
echo -e "${BLUE}═══ Recent Lambda Logs (Last 10 lines) ═══${NC}"
echo ""
aws logs tail "/aws/lambda/${LAMBDA_NAME}" \
    --since 1h \
    --format short \
    --region "${REGION}" 2>&1 | tail -10 || echo -e "${YELLOW}No recent logs found${NC}"
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Metrics Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Calculate success rate
if [ "$INVOCATIONS" != "0" ]; then
    SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", (${INVOCATIONS} - ${ERRORS}) / ${INVOCATIONS} * 100}")
    echo -e "Lambda Success Rate: ${GREEN}${SUCCESS_RATE}%${NC}"
else
    echo -e "Lambda Success Rate: ${YELLOW}N/A (no invocations)${NC}"
fi

# Data flow rate
if [ "$INCOMING_RECORDS" != "0" ]; then
    FLOW_RATE=$(awk "BEGIN {printf \"%.2f\", ${INCOMING_RECORDS} / 60}")
    echo -e "Avg Data Flow Rate: ${GREEN}${FLOW_RATE} records/min${NC}"
else
    echo -e "Avg Data Flow Rate: ${YELLOW}0 records/min${NC}"
fi

echo ""
echo -e "${CYAN}Tip: Run this script periodically to monitor your IoT pipeline${NC}"
echo ""
