# EcoVolt - Cost Estimation

## Overview

This document provides detailed cost estimates for the EcoVolt platform across different deployment scenarios. All estimates are based on AWS EU Central 1 (Frankfurt) pricing as of November 2024.

## Deployment Configurations

### Proof of Concept (PoC)
- **Target**: Development, testing, demonstration
- **Scale**: 10 IoT devices, minimal traffic
- **Strategy**: Destroy/recreate when not in use
- **Monthly Cost**: **$120-130**

### Staging
- **Target**: Pre-production testing
- **Scale**: 100 IoT devices, moderate traffic
- **Strategy**: Production-like, multi-AZ
- **Monthly Cost**: **$800-1000**

### Production
- **Target**: Live environment
- **Scale**: 1000+ IoT devices, high traffic
- **Strategy**: Full HA, multi-AZ, DR enabled
- **Monthly Cost**: **$2500-3500**

## PoC Cost Breakdown (160 hours/month usage)

### Assumptions
- **IoT Devices**: 10 total (5 bikes + 5 stations)
- **Messages**: 300,000/month
- **API Requests**: <10,000/day
- **Uptime**: 8 hours/day, 5 days/week
- **Region**: eu-central-1

### Detailed Costs

| Category | Service | Monthly Cost | Notes |
|----------|---------|--------------|-------|
| **Networking** | | **$12-17** | |
| | NAT Gateway | $7.20 | $0.045/hour × 160 hours |
| | Data Transfer | $4.50 | ~50 GB/month |
| **IoT Services** | | **$20** | |
| | IoT Core Connectivity | $1.20 | 10 devices × 160 hrs |
| | IoT Core Messaging | $0.30 | 300K messages |
| | IoT Rules Engine | $0.45 | 300K actions |
| | IoT Greengrass | $16.00 | 5 stations |
| **Compute** | | **$25** | |
| | Lambda Functions | $19.50 | API + processing |
| | API Gateway | $1.05 | 300K requests |
| | ALB | $4.60 | 160 hours |
| **Database** | | **$22** | |
| | RDS PostgreSQL | $5.60 | db.t3.micro × 160 hrs |
| | RDS Storage | $2.40 | 20 GB gp3 |
| | RDS Backups | $2.00 | 20 GB |
| | ElastiCache Redis | $5.28 | cache.t3.micro × 160 hrs |
| | Timestream | $6.69 | Memory + magnetic store |
| **Analytics** | | **$18** | |
| | Kinesis Streams | $2.40 | 1 shard × 160 hrs |
| | S3 Storage | $1.15 | 50 GB |
| | Athena | $10.00 | 20 GB scanned |
| | Glue | $3.08 | Crawlers + ETL |
| **Security** | | **$9-14** | |
| | KMS | $2.15 | 2 keys + requests |
| | Secrets Manager | $1.25 | 3 secrets |
| | CloudTrail | $1.00 | Data events |
| | GuardDuty | $3-5 | Optional |
| | Config | $2.00 | 5 rules |
| **Monitoring** | | **$12** | |
| | CloudWatch Logs | $2.75 | 5 GB ingestion + storage |
| | CloudWatch Metrics | $1.50 | 50 custom metrics |
| | CloudWatch Alarms | $1.00 | 10 alarms |
| | CloudWatch Dashboards | $6.00 | 2 dashboards |
| | X-Ray | $0.50 | 100K traces |
| **Content Delivery** | | **$2** | |
| | CloudFront | $0.95 | 10 GB + requests |
| | Route 53 | $0.90 | Hosted zone + queries |
| **Billing** | | **$1** | |
| | AWS Budgets | $0.10 | Budget actions |
| | SNS | $0.65 | SMS notifications |
| | | | |
| **TOTAL** | | **$120-130** | |

## Cost Optimization Strategies

### Immediate Actions
1. **Use Lambda instead of ECS** - Save ~$30-50/month
2. **Single NAT Gateway** - Save ~$65/month (vs 3 NAT Gateways)
3. **Single-AZ RDS** - Save ~$15-20/month
4. **Destroy when not in use** - Save ~$58/month
5. **Use S3 Intelligent-Tiering** - Save ~$0.50-1/month

### Ongoing Optimizations
1. **Right-size Lambda memory** - Monitor and adjust
2. **Optimize Kinesis shards** - Scale down during low traffic
3. **Use S3 lifecycle policies** - Move old data to Glacier
4. **Reduce log retention** - Keep only 7-14 days for PoC
5. **Batch IoT messages** - Reduce message count
6. **Use CloudFront caching** - Reduce origin requests
7. **Monitor with Cost Explorer** - Weekly cost reviews

### AWS Free Tier Benefits (First 12 Months)
- **750 hours/month** of t2.micro/t3.micro EC2/RDS
- **1 million Lambda requests/month** + 400,000 GB-seconds
- **5 GB S3 storage** + 20,000 GET requests
- **1 million IoT messages/month**
- **10 GB CloudWatch Logs**
- **1 TB CloudFront data transfer**

**With Free Tier**: Reduce PoC costs to **$50-70/month** for first year

## Production Cost Estimate

### Assumptions
- **IoT Devices**: 1,000 devices
- **Messages**: 10 million/month
- **API Requests**: 1 million/day
- **High Availability**: Multi-AZ, Multi-Region
- **24/7 Uptime**

### Estimated Monthly Cost: $2,500-3,500

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
| **TOTAL** | **$120-130** | **$2,500-3,500** | **20-27x** |

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

## Cost Management Strategy

### Destroy/Recreate Workflow

**Services to Destroy When Not in Use:**
1. ✅ NAT Gateway - Save $0.045/hour
2. ✅ RDS Instance - Save $0.035/hour
3. ✅ ElastiCache - Save $0.033/hour
4. ✅ Application Load Balancer - Save $0.0225/hour
5. ✅ Kinesis Shards - Save $0.015/hour

**Services That Persist (Low/No Cost):**
- VPC, Subnets, Route Tables (Free)
- S3 Storage (~$1-2/month)
- Lambda Functions ($0 when idle)
- IoT Thing Registry (Minimal)
- CloudWatch Logs (~$0.25/month)

**Terraform Strategy:**
```bash
# End of work session
terraform destroy -target=module.compute \
                  -target=module.database \
                  -target=module.analytics \
                  -target=module.networking.aws_nat_gateway

# Start of work session
terraform apply
```

**Estimated Savings**: ~$0.18/hour × 16 hours/day × 20 days = **~$58/month**

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

## Service Pricing References

### AWS Pricing Pages (November 2024)
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

**Last Updated**: November 2024  
**Next Review**: Monthly or when AWS pricing changes  
**Owner**: EcoVolt Infrastructure Team

**Note**: Prices are estimates based on AWS EU Central 1 region and may vary by region and actual usage patterns.

