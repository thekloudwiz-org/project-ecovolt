# EcoVolt Platform - AWS Services by Architecture Layer

**Project:** EcoVolt Electric Bike Sharing Platform  
**Architecture Pattern:** Polyglot & Fan-Out  
**Total AWS Resources:** 359  
**Date:** November 29, 2025

---

## 📋 Complete Service Breakdown by Layer

### 1. **Ingestion Layer** (Device → Cloud)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **AWS IoT Core** | MQTT message broker for device connectivity | - 3 Thing Types (bike, station, battery)<br>- X.509 certificate authentication<br>- 3 IoT Rules for routing | $5 |
| **IoT Device Registry** | Device identity and metadata management | - Thing registry<br>- Certificate management<br>- Policy attachments | Included |
| **IoT Rules Engine** | SQL-based message routing | - Rule: `ecovolt_dev_bike_telemetry`<br>- Rule: `ecovolt_dev_station_energy`<br>- Rule: `ecovolt_dev_station_swap` | Included |

**Total Ingestion Layer:** ~$5/month

---

### 2. **Buffering/Streaming Layer** (Data Flow Management)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon Kinesis Data Streams** | Real-time data streaming and fan-out | - Stream: `ecovolt-dev-telemetry-stream`<br>- 2 shards<br>- 24-hour retention<br>- Enhanced fan-out enabled | $22 |
| **Amazon Kinesis Data Firehose** | Managed delivery to S3 data lake | - Delivery stream: `ecovolt-dev-telemetry-firehose`<br>- Buffer: 60s or 1MB<br>- GZIP compression<br>- Hive partitioning | $5 |

**Total Buffering Layer:** ~$27/month

---

### 3. **Compute Layer** (Processing & Business Logic)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **AWS Lambda** | Serverless compute for stream processing and API | - `stream-processor`: Kinesis consumer (256MB, 60s timeout)<br>- `api-handler`: REST API backend (512MB, 30s timeout)<br>- `authorizer`: Custom JWT validation<br>- `admin-api`: Admin portal backend | $15 |
| **Lambda Event Source Mapping** | Connects Lambda to Kinesis | - Batch size: 100 records<br>- Batch window: 1 second<br>- Retry: 3 attempts<br>- DLQ enabled | Included |
| **Lambda Layers** | Shared dependencies | - Node.js dependencies<br>- Python libraries (boto3, influxdb-client) | Included |

**Total Compute Layer:** ~$15/month

---

### 4. **Database Layer** (Polyglot Persistence)

#### 4a. Current State (Real-Time)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon DynamoDB** | NoSQL database for current device state | **Tables:**<br>- `bike-status` (current bike location/battery)<br>- `station-status` (station availability)<br>- `battery-inventory` (battery tracking)<br>- `swap-events` (swap transactions)<br>- `user-sessions` (active rides)<br>- `device-registry` (device metadata)<br>- `alerts` (system alerts)<br><br>**Config:**<br>- On-demand capacity<br>- Point-in-time recovery<br>- Encryption at rest (KMS) | $10 |

#### 4b. Historical Data (Time-Series)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Timestream for InfluxDB** | Time-series database for historical telemetry | - Database: `ecovolt-dev-telemetry`<br>- Bucket: `dev-telemetry`<br>- Retention: 30 days raw, 90 days aggregated<br>- Organization: `ecovolt` | $50 |

#### 4c. Transactional Data (ACID)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon RDS (PostgreSQL)** | Relational database for transactional data | - Instance: db.t3.micro (dev)<br>- Storage: 20GB GP3<br>- Multi-AZ: No (dev), Yes (prod)<br>- Automated backups: 7 days<br>- Encryption: KMS<br><br>**Tables:**<br>- users, wallets, payments<br>- bookings, rides, invoices<br>- stations, bikes (metadata) | $15 |

#### 4d. Data Lake (Long-Term Archive)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon S3** | Object storage for raw data archive | **Buckets:**<br>- `data-lake`: Raw telemetry (bronze layer)<br>- `admin-portal`: Static website hosting<br>- `mobile-assets`: App assets<br>- `lambda-code`: Deployment packages<br>- `terraform-state`: IaC state files<br><br>**Features:**<br>- Versioning enabled<br>- Lifecycle policies (Glacier after 90 days)<br>- Server-side encryption (SSE-S3)<br>- Hive partitioning (year/month/day/hour) | $5 |

**Total Database Layer:** ~$80/month

---

