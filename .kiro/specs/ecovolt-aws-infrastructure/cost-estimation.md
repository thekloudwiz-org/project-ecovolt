# EcoVolt AWS Infrastructure - Cost Estimation

## Document Overview

This document provides detailed cost estimates for the EcoVolt AWS Infrastructure across different deployment scenarios. All estimates are based on AWS US East (N. Virginia) pricing as of November 2024.

## Deployment Configurations

### Proof of Concept (PoC) Configuration

**Target Use Case**: Development, testing, and demonstration
**Scale**: 10 IoT devices, minimal traffic, single region
**Strategy**: Destroy and recreate infrastructure when not in use to minimize costs

#### PoC Architecture Decisions

1. **CloudFront**: ✅ Maintained - Essential for user application delivery
2. **ElastiCache**: ✅ Maintained - Important for backend performance testing
3. **Greengrass**: ✅ Maintained - Core edge computing capability
4. **Backend Compute**: Lambda (instead of ECS) - More cost-effective for low traffic
5. **Networking**: Single NAT Gateway - Sufficient for PoC
6. **Database**: Single-AZ RDS - Acceptable for non-production
7. **Disaster Recovery**: Disabled - Not needed for PoC

---

## Proof of Concept Monthly Cost Estimate

### Assumptions

- **IoT Devices**: 10 total (5 EVs + 5 swap stations)
- **Message Volume**: 1,000 messages/day per device = 10,000 messages/day = 300,000 messages/month
- **Backend Traffic**: < 10,000 API requests/day
- **Data Retention**: 30 days
- **Uptime**: 8 hours/day, 5 days/week (160 hours/month) - destroy when not in use
- **Region**: Single region (us-east-1)

---

## Detailed Cost Breakdown

### 1. Networking ($15-20/month)

| Service | Configuration | Monthly Cost | Notes |
|---------|--------------|--------------|-------|
| VPC | 1 VPC, 6 subnets | $0 | Free |
| NAT Gateway | 1 NAT @ 160 hrs/month | $7.20 | $0.045/hour × 160 hours |
| Internet Gateway | 1 IGW | $0 | Free |
| Data Transfer Out | ~50 GB/month | $4.50 | $0.09/GB after first 100GB free |
| VPC Flow Logs | CloudWatch Logs | $3-5 | Included in CloudWatch costs |
| **Subtotal** | | **$11.70-16.70** | |

**Cost Optimization**:
- Destroy NAT Gateway when not in use: **Save $7.20/month**
- Use VPC Endpoints for S3/DynamoDB: **Save ~$2-3/month on data transfer**

---

### 2. IoT Services ($20-30/month)

| Service | Configuration | Monthly Cost | Notes |
|---------|--------------|--------------|-------|
| **IoT Core** | | | |
| - Connectivity | 10 devices × 160 hrs | $1.20 | $0.08 per million connection-minutes |
| - Messaging | 300K messages | $0.30 | $1.00 per million messages |
| - Rules Engine | 300K actions | $0.45 | $1.50 per million actions |
| **IoT Device Management** | | | |
| - Fleet Indexing | 10 devices | $0.10 | $0.001 per 1000 updates |
| - Remote Actions | Minimal | $0.50 | Job executions |
| **IoT Greengrass** | | | |
| - Core Devices | 5 swap stations | $16.00 | $0.16/device/month × 5 × 20 days |
| - Component Deployments | 10 deployments | $1.00 | $0.10 per deployment |
| **Subtotal** | | **$19.55** | |

**Cost Optimization**:
- Use IoT Core message batching: **Save ~$0.10-0.20/month**
- Optimize Greengrass component size: **Save ~$2-3/month**

---

### 3. Compute ($25-35/month)

| Service | Configuration | Monthly Cost | Notes |
|---------|--------------|--------------|-------|
| **Lambda Functions** | | | |
| - Backend API | 300K invocations, 512MB, 1s avg | $6.00 | Includes compute + requests |
| - Stream Processing | 300K invocations, 1024MB, 2s avg | $12.00 | Kinesis consumers |
| - Data Transformation | 50K invocations, 512MB, 500ms | $1.50 | ETL operations |
| **Application Load Balancer** | 160 hours/month | $3.60 | $0.0225/hour × 160 hours |
| - LCU Hours | Minimal | $1.00 | Load Balancer Capacity Units |
| **API Gateway** (Optional) | 300K requests | $1.05 | $3.50 per million requests |
| **Subtotal** | | **$25.15** | |

**Cost Optimization**:
- Use Lambda@Edge instead of ALB: **Save ~$4/month**
- Optimize Lambda memory allocation: **Save ~$3-5/month**
- Use Lambda reserved concurrency: **Save ~$2-3/month for predictable workloads**

