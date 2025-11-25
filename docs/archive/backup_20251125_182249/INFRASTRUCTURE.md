# EcoVolt Infrastructure Documentation

## Overview

This document covers the complete AWS infrastructure setup for EcoVolt, including Terraform modules, deployment procedures, CI/CD configuration, and operational guidelines.

## Table of Contents

- [Architecture](#architecture)
- [Terraform Modules](#terraform-modules)
- [Deployment](#deployment)
- [CI/CD Setup](#cicd-setup)
- [Secrets Management](#secrets-management)
- [Disaster Recovery](#disaster-recovery)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                     EcoVolt Platform                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  IoT Devices → IoT Core → Kinesis → Lambda → Timestream    │
│                    ↓                    ↓                    │
│              IoT Greengrass        DynamoDB                  │
│                                         ↓                    │
│  Mobile App → API Gateway → Lambda → RDS PostgreSQL         │
│                    ↓                    ↓                    │
│              CloudFront            ElastiCache               │
│                                                              │
│  Monitoring: CloudWatch + X-Ray + SNS Alerts               │
│  Security: Cognito + WAF + GuardDuty + Secrets Manager     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Network Architecture

**VPC**: 10.0.0.0/16 across 3 Availability Zones

```
AZ-A (eu-central-1a):
├── Public:  10.0.1.0/24   (NAT GW, ALB)
├── Private: 10.0.11.0/24  (Lambda, ECS)
└── Data:    10.0.21.0/24  (RDS, ElastiCache)

AZ-B (eu-central-1b):
├── Public:  10.0.2.0/24
├── Private: 10.0.12.0/24
└── Data:    10.0.22.0/24

AZ-C (eu-central-1c):
├── Public:  10.0.3.0/24
├── Private: 10.0.13.0/24
└── Data:    10.0.23.0/24
```

## Terraform Modules

### Module Structure

```
modules/
├── networking/          # VPC, subnets, NAT gateways
├── security/           # KMS, CloudTrail, GuardDuty
├── cognito/            # User authentication
├── iot/                # IoT Core, device management
├── analytics/          # Kinesis, Timestream, Athena
├── database/           # RDS, ElastiCache
├── dynamodb/           # DynamoDB tables
├── compute/            # Lambda, API Gateway
├── monitoring/         # CloudWatch, alarms
├── billing/            # AWS Budgets
├── edge-computing/     # IoT Greengrass
├── content-delivery/   # CloudFront, S3
├── waf/                # Web Application Firewall
├── compliance/         # AWS Config
└── disaster-recovery/  # Cross-region replication
```

### Module Dependencies

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
└── disaster-recovery (requires database, analytics)
```

## Deployment

### Prerequisites

```bash
# Install required tools
brew install terraform awscli go python@3.11

# Verify installations
terraform version  # >= 1.5
aws --version      # >= 2.0
go version         # >= 1.21
python3 --version  # >= 3.11
```

### AWS Account Setup

1. **Create S3 bucket for Terraform state**:
```bash
aws s3 mb s3://thekloudwiz-tf-state-bucket --region eu-central-1
aws s3api put-bucket-versioning \
  --bucket thekloudwiz-tf-state-bucket \
  --versioning-configuration Status=Enabled
```

2. **Create DynamoDB table for state locking**:
```bash
aws dynamodb create-table \
  --table-name terraform-state-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

### Environment Configuration

Create environment-specific variable files:

**environments/dev.tfvars**:
```hcl
environment = "dev"
aws_region  = "eu-central-1"

# Networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

# Database
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_multi_az = false

# Compute
lambda_memory_size = 512
lambda_timeout = 30

# IoT
iot_device_count = 10

# Tags
tags = {
  Environment = "dev"
  Project     = "ecovolt"
  ManagedBy   = "terraform"
}
```

### Deployment Steps

#### 1. Initialize Terraform

```bash
# Initialize for development
terraform init \
  -backend-config="bucket=thekloudwiz-tf-state-bucket" \
  -backend-config="key=project-ecovolt/dev-tf.state" \
  -backend-config="region=eu-central-1"
```

#### 2. Plan Changes

```bash
terraform plan -var-file=environments/dev.tfvars -out=dev.tfplan
```

#### 3. Apply Infrastructure

```bash
terraform apply dev.tfplan
```

#### 4. Deploy Lambda Functions

```bash
cd application/backend
./scripts/package_lambdas.sh

# Update Lambda functions
terraform apply -target=module.compute
```

#### 5. Run Database Migrations

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

# Connect and run migrations
psql -h $RDS_ENDPOINT -U ecovolt_admin -d ecovolt \
  -f application/backend/migrations/001_initial_schema.sql
psql -h $RDS_ENDPOINT -U ecovolt_admin -d ecovolt \
  -f application/backend/migrations/002_add_indexes.sql
psql -h $RDS_ENDPOINT -U ecovolt_admin -d ecovolt \
  -f application/backend/migrations/003_seed_data.sql
```

#### 6. Verify Deployment

```bash
# Get API Gateway URL
API_URL=$(terraform output -raw api_gateway_url)

# Test health endpoint
curl $API_URL/v1/health

# Expected: {"status": "healthy", "version": "1.0.0"}
```

### Makefile Commands

```bash
# Initialize
make init-dev

# Validate
make validate

# Format code
make fmt

# Plan changes
make plan dev

# Apply changes
make apply dev

# Show outputs
make output dev

# Run tests
make test

# Security scan
make security-scan

# Cost estimate
make cost-estimate dev

# Clean up
make clean
```

## CI/CD Setup

### GitHub Actions with OIDC

#### 1. Create IAM OIDC Provider

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### 2. Create IAM Roles

**For Development**:
```bash
aws iam create-role \
  --role-name github-actions-dev \
  --assume-role-policy-document file://github-actions-trust-policy.json

aws iam attach-role-policy \
  --role-name github-actions-dev \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**Trust Policy** (github-actions-trust-policy.json):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/YOUR_REPO:*"
        }
      }
    }
  ]
}
```

#### 3. Configure GitHub Secrets

```bash
# Add secrets via GitHub CLI
gh secret set AWS_ROLE_ARN_DEV --body "arn:aws:iam::ACCOUNT:role/github-actions-dev"
gh secret set AWS_ROLE_ARN_STAGING --body "arn:aws:iam::ACCOUNT:role/github-actions-staging"
gh secret set AWS_ROLE_ARN_PROD --body "arn:aws:iam::ACCOUNT:role/github-actions-prod"
```

#### 4. Workflow Configuration

Workflows are located in `.github/workflows/`:
- `terraform-reusable.yml` - Reusable Terraform workflow
- `backend-reusable.yml` - Reusable backend deployment
- `deploy-dev.yml` - Development deployment
- `deploy-prod.yml` - Production deployment

**Workflow Behavior**:

| Branch | Event | Jobs | Apply? |
|--------|-------|------|--------|
| `dev` | Push | init → validate → security → plan → apply | ✅ |
| `dev` | PR | init → validate → security → plan | ❌ |
| `main` | PR | init → validate → security → plan | ❌ |
| `main` | Merge | init → validate → security → plan → apply | ✅ |

## Secrets Management

### AWS Secrets Manager

#### 1. Store Database Credentials

```bash
aws secretsmanager create-secret \
  --name ecovolt/dev/database \
  --description "EcoVolt database credentials" \
  --secret-string '{
    "username": "ecovolt_admin",
    "password": "SECURE_PASSWORD",
    "engine": "postgres",
    "host": "ecovolt-db.xxx.eu-central-1.rds.amazonaws.com",
    "port": 5432,
    "dbname": "ecovolt"
  }'