### 5. **Networking Layer** (VPC & Connectivity)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon VPC** | Virtual private cloud for resource isolation | - CIDR: 10.0.0.0/16<br>- 3 Availability Zones<br>- 9 Subnets (3 public, 3 private, 3 data) | Free |
| **VPC Endpoints (Gateway)** | Private access to AWS services | - S3 Gateway Endpoint<br>- DynamoDB Gateway Endpoint | Free |
| **VPC Endpoints (Interface)** | Private access to AWS services | - Secrets Manager Interface Endpoint<br>- CloudWatch Logs Interface Endpoint | $14 |
| **Internet Gateway** | Public subnet internet access | - Attached to VPC<br>- Used by public subnets only | Free |
| **Route Tables** | Network routing configuration | - Public route table (3 subnets)<br>- Private route table (3 subnets)<br>- Data route table (3 subnets) | Free |
| **Security Groups** | Virtual firewalls for resources | - Lambda SG (no ingress, egress to RDS/VPC endpoints)<br>- RDS SG (5432 from Lambda SG only)<br>- VPC Endpoint SG (443 from private subnets)<br>- ALB SG (future)<br>- Bastion SG (future) | Free |
| **Network ACLs** | Subnet-level firewall | - Default NACL (allow all)<br>- Custom NACLs for data subnets | Free |

**Total Networking Layer:** ~$14/month

**Note:** No NAT Gateway = $40+/month savings per AZ (total savings: ~$120/month)

---

### 6. **API & Application Layer** (User-Facing Services)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon API Gateway** | REST API for mobile and admin portal | - Type: Regional<br>- API: `ecovolt-dev-api`<br>- Stage: `v1`<br>- 38+ endpoints<br>- Cognito authorizer<br>- Request validation<br>- CORS enabled | $10 |
| **Amazon CloudFront** | CDN for admin portal and static assets | - Distribution: Admin portal (S3 origin)<br>- Distribution: Mobile assets<br>- SSL/TLS certificate (ACM)<br>- Edge locations: Global<br>- Caching: 24 hours | $5 |
| **AWS Amplify** | Mobile app backend (optional) | - Authentication integration<br>- API integration<br>- Storage integration | $0 (using direct SDK) |

**Total API Layer:** ~$15/month

---

### 7. **Authentication & Authorization Layer** (Identity Management)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon Cognito User Pools** | User authentication and management | **Pools:**<br>- `ecovolt-dev-customers` (mobile app users)<br>- `ecovolt-dev-admins` (admin portal users)<br><br>**Features:**<br>- Email/password authentication<br>- MFA optional<br>- Password policies<br>- JWT tokens<br>- Offline JWK validation (no runtime API calls) | $0 (free tier) |
| **Cognito Identity Pools** | Federated identities for AWS resource access | - Temporary AWS credentials<br>- Role-based access<br>- Social login (future) | $0 |
| **AWS IAM** | Service-to-service authentication | - 12+ IAM roles<br>- 30+ IAM policies<br>- Least privilege principle<br>- Service-linked roles | Free |

**Total Authentication Layer:** ~$0/month (within free tier)

---

### 8. **Security Layer** (Encryption, Compliance, Threat Detection)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **AWS KMS** | Encryption key management | - Customer Managed Keys (CMK) for:<br>  - RDS encryption<br>  - DynamoDB encryption<br>  - S3 encryption<br>  - Secrets Manager<br>  - CloudWatch Logs | $4 |
| **AWS Secrets Manager** | Secure credential storage | - RDS database credentials<br>- InfluxDB credentials<br>- API keys<br>- Automatic rotation (30 days) | $2 |
| **AWS Systems Manager Parameter Store** | Configuration management | - 50+ parameters<br>- Encrypted with KMS<br>- Used for:<br>  - API URLs<br>  - Cognito IDs<br>  - S3 bucket names<br>  - Feature flags | Free |
| **AWS CloudTrail** | API audit logging | - All API calls logged<br>- S3 storage<br>- CloudWatch Logs integration<br>- 90-day retention | $2 |
| **Amazon GuardDuty** | Threat detection | - Continuous monitoring<br>- ML-based anomaly detection<br>- VPC Flow Logs analysis<br>- DNS logs analysis | $5 |
| **AWS Config** | Resource compliance monitoring | - Configuration recording<br>- Compliance rules<br>- Change tracking | $3 |
| **AWS Certificate Manager (ACM)** | SSL/TLS certificate management | - Certificates for CloudFront<br>- Certificates for API Gateway<br>- Auto-renewal | Free |

**Total Security Layer:** ~$16/month

---

