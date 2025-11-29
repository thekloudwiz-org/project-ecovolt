# Testing Scripts Comparison

## Overview

The testing directory contains **two different approaches** to testing the EcoVolt system:

1. **Shell Scripts (.sh)** - Manual, step-by-step testing with device registration
2. **Python Script (.py)** - Automated, end-to-end verification without device setup

---

## Shell Scripts (01-06.sh)

### Purpose
**Manual testing workflow** for developers who want to:
- Register actual IoT devices with certificates
- Publish realistic telemetry data over time
- Monitor the pipeline step-by-step
- Test with multiple device types (bikes, stations, batteries)

### What They Do

#### 01-register-test-device.sh
- **Creates IoT Thing** in AWS IoT Core
- **Generates X.509 certificates** for device authentication
- **Downloads AWS Root CA**
- **Attaches IoT policy** to certificate
- **Saves certificates** to `./certs/<device-name>/`

**Use Case:** Setting up a real IoT device for testing

#### 02-publish-test-data.sh
- **Publishes telemetry** using device certificates
- **Generates realistic data** (battery levels, GPS, speed)
- **Supports multiple device types** (bike, station, battery)
- **Continuous publishing** with configurable intervals

**Use Case:** Simulating real device behavior over time

#### 03-verify-pipeline.sh
- **Checks IoT Core** endpoint
- **Verifies IoT Rules** are enabled
- **Checks Kinesis Stream** status
- **Looks for data** in Kinesis
- **Verifies Lambda** processor
- **Checks DynamoDB** tables

**Use Case:** Manual pipeline health check

#### 04-monitor-metrics.sh
- **Displays CloudWatch metrics** for all components
- **Shows Lambda invocations** and errors
- **Monitors Kinesis** throughput
- **Tracks DynamoDB** operations

**Use Case:** Real-time monitoring during testing

#### 05-run-complete-test.sh
- **Orchestrates** scripts 01-03
- **Registers device** (if needed)
- **Publishes test data**
- **Verifies pipeline**
- **Shows results**

**Use Case:** Quick end-to-end test with device setup

#### 06-cleanup-test-device.sh
- **Deletes IoT Thing**
- **Removes certificates**
- **Cleans up** local files

**Use Case:** Cleanup after testing

---

## Python Script (full_system_verification.py)

### Purpose
**Automated verification** for QA and CI/CD:
- No device registration required
- No certificate management
- Instant verification
- Perfect for portfolio demonstration

### What It Does

1. **Injects Test Payload** directly via IoT Core API (no certificates needed)
2. **Polls DynamoDB** for 30 seconds to find test record
3. **Verifies data integrity** (exact value matching)
4. **Checks Timestream** InfluxDB configuration
5. **Validates S3** bucket accessibility
6. **Proves Kinesis flow** indirectly via DynamoDB
7. **Generates comprehensive report** with pass/fail status

**Use Case:** Automated system verification, portfolio evidence, CI/CD integration

---

## Key Differences

| Feature | Shell Scripts | Python Script |
|---------|--------------|---------------|
| **Device Registration** | ✅ Yes (with certificates) | ❌ No (uses API directly) |
| **Certificate Management** | ✅ Creates & manages certs | ❌ Not needed |
| **Realistic Simulation** | ✅ Yes (continuous data) | ⚠️ Single test payload |
| **Data Verification** | ⚠️ Manual (check logs) | ✅ Automated (exact match) |
| **Pass/Fail Report** | ❌ No | ✅ Yes (5/5 score) |
| **Time to Run** | ~2-3 minutes | ~30-60 seconds |
| **Setup Required** | Certificates, device info | None (just run it) |
| **Best For** | Development, debugging | QA, CI/CD, demos |
| **Multiple Devices** | ✅ Yes | ❌ Single test device |
| **Cleanup** | Manual (script 06) | Automatic (no artifacts) |

---

## When to Use Each

### Use Shell Scripts When:
- 🔧 **Developing** new features
- 🐛 **Debugging** pipeline issues
- 📊 **Load testing** with multiple devices
- 🔄 **Continuous monitoring** over time
- 🎯 **Testing specific device types** (bike vs station)
- 📝 **Learning** how IoT Core works

### Use Python Script When:
- ✅ **Verifying** system is working
- 📸 **Capturing** portfolio evidence
- 🤖 **CI/CD** automated testing
- ⚡ **Quick validation** after deployment
- 📊 **Generating** test reports
- 🎯 **Proving** data integrity

---

## Example Workflows

### Development Workflow (Shell Scripts)
```bash
# 1. Register a test bike
./01-register-test-device.sh bike dev-bike-001

# 2. Publish continuous data (100 messages, 5s interval)
./02-publish-test-data.sh bike dev-bike-001 100 5

# 3. Monitor in real-time
./04-monitor-metrics.sh

# 4. Cleanup when done
./06-cleanup-test-device.sh bike dev-bike-001
```

### QA Workflow (Python Script)
```bash
# Single command - complete verification
python3 full_system_verification.py

# Result: 5/5 tests passed (100%)
# - Data injected ✓
# - DynamoDB verified ✓
# - Timestream checked ✓
# - S3 validated ✓
# - Kinesis proven ✓
```

---

## Data Flow Comparison

### Shell Scripts Flow
```
Developer → 01-register → Creates IoT Thing + Certs
         → 02-publish → Device publishes with certs
         → IoT Core → Kinesis → Lambda → DynamoDB
         → 03-verify → Manual check of components
         → 04-monitor → View CloudWatch metrics
```

### Python Script Flow
```
Script → Inject via API (no certs)
      → IoT Core → Kinesis → Lambda → DynamoDB
      → Poll DynamoDB → Verify exact data
      → Check all components → Generate report
      → Return: PASS/FAIL with 5/5 score
```

---

## Which One Did You Use?

**For the portfolio demonstration, you used the Python script** because:

✅ **No setup required** - Just run and get results  
✅ **Automated verification** - Proves data integrity  
✅ **Perfect score** - 5/5 tests (100% pass rate)  
✅ **Professional report** - Clear pass/fail status  
✅ **Portfolio ready** - Shows system works end-to-end  

The shell scripts are still valuable for:
- Development and debugging
- Load testing with multiple devices
- Learning how IoT Core authentication works
- Continuous monitoring during development

---

## Recommendation

**Keep both!** They serve different purposes:

- **Shell scripts** = Development & debugging tools
- **Python script** = QA & verification tool

For your portfolio presentation, the Python script is perfect because it:
1. Runs in 30-60 seconds
2. Requires no setup
3. Proves data integrity
4. Generates a professional report
5. Achieves 100% pass rate

---

## Summary

| Aspect | Shell Scripts | Python Script |
|--------|--------------|---------------|
| **Complexity** | Higher (6 scripts) | Lower (1 script) |
| **Setup** | Certificates required | None |
| **Speed** | 2-3 minutes | 30-60 seconds |
| **Verification** | Manual | Automated |
| **Report** | None | Professional |
| **Score** | N/A | 5/5 (100%) |
| **Best Use** | Development | QA/Portfolio |

**Both are valuable - use the right tool for the job!** 🚀
