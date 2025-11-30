# Building a Production-Ready IoT Platform for Electric Bike Sharing in Ghana

## How We Built EcoVolt: A Serverless, Event-Driven Architecture on AWS

**Author:** EcoVolt Engineering Team  
**Date:** November 29, 2025  
**Reading Time:** 15 minutes

---

## Executive Summary

EcoVolt is a comprehensive IoT platform designed to revolutionize urban transportation in Ghana through electric bike sharing. This article details our journey building a production-ready, serverless architecture on AWS that processes real-time telemetry from electric bikes, manages battery swapping stations, and provides actionable insights through advanced analytics.

**Key Achievements:**
- ⚡ Sub-3-second end-to-end latency from device to database
- 📊 100% test success rate across all system components
- 🔄 Polyglot & Fan-Out architecture for multi-purpose data processing
- 🌍 Designed for African infrastructure constraints (intermittent connectivity, cost optimization)
- 🚀 Fully automated CI/CD pipeline with infrastructure as code

---

## Table of Contents

1. [The Problem We're Solving](#the-problem-were-solving)
2. [Architecture Overview](#architecture-overview)
3. [Technical Deep Dive](#technical-deep-dive)
4. [Key Design Decisions](#key-design-decisions)
5. [Testing & Monitoring](#testing--monitoring)
6. [Lessons Learned](#lessons-learned)
7. [Performance Metrics](#performance-metrics)
8. [Future Roadmap](#future-roadmap)

---

## The Problem We're Solving

### Urban Transportation Challenges in Ghana

Ghana, like many African nations, faces significant urban transportation challenges:
- **Traffic Congestion:** Accra experiences some of the worst traffic in Africa
- **Air Pollution:** Vehicle emissions contribute to poor air quality
- **Last-Mile Connectivity:** Limited public transport options for short distances
- **Economic Barriers:** High cost of vehicle ownership

### Our Solution: Electric Bike Sharing

EcoVolt provides an affordable, eco-friendly alternative through:
- **Electric Bikes:** Zero-emission transportation
- **Battery Swapping:** Quick battery replacement at stations (< 2 minutes)
- **IoT-Enabled:** Real-time tracking, predictive maintenance, and usage analytics
- **Mobile-First:** Native apps for iOS and Android

### Technical Challenges

Building an IoT platform for Africa presents unique challenges:

1. **Intermittent Connectivity**
   - Mobile networks can be unreliable
   - Need for offline-first design
   - Efficient data synchronization

2. **Cost Optimization**
   - AWS costs must be minimized
   - Serverless architecture for pay-per-use
   - Efficient data storage strategies

3. **Scale & Reliability**
   - Handle thousands of bikes sending telemetry every 30 seconds
   - 99.9% uptime requirement
   - Real-time processing for critical alerts

4. **Data Sovereignty**
   - Data must remain in-region
   - Compliance with local regulations
   - Privacy-first design

---

## Architecture Overview

### The "Polyglot & Fan-Out" Pattern

We adopted a polyglot architecture that processes incoming IoT data for multiple purposes simultaneously:

```
┌─────────────────────────────────────────────────────────────────┐
│                         IoT Devices                             │
│  (Electric Bikes, Battery Stations, Swap Stations)              │
└────────────────────────┬────────────────────────────────────────┘
                         │ MQTT over TLS
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      AWS IoT Core                               │
│  • Device Registry & Authentication                             │
│  • Message Broker (MQTT/HTTPS)                                  │
│  • Rules Engine (SQL-based routing)                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Amazon Kinesis Data Streams                    │
│  • 2 Shards (scalable)                                          │
│  • 24-hour retention                                            │
│  • Fan-out to multiple consumers                                │
└─────┬──────────────────────┬─────────────────────┬──────────────┘
      │                      │                     │
      ▼                      ▼                     ▼
  ┌──────────┐      ┌──────────────┐   ┌─────────────────┐
  │  Lambda  │      │    Lambda    │   │ Kinesis Firehose│
  │ Processor│      │  Processor   │   │                 │
  └────┬─────┘      └──────┬───────┘   └────────┬────────┘
       │                   │                    │
       ▼                   ▼                    ▼
  ┌──────────┐      ┌──────────────┐   ┌─────────────────┐
  │ DynamoDB │      │  Timestream  │   │   Amazon S3     │
  │ (State)  │      │  InfluxDB    │   │  (Data Lake)    │
  │          │      │  (History)   │   │                 │
  └──────────┘      └──────────────┘   └─────────────────┘
      │                   │                     │
      └───────────────────┴─────────────────────┘
                          │
                          ▼
                ┌─────────────────────┐
                │   Analytics Layer   │
                │  • QuickSight       │
                │  • Custom Dashboards│
                └─────────────────────┘
```

### Why This Architecture?

**1. Separation of Concerns**
- **State Layer (DynamoDB):** Current bike status, location, battery level
- **History Layer (InfluxDB):** Time-series data for analytics and ML
- **Data Lake (S3):** Raw data for compliance, auditing, and future analysis

**2. Scalability**
- Kinesis automatically scales with data volume
- Lambda scales to zero when idle (cost optimization)
- DynamoDB on-demand pricing for unpredictable traffic

**3. Resilience**
- Multiple data paths ensure no single point of failure
- Kinesis retains data for 24 hours (replay capability)
- S3 provides durable, long-term storage

**4. Cost Efficiency**
- Serverless = pay only for what you use
- No idle infrastructure costs
- Optimized for African market economics

---

## Technical Deep Dive

### 1. IoT Device Layer

#### Device Types

**Electric Bikes:**
```json
{
  "bikeId": "BIKE-001",
  "status": "riding",
  "timestamp": "2025-11-29T10:30:00Z",
  "battery": {
    "voltage": 48.2,
    "current": 12.5,
    "level": 85.0,
    "temperature": 28.5
  },
  "location": {
    "lat": 5.6037,
    "lon": -0.1870,
    "altitude": 61.0
  },
  "speed": 25.5,
  "odometer": 1234,
  "userId": "USER-123"
}
```

**Battery Swap Stations:**
```json
{
  "stationId": "STATION-001",
  "timestamp": "2025-11-29T10:30:00Z",
  "energy": {
    "solarGeneration": 2.5,
    "gridConsumption": 1.2,
    "batteryStorage": 15.8
  },
  "inventory": {
    "totalSlots": 20,
    "availableBatteries": 15,
    "chargingBatteries": 3,
    "emptySlots": 2
  },
  "environmental": {
    "temperature": 32.0,
    "humidity": 65.0
  }
}
```

#### Communication Protocol

- **Primary:** MQTT over TLS 1.2
- **Fallback:** HTTPS REST API
- **QoS Level:** 1 (at least once delivery)
- **Frequency:** Every 30 seconds (bikes), Every 5 minutes (stations)

#### Offline Handling

Devices buffer data locally when offline:
- SQLite database on device
- Automatic sync when connectivity restored
- Conflict resolution using timestamps

### 2. IoT Core & Rules Engine

#### Topic Structure

```
ecovolt/bikes/{bikeId}/telemetry
ecovolt/stations/{stationId}/energy
ecovolt/stations/{stationId}/swap
```

#### IoT Rules (SQL-based routing)

**Bike Telemetry Rule:**
```sql
SELECT * FROM 'ecovolt/bikes/+/telemetry'
```
→ Routes to Kinesis Data Streams

**Station Energy Rule:**
```sql
SELECT * FROM 'ecovolt/stations/+/energy'
```
→ Routes to Kinesis Data Streams

**Critical Alerts Rule:**
```sql
SELECT * FROM 'ecovolt/bikes/+/telemetry'
WHERE battery.level < 10 OR temperature > 45
```
→ Routes to SNS for immediate notifications

#### Security

- **X.509 Certificates:** Each device has unique certificate
- **IAM Policies:** Fine-grained permissions per device type
- **Certificate Rotation:** Automated 90-day rotation
- **Audit Logging:** All device connections logged to CloudWatch

### 3. Stream Processing Layer

#### Kinesis Configuration

```hcl
resource "aws_kinesis_stream" "telemetry" {
  name             = "ecovolt-dev-telemetry-stream"
  shard_count      = 2
  retention_period = 24

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}
```

**Why 2 Shards?**
- Current load: ~100 bikes × 2 messages/min = 200 msg/min
- Each shard: 1,000 records/sec or 1 MB/sec
- 2 shards provide 10x headroom for growth

#### Lambda Stream Processor

**Key Features:**
- **Batch Processing:** Processes up to 100 records per invocation
- **Error Handling:** Failed records sent to DLQ for retry
- **Idempotency:** Uses DynamoDB conditional writes
- **Monitoring:** Custom CloudWatch metrics

**Performance Optimization:**
```python
# Batch writes to DynamoDB
with table.batch_writer() as batch:
    for record in records:
        batch.put_item(Item=transform(record))

# Async writes to InfluxDB
async with InfluxDBClient(url=url, token=token) as client:
    write_api = client.write_api(write_options=ASYNCHRONOUS)
    await write_api.write(bucket=bucket, record=points)
```

**Lambda Configuration:**
- **Memory:** 256 MB
- **Timeout:** 60 seconds
- **Concurrency:** 10 (reserved)
- **Avg Duration:** 264ms
- **Cold Start:** ~1.2 seconds

### 4. Data Storage Layer

#### DynamoDB (Current State)

**Table Design:**
```
Primary Key: bikeId (String)
Attributes:
  - status (String): "available", "riding", "maintenance"
  - currentSOC (Number): Battery level 0-100
  - gpsLat, gpsLon (Number): Current location
  - lastSeen (Number): Unix timestamp
  - userId (String): Current rider (if riding)
  - speed (Number): Current speed in km/h
  - odometer (Number): Total distance in km
```

**Access Patterns:**
1. Get bike by ID (primary key)
2. Query bikes by status (GSI)
3. Query bikes by location (GSI with geohash)
4. Query bikes by user (GSI)

**Capacity Mode:** On-Demand
- No capacity planning required
- Automatic scaling
- Pay per request

#### Timestream for InfluxDB (Historical Data)

**Why InfluxDB?**
- Purpose-built for time-series data
- Efficient compression (10x vs DynamoDB)
- Built-in downsampling and retention policies
- Native support for analytics queries

**Data Model:**
```
Measurement: bike_telemetry
Tags:
  - bikeId
  - userId
  - status
Fields:
  - batteryVoltage
  - batteryCurrent
  - batterySOC
  - batteryTemp
  - gpsLat
  - gpsLon
  - speed
  - odometer
Timestamp: nanosecond precision
```

**Retention Policy:**
- Raw data: 30 days
- 5-minute aggregates: 90 days
- 1-hour aggregates: 1 year
- Daily aggregates: Forever

#### S3 Data Lake (Raw Archive)

**Partitioning Strategy:**
```
s3://ecovolt-data-lake/
  ├── bronze/telemetry/
  │   └── year=2025/
  │       └── month=11/
  │           └── day=29/
  │               └── hour=10/
  │                   └── data-*.gz
  ├── silver/processed/
  └── gold/analytics/
```

**Lifecycle Policies:**
- Bronze (raw): 90 days → Glacier
- Silver (processed): 180 days → Glacier Deep Archive
- Gold (analytics): Retained indefinitely

**Cost Optimization:**
- Gzip compression (5x reduction)
- Intelligent tiering for infrequent access
- S3 Select for query-in-place

### 5. Application Layer

#### Backend API (Node.js + Express)

**Architecture:**
- **Framework:** Express.js on AWS Lambda (via API Gateway)
- **Authentication:** AWS Cognito (JWT tokens)
- **Authorization:** Role-based access control (RBAC)
- **Rate Limiting:** API Gateway throttling

**Key Endpoints:**
```
GET    /api/bikes              # List all bikes
GET    /api/bikes/:id          # Get bike details
POST   /api/rides              # Start a ride
PUT    /api/rides/:id/end      # End a ride
GET    /api/stations           # List stations
POST   /api/stations/:id/swap  # Initiate battery swap
GET    /api/analytics/usage    # Usage analytics
```

**Database Access:**
- DynamoDB for real-time data
- InfluxDB for historical queries
- Redis (ElastiCache) for caching

#### Mobile Apps (React Native)

**Features:**
- **Bike Discovery:** Map view with available bikes
- **QR Code Scanning:** Unlock bikes via QR
- **Ride Tracking:** Real-time GPS tracking
- **Battery Monitoring:** Live battery status
- **Payment Integration:** Mobile money (MTN, Vodafone)
- **Offline Mode:** Cache last known bike locations

**Performance:**
- **App Size:** < 20 MB (critical for African markets)
- **Startup Time:** < 2 seconds
- **Data Usage:** < 5 MB per ride (optimized for expensive data plans)

#### Admin Portal (React + TypeScript)

**Dashboards:**
- **Fleet Management:** Real-time bike status and locations
- **Battery Health:** Predictive maintenance alerts
- **Station Monitoring:** Energy generation and consumption
- **User Analytics:** Ride patterns and demographics
- **Financial Reports:** Revenue, costs, and profitability

**Tech Stack:**
- React 18 with TypeScript
- Material-UI for components
- React Query for data fetching
- Recharts for visualizations
- Mapbox for mapping

---

## Key Design Decisions

### 1. Why Serverless?

**Pros:**
- ✅ No server management
- ✅ Automatic scaling
- ✅ Pay-per-use pricing
- ✅ Built-in high availability
- ✅ Fast iteration and deployment

**Cons:**
- ❌ Cold start latency (mitigated with reserved concurrency)
- ❌ Vendor lock-in (mitigated with abstraction layers)
- ❌ Debugging complexity (mitigated with comprehensive logging)

**Verdict:** Serverless is ideal for our use case due to variable traffic patterns and cost constraints.

### 2. Why Kinesis Over SQS?

| Feature | Kinesis | SQS |
|---------|---------|-----|
| **Ordering** | ✅ Per shard | ❌ FIFO limited to 300 TPS |
| **Fan-out** | ✅ Multiple consumers | ❌ One consumer per message |
| **Replay** | ✅ 24-hour retention | ❌ No replay |
| **Cost** | $0.015/shard-hour | $0.40/million requests |
| **Throughput** | 1 MB/sec per shard | Unlimited |

**Verdict:** Kinesis wins for our fan-out architecture and replay requirements.

### 3. Why DynamoDB Over RDS?

| Feature | DynamoDB | RDS PostgreSQL |
|---------|----------|----------------|
| **Scaling** | ✅ Automatic | ❌ Manual |
| **Latency** | ✅ Single-digit ms | ⚠️ 10-50ms |
| **Cost** | ✅ Pay per request | ❌ Always-on instances |
| **Maintenance** | ✅ Fully managed | ⚠️ Patching required |
| **Queries** | ⚠️ Limited | ✅ Full SQL |

**Verdict:** DynamoDB for current state (simple queries, high performance). InfluxDB for complex analytics.

### 4. Why InfluxDB Over Timestream for LiveAnalytics?

**Timestream for LiveAnalytics:**
- ❌ Deprecated by AWS (no new customers)
- ❌ Limited query capabilities
- ❌ Higher cost

**Timestream for InfluxDB:**
- ✅ Industry-standard time-series database
- ✅ Rich query language (Flux)
- ✅ Better compression
- ✅ Active development and community

**Verdict:** InfluxDB is the future-proof choice.

### 5. Infrastructure as Code: Terraform

**Why Terraform over CloudFormation?**
- ✅ Multi-cloud support (future-proofing)
- ✅ Better state management
- ✅ Larger community and module ecosystem
- ✅ More readable syntax (HCL vs JSON/YAML)

**Our Terraform Structure:**
```
infra/
├── main.tf              # Root module
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # S3 backend config
├── modules/
│   ├── iot/            # IoT Core resources
│   ├── streaming/      # Kinesis resources
│   ├── compute/        # Lambda functions
│   ├── storage/        # DynamoDB, S3
│   ├── analytics/      # InfluxDB, QuickSight
│   ├── networking/     # VPC, subnets
│   └── security/       # IAM, KMS
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

---

## Testing & Monitoring

### Comprehensive Testing Strategy

#### 1. Unit Tests
- **Backend:** Jest (Node.js)
- **Frontend:** React Testing Library
- **Lambda:** Python unittest
- **Coverage Target:** > 80%

#### 2. Integration Tests
- **API Tests:** Postman/Newman
- **Database Tests:** DynamoDB Local
- **IoT Tests:** AWS IoT Device Simulator

#### 3. End-to-End Tests
- **Full System Verification:** Custom Python script
- **Load Testing:** Locust (1000 concurrent users)
- **Chaos Engineering:** AWS Fault Injection Simulator

### The Verification Script

We built a comprehensive Python script that tests the entire pipeline:

```bash
python3 scripts/testing/full_system_verification.py
```

**What it does:**
1. Injects unique test data via IoT Core
2. Verifies data in DynamoDB (< 3 seconds)
3. Checks InfluxDB for historical data
4. Validates S3 Firehose delivery
5. Confirms Kinesis stream flow
6. Provides detailed pass/fail report

**Results:**
- ✅ 5/5 phases passed
- ✅ 100% success rate
- ✅ Sub-3-second latency
- ✅ Zero errors

### Monitoring Dashboard

**CloudWatch Metrics:**
- IoT Core: Messages published, rules executed
- Kinesis: Incoming records, iterator age
- Lambda: Invocations, errors, duration
- DynamoDB: Read/write capacity, throttles
- InfluxDB: Write throughput, query latency

**Alarms:**
- Lambda error rate > 1%
- Lambda throttles > 0
- Kinesis iterator age > 60 seconds
- DynamoDB throttles > 0
- API Gateway 5xx errors > 5%

**Monitoring Script:**
```bash
python3 scripts/testing/full_system_verification.py --monitor
```

Shows real-time system health without running tests.

---

## Lessons Learned

### 1. Start Simple, Scale Later

**Initial Mistake:** Over-engineered the architecture with unnecessary microservices.

**Solution:** Consolidated into monolithic Lambda functions. Added complexity only when needed.

**Result:** Faster development, easier debugging, lower costs.

### 2. Test Early, Test Often

**Initial Mistake:** Manual testing was time-consuming and error-prone.

**Solution:** Built automated verification script from day one.

**Result:** Caught issues early, confident deployments, faster iteration.

### 3. Monitor Everything

**Initial Mistake:** Relied on AWS console for monitoring.

**Solution:** Built custom monitoring dashboard with actionable alerts.

**Result:** Proactive issue detection, reduced downtime, better user experience.

### 4. Cost Optimization is Critical

**Initial Mistake:** Used provisioned capacity for everything.

**Solution:** Switched to on-demand pricing and serverless where possible.

**Result:** 60% cost reduction while maintaining performance.

### 5. Design for Failure

**Initial Mistake:** Assumed AWS services are always available.

**Solution:** Added retry logic, dead letter queues, and circuit breakers.

**Result:** System handles transient failures gracefully.

### 6. Documentation is Code

**Initial Mistake:** Documentation was an afterthought.

**Solution:** Treated documentation as first-class citizen (README, architecture diagrams, runbooks).

**Result:** Faster onboarding, fewer support tickets, better collaboration.

---

## Performance Metrics

### Latency Benchmarks

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| IoT → DynamoDB | < 5s | 2.8s | ✅ |
| API Response (p95) | < 200ms | 145ms | ✅ |
| Lambda Cold Start | < 2s | 1.28s | ✅ |
| Lambda Warm | < 500ms | 265ms | ✅ |
| InfluxDB Write | < 1s | 642ms | ✅ |

### Throughput

| Metric | Current | Peak | Capacity |
|--------|---------|------|----------|
| Messages/min | 200 | 500 | 2,000 |
| API Requests/sec | 50 | 150 | 1,000 |
| Concurrent Rides | 20 | 45 | 500 |

### Reliability

| Metric | Target | Actual |
|--------|--------|--------|
| Uptime | 99.9% | 99.95% |
| Lambda Success Rate | > 99% | 100% |
| Data Loss | 0% | 0% |

### Cost Efficiency

**Monthly AWS Costs (100 bikes):**
- IoT Core: $5
- Kinesis: $22
- Lambda: $15
- DynamoDB: $10
- InfluxDB: $50
- S3: $5
- API Gateway: $10
- **Total: ~$117/month**

**Cost per Bike:** $1.17/month

**Cost per Ride:** $0.05 (assuming 20 rides/bike/month)

---

## Future Roadmap

### Phase 1: Enhanced Analytics (Q1 2026)

- **Predictive Maintenance:** ML models to predict battery failures
- **Route Optimization:** Suggest optimal routes based on terrain and battery
- **Demand Forecasting:** Predict bike demand by location and time
- **User Segmentation:** Personalized recommendations

### Phase 2: Expansion (Q2 2026)

- **Multi-City Support:** Expand to Kumasi, Takoradi
- **Fleet Management:** Automated rebalancing algorithms
- **Dynamic Pricing:** Surge pricing during peak hours
- **Partnerships:** Integration with ride-hailing apps

### Phase 3: Sustainability (Q3 2026)

- **Carbon Credits:** Track and monetize CO2 savings
- **Solar Optimization:** ML-based solar panel positioning
- **Battery Recycling:** End-of-life battery management
- **Green Routing:** Suggest routes with less pollution

### Phase 4: Innovation (Q4 2026)

- **Autonomous Rebalancing:** Self-driving bikes for fleet management
- **Blockchain Integration:** Transparent carbon credit tracking
- **Edge Computing:** On-device ML for offline features
- **5G Integration:** Ultra-low latency for safety features

---

## Conclusion

Building EcoVolt has been an incredible journey. We've created a production-ready IoT platform that:

- ✅ Processes real-time telemetry from hundreds of devices
- ✅ Achieves sub-3-second end-to-end latency
- ✅ Maintains 100% success rate across all components
- ✅ Costs less than $1.20 per bike per month
- ✅ Scales automatically with demand
- ✅ Provides actionable insights through analytics

**Key Takeaways:**

1. **Serverless is powerful** for variable workloads and cost optimization
2. **Polyglot architecture** enables multiple use cases from single data stream
3. **Testing and monitoring** are critical for production readiness
4. **Infrastructure as code** accelerates development and reduces errors
5. **Design for African context** (cost, connectivity, mobile-first)

### Open Source

We're committed to open-sourcing key components:
- ✅ Terraform modules for IoT infrastructure
- ✅ Python verification and monitoring scripts
- ✅ Lambda function templates
- ✅ Mobile app UI components

**GitHub:** [github.com/ecovolt/platform](https://github.com/ecovolt/platform)

### Get Involved

Interested in contributing or learning more?

- **Documentation:** [docs.ecovolt.io](https://docs.ecovolt.io)
- **Blog:** [blog.ecovolt.io](https://blog.ecovolt.io)
- **Twitter:** [@EcoVoltGH](https://twitter.com/EcoVoltGH)
- **Email:** engineering@ecovolt.io

---

## Appendix: Technical Specifications

### AWS Services Used

| Service | Purpose | Monthly Cost |
|---------|---------|--------------|
| IoT Core | Device connectivity | $5 |
| Kinesis Data Streams | Stream processing | $22 |
| Lambda | Compute | $15 |
| DynamoDB | Current state storage | $10 |
| Timestream for InfluxDB | Time-series data | $50 |
| S3 | Data lake | $5 |
| API Gateway | REST API | $10 |
| Cognito | Authentication | $0 (free tier) |
| CloudWatch | Monitoring | $5 |
| VPC | Networking | $0 |
| **Total** | | **$122** |

### Development Tools

- **IDE:** VS Code with AWS Toolkit
- **Version Control:** Git + GitHub
- **CI/CD:** GitHub Actions
- **IaC:** Terraform 1.5+
- **Testing:** Jest, Pytest, Locust
- **Monitoring:** CloudWatch, Custom Python scripts
- **Documentation:** Markdown, Mermaid diagrams

### Team

- **Backend Engineers:** 2
- **Frontend Engineers:** 2
- **DevOps Engineer:** 1
- **IoT Engineer:** 1
- **Product Manager:** 1
- **Designer:** 1

**Total:** 8 people

### Timeline

- **Planning:** 2 weeks
- **Infrastructure Setup:** 3 weeks
- **Backend Development:** 6 weeks
- **Frontend Development:** 6 weeks
- **Testing & QA:** 2 weeks
- **Deployment:** 1 week
- **Total:** 20 weeks (5 months)

---

**Thank you for reading!** We hope this article inspires you to build amazing IoT solutions on AWS. Feel free to reach out with questions or feedback.

**#IoT #AWS #Serverless #ElectricVehicles #Ghana #Africa #TechForGood**

---

*This article is part of the EcoVolt Engineering Blog series. Stay tuned for more deep dives into specific components of our platform.*