### 9. **Monitoring & Observability Layer** (Logging, Metrics, Alarms)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon CloudWatch Logs** | Centralized logging | **Log Groups:**<br>- `/aws/lambda/stream-processor`<br>- `/aws/lambda/api-handler`<br>- `/aws/rds/postgresql`<br>- `/aws/iot/rules`<br>- `/aws/apigateway/ecovolt-dev-api`<br><br>**Retention:** 7 days (dev), 30 days (prod) | $5 |
| **CloudWatch Metrics** | Performance monitoring | **Custom Metrics:**<br>- Lambda invocations, errors, duration<br>- API Gateway requests, latency<br>- DynamoDB read/write capacity<br>- Kinesis incoming records<br>- RDS CPU, connections<br><br>**Standard Metrics:** All AWS services | $3 |
| **CloudWatch Alarms** | Automated alerting | **Alarms:**<br>- Lambda error rate > 1%<br>- Lambda throttles > 0<br>- API Gateway 5xx > 5%<br>- DynamoDB throttles > 0<br>- RDS storage < 10GB<br>- Kinesis iterator age > 60s<br>- Budget > 80% forecast | $1 |
| **CloudWatch Dashboards** | Visual monitoring | - System overview dashboard<br>- IoT pipeline dashboard<br>- API performance dashboard<br>- Cost dashboard | $3 |
| **Amazon SNS** | Notification delivery | **Topics:**<br>- `critical-alerts` (PagerDuty)<br>- `warnings` (Email)<br>- `budget-alerts` (Email) | $1 |
| **AWS X-Ray** | Distributed tracing (optional) | - Lambda tracing<br>- API Gateway tracing<br>- Service map visualization | $0 (not enabled in dev) |

**Total Monitoring Layer:** ~$13/month

---

### 10. **Content Delivery & DNS Layer** (Global Distribution)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon CloudFront** | Global CDN | - 2 distributions (admin portal, mobile assets)<br>- Edge locations: Global<br>- SSL/TLS: ACM certificates<br>- Caching: 24 hours<br>- Compression: Gzip/Brotli | $5 |
| **Amazon Route 53** | DNS management | - Hosted zone: `ecovolt.io`<br>- Records: A, CNAME, TXT<br>- Health checks (prod)<br>- Geolocation routing (future) | $1 |

**Total CDN Layer:** ~$6/month

---

### 11. **Analytics & Business Intelligence Layer** (Future)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **Amazon Athena** | SQL queries on S3 data lake | - Query S3 data without loading<br>- Hive partitioning support<br>- Pay per query | $0 (not used yet) |
| **Amazon QuickSight** | Business intelligence dashboards | - Admin dashboards<br>- Usage analytics<br>- Financial reports | $0 (not deployed yet) |
| **AWS Glue** | ETL and data catalog | - Data catalog for S3<br>- ETL jobs (bronze → silver → gold)<br>- Schema discovery | $0 (not deployed yet) |

**Total Analytics Layer:** ~$0/month (future)

---

### 12. **DevOps & CI/CD Layer** (Automation)

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **AWS CodePipeline** | CI/CD orchestration (future) | - Pipeline: Source → Build → Deploy<br>- GitHub integration | $0 (using GitHub Actions) |
| **AWS CodeBuild** | Build automation (future) | - Docker builds<br>- Lambda packaging | $0 (using GitHub Actions) |
| **AWS CodeDeploy** | Deployment automation (future) | - Lambda deployments<br>- Blue/green deployments | $0 (using Terraform) |
| **Amazon ECR** | Container registry (future) | - Docker images for Lambda<br>- Private registry | $0 (not used yet) |
| **AWS Systems Manager Session Manager** | Secure shell access | - Bastion-less SSH<br>- Audit logging | Free |

**Total DevOps Layer:** ~$0/month (using GitHub Actions + Terraform)

---

### 13. **Backup & Disaster Recovery Layer**

| Service | Purpose | Configuration | Cost/Month |
|---------|---------|---------------|------------|
| **AWS Backup** | Centralized backup management | - RDS automated backups (7 days)<br>- DynamoDB point-in-time recovery<br>- S3 versioning | $2 |
| **S3 Versioning** | Object-level backup | - Enabled on all critical buckets<br>- Lifecycle policies for old versions | Included |
| **DynamoDB Point-in-Time Recovery** | Continuous backups | - 35-day recovery window<br>- Per-table basis | $2 |
| **RDS Automated Snapshots** | Database backups | - Daily snapshots<br>- 7-day retention (dev)<br>- 30-day retention (prod) | Included |

**Total Backup Layer:** ~$4/month

---

## 💰 Total Cost Breakdown by Layer

