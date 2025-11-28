# EcoVolt IoT Infrastructure Testing Scripts

This directory contains automated testing scripts for validating the EcoVolt IoT infrastructure, including device registration, data publishing, pipeline verification, and metrics monitoring.

## 📋 Overview

The testing suite validates the complete data flow:

```
IoT Device → IoT Core → IoT Rules → Kinesis Stream → Lambda Processor → DynamoDB
```

## 🚀 Quick Start

### Run Complete Test (Recommended)

```bash
cd scripts/testing

# Make scripts executable
chmod +x *.sh

# Run complete end-to-end test
./05-run-complete-test.sh bike test-001 10
```

This will:
1. Register a test bike device
2. Verify pipeline components
3. Publish 10 test messages
4. Verify data flow through the pipeline

### Individual Scripts

Each script can also be run individually for specific testing needs.

## 📚 Script Documentation

### 1. Register Test Device
**Script:** `01-register-test-device.sh`

Registers a test IoT device (bike, station, or battery) with AWS IoT Core.

**Usage:**
```bash
./01-register-test-device.sh <device-type> <device-id>
```

**Examples:**
```bash
# Register a test bike
./01-register-test-device.sh bike test-001

# Register a test station
./01-register-test-device.sh station test-station-01

# Register a test battery
./01-register-test-device.sh battery test-battery-01
```

**What it does:**
- Creates an IoT Thing with specified type
- Generates X.509 certificates for authentication
- Downloads AWS IoT Root CA
- Attaches IoT policy to certificate
- Attaches certificate to thing
- Saves device info and certificates to `./certs/<device-name>/`

**Output:**
- `./certs/<device-name>/certificate.pem` - Device certificate
- `./certs/<device-name>/private.key` - Private key
- `./certs/<device-name>/public.key` - Public key
- `./certs/<device-name>/AmazonRootCA1.pem` - AWS Root CA
- `./certs/<device-name>/device-info.json` - Device metadata

---

### 2. Publish Test Data
**Script:** `02-publish-test-data.sh`

Publishes test telemetry data to AWS IoT Core.

**Usage:**
```bash
./02-publish-test-data.sh <device-type> <device-id> <num-messages> <interval>
```

**Examples:**
```bash
# Publish 10 messages with 2 second interval
./02-publish-test-data.sh bike test-001 10 2

# Publish 100 messages rapidly (1 second interval)
./02-publish-test-data.sh bike test-001 100 1

# Publish station energy data
./02-publish-test-data.sh station test-station-01 20 3
```

**Telemetry Data:**

**Bike:**
- Battery state of charge, voltage, current, temperature
- GPS location (Accra area)
- Speed, odometer
- Timestamp

**Station:**
- Solar power generation
- Grid power consumption
- Battery inventory count
- Panel efficiency

**Battery:**
- State of charge, voltage, temperature
- Battery health percentage
- Charge cycle count
- Status (charging/available)

---

### 3. Verify Pipeline
**Script:** `03-verify-pipeline.sh`

Verifies the end-to-end IoT pipeline and data flow.

**Usage:**
```bash
./03-verify-pipeline.sh
```

**What it checks:**
1. ✓ IoT Core endpoint accessibility
2. ✓ IoT Rules status (3 rules: bike, station, swap)
3. ✓ Kinesis Stream status and shard count
4. ✓ Data presence in Kinesis
5. ✓ Lambda Stream Processor status
6. ✓ DynamoDB tables and item counts

**Output:**
- Component status (✓ or ✗)
- Sample data from Kinesis
- Lambda processing status
- Recommendations if issues found

---

### 4. Monitor Metrics
**Script:** `04-monitor-metrics.sh`

Displays CloudWatch metrics for the IoT pipeline.

**Usage:**
```bash
./04-monitor-metrics.sh
```

**Metrics displayed:**

**IoT Core:**
- Rules executed per rule
- Total messages published

**Kinesis Stream:**
- Incoming records
- Incoming data size
- Records retrieved
- Iterator age

**Lambda:**
- Invocations
- Errors and throttles
- Average duration
- Concurrent executions

**DynamoDB:**
- Item counts per table
- User errors
- System errors

**Additional:**
- Recent Lambda logs (last 10 lines)
- Success rate calculation
- Data flow rate

---

### 5. Run Complete Test
**Script:** `05-run-complete-test.sh`

Runs a complete end-to-end test of the IoT infrastructure.

**Usage:**
```bash
./05-run-complete-test.sh <device-type> <device-id> <num-messages>
```

**Example:**
```bash
./05-run-complete-test.sh bike test-001 5
```

**Test flow:**
1. Register device (if not exists)
2. Verify pipeline before test
3. Publish test messages
4. Wait 15 seconds for propagation
5. Verify data flow
6. Display results and sample data

---

### 6. Cleanup Test Device
**Script:** `06-cleanup-test-device.sh`

Removes a test device and all associated resources.

