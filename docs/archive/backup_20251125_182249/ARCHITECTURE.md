# EcoVolt AWS Infrastructure Architecture

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                   │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    VPC (Multi-AZ)                                   │ │
│  │                                                                      │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │ │
│  │  │ Public       │  │ Private      │  │ Data         │             │ │
│  │  │ Subnets      │  │ Subnets      │  │ Subnets      │             │ │
│  │  │              │  │              │  │              │             │ │
│  │  │ - NAT GW     │  │ - Lambda     │  │ - RDS        │             │ │
│  │  │ - ALB        │  │ - ECS        │  │ - ElastiCache│             │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘             │ │
│  │                                                                      │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                         IoT Core                                    │ │
│  │  - Device Registry (X.509 auth)                                    │ │
│  │  - Message Broker (MQTT)                                           │ │
│  │  - Rules Engine → Kinesis                                          │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    Analytics Pipeline                               │ │
│  │  Kinesis → Lambda → Timestream/S3 → Athena                         │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                    Monitoring & Alerting                            │ │
│  │  CloudWatch → SNS → Email/SMS                                       │ │
│  │  AWS Budgets → SNS → Cost Alerts                                    │ │
│  └────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
         ▲                                    │
         │                                    │
    IoT Devices                          CloudFront
    (EVs, Stations)                      (User Apps)
```

## Data Flow

### 1. IoT Telemetry Flow
```
EV/Station → IoT Core (MQTT) → IoT Rules → Kinesis Stream → Lambda → Timestream
                                                                    └→ S3 (Archive)
```

### 2. API Request Flow
```
User/App → CloudFront → API Gateway → Lambda → RDS/ElastiCache
                                              └→ Response
```

### 3. Analytics Query Flow
```
Analyst → Athena → S3 Data Lake → Results
       → Timestream → Recent Data → Results
```

### 4. Monitoring Flow
```
All Services → CloudWatch Metrics → Alarms → SNS → Email/SMS
            → CloudWatch Logs → Log Insights → Analysis
```

### 5. Cost Monitoring Flow
```
AWS Services → AWS Budgets → Threshold Check → SNS → Email/SMS Alerts
```

## Network Architecture

### Subnet Design (3 AZs)

```
VPC: 10.0.0.0/16

AZ-A (us-east-1a):
├── Public:  10.0.1.0/24   (NAT GW, ALB)
├── Private: 10.0.11.0/24  (Lambda, ECS)
└── Data:    10.0.21.0/24  (RDS, ElastiCache)

AZ-B (us-east-1b):
├── Public:  10.0.2.0/24   (NAT GW, ALB)
├── Private: 10.0.12.0/24  (Lambda, ECS)
└── Data:    10.0.22.0/24  (RDS, ElastiCache)

AZ-C (us-east-1c):
├── Public:  10.0.3.0/24   (NAT GW, ALB)
├── Private: 10.0.13.0/24  (Lambda, ECS)
└── Data:    10.0.23.0/24  (RDS, ElastiCache)
```

### Security Groups

```
┌─────────────────────────────────────────────────────────────┐
│ Internet → ALB SG (80, 443)                                 │
│            ↓                                                 │
│         Lambda SG (all from ALB)                            │
│            ↓                                                 │
│         RDS SG (5432 from Lambda)                           │
│         ElastiCache SG (6379 from Lambda)                   │
└─────────────────────────────────────────────────────────────┘
```

## Module Dependencies

```
networking (foundation)
    ↓
security (KMS, CloudTrail)
    ↓
├── iot (requires Kinesis from analytics)
├── analytics (requires KMS)
├── database (requires networking, security)
├── compute (requires networking, database, analytics)
├── monitoring (requires all modules)
├── billing (independent)
├── edge-computing (requires IoT)
├── content-delivery (independent)
├── compliance (independent)
└── disaster-recovery (requires database, analytics)
```

## Deployment Order

1. **Networking** - Foundation for all other modules
2. **Security** - KMS keys needed by other modules
3. **Analytics** - Kinesis stream needed by IoT
4. **IoT** - Device connectivity
5. **Database** - Data persistence
6. **Compute** - Application logic
7. **Monitoring** - Observability
8. **Billing** - Cost management
9. **Edge Computing** - Edge processing
10. **Content Delivery** - Static assets
11. **Compliance** - Governance
12. **Disaster Recovery** - Business continuity

## Scaling Considerations

### Horizontal Scaling
- **Lambda**: Automatic (up to account limits)
- **API Gateway**: Automatic
- **Kinesis**: Add shards as needed
- **RDS**: Add read replicas

### Vertical Scaling
- **RDS**: Change instance class
- **ElastiCache**: Change node type
- **Lambda**: Increase memory/timeout

### Geographic Scaling
- **CloudFront**: Already global
- **Multi-Region**: Deploy to additional regions
- **Route 53**: Geographic routing

## High Availability

### Implemented
- ✅ Multi-AZ VPC
- ✅ RDS Multi-AZ (automatic failover)
- ✅ Multiple NAT Gateways
- ✅ Lambda across multiple AZs
- ✅ CloudFront global edge locations

### Recommended Additions
- RDS read replicas for read scaling
- Multi-region deployment
- Route 53 health checks and failover
- DynamoDB global tables

## Security Architecture

### Defense in Depth

```
Layer 1: Network (VPC, Security Groups, NACLs)
    ↓
Layer 2: Identity (IAM, X.509 certificates)
    ↓
Layer 3: Data (KMS encryption, TLS)
    ↓
Layer 4: Monitoring (CloudTrail, GuardDuty, Config)
    ↓
Layer 5: Response (CloudWatch Alarms, SNS)
```

### Encryption

- **At Rest**: KMS customer-managed keys
- **In Transit**: TLS 1.2+
- **Backups**: Encrypted with same KMS key
- **Logs**: Encrypted in CloudWatch

## Cost Optimization

### Implemented
- ✅ Auto-scaling (Lambda, RDS storage)
- ✅ S3 lifecycle policies
- ✅ Appropriate instance sizing
- ✅ Budget alerts
- ✅ Resource tagging

### Recommendations
- Purchase Reserved Instances for RDS
- Use Savings Plans for Lambda
- Enable S3 Intelligent-Tiering
- Review and optimize Lambda memory
- Use Spot Instances for non-critical workloads

## Monitoring Strategy

### Metrics Collected
- Lambda: Invocations, errors, duration, throttles
- API Gateway: Requests, 4xx/5xx errors, latency
- RDS: CPU, connections, storage, replication lag
- Kinesis: Iterator age, throttling
- IoT: Connection failures, message rates

### Alerting Thresholds
- **Critical**: 5xx errors, database down, storage < 10GB
- **Warning**: 4xx errors > 10%, CPU > 80%, latency > 1s
- **Info**: Budget > 80%, unusual traffic patterns

### Dashboard Widgets
- System health overview
- Request rates and errors
- Database performance
- Cost trends
- IoT device status

## Compliance

### Standards Supported
- **Encryption**: FIPS 140-2 (KMS)
- **Audit**: CloudTrail logging
- **Access Control**: IAM least-privilege
- **Network**: VPC isolation
- **Monitoring**: CloudWatch, Config

### Compliance Checks
- AWS Config Rules for encryption
- Security group validation
- Backup verification
- Access logging

## References

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS IoT Core Documentation](https://docs.aws.amazon.com/iot/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terratest Documentation](https://terratest.gruntwork.io/)