| Layer | Monthly Cost (Dev) | Monthly Cost (Prod) |
|-------|-------------------|---------------------|
| **1. Ingestion** | $5 | $10 |
| **2. Buffering/Streaming** | $27 | $50 |
| **3. Compute** | $15 | $100 |
| **4. Database** | $80 | $300 |
| **5. Networking** | $14 | $42 |
| **6. API & Application** | $15 | $50 |
| **7. Authentication** | $0 | $50 |
| **8. Security** | $16 | $30 |
| **9. Monitoring** | $13 | $40 |
| **10. CDN & DNS** | $6 | $20 |
| **11. Analytics** | $0 | $100 |
| **12. DevOps** | $0 | $0 |
| **13. Backup & DR** | $4 | $20 |
| **TOTAL** | **~$195/month** | **~$812/month** |

**Note:** Actual costs may vary based on usage. Development environment uses minimal resources.

---

## 🎯 Cost Optimization Strategies Implemented

### 1. **No NAT Gateway Architecture**
- **Savings:** $40/month per AZ × 3 AZs = **$120/month**
- **Method:** VPC Endpoints + Terraform secret injection + Offline JWT validation

### 2. **Polyglot Persistence**
- **Savings:** ~$110/month vs single RDS instance
- **Method:** Right database for each workload (DynamoDB, InfluxDB, RDS, S3)

### 3. **Serverless Compute**
- **Savings:** ~$200/month vs EC2 instances
- **Method:** Lambda pay-per-use, scales to zero

### 4. **On-Demand Pricing**
- **Savings:** Variable, no idle costs
- **Method:** DynamoDB on-demand, Lambda pay-per-invocation

### 5. **S3 Lifecycle Policies**
- **Savings:** 70% storage costs after 90 days
- **Method:** Automatic archival to Glacier

### 6. **CloudFront Caching**
- **Savings:** Reduced API Gateway costs
- **Method:** 24-hour cache for static assets

### 7. **Reserved Capacity (Production)**
- **Savings:** 40% discount on RDS
- **Method:** 1-year reserved instances

**Total Savings:** ~$450/month compared to traditional architecture

---

## 📊 Service Count Summary

| Category | Service Count | Key Services |
|----------|---------------|--------------|
| **Compute** | 4 | Lambda (4 functions) |
| **Storage** | 9 | DynamoDB (7 tables), RDS (1), S3 (5 buckets) |
| **Networking** | 15+ | VPC, Subnets (9), VPC Endpoints (4), Security Groups (6+) |
| **Security** | 8 | KMS, Secrets Manager, IAM, CloudTrail, GuardDuty, Config, ACM, Cognito |
| **Monitoring** | 6 | CloudWatch (Logs, Metrics, Alarms, Dashboards), SNS, X-Ray |
| **IoT & Streaming** | 4 | IoT Core, IoT Rules (3), Kinesis Streams, Kinesis Firehose |
| **API & CDN** | 4 | API Gateway, CloudFront (2), Route 53 |
| **Analytics** | 3 | Athena, QuickSight, Glue (future) |
| **DevOps** | 5 | CodePipeline, CodeBuild, CodeDeploy, ECR, Systems Manager (future) |
| **Backup** | 4 | AWS Backup, S3 Versioning, DynamoDB PITR, RDS Snapshots |
| **TOTAL** | **62+ Services** | Across 13 architectural layers |

---

## 🏗️ Architecture Patterns Used

### 1. **Polyglot & Fan-Out Pattern**
- Single ingestion point (IoT Core → Kinesis)
- Multiple consumers (Lambda → DynamoDB/InfluxDB, Firehose → S3)
- Right database for each workload

### 2. **Serverless-First**
- Lambda for all compute
- API Gateway for REST API
- DynamoDB for state
- S3 for storage

### 3. **Private Subnet Architecture**
- Lambda in private subnets
- No NAT Gateway
- VPC Endpoints for AWS services
- RDS in data subnets (no public access)

### 4. **Event-Driven Architecture**
- IoT Core publishes events
- Kinesis streams events
- Lambda consumes events
- SNS for notifications

### 5. **Immutable Infrastructure**
- Infrastructure as Code (Terraform)
- No manual changes
- Version controlled
- Reproducible deployments

---

## 📚 References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS IoT Core Best Practices](https://docs.aws.amazon.com/iot/latest/developerguide/iot-best-practices.html)
- [Serverless Architectures with AWS Lambda](https://d1.awsstatic.com/whitepapers/serverless-architectures-with-aws-lambda.pdf)
- [Cost Optimization Pillar](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)
- [AWS Pricing Calculator](https://calculator.aws/)

---

**Last Updated:** November 29, 2025  
**Architecture Version:** 2.0 (Polyglot & Fan-Out)  
**Total Resources:** 359 AWS resources deployed  
**Test Status:** ✅ 100% pass rate (5/5 phases)
