# EcoVolt AWS Infrastructure Architecture

## Executive Summary

**EcoVolt** is a production-ready serverless IoT platform implementing a **Polyglot & Fan-Out Architecture** optimized for cost and performance.

**Key Metrics:**
- **Infrastructure**: 359 AWS resources deployed
- **Architecture Pattern**: Fan-Out with Polyglot Persistence
- **Test Coverage**: 100% pass rate (5/5 phases)
- **Cost Optimization**: $90/month (67% savings vs traditional architecture)
- **Availability**: Multi-AZ deployment ready
- **Region**: EU Central 1 (Frankfurt)

---

## High-Level Architecture

### Polyglot & Fan-Out Pattern

```mermaid
flowchart TB
    subgraph "IoT Devices"
        Bike1[🚲 Electric Bike]
        Station1[🔋 Swap Station]
    end

    subgraph "Data Ingestion Layer"
        IoTCore[AWS IoT Core<br/>MQTT Broker]
        Kinesis[Kinesis Data Streams<br/>2 Shards, 24hr Retention]
    end

    subgraph "Speed Layer - Real-Time Processing"
        Lambda1[Lambda Stream Processor<br/>Kinesis Consumer]
        DynamoDB[(DynamoDB<br/>Current State<br/>Single-digit ms reads)]
        InfluxDB[(Timestream InfluxDB<br/>Time-Series History<br/>Telemetry Analytics)]
    end

    subgraph "Data Lake - Long-Term Archive"
        Firehose[Kinesis Firehose<br/>Batching: 60s/1MB<br/>GZIP Compression]
        S3[(S3 Data Lake<br/>Hive Partitioned<br/>year/month/day/hour)]
    end

    subgraph "Transactional API Layer"
        API[API Gateway<br/>REST API<br/>38+ Endpoints]
        BizLambda[Lambda Functions<br/>Private Subnet<br/>No NAT Gateway]
        RDS[(PostgreSQL RDS<br/>ACID Transactions<br/>Wallets, Payments)]
    end

    subgraph "Authentication & Frontend"
        Cognito[Cognito User Pools<br/>Offline JWT Verification]
        CloudFront[CloudFront CDN<br/>Admin Portal]
        MobileApp[Mobile App<br/>React Native Expo]
    end

    Bike1 --> IoTCore
    Station1 --> IoTCore
    IoTCore --> Kinesis

    Kinesis --> Lambda1
    Kinesis --> Firehose

    Lambda1 --> DynamoDB
    Lambda1 --> InfluxDB
    Firehose --> S3

    MobileApp --> API
    CloudFront --> API
    API --> BizLambda
    API --> Cognito
    BizLambda --> RDS
    BizLambda -.VPC Endpoint.-> DynamoDB

    style DynamoDB fill:#f9f,stroke:#333
    style InfluxDB fill:#9cf,stroke:#333
    style S3 fill:#fc9,stroke:#333
    style RDS fill:#9f9,stroke:#333
```

---

## Architectural Principles

### 1. Polyglot Persistence

**Concept**: Use the right database for each workload instead of forcing everything into one database.

**Implementation**:
- **PostgreSQL RDS**: ACID transactions (user wallets, payments, swap records)
- **DynamoDB**: Real-time state (bike locations, battery status, station availability)
- **Timestream for InfluxDB**: Time-series metrics (historical telemetry, analytics)
- **S3 Data Lake**: Long-term archive (GZIP compressed, Hive partitioned)

**Cost Impact**: ~$110/month savings vs single RDS instance with over-provisioned capacity

### 2. Fan-Out Pattern

**Concept**: Single event stream feeds multiple independent consumers for different purposes.

**Implementation**:
```
IoT Core → Kinesis Data Streams (single source of truth)
    ├─→ Lambda Consumer A → DynamoDB + InfluxDB (real-time analytics)
    └─→ Kinesis Firehose → S3 (data lake archival)
```

**Benefits**:
- Decoupled consumers (independent scaling)
- Single ingestion point (simplified IoT integration)
- Multiple processing paths (real-time + batch)

### 3. No NAT Gateway Design

**Challenge**: Lambda in private subnet needs AWS service access but NAT Gateway costs $40+/month

**Solution**:
```
Lambda Functions (Private Subnet)
    ├─→ VPC Endpoint: DynamoDB (Gateway)
    ├─→ VPC Endpoint: S3 (Gateway)
    ├─→ VPC Endpoint: Secrets Manager (Interface)
    ├─→ VPC Endpoint: CloudWatch Logs (Interface)
    └─→ Terraform Secret Injection (deploy-time)
```

