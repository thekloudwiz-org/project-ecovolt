# AWS Region Configuration

## Primary and DR Regions

### Primary Region: eu-central-1 (Frankfurt)
- **Location**: Frankfurt, Germany
- **Purpose**: Main production infrastructure
- **Services**: All core services deployed here
- **Latency**: Optimal for European and African markets
- **Compliance**: GDPR compliant, data residency in EU

### DR Region: eu-west-1 (Ireland)
- **Location**: Dublin, Ireland  
- **Purpose**: Disaster recovery and backup
- **Services**: RDS read replicas, S3 replication
- **Latency**: Low latency to primary region
- **Compliance**: GDPR compliant, data residency in EU

## Availability Zones

### eu-central-1 (Frankfurt)
- **eu-central-1a**: Primary AZ for production workloads
- **eu-central-1b**: Secondary AZ for high availability
- **eu-central-1c**: Tertiary AZ for additional redundancy

### eu-west-1 (Ireland) - DR Only
- **eu-west-1a**: DR primary AZ
- **eu-west-1b**: DR secondary AZ
- **eu-west-1c**: DR tertiary AZ

## Special Region Requirements

### us-east-1 (N. Virginia) - CloudFront Only
**Important**: CloudFront requires ACM certificates to be created in `us-east-1` regardless of where your infrastructure is deployed.

The infrastructure includes a secondary AWS provider aliased as `aws.us-east-1` specifically for:
- ACM certificates for CloudFront distributions
- WAF Web ACLs for CloudFront (must be in us-east-1)

**This is the ONLY use of us-east-1 in the infrastructure.**

```hcl
# In main.tf
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  
  default_tags {
    tags = local.common_tags
  }
}

# WAF module uses this provider
module "waf" {
  source = "./modules/waf"
  
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
```

## Region Selection Rationale

### Why eu-central-1 (Frankfurt)?

1. **Geographic Location**: 
   - Central location in Europe
   - Good connectivity to Africa (Kenya/Nairobi target market)
   - Lower latency than US regions for European/African users

2. **Service Availability**:
   - All required AWS services available
   - IoT Core fully supported
   - Timestream available
   - IoT Greengrass supported

3. **Compliance**:
   - GDPR compliant
   - Data residency in EU
   - Strong data protection laws

4. **Cost**:
   - Competitive pricing compared to other EU regions
   - Good balance of cost and performance

### Why eu-west-1 (Ireland) for DR?

1. **Proximity**: 
   - Close to primary region (low replication latency)
   - Same continent for data sovereignty

2. **Reliability**:
   - One of AWS's oldest and most stable regions
   - Excellent track record for uptime

3. **Service Parity**:
   - All services available in primary region also available here
   - Ensures seamless failover capability

4. **Network**:
   - High-bandwidth connection to eu-central-1
   - Low latency for cross-region replication

## Environment Configuration

### Development (dev)
```hcl
aws_region = "eu-central-1"
dr_region  = "eu-west-1"
```
- Single AZ deployment to reduce costs
- No cross-region replication
- Minimal resources

### Staging (staging)
```hcl
aws_region = "eu-central-1"
dr_region  = "eu-west-1"
```
- Multi-AZ deployment (3 AZs)
- Optional cross-region replication
- Production-like configuration

### Production (prod)
```hcl
aws_region = "eu-central-1"
dr_region  = "eu-west-1"
```
- Multi-AZ deployment (3 AZs)
- Full cross-region replication
- Maximum redundancy and availability

## Latency Considerations

### From Nairobi, Kenya to AWS Regions

| Region | Typical Latency | Notes |
|--------|----------------|-------|
| eu-central-1 (Frankfurt) | ~180-220ms | Best EU option for Africa |
| eu-west-1 (Ireland) | ~200-240ms | Slightly higher than Frankfurt |
| us-east-1 (N. Virginia) | ~250-300ms | Higher latency |
| ap-south-1 (Mumbai) | ~150-180ms | Lower latency but not EU |

**Decision**: eu-central-1 provides the best balance of:
- Acceptable latency to Africa (~200ms)
- EU data residency requirements
- Service availability
- Cost effectiveness

## IoT Core Endpoints

IoT Core endpoints are region-specific:

```bash
# Get your IoT endpoint for eu-central-1
aws iot describe-endpoint --endpoint-type iot:Data-ATS --region eu-central-1

# Example output:
# xxxxxxxxxxxxx-ats.iot.eu-central-1.amazonaws.com
```

The IoT simulator automatically uses the correct regional endpoint based on the `--region` parameter.

## Cost Implications

### Data Transfer Costs

1. **Within eu-central-1**: Free (same region)
2. **eu-central-1 to eu-west-1**: ~$0.02/GB (cross-region)
3. **eu-central-1 to Internet**: ~$0.09/GB (first 10TB)
4. **IoT to Kinesis**: Free (same region)

### Service Pricing Differences

Most AWS services have similar pricing across EU regions, with minor variations:
- **IoT Core**: Same pricing in eu-central-1 and eu-west-1
- **Lambda**: Same pricing
- **RDS**: Slightly higher in eu-central-1 (~5%)
- **S3**: Same pricing

## Migration Considerations

If you need to change regions in the future:

1. **Backup all data** (RDS snapshots, S3 exports)
2. **Update tfvars files** with new regions
3. **Run terraform plan** to see changes
4. **Deploy to new region** (new infrastructure)
5. **Migrate data** (restore from backups)
6. **Update DNS** to point to new region
7. **Decommission old region** after validation

## Monitoring Regional Health

```bash
# Check AWS service health for eu-central-1
aws health describe-events --region eu-central-1

# Check RDS replication lag
aws rds describe-db-instances \
  --region eu-central-1 \
  --query 'DBInstances[*].[DBInstanceIdentifier,ReplicaLag]'

# Check S3 replication status
aws s3api get-bucket-replication \
  --bucket ecovolt-prod-data-lake \
  --region eu-central-1
```

## References

- [AWS Global Infrastructure](https://aws.amazon.com/about-aws/global-infrastructure/)
- [AWS Regional Services](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/)
- [CloudFront Certificate Requirements](https://docs.aws.amazon.com/acm/latest/userguide/acm-regions.html)
- [AWS Latency Monitoring](https://www.cloudping.info/)