---

### 4. Database & Caching ($35-45/month)

| Service | Configuration | Monthly Cost | Notes |
|---------|--------------|--------------|-------|
| **RDS PostgreSQL** | | | |
| - Instance | db.t3.micro, Single-AZ, 160 hrs | $5.60 | $0.035/hour × 160 hours |
| - Storage | 20 GB gp3 | $2.40 | $0.12/GB-month |
| - Backup Storage | 20 GB | $2.00 | $0.10/GB-month |
| **ElastiCache Redis** | | | |
| - Instance | cache.t3.micro, 160 hrs | $5.28 | $0.033/hour × 160 hours |
| **Amazon Timestream** | | | |
| - Memory Store Writes | 300K writes | $1.50 | $0.50 per million writes |
| - Memory Store Storage | 1 GB-hour | $0.04 | $0.036/GB-hour |
| - Magnetic Store Storage | 5 GB | $0.15 | $0.03/GB-month |
| - Queries | 10 GB scanned | $5.00 | $0.50/GB scanned |
| **Subtotal** | | **$21.97** | |

**Cost Optimization**:
- Stop RDS when not in use: **Save $5.60/month**
- Use Aurora Serverless v2: **Pay only for actual usage**
- Reduce Timestream query frequency: **Save ~$2-3/month**

---

### 5. Analytics & Storage ($25-35/month)

| Service | Configuration | Monthly Cost | Notes |
|---------|--------------|--------------|-------|
| **Kinesis Data Streams** | | | |
| - Shard Hours | 1 shard × 160 hrs | $2.40 | $0.015/shard-hour × 160 hours |
| - PUT Payload Units | 300K records | $0.43 | $0.014 per 1M units |
| **Kinesis Data Firehose** | | | |
| - Data Ingestion | 1 GB | $0.03 | $0.029/GB |
| **S3 Storage** | | | |
| - Standard Storage | 50 GB | $1.15 | $0.023/GB |
| - Requests | 100K PUT, 500K GET | $0.55 | Various pricing |
| **AWS Glue** | | | |
| - Crawler | 2 runs/month | $0.88 | $0.44/DPU-hour |
| - ETL Jobs | 5 runs, 2 DPU each | $2.20 | $0.44/DPU-hour |
| **Amazon Athena** | | | |
| - Queries | 20 GB scanned | $10.00 | $5.00/TB scanned |
| **Subtotal** | | **$17.64** | |

**Cost Optimization**:
- Use S3 Intelligent-Tiering: **Save ~$0.30-0.50/month**
- Partition data in S3: **Save ~$5-7/month on Athena queries**
- Reduce Kinesis shard count during off-hours: **Save ~$1-2/month**

---

### 6. Security & Compliance ($10-15/month)

| Service | Configuration | Monthly Cost | Notes |
|---------|--------------|--------------|-------|
| **AWS KMS** | | | |
| - Customer Managed Keys | 2 keys | $2.00 | $1.00/key/month |
| - API Requests | 50K requests | $0.15 | $0.03 per 10K requests |
| **AWS CloudTrail** | | | |
| - Management Events | 1 trail | $0 | First trail free |
| - Data Events | Minimal | $1.00 | $0.10 per 100K events |
| **AWS Secrets Manager** | | | |
| - Secrets | 3 secrets | $1.20 | $0.40/secret/month |
| - API Calls | 10K calls | $0.05 | $0.05 per 10K calls |
| **GuardDuty** (Optional) | 160 hours | $3-5 | Prorated for usage |
| **AWS Config** | | | |
| - Config Rules | 5 rules | $2.00 | $0.001 per evaluation (first 100K free) |
| **Subtotal** | | **$9.40-14.40** | |

**Cost Optimization**:
- Disable GuardDuty for PoC: **Save $3-5/month**
- Reduce Config rule evaluations: **Save ~$1/month**

---

### 7. Monitoring & Logging ($8-12/month)

| Service | Configuration | Monthly Cost | Notes |
|---------|--------------|--------------|-------|
| **CloudWatch Logs** | | | |
| - Ingestion | 5 GB | $2.50 | $0.50/GB |
| - Storage | 5 GB | $0.25 | $0.03/GB after first 5GB free |
| **CloudWatch Metrics** | | | |
| - Custom Metrics | 50 metrics | $1.50 | $0.30 per metric |
| - API Requests | 100K requests | $0.10 | $0.01 per 1K requests |
| **CloudWatch Alarms** | | | |
| - Standard Alarms | 10 alarms | $1.00 | $0.10 per alarm |
| **CloudWatch Dashboards** | | | |
| - Custom Dashboards | 2 dashboards | $6.00 | $3.00 per dashboard |
| **X-Ray** (Optional) | | | |
| - Traces | 100K traces | $0.50 | $5.00 per million traces |
| **Subtotal** | | **$11.85** | |