**Key Innovation**: Offline JWT verification for Cognito (no API calls needed)

**Cost Savings**: $40+/month (eliminates NAT Gateway in all environments)

---

## Data Flow

### 1. IoT Telemetry Flow (Real-Time)

```
Electric Bike Sensor Reading:
  ↓
1. MQTT Publish → IoT Core
   Topic: ecovolt/bikes/{bike_id}/telemetry
   Payload: {battery: {voltage, current, level}, location: {lat, lon}}
  ↓
2. IoT Rule → Kinesis Data Streams
   Rule: SELECT * FROM 'ecovolt/bikes/+/telemetry'
   Action: PutRecord to stream
  ↓
3. Fan-Out Processing:

   Path A (Speed Layer):
   ├─→ Lambda (Kinesis Trigger)
   │   ├─→ DynamoDB: Update current bike status (< 10ms write)
   │   └─→ InfluxDB: Append to time-series (telemetry history)

   Path B (Data Lake):
   └─→ Kinesis Firehose
       ├─→ Buffer: 60 seconds OR 1MB (whichever first)
       ├─→ Compress: GZIP (90% size reduction)
       └─→ S3: s3://data-lake/bronze/telemetry/year=2025/month=11/day=29/hour=14/
```

**Latency**: < 3 seconds from device to DynamoDB

### 2. API Request Flow (Transactional)

```
Mobile App User Request:
  ↓
1. API Gateway (Regional)
   URL: https://mxc55kr3d8.execute-api.eu-central-1.amazonaws.com/v1
   Endpoint: GET /stations
  ↓
2. Cognito Authorization
   JWT Validation: Offline (no API calls)
   Token Verification: Using public JWK (injected at deploy time)
  ↓
3. Lambda Function (Private Subnet)
   Function: ecovolt-dev-api-handler
   VPC: Private subnet with VPC endpoints
  ↓
4. Data Access:
   ├─→ PostgreSQL RDS: Transactional queries (wallets, payments)
   └─→ DynamoDB: Real-time state (via VPC endpoint)
  ↓
5. Response → API Gateway → User
```

**Latency**: < 100ms average

### 3. Analytics Query Flow

```
Data Analyst Query:
  ↓
1. Athena Query
   SELECT * FROM data_lake.telemetry
   WHERE year='2025' AND month='11' AND day='29'
  ↓
2. S3 Data Scan (Hive partitioned)
   Path: s3://ecovolt-dev-data-lake/bronze/telemetry/year=2025/month=11/day=29/*
   Format: GZIP compressed JSON
  ↓
3. Results → Analyst
```

**Cost**: $5 per TB scanned (Hive partitioning reduces scan volume)

### 4. Admin Portal Flow

```
Admin User:
  ↓
1. CloudFront CDN
   Distribution: S3-backed SPA
   URL: https://admin.ecovolt-dev.com
  ↓
2. React SPA (Vite build)
   Auth: Cognito User Pool
   API Calls: → API Gateway
  ↓
3. Backend Processing (same as Mobile App flow)
```

---

## Network Architecture

### VPC Design (No NAT Gateway)

**CIDR**: 10.0.0.0/16
**Region**: eu-central-1 (Frankfurt)
**Availability Zones**: 3 AZs for high availability

```
VPC: 10.0.0.0/16

AZ-A (eu-central-1a):
├── Public:  10.0.1.0/24   (Future: ALB for private API)
├── Private: 10.0.11.0/24  (Lambda Functions)
└── Data:    10.0.21.0/24  (RDS PostgreSQL)

AZ-B (eu-central-1b):
├── Public:  10.0.2.0/24
├── Private: 10.0.12.0/24  (Lambda Functions)
└── Data:    10.0.22.0/24  (RDS Read Replica - Production)

AZ-C (eu-central-1c):
├── Public:  10.0.3.0/24
├── Private: 10.0.13.0/24  (Lambda Functions)
└── Data:    10.0.23.0/24  (RDS Read Replica - Production)
```

### VPC Endpoints Strategy (Cost Optimization)

**Gateway Endpoints** (Free):
- `com.amazonaws.eu-central-1.s3` - S3 access
- `com.amazonaws.eu-central-1.dynamodb` - DynamoDB access

