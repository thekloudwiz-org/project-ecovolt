#!/bin/bash
# Generate Sample GuardDuty Findings for Testing
# This uses AWS's official sample finding generation feature

set -e

# Configuration
REGION="eu-central-1"
ENVIRONMENT="dev"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}GuardDuty Sample Findings Generator${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Step 1: Check if GuardDuty is enabled
echo -e "${BLUE}Step 1: Checking GuardDuty status...${NC}"

DETECTOR_ID=$(aws guardduty list-detectors \
    --region "${REGION}" \
    --query 'DetectorIds[0]' \
    --output text)

if [ "$DETECTOR_ID" == "None" ] || [ -z "$DETECTOR_ID" ]; then
    echo -e "${RED}✗ GuardDuty is not enabled in ${REGION}${NC}"
    echo -e "${YELLOW}To enable GuardDuty:${NC}"
    echo -e "  aws guardduty create-detector --enable --region ${REGION}"
    exit 1
fi

echo -e "${GREEN}✓ GuardDuty is enabled${NC}"
echo -e "  Detector ID: ${DETECTOR_ID}"
echo ""

# Step 2: Generate sample findings
echo -e "${BLUE}Step 2: Generating sample findings...${NC}"
echo ""

# Generate ALL sample finding types (AWS will create one of each type)
echo -e "${YELLOW}Generating sample findings (all types)...${NC}"
echo ""

aws guardduty create-sample-findings \
    --detector-id "${DETECTOR_ID}" \
    --region "${REGION}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Sample findings generated successfully${NC}"
else
    echo -e "${RED}✗ Failed to generate sample findings${NC}"
    exit 1
fi

echo ""

# Step 3: Wait for findings to appear
echo -e "${BLUE}Step 3: Waiting for findings to appear (10 seconds)...${NC}"
sleep 10

# Step 4: List findings
echo -e "${BLUE}Step 4: Retrieving findings...${NC}"
echo ""

FINDING_IDS=$(aws guardduty list-findings \
    --detector-id "${DETECTOR_ID}" \
    --region "${REGION}" \
    --query 'FindingIds' \
    --output json)

FINDING_COUNT=$(echo "$FINDING_IDS" | jq '. | length')

echo -e "${GREEN}✓ Found ${FINDING_COUNT} findings${NC}"
echo ""

# Step 5: Get detailed findings
if [ "$FINDING_COUNT" -gt 0 ]; then
    echo -e "${BLUE}Step 5: Displaying finding details...${NC}"
    echo ""
    
    # Get first 5 findings
    FIRST_FIVE=$(echo "$FINDING_IDS" | jq -r '.[0:5] | .[]')
    
    for FINDING_ID in $FIRST_FIVE; do
        echo -e "${CYAN}─────────────────────────────────────────${NC}"
        
        FINDING_DETAILS=$(aws guardduty get-findings \
            --detector-id "${DETECTOR_ID}" \
            --finding-ids "$FINDING_ID" \
            --region "${REGION}" \
            --output json)
        
        # Extract key information
        TITLE=$(echo "$FINDING_DETAILS" | jq -r '.Findings[0].Title')
        SEVERITY=$(echo "$FINDING_DETAILS" | jq -r '.Findings[0].Severity')
        TYPE=$(echo "$FINDING_DETAILS" | jq -r '.Findings[0].Type')
        DESCRIPTION=$(echo "$FINDING_DETAILS" | jq -r '.Findings[0].Description')
        
        # Color code severity
        if [ "$SEVERITY" == "8" ] || [ "$SEVERITY" == "7" ]; then
            SEVERITY_COLOR="${RED}"
            SEVERITY_TEXT="HIGH"
        elif [ "$SEVERITY" == "5" ] || [ "$SEVERITY" == "4" ]; then
            SEVERITY_COLOR="${YELLOW}"
            SEVERITY_TEXT="MEDIUM"
        else
            SEVERITY_COLOR="${GREEN}"
            SEVERITY_TEXT="LOW"
        fi
        
        echo -e "${SEVERITY_COLOR}Severity: ${SEVERITY_TEXT} (${SEVERITY})${NC}"
        echo -e "${BLUE}Type: ${TYPE}${NC}"
        echo -e "${CYAN}Title: ${TITLE}${NC}"
        echo -e "Description: ${DESCRIPTION}"
        echo ""
    done
    
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
fi

# Step 6: Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Detector ID: ${DETECTOR_ID}"
echo -e "Total Findings: ${FINDING_COUNT}"
echo -e "Region: ${REGION}"
echo ""

# Step 7: AWS Console link
echo -e "${BLUE}View in AWS Console:${NC}"
echo -e "https://console.aws.amazon.com/guardduty/home?region=${REGION}#/findings"
echo ""

# Step 8: Cleanup instructions
echo -e "${YELLOW}Note: These are SAMPLE findings for testing purposes.${NC}"
echo -e "${YELLOW}They will automatically expire after 7 days.${NC}"
echo ""
echo -e "${CYAN}To archive these findings:${NC}"
echo -e "  aws guardduty archive-findings \\"
echo -e "    --detector-id ${DETECTOR_ID} \\"
echo -e "    --finding-ids <finding-id> \\"
echo -e "    --region ${REGION}"
echo ""

# Step 9: Export findings to JSON
OUTPUT_FILE="guardduty-findings-$(date +%Y%m%d-%H%M%S).json"
echo -e "${BLUE}Exporting findings to ${OUTPUT_FILE}...${NC}"

aws guardduty get-findings \
    --detector-id "${DETECTOR_ID}" \
    --finding-ids $(echo "$FINDING_IDS" | jq -r '.[]') \
    --region "${REGION}" \
    --output json > "$OUTPUT_FILE"

echo -e "${GREEN}✓ Findings exported to ${OUTPUT_FILE}${NC}"
echo ""

echo -e "${GREEN}Done!${NC}"
