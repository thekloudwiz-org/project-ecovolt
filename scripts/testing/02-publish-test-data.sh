#!/bin/bash
# EcoVolt IoT Data Publishing Script
# This script publishes test telemetry data to AWS IoT Core

set -e

# Configuration
REGION="eu-central-1"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
DEVICE_TYPE=${1:-bike}
DEVICE_ID=${2:-test-001}
NUM_MESSAGES=${3:-10}
INTERVAL=${4:-2}  # seconds between messages

DEVICE_NAME="${DEVICE_TYPE}-${DEVICE_ID}"
CERTS_DIR="./certs/${DEVICE_NAME}"

# Check if device is registered
if [ ! -f "${CERTS_DIR}/device-info.json" ]; then
    echo -e "${RED}Error: Device ${DEVICE_NAME} not registered${NC}"
    echo "Run ./01-register-test-device.sh first"
    exit 1
fi

# Load device info
DEVICE_INFO=$(cat "${CERTS_DIR}/device-info.json")
MQTT_TOPIC=$(echo "$DEVICE_INFO" | jq -r '.mqttTopic')

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}EcoVolt IoT Data Publisher${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo -e "Device:       ${GREEN}${DEVICE_NAME}${NC}"
echo -e "Topic:        ${GREEN}${MQTT_TOPIC}${NC}"
echo -e "Messages:     ${GREEN}${NUM_MESSAGES}${NC}"
echo -e "Interval:     ${GREEN}${INTERVAL}s${NC}"
echo ""

# Function to generate bike telemetry
generate_bike_telemetry() {
    local bike_id=$1
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local battery_level=$((RANDOM % 80 + 20))  # 20-100%
    local voltage=$(awk "BEGIN {print 48.0 + (RANDOM / 32767.0) * 6}")  # 48-54V
    local current=$(awk "BEGIN {print 5.0 + (RANDOM / 32767.0) * 15}")  # 5-20A
    local temp=$((RANDOM % 15 + 20))  # 20-35°C
    local speed=$(awk "BEGIN {print (RANDOM / 32767.0) * 40}")  # 0-40 km/h
    local lat=$(awk "BEGIN {print 5.6037 + (RANDOM / 32767.0) * 0.1 - 0.05}")
    local lon=$(awk "BEGIN {print -0.1870 + (RANDOM / 32767.0) * 0.1 - 0.05}")

    cat <<EOF
{
  "bikeId": "${bike_id}",
  "battery": {
    "stateOfCharge": ${battery_level},
    "voltage": ${voltage},
    "current": ${current},
    "temperature": ${temp}
  },
  "location": {
    "latitude": ${lat},
    "longitude": ${lon}
  },
  "speed": ${speed},
  "odometer": $((RANDOM % 10000)),
  "timestamp": "${timestamp}"
}
EOF
}

# Function to generate station energy telemetry
generate_station_telemetry() {
    local station_id=$1
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local solar_power=$(awk "BEGIN {print (RANDOM / 32767.0) * 50}")  # 0-50 kW
    local grid_power=$(awk "BEGIN {print (RANDOM / 32767.0) * 30}")   # 0-30 kW
    local battery_count=$((RANDOM % 20 + 5))  # 5-25 batteries

    cat <<EOF
{
  "stationId": "${station_id}",
  "solar": {
    "powerGenerated": ${solar_power},
    "panelEfficiency": $((RANDOM % 20 + 80))
  },
  "grid": {
    "powerConsumed": ${grid_power},
    "frequency": 50
  },
  "inventory": {
    "totalBatteries": ${battery_count},
    "availableBatteries": $((battery_count - RANDOM % 5))
  },
  "timestamp": "${timestamp}"
}
EOF
}

# Function to generate battery telemetry
generate_battery_telemetry() {
    local battery_id=$1
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local soc=$((RANDOM % 100))
    local voltage=$(awk "BEGIN {print 48.0 + (RANDOM / 32767.0) * 6}")
    local temp=$((RANDOM % 15 + 20))
    local health=$((RANDOM % 20 + 80))

    cat <<EOF
{
  "batteryId": "${battery_id}",
  "stateOfCharge": ${soc},
  "voltage": ${voltage},
  "temperature": ${temp},
  "health": ${health},
  "cycleCount": $((RANDOM % 500)),
  "status": "charging",
  "timestamp": "${timestamp}"
}
EOF
}

# Publish messages
echo -e "${BLUE}Publishing ${NUM_MESSAGES} messages...${NC}"
echo ""

for i in $(seq 1 $NUM_MESSAGES); do
    # Generate appropriate telemetry based on device type
    case $DEVICE_TYPE in
        bike)
            PAYLOAD=$(generate_bike_telemetry "$DEVICE_NAME")
            ;;
        station)
            PAYLOAD=$(generate_station_telemetry "$DEVICE_NAME")
            ;;
        battery)
            PAYLOAD=$(generate_battery_telemetry "$DEVICE_NAME")
            ;;
        *)
            echo -e "${RED}Unknown device type: ${DEVICE_TYPE}${NC}"
            exit 1
            ;;
    esac

    # Publish to IoT Core
    aws iot-data publish \
        --topic "${MQTT_TOPIC}" \
        --payload "${PAYLOAD}" \
        --region "${REGION}" \
        --cli-binary-format raw-in-base64-out

    echo -e "${GREEN}[${i}/${NUM_MESSAGES}]${NC} Published message at $(date +%H:%M:%S)"

    if [ $i -lt $NUM_MESSAGES ]; then
        sleep $INTERVAL
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Published ${NUM_MESSAGES} messages!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Wait 10-30 seconds for messages to propagate"
echo "2. Run ./03-verify-pipeline.sh to check data flow"
echo "3. Run ./04-monitor-metrics.sh to view metrics"
echo ""