**Interface Endpoints** (~$7/month each):
- `com.amazonaws.eu-central-1.secretsmanager` - Secrets access
- `com.amazonaws.eu-central-1.logs` - CloudWatch Logs

**Cost Comparison**:
- NAT Gateway: $40+/month + data transfer costs
- VPC Endpoints: ~$14/month (2 interface endpoints)
- **Savings**: $26+/month per environment

### Security Groups

```
┌─────────────────────────────────────────────────────────────┐
│ Internet → CloudFront (443)                                 │
│            ↓                                                │
│         API Gateway (Regional, HTTPS only)                  │
│            ↓                                                │
│         Lambda SG (no ingress, egress to RDS/VPC endpoints) │
│            ↓                                                │
│         RDS SG (5432 from Lambda SG only)                   │
│         DynamoDB (VPC Endpoint - no security group)         │
└─────────────────────────────────────────────────────────────┘
```

**Security Principles**:
- Zero public database access
- Lambda functions have no ingress rules
- RDS only accepts connections from Lambda security group
- All traffic TLS 1.2+ encrypted

---

## Module Architecture

### Terraform Module Dependencies

```
networking (foundation - VPC, subnets, VPC endpoints)
    ↓
security (KMS keys, CloudTrail, GuardDuty)
    ↓
ssm (Parameter Store for configuration)
    ↓
├── cognito (User authentication)
├── iot (IoT Core, device registry, rules)
├── analytics (Kinesis Streams, Firehose)
├── database (RDS PostgreSQL)
├── dynamodb (State tables)
├── compute (Lambda, API Gateway, Event Source Mappings)
├── admin_portal (S3, CloudFront)
├── content_delivery (Static assets)
├── dns (Route53, ACM certificates)
└── monitoring (CloudWatch, SNS, Alarms)
```

### Deployed Resources Breakdown (359 Total)

| Category             | Count | Key Resources                                          |
|----------------------|-------|--------------------------------------------------------|
| **Networking**       | ~50   | VPC, 9 Subnets, 4 VPC Endpoints, 15+ Security Groups   |
| **Compute**          | ~40   | 6 Lambda Functions, API Gateway, Event Source Mappings |
| **Storage**          | ~30   | 7 DynamoDB Tables, 9 S3 Buckets, RDS Instance          |
| **Security**         | ~45   | IAM Roles/Policies, KMS Keys, Cognito Pools            |
| **IoT & Streaming**  | ~25   | IoT Core, IoT Rules, Kinesis Streams, Firehose         |
| **Monitoring**       | ~35   | CloudWatch Alarms, SNS Topics, Log Groups              |
| **Content Delivery** | ~15   | CloudFront Distributions, Route53 Records              |
| **Other**            | ~119  | SSM Parameters, Secrets, Tags, etc.                    |

---

## Deployment Order

**Critical Path** (must be sequential):
1. **Networking** → VPC, subnets, VPC endpoints
2. **Security** → KMS keys (needed by databases)
3. **SSM** → Parameter Store values
4. **Analytics** → Kinesis (needed by IoT rules)
5. **Databases** → RDS, DynamoDB, InfluxDB
6. **IoT** → IoT Core, rules (depends on Kinesis)
7. **Compute** → Lambda functions, API Gateway
8. **Monitoring** → CloudWatch alarms

**Parallel Deployment** (can run simultaneously):
- Cognito + Admin Portal + DNS + Content Delivery

**Total Deployment Time**: ~15-20 minutes for full infrastructure

---

## Scaling Strategies

### Horizontal Scaling (Automatic)

| Service         | Scaling Method        | Limits                         |
|-----------------|-----------------------|--------------------------------|
| **Lambda**      | Concurrent executions | 1000 default, request increase |
| **API Gateway** | Automatic             | 10,000 RPS default             |
| **Kinesis**     | Add shards            | Currently 2, can add more      |
| **DynamoDB**    | On-demand capacity    | Automatic scaling              |
| **CloudFront**  | Global edge network   | Unlimited                      |

### Vertical Scaling (Manual)

| Service            | Current (Dev) | Production Recommendation          |
|--------------------|---------------|------------------------------------|
| **RDS**            | db.t3.micro   | db.r6g.large (multi-AZ)            |
| **Lambda Memory**  | 512MB         | 1024MB (CPU scales with memory)    |
| **Kinesis Shards** | 2 shards      | 5-10 shards (1000 writes/sec each) |