**Cost Optimization**:
- Reduce log retention to 7 days: **Save ~$1-2/month**
- Use metric filters instead of custom metrics: **Save ~$0.50-1/month**
- Disable X-Ray for PoC: **Save $0.50/month**

---

### 8. Content Delivery ($3-8/month)

| Service | Configuration | Monthly Cost | Notes |
|---------|--------------|--------------|-------|
| **CloudFront** | | | |
| - Data Transfer Out | 10 GB | $0.85 | $0.085/GB |
| - HTTP/HTTPS Requests | 100K requests | $0.10 | $0.0075 per 10K requests |
| **Route 53** | | | |
| - Hosted Zone | 1 zone | $0.50 | $0.50/zone/month |
| - Queries | 1M queries | $0.40 | $0.40 per million queries |
| **ACM** | | | |
| - SSL/TLS Certificates | 2 certs | $0 | Free for public certs |
| **Subtotal** | | **$1.85** | |

**Cost Optimization**:
- Use CloudFront free tier: **First 1TB free for 12 months**
- Cache static assets aggressively: **Save ~$0.20-0.50/month**

---

### 9. Billing & Cost Management ($0-2/month)

| Service | Configuration | Monthly Cost | Notes |
|---------|--------------|--------------|-------|
| **AWS Budgets** | | | |
| - Budgets | 7 budgets | $0 | First 2 free, $0.02 each after |
| - Budget Actions | 10 actions | $0.10 | $0.10 per action |
| **SNS** (for budget alerts) | | | |
| - Topics | 2 topics | $0 | Free |
| - Email Notifications | 100 emails | $0 | First 1000 free |
| - SMS Notifications | 10 SMS | $0.65 | $0.00645 per SMS (US) |
| **Subtotal** | | **$0.75** | |

---

## Total PoC Cost Summary

### Monthly Cost (160 hours/month usage)

| Category | Cost Range |
|----------|------------|
| Networking | $11.70 - $16.70 |
| IoT Services | $19.55 |
| Compute (Lambda) | $25.15 |
| Database & Caching | $21.97 |
| Analytics & Storage | $17.64 |
| Security & Compliance | $9.40 - $14.40 |
| Monitoring & Logging | $11.85 |
| Content Delivery | $1.85 |
| Billing & Cost Management | $0.75 |
| **TOTAL** | **$119.86 - $128.86** |

### With Optimizations: $95-110/month

---

## Hourly Cost Breakdown (When Running)

| Component | Hourly Cost |
|-----------|-------------|
| NAT Gateway | $0.045 |
| RDS PostgreSQL | $0.035 |
| ElastiCache Redis | $0.033 |
| Kinesis Data Streams | $0.015 |
| Application Load Balancer | $0.0225 |
| Lambda (on-demand) | Variable |
| Other Services | ~$0.10 |
| **Total** | **~$0.26/hour** |

**Daily Cost (8 hours)**: ~$2.08
**Weekly Cost (5 days × 8 hours)**: ~$10.40
**Monthly Cost (20 days × 8 hours)**: ~$41.60 (infrastructure only)

---

## Cost Management Strategy for PoC

### Destroy/Recreate Workflow

**Services to Destroy When Not in Use:**
1. ✅ NAT Gateway - **Save $0.045/hour**
2. ✅ RDS Instance - **Save $0.035/hour**
3. ✅ ElastiCache - **Save $0.033/hour**
4. ✅ Application Load Balancer - **Save $0.0225/hour**
5. ✅ Kinesis Shards - **Save $0.015/hour**

**Services That Persist (Low/No Cost):**
- VPC, Subnets, Route Tables (Free)
- S3 Storage (Pay only for storage: ~$1-2/month)
- Lambda Functions (Pay only for invocations: $0 when idle)
- IoT Thing Registry (Minimal cost)
- CloudWatch Logs (Pay for storage: ~$0.25/month)

**Terraform Destroy/Apply Strategy:**
```bash
# End of work session
terraform destroy -target=module.compute \
                  -target=module.database \
                  -target=module.analytics \
                  -target=module.networking.aws_nat_gateway

# Start of work session
terraform apply
```

**Estimated Savings**: ~$0.18/hour × 16 hours/day × 20 days = **~$57.60/month**

---

## Production Cost Estimate (For Reference)

### Assumptions
- **IoT Devices**: 1,000 devices
- **Message Volume**: 10 million messages/month
- **Backend Traffic**: 1 million API requests/day
- **High Availability**: Multi-AZ, Multi-Region
- **24/7 Uptime**