```

#### 2. Enable Automatic Rotation

```bash
aws secretsmanager rotate-secret \
  --secret-id ecovolt/dev/database \
  --rotation-lambda-arn arn:aws:lambda:eu-central-1:ACCOUNT:function:SecretsManagerRotation \
  --rotation-rules AutomaticallyAfterDays=30
```

#### 3. Access from Lambda

```python
import boto3
import json

def get_db_credentials():
    client = boto3.client('secretsmanager', region_name='eu-central-1')
    response = client.get_secret_value(SecretId='ecovolt/dev/database')
    return json.loads(response['SecretString'])
```

## Disaster Recovery

### RDS Backup Strategy

**Automated Backups**:
- Retention: 7 days (dev), 30 days (prod)
- Backup window: 03:00-04:00 UTC
- Maintenance window: Sun 04:00-05:00 UTC

**Manual Snapshots**:
```bash
aws rds create-db-snapshot \
  --db-instance-identifier ecovolt-db \
  --db-snapshot-identifier ecovolt-db-snapshot-$(date +%Y%m%d)
```

**Cross-Region Replication** (Production only):
```bash
aws rds create-db-instance-read-replica \
  --db-instance-identifier ecovolt-db-replica \
  --source-db-instance-identifier ecovolt-db \
  --source-region eu-central-1 \
  --region eu-west-1
```

### DynamoDB Backup

**Enable Point-in-Time Recovery**:
```bash
aws dynamodb update-continuous-backups \
  --table-name ecovolt-telemetry \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

