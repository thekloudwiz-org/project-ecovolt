# EcoVolt System Verification - Quick Start Guide

## 🚀 Running the Full System Test

### Prerequisites
```bash
pip3 install boto3
```

### Execute Verification
```bash
cd scripts/testing
python3 full_system_verification.py
```

### What It Does

1. **Injects** unique test payload via IoT Core (device_id: TEST-xxx, voltage: 450V)
2. **Polls DynamoDB** for 30 seconds to find the test record
3. **Queries Timestream** for historical data
4. **Verifies S3** bucket accessibility (Firehose data arrives in 60s)
5. **Checks Kinesis** stream for data flow

### Expected Result

```
✓ SYSTEM VERIFICATION SUCCESSFUL
Tests Passed: 5/5
Pass Rate: 100.0%
```

---

## 📸 Portfolio Screenshots Checklist

After running the verification, capture these screenshots:

### Critical Evidence (Must Have)

- [ ] **01-kinesis-pulse.png** - Kinesis monitoring showing data flow
- [ ] **02-dynamodb-state.png** - DynamoDB item with TEST device (voltage: 450V)
- [ ] **04-s3-data-lake.png** - S3 folder structure (bronze/telemetry/year/month/day/hour/)
- [ ] **06-lambda-fanout.png** - Lambda metrics showing invocations

### Supporting Evidence (Nice to Have)

- [ ] **03-timestream-history.png** - Timestream query results
- [ ] **05a-lambda-rds-connection.png** - CloudWatch logs showing RDS connection
- [ ] **07-api-gateway-metrics.png** - API Gateway dashboard
- [ ] **10-cloudwatch-dashboard.png** - Complete system overview

---

## 📋 Navigation Paths

### Kinesis Monitoring
```
AWS Console → Kinesis → Data streams → ecovolt-dev-telemetry-stream → Monitoring
```

### DynamoDB Item
```
AWS Console → DynamoDB → Tables → ecovolt-dev-bike-status → Explore items
Filter: device_id = TEST-<timestamp>
```

### S3 Data Lake
```
AWS Console → S3 → ecovolt-dev-data-lake → bronze/telemetry/year=2025/
```

### Lambda Metrics
```
AWS Console → Lambda → ecovolt-dev-stream-processor → Monitor
```

---

## 🔍 Troubleshooting

### Data Not in DynamoDB?

```bash
# Check Lambda logs
aws logs tail /aws/lambda/ecovolt-dev-stream-processor --follow --region eu-central-1

# Check IoT Rules
aws iot list-topic-rules --region eu-central-1

# Check event source mapping
aws lambda list-event-source-mappings \
  --function-name ecovolt-dev-stream-processor \
  --region eu-central-1
```

### S3 Data Not Appearing?

**Wait 60-90 seconds** - Firehose buffers data before writing to S3.

Check manually:
```bash
aws s3 ls s3://ecovolt-dev-data-lake/bronze/telemetry/ --recursive --human-readable
```

---

## 📚 Full Documentation

See **PROJECT_MASTER_REPORT.md** for:
- Complete architecture diagrams
- Engineering decisions & trade-offs
- Cost analysis
- Security posture
- Performance benchmarks
- Blog-ready technical content

---

## ✅ Success Criteria

Your system is working correctly if:

1. ✅ Test data appears in DynamoDB within 5 seconds
2. ✅ Lambda shows successful invocations (no errors)
3. ✅ S3 shows .gz files in partitioned folders (after 60s)
4. ✅ Kinesis shows incoming data metrics
5. ✅ CloudWatch shows no critical alarms

---

**Next Step:** Run the verification script and capture screenshots!