### Estimated Monthly Cost: $2,500 - $3,500/month

| Category | PoC Cost | Production Cost | Multiplier |
|----------|----------|-----------------|------------|
| Networking | $12-17 | $150-200 | 12x |
| IoT Services | $20 | $300-400 | 15-20x |
| Compute | $25 | $400-600 | 16-24x |
| Database | $22 | $300-400 | 14-18x |
| Analytics | $18 | $400-500 | 22-28x |
| Security | $10-14 | $100-150 | 10x |
| Monitoring | $12 | $150-200 | 12-17x |
| Content Delivery | $2 | $200-300 | 100-150x |
| Disaster Recovery | $0 | $400-500 | N/A |
| **TOTAL** | **$120-129** | **$2,500-3,500** | **20-27x** |

---

## Cost Optimization Best Practices

### Immediate Actions
1. ✅ **Use Lambda instead of ECS** - Save ~$30-50/month
2. ✅ **Single NAT Gateway** - Save ~$65/month (vs 3 NAT Gateways)
3. ✅ **Single-AZ RDS** - Save ~$15-20/month
4. ✅ **Destroy when not in use** - Save ~$58/month
5. ✅ **Use S3 Intelligent-Tiering** - Save ~$0.50-1/month

### Ongoing Optimizations
1. **Right-size Lambda memory** - Monitor and adjust based on actual usage
2. **Optimize Kinesis shards** - Scale down during low traffic
3. **Use S3 lifecycle policies** - Move old data to Glacier
4. **Reduce log retention** - Keep only 7-14 days for PoC
5. **Batch IoT messages** - Reduce message count and costs
6. **Use CloudFront caching** - Reduce origin requests
7. **Monitor with Cost Explorer** - Identify unexpected costs weekly

### AWS Free Tier Benefits (First 12 Months)
- **750 hours/month** of t2.micro/t3.micro EC2/RDS
- **1 million Lambda requests/month** + 400,000 GB-seconds compute
- **5 GB S3 storage** + 20,000 GET requests
- **1 million IoT messages/month**
- **10 GB CloudWatch Logs**
- **1 TB CloudFront data transfer**

**With Free Tier**: Reduce PoC costs to **$50-70/month** for first year

---

## Budget Recommendations

### PoC Budget Allocation

| Budget Type | Monthly Limit | Alert Threshold |
|-------------|---------------|-----------------|
| Overall AWS Spending | $150 | 80% ($120) |
| Compute (Lambda) | $40 | 80% ($32) |
| Database & Caching | $30 | 80% ($24) |
| IoT Services | $30 | 80% ($24) |
| Analytics & Storage | $25 | 80% ($20) |
| Networking | $20 | 80% ($16) |
| Other Services | $5 | 80% ($4) |

### Cost Alerts
- **Email alerts** at 80%, 90%, 100% of budget
- **SMS alerts** at 90% and 100% of budget
- **Forecasted alerts** when projected to exceed budget

---

## Cost Tracking & Reporting

### Weekly Cost Review Checklist
- [ ] Review AWS Cost Explorer for unexpected charges
- [ ] Check top 5 cost-driving services
- [ ] Verify resources are destroyed when not in use
- [ ] Review CloudWatch metrics for optimization opportunities
- [ ] Check for idle resources (unused EIPs, unattached volumes)

### Monthly Cost Report
- Total spend vs budget
- Cost breakdown by service
- Cost trends (week-over-week)
- Optimization opportunities identified
- Forecast for next month

---

## Appendix: Service Pricing References

### AWS Pricing Pages (as of November 2024)
- [VPC Pricing](https://aws.amazon.com/vpc/pricing/)
- [IoT Core Pricing](https://aws.amazon.com/iot-core/pricing/)
- [Lambda Pricing](https://aws.amazon.com/lambda/pricing/)
- [RDS Pricing](https://aws.amazon.com/rds/postgresql/pricing/)
- [ElastiCache Pricing](https://aws.amazon.com/elasticache/pricing/)
- [Kinesis Pricing](https://aws.amazon.com/kinesis/data-streams/pricing/)
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [CloudWatch Pricing](https://aws.amazon.com/cloudwatch/pricing/)

### Cost Calculators
- [AWS Pricing Calculator](https://calculator.aws/)
- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)

---

## Document Maintenance

**Last Updated**: November 2024
**Next Review**: Monthly or when AWS pricing changes
**Owner**: EcoVolt Infrastructure Team

**Note**: Prices are estimates based on AWS US East (N. Virginia) region and may vary by region and actual usage patterns. Always verify current pricing on AWS pricing pages.
