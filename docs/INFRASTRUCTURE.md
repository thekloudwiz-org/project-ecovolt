# EcoVolt Infrastructure Documentation

## Overview

This document covers the complete AWS infrastructure setup for EcoVolt, including Terraform modules, deployment procedures, CI/CD configuration, and operational guidelines.

**Current Status**:
- ✅ **Infrastructure**: 359 AWS resources deployed
- ✅ **Test Coverage**: 100% pass rate (5/5 phases)
- ✅ **Cost Optimization**: $90/month (67% savings)
- ✅ **Region**: EU Central 1 (Frankfurt)
- ✅ **Architecture**: Polyglot & Fan-Out pattern

---

## Table of Contents

- [Architecture Summary](#architecture-summary)
- [Terraform Modules](#terraform-modules)
- [Deployment](#deployment)
- [CI/CD Setup](#cicd-setup)
- [Secrets Management](#secrets-management)
- [GitHub Secrets Automation](#github-secrets-automation)
- [Disaster Recovery](#disaster-recovery)
- [Monitoring](#monitoring)
- [Production Scaling](#production-scaling)
- [Troubleshooting](#troubleshooting)

---

## Architecture Summary

### High-Level Components

```
┌──────────────────────────────────────────────────────────────┐
│                     EcoVolt Platform                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  IoT Devices → IoT Core → Kinesis Streams                   │
│                    ↓           ├─→ Lambda → DynamoDB          │
│              IoT Rules         ├─→ Lambda → InfluxDB          │
│                                └─→ Firehose → S3 Data Lake    │
│                                                               │
│  Mobile App → API Gateway → Lambda (Private Subnet)          │
│                    ↓              ├─→ RDS PostgreSQL          │
│              CloudFront           └─→ DynamoDB (VPC Endpoint) │
│                                                               │
│  Monitoring: CloudWatch + SNS Alerts                         │
│  Security: Cognito + GuardDuty + Secrets Manager             │
│  Cost Optimization: No NAT Gateway + VPC Endpoints           │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### Network Architecture

**VPC**: 10.0.0.0/16 across 3 Availability Zones
**Region**: eu-central-1 (Frankfurt)
**Cost Optimization**: VPC Endpoints instead of NAT Gateway ($40+/month savings)

```
VPC: 10.0.0.0/16

AZ-A (eu-central-1a):
├── Public:  10.0.1.0/24   (Reserved for ALB if needed)
├── Private: 10.0.11.0/24  (Lambda Functions)
└── Data:    10.0.21.0/24  (RDS Primary)

AZ-B (eu-central-1b):
├── Public:  10.0.2.0/24
├── Private: 10.0.12.0/24  (Lambda Functions)
└── Data:    10.0.22.0/24  (RDS Read Replica - Prod)

AZ-C (eu-central-1c):
├── Public:  10.0.3.0/24
├── Private: 10.0.13.0/24  (Lambda Functions)
└── Data:    10.0.23.0/24  (RDS Read Replica - Prod)
```

**VPC Endpoints** (No NAT Gateway):
- `com.amazonaws.eu-central-1.s3` (Gateway - Free)
- `com.amazonaws.eu-central-1.dynamodb` (Gateway - Free)
- `com.amazonaws.eu-central-1.secretsmanager` (Interface - ~$7/month)
- `com.amazonaws.eu-central-1.logs` (Interface - ~$7/month)

---

## Terraform Modules

### Module Structure

```
modules/
├── networking/          # VPC, subnets, VPC endpoints (NO NAT Gateway)
├── security/           # KMS, CloudTrail, GuardDuty
├── ssm/                # Parameter Store (encrypted config)
├── cognito/            # User authentication pools
├── iot/                # IoT Core, device management, rules
├── analytics/          # Kinesis Streams, Firehose, InfluxDB
├── database/           # RDS PostgreSQL
├── dynamodb/           # DynamoDB tables (7 tables)
├── compute/            # Lambda (6 functions), API Gateway
├── admin_portal/       # S3, CloudFront for admin UI
├── content_delivery/   # Static assets S3 bucket
├── dns/                # Route53, ACM certificates
└── monitoring/         # CloudWatch, SNS, Alarms
```

### Deployed Resources (359 Total)

| Module | Resources | Key Components |
|--------|-----------|----------------|
| **networking** | ~50 | VPC, 9 Subnets, 4 VPC Endpoints, Security Groups |
| **compute** | ~40 | 6 Lambda Functions, API Gateway, ESM |
| **storage** | ~30 | 7 DynamoDB Tables, 9 S3 Buckets, RDS |
| **security** | ~45 | IAM Roles/Policies, KMS Keys, Cognito |
| **iot_streaming** | ~25 | IoT Core, Kinesis Streams (2 shards), Firehose |
| **monitoring** | ~35 | CloudWatch Alarms, SNS Topics, Log Groups |
| **content** | ~15 | CloudFront, Route53 Records |
| **other** | ~119 | SSM Parameters, Secrets, Tags |

### Lambda Functions Deployed

1. **ecovolt-dev-api-handler**
   - Purpose: REST API request handling
   - VPC: Private subnet with VPC endpoints
   - Memory: 512MB (dev), 1024MB (prod)
   - Timeout: 30s
   - Trigger: API Gateway

2. **ecovolt-dev-stream-processor**
   - Purpose: Kinesis stream consumer for telemetry
   - Trigger: Kinesis Data Streams
   - Writes to: DynamoDB + InfluxDB
   - Batch size: 100 records

3. **ecovolt-dev-iot-processor**
   - Purpose: Process IoT device events
   - Trigger: IoT Core rules
   - Memory: 256MB

4. **ecovolt-dev-auth-handler**
   - Purpose: Cognito custom authentication
   - Memory: 256MB

5. **ecovolt-dev-data-transformer**
   - Purpose: Transform telemetry data for analytics
   - Memory: 512MB

6. **ecovolt-dev-db-migrator**
   - Purpose: Database schema migrations
   - Timeout: 900s (15 minutes)

### DynamoDB Tables

1. **ecovolt-dev-bike-status** - Current bike state
2. **ecovolt-dev-bike-telemetry** - Historical telemetry
3. **ecovolt-dev-stations** - Swap station data
4. **ecovolt-dev-swap-events** - Swap transaction records
5. **ecovolt-dev-battery-inventory** - Battery tracking
6. **ecovolt-dev-station-energy** - Energy consumption
7. **ecovolt-dev-user-profiles** - User metadata

### Module Dependencies

```
networking (VPC, subnets, VPC endpoints)
    ↓
security (KMS keys, CloudTrail)
    ↓
ssm (Parameter Store)
    ↓
├── analytics (Kinesis - needed by IoT)
├── cognito (User authentication)
├── database (RDS PostgreSQL)
├── dynamodb (State tables)
├── iot (IoT Core, requires Kinesis)
├── compute (Lambda, API Gateway)
├── admin_portal (S3, CloudFront)
├── dns (Route53, ACM)
└── monitoring (CloudWatch, SNS)
```

---

## Deployment

### Prerequisites

```bash
# Install required tools
brew install terraform awscli gh python@3.11 jq

# Verify installations
terraform version  # >= 1.5
aws --version      # >= 2.0
gh --version       # >= 2.0
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

**infra/dev.tfvars**:
```hcl
environment = "dev"
aws_region  = "eu-central-1"

# Networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

# Cost Optimization
use_nat_gateway = false  # Use VPC endpoints instead ($40/month savings)

# Database
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_multi_az = false
db_backup_retention_days = 7

# Compute
lambda_memory_size = 512
lambda_timeout = 30

# Analytics
kinesis_shard_count = 2
influxdb_instance_type = "db.t3.small"

# Tags
tags = {
  Environment = "dev"
  Project     = "ecovolt"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}
```

**infra/prod.tfvars**:
```hcl
environment = "prod"
aws_region  = "eu-central-1"

# Networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

# Cost Optimization
use_nat_gateway = false  # Use VPC endpoints even in prod

# Database (Production)
db_instance_class = "db.r6g.large"  # ARM-based (20% cheaper)
db_allocated_storage = 100
db_multi_az = true  # High availability
db_backup_retention_days = 30
db_read_replica_count = 2  # Read scaling

# Compute (Production)
lambda_memory_size = 1024
lambda_timeout = 60
lambda_reserved_concurrency = 100  # Reserved capacity

# Analytics (Production)
kinesis_shard_count = 10  # 10,000 writes/sec capacity
influxdb_instance_type = "db.r6g.xlarge"

# DynamoDB (Production)
dynamodb_billing_mode = "PROVISIONED"  # Cheaper with predictable load
dynamodb_read_capacity = 50
dynamodb_write_capacity = 25

# High Availability
enable_cross_region_backup = true
backup_region = "eu-west-1"

# Tags
tags = {
  Environment = "prod"
  Project     = "ecovolt"
  ManagedBy   = "terraform"
  CostCenter  = "operations"
  Compliance  = "gdpr"
}
```

### Deployment Steps

#### 1. Initialize Terraform

```bash
cd infra

# Initialize for development
terraform init \
  -backend-config="bucket=thekloudwiz-tf-state-bucket" \
  -backend-config="key=project-ecovolt/dev-tf.state" \
  -backend-config="region=eu-central-1"
```

#### 2. Plan Changes

```bash
terraform plan -var-file=dev.tfvars -out=dev.tfplan
```

#### 3. Apply Infrastructure

```bash
terraform apply dev.tfplan
```

**Note**: GitHub secrets are automatically updated after `terraform apply` via the GitHub Actions workflow or manual script execution.

#### 4. Deploy Lambda Functions

Lambda functions are packaged and deployed as part of the Terraform compute module:

```bash
# Package Lambda code
cd ../application/backend
./scripts/package_lambdas.sh

# Deploy via Terraform
cd ../../infra
terraform apply -target=module.compute -var-file=dev.tfvars
```

#### 5. Run Database Migrations

```bash
# Get RDS endpoint from Terraform outputs
RDS_ENDPOINT=$(terraform output -raw db_endpoint)

# Connect and run migrations
psql -h $RDS_ENDPOINT -U ecovolt_admin -d ecovolt \
  -f ../application/backend/migrations/001_initial_schema.sql

psql -h $RDS_ENDPOINT -U ecovolt_admin -d ecovolt \
  -f ../application/backend/migrations/002_add_indexes.sql

psql -h $RDS_ENDPOINT -U ecovolt_admin -d ecovolt \
  -f ../application/backend/migrations/003_seed_data.sql
```

#### 6. Verify Deployment

```bash
# Get API Gateway URL
API_URL=$(terraform output -raw api_gateway_url)

# Test health endpoint
curl $API_URL/health

# Expected: {"status": "healthy"}
```

### Deployment Timeline

| Phase | Duration | Notes |
|-------|----------|-------|
| Networking | ~3 min | VPC, subnets, VPC endpoints |
| Security | ~2 min | KMS keys, CloudTrail |
| Analytics | ~5 min | Kinesis streams, Firehose |
| Databases | ~8 min | RDS, DynamoDB, InfluxDB |
| Compute | ~4 min | Lambda functions, API Gateway |
| Monitoring | ~2 min | CloudWatch alarms |
| **Total** | **~20-25 min** | Full infrastructure deployment |

---

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
          "token.actions.githubusercontent.com:sub": "repo:thekloudwiz-org/project-ecovolt:*"
        }
      }
    }
  ]
}
```

```bash
# Create role for development
aws iam create-role \
  --role-name github-actions-dev \
  --assume-role-policy-document file://github-actions-trust-policy.json

# Attach admin policy (dev only - use restricted policy in prod)
aws iam attach-role-policy \
  --role-name github-actions-dev \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### 3. Configure GitHub Secrets

```bash
# Repository secrets (manual via GitHub UI or CLI)
gh secret set AWS_ROLE_ARN_DEV --body "arn:aws:iam::ACCOUNT:role/github-actions-dev"
gh secret set AWS_ROLE_ARN_STAGING --body "arn:aws:iam::ACCOUNT:role/github-actions-staging"
gh secret set AWS_ROLE_ARN_PROD --body "arn:aws:iam::ACCOUNT:role/github-actions-prod"

# Infrastructure outputs (automatically updated after terraform apply)
# See "GitHub Secrets Automation" section
```

#### 4. Workflow Behavior

| Branch | Event | Terraform Plan | Terraform Apply | Secrets Update |
|--------|-------|----------------|-----------------|----------------|
| `dev` | Push | ✅ | ✅ | ✅ |
| `dev` | PR | ✅ | ❌ | ❌ |
| `main` | PR | ✅ | ❌ | ❌ |
| `main` | Merge | ✅ | ✅ | ✅ |

**Workflows**:
- `.github/workflows/terraform-reusable.yml` - Terraform deployment
- `.github/workflows/admin-portal-dev.yml` - Frontend deployment (dev)
- `.github/workflows/admin-portal-prod.yml` - Frontend deployment (prod)

---

## Secrets Management

### Strategy: Terraform Deployment-Time Injection

**Problem**: Lambda functions in private subnet traditionally need Secrets Manager API calls, requiring VPC endpoints or NAT Gateway.

**Solution**: Inject secrets into Lambda environment variables at deployment time (no runtime API calls needed).

### Implementation

#### 1. Terraform Generates and Stores Secrets

```hcl
# Generate random password
resource "random_password" "db_master_password" {
  length  = 16
  special = false
}

# Store in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "ecovolt-${var.environment}-db-credentials"
  description = "RDS master credentials"

  # Dev: 0-day recovery (immediate deletion)
  # Prod: 30-day recovery window
  recovery_window_in_days = var.environment == "dev" ? 0 : 30
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_master_password.result
    host     = module.database.db_endpoint
    port     = 5432
    dbname   = var.db_name
  })
}
```

#### 2. Terraform Reads Secrets at Deploy Time

```hcl
# Read secret value during terraform apply
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}
```

#### 3. Terraform Injects into Lambda Environment

```hcl
resource "aws_lambda_function" "api_handler" {
  function_name = "ecovolt-${var.environment}-api-handler"

  # Secrets injected at deployment time (not runtime)
  environment {
    variables = {
      DB_HOST = local.db_creds["host"]
      DB_PORT = local.db_creds["port"]
      DB_NAME = local.db_creds["dbname"]
      DB_USER = local.db_creds["username"]
      DB_PASS = local.db_creds["password"]

      # Cognito public key for offline JWT verification
      COGNITO_JWK = var.cognito_jwk
    }
  }

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }
}
```

#### 4. Lambda Reads from Environment (No AWS API Calls)

```python
import os
import psycopg2

def get_db_connection():
    """
    Credentials already in environment variables.
    No AWS API calls needed - works entirely within VPC.
    """
    return psycopg2.connect(
        host=os.environ['DB_HOST'],
        port=os.environ['DB_PORT'],
        database=os.environ['DB_NAME'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASS'],
        connect_timeout=5
    )
```

### Benefits

- ✅ **No NAT Gateway needed** - No API calls to Secrets Manager
- ✅ **Faster cold starts** - No network calls during initialization
- ✅ **Lower cost** - No Secrets Manager API charges
- ✅ **Simpler architecture** - Fewer VPC endpoints needed
- ✅ **Works offline** - Lambda functions fully self-contained

### Security Considerations

- Secrets stored encrypted in Secrets Manager (KMS)
- Secrets injected during Terraform apply (local execution or CI/CD)
- Lambda environment variables encrypted at rest (KMS)
- Secrets Manager provides audit trail (CloudTrail)
- Dev environment: 0-day recovery window (immediate deletion)
- Prod environment: 30-day recovery window (safety net)

---

## GitHub Secrets Automation

### Problem

Frontend applications (admin portal, mobile app) need infrastructure values that change with each `terraform apply`:
- API Gateway URL
- Cognito User Pool ID
- Cognito Client IDs
- S3 bucket names
- CloudFront distribution IDs

Manual updates are error-prone and time-consuming.

### Solution

Automated synchronization from Terraform outputs to GitHub repository secrets.

### Implementation

#### 1. Terraform Outputs

```hcl
# infra/outputs.tf
output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.compute.api_gateway_invoke_url
}

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.customer_user_pool_id
}

output "admin_portal_client_id" {
  description = "Admin Portal Cognito Client ID"
  value       = module.cognito.admin_portal_client_id
}

output "mobile_app_client_id" {
  description = "Mobile App Cognito Client ID"
  value       = module.cognito.mobile_app_client_id
}

output "admin_portal_s3_bucket" {
  description = "S3 bucket for admin portal"
  value       = module.admin_portal.s3_bucket_name
}

output "admin_portal_cloudfront_id" {
  description = "CloudFront distribution ID"
  value       = module.admin_portal.cloudfront_distribution_id
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}
```

#### 2. Automation Script

**scripts/update-github-secrets.sh**:
```bash
#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR=${2:-infra}

cd "$TERRAFORM_DIR"

# Extract Terraform outputs as JSON
terraform output -json > /tmp/tf-outputs.json

# Extract values
API_URL=$(jq -r '.api_gateway_url.value // empty' /tmp/tf-outputs.json)
USER_POOL_ID=$(jq -r '.user_pool_id.value // empty' /tmp/tf-outputs.json)
ADMIN_CLIENT_ID=$(jq -r '.admin_portal_client_id.value // empty' /tmp/tf-outputs.json)
MOBILE_CLIENT_ID=$(jq -r '.mobile_app_client_id.value // empty' /tmp/tf-outputs.json)
S3_BUCKET=$(jq -r '.admin_portal_s3_bucket.value // empty' /tmp/tf-outputs.json)
CLOUDFRONT_ID=$(jq -r '.admin_portal_cloudfront_id.value // empty' /tmp/tf-outputs.json)
AWS_REGION=$(jq -r '.aws_region.value // "eu-central-1"' /tmp/tf-outputs.json)

# Update GitHub secrets via gh CLI
echo "$API_URL" | gh secret set "API_URL_${ENVIRONMENT^^}" --body -
echo "$USER_POOL_ID" | gh secret set "USER_POOL_ID_${ENVIRONMENT^^}" --body -
echo "$ADMIN_CLIENT_ID" | gh secret set "USER_POOL_CLIENT_ID_${ENVIRONMENT^^}" --body -
echo "$MOBILE_CLIENT_ID" | gh secret set "MOBILE_APP_CLIENT_ID_${ENVIRONMENT^^}" --body -
echo "$S3_BUCKET" | gh secret set "ADMIN_PORTAL_S3_BUCKET_${ENVIRONMENT^^}" --body -
echo "$CLOUDFRONT_ID" | gh secret set "ADMIN_PORTAL_CLOUDFRONT_ID_${ENVIRONMENT^^}" --body -

echo "✅ GitHub secrets updated successfully"
```

#### 3. GitHub Workflow Integration

**.github/workflows/terraform-reusable.yml**:
```yaml
- name: Terraform Apply
  run: |
    cd ${{ inputs.working_directory }}
    terraform apply -auto-approve ${{ inputs.environment }}.tfplan

- name: Update GitHub Secrets
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    chmod +x scripts/update-github-secrets.sh
    ./scripts/update-github-secrets.sh ${{ inputs.environment }} ${{ inputs.working_directory }}
```

#### 4. Frontend Usage

**.github/workflows/admin-portal-dev.yml**:
```yaml
- name: Build Admin Portal
  env:
    VITE_API_URL: ${{ secrets.API_URL_DEV }}
    VITE_USER_POOL_ID: ${{ secrets.USER_POOL_ID_DEV }}
    VITE_USER_POOL_CLIENT_ID: ${{ secrets.USER_POOL_CLIENT_ID_DEV }}
    VITE_AWS_REGION: eu-central-1
  run: |
    npm run build

- name: Deploy to S3
  run: |
    aws s3 sync ./dist s3://${{ secrets.ADMIN_PORTAL_S3_BUCKET_DEV }}/ --delete

- name: Invalidate CloudFront Cache
  run: |
    aws cloudfront create-invalidation \
      --distribution-id ${{ secrets.ADMIN_PORTAL_CLOUDFRONT_ID_DEV }} \
      --paths "/*"
```

### Secrets Updated Automatically

| Secret | Example Value | Usage |
|--------|---------------|-------|
| `API_URL_DEV` | https://mxc55kr3d8.execute-api.eu-central-1.amazonaws.com/v1 | API requests |
| `USER_POOL_ID_DEV` | eu-central-1_Vh37Fd4ul | Cognito auth |
| `USER_POOL_CLIENT_ID_DEV` | 2h0hsagipne3d9l1phtk4ig29a | Admin portal |
| `MOBILE_APP_CLIENT_ID_DEV` | (different ID) | Mobile app |
| `ADMIN_PORTAL_S3_BUCKET_DEV` | ecovolt-dev-admin-portal | Deployment target |
| `ADMIN_PORTAL_CLOUDFRONT_ID_DEV` | E1234567890ABC | Cache invalidation |

### Manual Execution

```bash
# Ensure GitHub CLI is authenticated
gh auth status

# Run script manually
cd /Users/thekloudwiz/project-ecovolt
./scripts/update-github-secrets.sh dev infra
```

**Documentation**: See `/docs/GITHUB_SECRETS_AUTOMATION.md` for comprehensive guide.

---

## Disaster Recovery

### RDS Backup Strategy

**Automated Backups**:
- **Development**: 7 days retention
- **Production**: 30 days retention
- **Backup window**: 03:00-04:00 UTC
- **Maintenance window**: Sunday 04:00-05:00 UTC

**Manual Snapshots**:
```bash
aws rds create-db-snapshot \
  --db-instance-identifier ecovolt-${ENVIRONMENT}-db \
  --db-snapshot-identifier ecovolt-db-snapshot-$(date +%Y%m%d)
```

**Cross-Region Replication** (Production only):
```bash
aws rds create-db-instance-read-replica \
  --db-instance-identifier ecovolt-prod-db-replica-euwest \
  --source-db-instance-identifier ecovolt-prod-db \
  --source-region eu-central-1 \
  --region eu-west-1
```

### DynamoDB Backup

**Enable Point-in-Time Recovery**:
```bash
for table in bike-status bike-telemetry stations swap-events battery-inventory station-energy user-profiles; do
  aws dynamodb update-continuous-backups \
    --table-name ecovolt-${ENVIRONMENT}-${table} \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
done
```

**Create On-Demand Backup**:
```bash
aws dynamodb create-backup \
  --table-name ecovolt-prod-bike-status \
  --backup-name ecovolt-bike-status-backup-$(date +%Y%m%d)
```

### S3 Data Lake Backup

**Enable Versioning**:
```bash
aws s3api put-bucket-versioning \
  --bucket ecovolt-${ENVIRONMENT}-data-lake \
  --versioning-configuration Status=Enabled
```

**Cross-Region Replication** (Production):
```bash
# Configure replication to eu-west-1
aws s3api put-bucket-replication \
  --bucket ecovolt-prod-data-lake \
  --replication-configuration file://s3-replication-config.json
```

### Recovery Procedures

**RDS Recovery**:
```bash
# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ecovolt-db-restored \
  --db-snapshot-identifier ecovolt-db-snapshot-20241129

# Point-in-time restore (production)
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier ecovolt-prod-db \
  --target-db-instance-identifier ecovolt-prod-db-restored \
  --restore-time 2024-11-29T10:00:00Z
```

**DynamoDB Recovery**:
```bash
# Restore from point-in-time (up to 35 days back)
aws dynamodb restore-table-to-point-in-time \
  --source-table-name ecovolt-prod-bike-status \
  --target-table-name ecovolt-prod-bike-status-restored \
  --restore-date-time 2024-11-29T10:00:00Z
```

### RTO/RPO Targets

| Environment | RTO | RPO | Strategy |
|-------------|-----|-----|----------|
| **Development** | 4 hours | 24 hours | Daily snapshots |
| **Staging** | 1 hour | 1 hour | Point-in-time recovery |
| **Production** | 15 minutes | 5 minutes | Multi-AZ + Read Replicas + PITR |

---

## Monitoring

### CloudWatch Dashboards

**Automatic Dashboards**:
- Lambda (all functions aggregated)
- API Gateway (request metrics)
- DynamoDB (capacity and latency)

**Access**:
```
AWS Console → CloudWatch → Dashboards → Automatic dashboards
```

### CloudWatch Alarms

**Critical Alarms**:

```bash
# API Error Rate
aws cloudwatch put-metric-alarm \
  --alarm-name ecovolt-${ENVIRONMENT}-api-errors \
  --alarm-description "Alert on high API error rate" \
  --metric-name 5XXError \
  --namespace AWS/ApiGateway \
  --dimensions Name=ApiName,Value=ecovolt-${ENVIRONMENT}-ecovolt-api \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:eu-central-1:ACCOUNT:ecovolt-${ENVIRONMENT}-alerts

# Lambda Errors
aws cloudwatch put-metric-alarm \
  --alarm-name ecovolt-${ENVIRONMENT}-lambda-errors \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --dimensions Name=FunctionName,Value=ecovolt-${ENVIRONMENT}-api-handler \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:eu-central-1:ACCOUNT:ecovolt-${ENVIRONMENT}-alerts

# Database Connections
aws cloudwatch put-metric-alarm \
  --alarm-name ecovolt-${ENVIRONMENT}-db-connections \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --dimensions Name=DBInstanceIdentifier,Value=ecovolt-${ENVIRONMENT}-db \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:eu-central-1:ACCOUNT:ecovolt-${ENVIRONMENT}-alerts
```

### Log Groups

Lambda functions automatically create CloudWatch log groups:
- `/aws/lambda/ecovolt-dev-api-handler`
- `/aws/lambda/ecovolt-dev-stream-processor`
- `/aws/lambda/ecovolt-dev-iot-processor`
- `/aws/lambda/ecovolt-dev-auth-handler`
- `/aws/lambda/ecovolt-dev-data-transformer`
- `/aws/lambda/ecovolt-dev-db-migrator`

**Query Logs**:
```bash
# Tail logs in real-time
aws logs tail /aws/lambda/ecovolt-dev-api-handler --follow

# Query with CloudWatch Insights
aws logs start-query \
  --log-group-name /aws/lambda/ecovolt-dev-api-handler \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20'
```

### Metrics Validation

After deployment, verify all metrics are populated:

```bash
# Check API Gateway metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=ecovolt-dev-ecovolt-api \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region eu-central-1

# Check Lambda invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=ecovolt-dev-api-handler \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region eu-central-1
```

**Test Scripts**:
- `/scripts/testing/full_system_verification.py` - End-to-end test (5 phases)
- `/scripts/testing/generate-cloudwatch-metrics.sh` - Generate test traffic
- See `/scripts/testing/README.md` for comprehensive test suite

---

## Production Scaling

### Vertical Scaling Recommendations

| Service | Development | Staging | Production |
|---------|-------------|---------|------------|
| **RDS Instance** | db.t3.micro | db.t3.small | db.r6g.large (ARM) |
| **Lambda Memory** | 512MB | 768MB | 1024MB |
| **Kinesis Shards** | 2 | 5 | 10-20 |
| **DynamoDB Mode** | On-Demand | On-Demand | Provisioned (cheaper) |
| **InfluxDB Instance** | db.t3.small | db.t3.medium | db.r6g.xlarge |

### Horizontal Scaling

**Lambda Concurrency**:
```bash
# Set reserved concurrency (production)
aws lambda put-function-concurrency \
  --function-name ecovolt-prod-api-handler \
  --reserved-concurrent-executions 100
```

**RDS Read Replicas** (Production):
```bash
# Create read replica in different AZ
aws rds create-db-instance-read-replica \
  --db-instance-identifier ecovolt-prod-db-replica-1 \
  --source-db-instance-identifier ecovolt-prod-db \
  --availability-zone eu-central-1b

aws rds create-db-instance-read-replica \
  --db-instance-identifier ecovolt-prod-db-replica-2 \
  --source-db-instance-identifier ecovolt-prod-db \
  --availability-zone eu-central-1c
```

**Kinesis Shard Scaling**:
```bash
# Increase shards for higher throughput
aws kinesis update-shard-count \
  --stream-name ecovolt-prod-telemetry-stream \
  --target-shard-count 20 \
  --scaling-type UNIFORM_SCALING
```

### Multi-Region Deployment (Future)

**Planned Architecture**:
```
Primary: eu-central-1 (Frankfurt)
  ├─→ Serves: West Africa, Europe
  └─→ Latency: ~150ms from Accra

Secondary: af-south-1 (Cape Town) - When available
  ├─→ Serves: Southern Africa
  └─→ Latency: ~50ms from Accra

Route 53: Geolocation routing
DynamoDB: Global Tables
S3: Cross-Region Replication
RDS: Cross-Region Read Replicas
```

### Auto-Scaling Policies

**DynamoDB Auto-Scaling** (Production):
```bash
# Enable auto-scaling for read capacity
aws application-autoscaling register-scalable-target \
  --service-namespace dynamodb \
  --resource-id table/ecovolt-prod-bike-status \
  --scalable-dimension dynamodb:table:ReadCapacityUnits \
  --min-capacity 5 \
  --max-capacity 100

aws application-autoscaling put-scaling-policy \
  --service-namespace dynamodb \
  --resource-id table/ecovolt-prod-bike-status \
  --scalable-dimension dynamodb:table:ReadCapacityUnits \
  --policy-name ecovolt-prod-bike-status-read-scaling \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "DynamoDBReadCapacityUtilization"
    }
  }'
```

---

## Troubleshooting

### Common Issues

#### 1. Lambda Timeout in Private Subnet

**Symptoms**: Lambda functions timing out, 504 errors from API Gateway

**Causes**:
- Missing VPC endpoint for required service
- Security group blocking egress
- Database connection pool exhaustion

**Solution**:
```bash
# Check VPC endpoints exist
aws ec2 describe-vpc-endpoints \
  --filters Name=vpc-id,Values=$(terraform output -raw vpc_id)

# Verify security group allows egress
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw lambda_security_group_id)

# Increase Lambda timeout
aws lambda update-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --timeout 60

# Increase Lambda memory (also increases CPU)
aws lambda update-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --memory-size 1024
```

#### 2. Database Connection Issues

**Symptoms**: "Connection refused" or "No route to host" errors

**Solution**:
```bash
# Verify Lambda in correct subnets
aws lambda get-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --query 'VpcConfig.SubnetIds'

# Check RDS security group allows Lambda SG
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw rds_security_group_id) \
  --query 'SecurityGroups[0].IpPermissions'

# Test connection from Lambda (via Lambda console test)
```

#### 3. API Gateway 502 Errors

**Symptoms**: 502 Bad Gateway, intermittent

**Causes**:
- Lambda function returning invalid response format
- Lambda execution role missing permissions
- Lambda function crashing

**Solution**:
```bash
# Check Lambda logs for errors
aws logs tail /aws/lambda/ecovolt-dev-api-handler --since 10m

# Verify Lambda returns correct response format
# Expected: {"statusCode": 200, "body": "..."}

# Check Lambda execution role
aws iam get-role --role-name ecovolt-dev-lambda-execution-role
```

#### 4. Terraform State Lock

**Symptoms**: "Error locking state" when running Terraform

**Solution**:
```bash
# List locks
aws dynamodb scan \
  --table-name terraform-state-locks \
  --filter-expression "begins_with(LockID, :prefix)" \
  --expression-attribute-values '{":prefix":{"S":"thekloudwiz-tf-state-bucket/project-ecovolt"}}'

# Force unlock (use with caution - only if no other terraform process running)
terraform force-unlock LOCK_ID

# Or delete from DynamoDB
aws dynamodb delete-item \
  --table-name terraform-state-locks \
  --key '{"LockID": {"S": "thekloudwiz-tf-state-bucket/project-ecovolt/dev-tf.state"}}'
```

#### 5. CloudWatch Metrics Not Appearing

**Symptoms**: Dashboard shows "No data available"

**Causes**:
- Metrics take 1-5 minutes to aggregate
- Wrong time range selected
- No traffic to generate metrics

**Solution**:
```bash
# Generate test traffic
cd /Users/thekloudwiz/project-ecovolt/scripts/testing
./generate-cloudwatch-metrics.sh

# Wait 2-3 minutes for metrics aggregation

# Check metrics via CLI
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=ecovolt-dev-ecovolt-api \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region eu-central-1
```

#### 6. IoT Device Connection Issues

**Symptoms**: Devices cannot connect to IoT Core

**Solution**:
```bash
# Check IoT endpoint
aws iot describe-endpoint --endpoint-type iot:Data-ATS

# Verify certificate is active
aws iot describe-certificate --certificate-id CERT_ID

# Check IoT policy
aws iot get-policy --policy-name EcoVoltDevicePolicy

# Check IoT Core logs
aws logs tail AWSIotLogsV2 --follow
```

### Debugging Commands

```bash
# Terraform state inspection
terraform state list
terraform state show module.compute.aws_lambda_function.api_handler

# Validate Terraform configuration
terraform validate

# Check AWS credentials
aws sts get-caller-identity

# Test API Gateway endpoint
API_URL=$(terraform output -raw api_gateway_url)
curl -v $API_URL/health

# Check Lambda function logs (last hour)
aws logs tail /aws/lambda/ecovolt-dev-api-handler --since 1h

# List all Lambda functions
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `ecovolt`)].FunctionName'

# Check DynamoDB tables
aws dynamodb list-tables --query 'TableNames[?starts_with(@, `ecovolt`)]'

# Check S3 buckets
aws s3 ls | grep ecovolt

# Check VPC endpoints
aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[*].ServiceName'
```

### Health Check Script

```bash
#!/bin/bash
# scripts/health-check.sh

echo "=== EcoVolt Infrastructure Health Check ==="

# API Gateway
echo -n "API Gateway: "
curl -sf $(terraform output -raw api_gateway_url)/health > /dev/null && echo "✅" || echo "❌"

# RDS
echo -n "RDS: "
aws rds describe-db-instances \
  --db-instance-identifier ecovolt-dev-db \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text

# DynamoDB
echo -n "DynamoDB: "
aws dynamodb describe-table \
  --table-name ecovolt-dev-bike-status \
  --query 'Table.TableStatus' \
  --output text

# Kinesis
echo -n "Kinesis: "
aws kinesis describe-stream \
  --stream-name ecovolt-dev-telemetry-stream \
  --query 'StreamDescription.StreamStatus' \
  --output text

# Lambda
echo -n "Lambda Functions: "
aws lambda list-functions \
  --query 'length(Functions[?starts_with(FunctionName, `ecovolt-dev`)])' \
  --output text
echo " functions deployed"
```

---

## Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [VPC Endpoints Guide](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)

---

**Last Updated**: November 2024
**Infrastructure Version**: 2.0 (No NAT Gateway + VPC Endpoints)
**Deployment Status**: ✅ Production-Ready (359 resources, 100% test pass rate)
**Maintained By**: EcoVolt Infrastructure Team