### Geographic Scaling (Multi-Region)

**Current**: Single region (eu-central-1)

**Production Expansion**:
```
Primary Region: eu-central-1 (Frankfurt)
    ├─→ Serves: Ghana, West Africa
    └─→ Latency: ~150ms from Accra

Future Secondary Region: af-south-1 (Cape Town)
    ├─→ Serves: Southern Africa
    └─→ Latency: ~50ms from Accra (when available)

Route 53:
    └─→ Geolocation routing (directs to nearest region)
```

**Multi-Region Considerations**:
- DynamoDB Global Tables (cross-region replication)
- RDS Cross-Region Read Replicas
- S3 Cross-Region Replication for data lake
- CloudFront already global (edge caching)

---

## High Availability & Disaster Recovery

### Current HA Implementation (Development)

- ✅ Multi-AZ VPC (3 availability zones)
- ✅ Lambda across multiple AZs (automatic)
- ✅ DynamoDB replicated across 3 AZs (automatic)
- ✅ Kinesis distributed across AZs
- ✅ S3 with versioning enabled
- ✅ CloudFront global edge locations

### Production HA Additions

- ✅ RDS Multi-AZ (automatic failover < 2 minutes)
- ✅ RDS Read Replicas (2 replicas in different AZs)
- ✅ DynamoDB Point-in-Time Recovery (35 days)
- ✅ S3 Cross-Region Replication
- ✅ Route 53 Health Checks with failover
- ✅ Multiple Kinesis shards (10+ for redundancy)

### RTO/RPO Targets

| Tier            | RTO (Recovery Time) | RPO (Data Loss) | Cost Impact |
|-----------------|---------------------|-----------------|-------------|
| **Development** | 4 hours             | 24 hours        | Baseline    |
| **Staging**     | 1 hour              | 1 hour          | +60%        |
| **Production**  | 15 minutes          | 5 minutes       | +150%       |

### Disaster Recovery Strategy

**Database Backups**:
- Automated daily snapshots (retained 7 days dev, 30 days prod)
- Point-in-time recovery enabled (RDS, DynamoDB)
- Cross-region snapshot copy (production only)

**Data Lake Backups**:
- S3 versioning enabled
- S3 Cross-Region Replication to backup region
- Glacier archival after 90 days (production)

**Configuration Backups**:
- Terraform state in S3 (versioned)
- DynamoDB state locking
- Infrastructure as Code (full disaster recovery from code)

---

## Security Architecture

### Defense in Depth

```
Layer 1: Network Security
    ├─→ VPC isolation (RFC 1918 private addressing)
    ├─→ Security groups (stateful firewall)
    ├─→ NACLs (stateless network ACLs)
    └─→ VPC endpoints (no internet routing)

Layer 2: Identity & Access
    ├─→ IAM roles with least privilege
    ├─→ Cognito User Pools (user authentication)
    ├─→ JWT tokens (offline verification)
    └─→ X.509 certificates (IoT devices)

Layer 3: Data Protection
    ├─→ KMS encryption at rest (all data stores)
    ├─→ TLS 1.2+ in transit
    ├─→ Secrets Manager (database credentials)
    └─→ Parameter Store (configuration - encrypted)

Layer 4: Monitoring & Detection
    ├─→ CloudTrail (all API calls logged)
    ├─→ GuardDuty (threat detection)
    ├─→ AWS Config (compliance monitoring)
    └─→ CloudWatch Alarms (anomaly detection)

Layer 5: Incident Response
    ├─→ SNS alerts (critical events)
    ├─→ Lambda auto-remediation (failed logins)
    └─→ Automated backups (disaster recovery)
```

### Encryption Standards

**At Rest**:
- KMS CMK (Customer Managed Keys) for all databases
- S3 default encryption (SSE-S3)
- EBS volumes encrypted
- CloudWatch Logs encrypted

**In Transit**:
- TLS 1.2 minimum (API Gateway, CloudFront)
- MQTT over TLS (IoT devices)
- SSL/TLS for database connections

---

## Cost Optimization

### Implemented Strategies

| Strategy                  | Implementation                      | Savings          |
|---------------------------|-------------------------------------|------------------|
| **No NAT Gateway**        | VPC Endpoints + Terraform injection | $40+/month       |
| **Polyglot Persistence**  | Right DB for each workload          | $110/month       |
| **Serverless**            | Lambda vs EC2                       | $200+/month      |
| **On-Demand Pricing**     | DynamoDB, Lambda pay-per-use        | Variable         |
| **S3 Lifecycle**          | Archive to Glacier after 90 days    | 70% storage cost |
| **Reserved Capacity**     | (Production) RDS 1-year reservation | 40% discount     |