**Usage:**
```bash
./06-cleanup-test-device.sh <device-type> <device-id>
```

**Example:**
```bash
./06-cleanup-test-device.sh bike test-001
```

**What it does:**
1. Detaches certificate from thing
2. Detaches policies from certificate
3. Deactivates certificate
4. Deletes certificate
5. Deletes IoT thing
6. Removes local certificate files

⚠️ **Warning:** This action cannot be undone. Confirm before proceeding.

---

## 🧪 Common Testing Scenarios

### Scenario 1: Load Testing
Test with high message volume:

```bash
# Register device
./01-register-test-device.sh bike load-test-001

# Publish 1000 messages rapidly
./02-publish-test-data.sh bike load-test-001 1000 0.5

# Monitor metrics
./04-monitor-metrics.sh
```

### Scenario 2: Multiple Device Types
Test all device types simultaneously:

```bash
# Register devices
./01-register-test-device.sh bike multi-test-001
./01-register-test-device.sh station multi-test-001
./01-register-test-device.sh battery multi-test-001

# Publish from all devices
./02-publish-test-data.sh bike multi-test-001 20 2 &
./02-publish-test-data.sh station multi-test-001 20 2 &
./02-publish-test-data.sh battery multi-test-001 20 2 &
wait

# Verify
./03-verify-pipeline.sh
```

### Scenario 3: Continuous Monitoring
Monitor pipeline continuously:

```bash
# Publish data in background
./02-publish-test-data.sh bike monitor-001 1000 5 &

# Monitor in real-time (refresh every 30 seconds)
watch -n 30 ./04-monitor-metrics.sh
```

---

## 📊 Understanding the Results

### Success Indicators
- ✅ All components show "OK" status
- ✅ Records appear in Kinesis within 30 seconds
- ✅ Lambda invocations match message count
- ✅ No errors in Lambda logs
- ✅ Data appears in DynamoDB

### Common Issues

**No records in Kinesis:**
- Check IoT Rules are enabled
- Verify MQTT topic pattern matches
- Check IAM role permissions

**Lambda not processing:**
- Check Lambda environment variables (TIMESTREAM_* may be missing)
- Verify event source mapping is enabled
- Check Lambda execution role permissions

**High Iterator Age:**
- Lambda may be falling behind
- Consider increasing Lambda concurrency
- Check for Lambda errors

---

## 🔍 Troubleshooting

### View IoT Core Logs
```bash
aws logs tail AWSIotLogsV2 --since 30m --format short --region eu-central-1
```

### View Lambda Logs
```bash
aws logs tail /aws/lambda/ecovolt-dev-stream-processor --follow --region eu-central-1
```

### Manually Check Kinesis
```bash
# Get shard iterator
SHARD_IT=$(aws kinesis get-shard-iterator \
  --stream-name ecovolt-dev-telemetry-stream \
  --shard-id shardId-000000000000 \
  --shard-iterator-type LATEST \
  --region eu-central-1 | jq -r '.ShardIterator')

# Get records
aws kinesis get-records --shard-iterator "$SHARD_IT" --region eu-central-1 | jq '.Records'
```

### Check Lambda Event Source Mapping
```bash
aws lambda list-event-source-mappings \
  --function-name ecovolt-dev-stream-processor \
  --region eu-central-1
```

---

## 🛠️ Configuration

All scripts use these default values:

- **Region:** `eu-central-1`
- **Environment:** `dev`
- **Project:** `ecovolt`
- **Kinesis Stream:** `ecovolt-dev-telemetry-stream`
- **Lambda:** `ecovolt-dev-stream-processor`

To modify for different environments, edit the configuration section at the top of each script.

---

## 📝 Important Notes

### Lambda Stream Processor Limitation
⚠️ The current Lambda stream processor attempts to write to **AWS Timestream**, which is not accessible (AWS is not accepting new users for Timestream LiveAnalytics).

**Current State:**
- Messages reach IoT Core ✓
- IoT Rules route to Kinesis ✓
- Lambda is triggered ✓
- Lambda fails when writing to Timestream ✗

**Options:**
1. **Modify Lambda** to write to DynamoDB instead (recommended for testing)
2. **Set up Timestream for InfluxDB** as recommended by AWS
3. **Disable Lambda** to test IoT → Kinesis flow only

See the main documentation for instructions on modifying the Lambda function.

---

## 🎯 Next Steps

After running tests:

1. **Monitor Continuously:** Use `04-monitor-metrics.sh` to track metrics
2. **Check Lambda Logs:** Verify Lambda processing
3. **Modify Lambda:** Update to write to DynamoDB instead of Timestream
4. **Scale Testing:** Increase message volume to test performance
5. **Clean Up:** Remove test devices with `06-cleanup-test-device.sh`

---

## 📞 Support

For issues or questions:
- Check CloudWatch Logs for detailed error messages
- Review IoT Core test client for MQTT debugging
- Check AWS IoT Core documentation
- Review the main project documentation

---

**Happy Testing! 🚀**