**Create On-Demand Backup**:
```bash
aws dynamodb create-backup \
  --table-name ecovolt-telemetry \
  --backup-name ecovolt-telemetry-backup-$(date +%Y%m%d)
```

### Recovery Procedures

**RDS Recovery**:
```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ecovolt-db-restored \
  --db-snapshot-identifier ecovolt-db-snapshot-20241115

# Point-in-time restore
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier ecovolt-db \
  --target-db-instance-identifier ecovolt-db-restored \
  --restore-time 2024-11-15T10:00:00Z
```

**DynamoDB Recovery**:
```bash
# Restore from backup
aws dynamodb restore-table-from-backup \
  --target-table-name ecovolt-telemetry-restored \
  --backup-arn arn:aws:dynamodb:eu-central-1:ACCOUNT:table/ecovolt-telemetry/backup/01234567890123-abcdef12
```

## Monitoring

### CloudWatch Dashboards

**Create Dashboard**:
```bash
aws cloudwatch put-dashboard \
  --dashboard-name EcoVolt-Production \
  --dashboard-body file://cloudwatch-dashboard.json
```

### CloudWatch Alarms

**API Error Rate**:
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name ecovolt-api-errors \
  --alarm-description "Alert on high API error rate" \
  --metric-name 5XXError \
  --namespace AWS/ApiGateway \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:eu-central-1:ACCOUNT:ecovolt-alerts
```

**Database Connections**:
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name ecovolt-db-connections \
  --alarm-description "Alert on high DB connections" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:eu-central-1:ACCOUNT:ecovolt-alerts
```

### Log Groups

Lambda functions automatically create CloudWatch log groups:
- `/aws/lambda/ecovolt-api-handler`
- `/aws/lambda/ecovolt-iot-processor`
- `/aws/lambda/ecovolt-stream-processor`

**Query Logs**:
```bash
aws logs tail /aws/lambda/ecovolt-api-handler --follow
```

## Troubleshooting

### Common Issues

#### 1. Lambda Timeout

**Symptoms**: Lambda functions timing out, 504 errors from API Gateway

**Solution**:
```bash
# Increase timeout
aws lambda update-function-configuration \
  --function-name ecovolt-api-handler \
  --timeout 60

# Increase memory (also increases CPU)
aws lambda update-function-configuration \
  --function-name ecovolt-api-handler \
  --memory-size 1024
```

#### 2. Database Connection Issues

**Symptoms**: Cannot connect to RDS from Lambda

**Solution**:
```bash
# Check security group rules
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx

# Verify Lambda VPC configuration
aws lambda get-function-configuration \
  --function-name ecovolt-api-handler

# Ensure Lambda is in same VPC as RDS
# Ensure security group allows inbound on port 5432
```

#### 3. API Gateway 502 Errors

**Symptoms**: 502 Bad Gateway errors

**Solution**:
```bash
# Check Lambda logs
aws logs tail /aws/lambda/ecovolt-api-handler --follow

# Check Lambda execution role permissions
aws iam get-role --role-name ecovolt-lambda-execution-role

# Verify Lambda function is not in failed state
aws lambda get-function --function-name ecovolt-api-handler
```

#### 4. Terraform State Lock

**Symptoms**: "Error locking state" when running Terraform

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Or delete lock from DynamoDB
aws dynamodb delete-item \
  --table-name terraform-state-locks \
  --key '{"LockID": {"S": "thekloudwiz-tf-state-bucket/project-ecovolt/dev-tf.state"}}'
```

#### 5. IoT Device Connection Issues

**Symptoms**: Devices cannot connect to IoT Core

**Solution**:
```bash
# Check IoT policy
aws iot get-policy --policy-name EcoVoltDevicePolicy

# Verify certificate is active
aws iot describe-certificate --certificate-id CERT_ID

# Check IoT Core logs
aws logs tail /aws/iot/events --follow
```

### Debugging Commands

```bash
# Check Terraform state
terraform state list
terraform state show module.compute.aws_lambda_function.api_handler

# Validate Terraform configuration
terraform validate

# Check AWS CLI configuration
aws sts get-caller-identity

# Test API Gateway endpoint
curl -v https://API_ID.execute-api.eu-central-1.amazonaws.com/v1/health

# Check Lambda function logs
aws logs tail /aws/lambda/ecovolt-api-handler --since 1h

# List all resources in a module
terraform state list | grep module.compute
```

### Support Contacts

- **DevOps Team**: devops@ecovolt.com
- **On-Call**: +233-XXX-XXXX
- **AWS Support**: Enterprise Support Plan

## Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)

---

**Last Updated**: November 2024  
**Maintained By**: EcoVolt Infrastructure Team