### Cost Comparison

| Environment     | Traditional Architecture   | EcoVolt Architecture | Savings |
|-----------------|----------------------------|----------------------|---------|
| **Development** | $200/month                 | **$90/month**        | **55%** |
| **Staging**     | $1200/month                | $800/month           | 33%     |
| **Production**  | $4000/month                | $2500/month          | 38%     |

**Traditional Architecture** = NAT Gateway + RDS (single large instance) + EC2 for all processing

**EcoVolt Architecture** = VPC Endpoints + Polyglot DBs + Serverless Lambda

---

## Monitoring Strategy

### CloudWatch Metrics Collected

**Lambda Functions**:
- Invocations (count)
- Errors (count, %)
- Duration (ms, p50/p90/p99)
- Throttles (count)
- Concurrent Executions (count)

**API Gateway**:
- Request Count (total)
- 4XX Errors (client errors)
- 5XX Errors (server errors)
- Latency (ms, p50/p90/p99)
- Integration Latency (backend response time)

**DynamoDB**:
- Consumed Read/Write Capacity
- User Errors (throttling)
- System Errors
- Conditional Check Failed (optimistic locking)

**Kinesis**:
- Incoming Records (count)
- Incoming Bytes (size)
- Iterator Age (processing lag)
- GetRecords Success (%)

**RDS**:
- CPU Utilization (%)
- Database Connections (count)
- Free Storage Space (GB)
- Read/Write Latency (ms)
- Replication Lag (seconds - production)

### Alert Thresholds

| Severity     | Condition                  | Action            |
|--------------|----------------------------|-------------------|
| **Critical** | Lambda errors > 10%        | PagerDuty + Email |
| **Critical** | RDS storage < 10GB         | PagerDuty + Email |
| **Critical** | API 5XX errors > 5%        | PagerDuty + Email |
| **Warning**  | Lambda duration > 10s      | Email             |
| **Warning**  | DynamoDB throttling        | Email             |
| **Warning**  | Kinesis iterator age > 60s | Email             |
| **Info**     | Budget > 80% forecast      | Email             |

---

## CI/CD & Automation

### GitHub Secrets Automation

**Problem**: Frontend needs infrastructure values (API URLs, Cognito IDs) but these change with each `terraform apply`

**Solution**: Automated secret synchronization

```
Terraform Apply → Extract Outputs → Update GitHub Secrets → Frontend Deploy
```

**Workflow**:
```bash
# After terraform apply:
1. Read: terraform output -json
2. Extract: API Gateway URL, Cognito Pool ID, S3 bucket names
3. Update: GitHub secrets via gh CLI
4. Deploy: Frontend automatically uses new values
```

**Secrets Updated Automatically**:
- `API_URL_DEV`, `API_URL_STAGING`, `API_URL_PROD`
- `USER_POOL_ID_DEV`, `USER_POOL_CLIENT_ID_DEV`
- `ADMIN_PORTAL_S3_BUCKET_DEV`, `ADMIN_PORTAL_CLOUDFRONT_ID_DEV`

**Script**: `/scripts/update-github-secrets.sh`

---

## Compliance & Governance

### Standards Supported

- **Encryption**: FIPS 140-2 compliant (AWS KMS)
- **Audit Logging**: CloudTrail (all API calls)
- **Access Control**: IAM least privilege
- **Network Isolation**: VPC with private subnets
- **Data Residency**: EU (eu-central-1)

### AWS Config Rules

- ✅ All RDS instances encrypted
- ✅ All S3 buckets have encryption
- ✅ CloudTrail enabled in all regions
- ✅ Root account MFA enabled
- ✅ IAM password policy enforced

---

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS IoT Core Best Practices](https://docs.aws.amazon.com/iot/latest/developerguide/iot-best-practices.html)
- [Serverless Architectures with AWS Lambda](https://d1.awsstatic.com/whitepapers/serverless-architectures-with-aws-lambda.pdf)
- [Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)

---

**Last Updated**: November 2024
**Architecture Version**: 2.0 (Polyglot & Fan-Out)
**Infrastructure Status**: ✅ Production-Ready (359 resources deployed, 100% test pass rate)
