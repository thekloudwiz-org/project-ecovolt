# EcoVolt Deployment Guide

This guide provides step-by-step instructions for deploying the EcoVolt backend infrastructure to AWS.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Database Setup](#database-setup)
4. [Infrastructure Deployment](#infrastructure-deployment)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
- **Terraform** >= 1.0.0
- **AWS CLI** >= 2.0
- **Python** >= 3.11
- **PostgreSQL Client** (psql)
- **Git**

### AWS Account Requirements
- AWS Account with appropriate permissions
- IAM user with AdministratorAccess or equivalent
- AWS CLI configured with credentials

### Required AWS Services
- VPC and Networking
- RDS PostgreSQL
- DynamoDB
- Lambda
- API Gateway
- Cognito
- SNS
- IoT Core
- CloudWatch
- Secrets Manager
- WAF

---

## Pre-Deployment Checklist

### 1. Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity
```

### 2. Set Environment Variables

```bash
export AWS_REGION="us-east-1"  # or your preferred region
export ENVIRONMENT="dev"        # dev, staging, or prod
export PROJECT_NAME="ecovolt"
```

### 3. Review Terraform Variables

Edit `environments/dev.tfvars`:

```hcl
# Project Configuration
project_name = "ecovolt"
environment  = "dev"
aws_region   = "us-east-1"

# Networking
vpc_cidr = "10.0.0.0/16"

# Database
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_name              = "ecovolt"
db_username          = "ecovolt_admin"

# Lambda
lambda_runtime     = "python3.11"
lambda_memory_size = 512
lambda_timeout     = 30

# API Gateway
api_gateway_stage_name = "v1"
```

---

## Database Setup

### Step 1: Run Database Migrations

After RDS is created, run the migration scripts:

```bash
# Get database endpoint from Terraform output
DB_ENDPOINT=$(terraform output -raw db_endpoint)
DB_NAME=$(terraform output -raw db_name)

# Get database password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ${ENVIRONMENT}/ecovolt/db-password \
  --query SecretString \
  --output text)

# Run migrations
cd application/backend/migrations

# 1. Create schema
psql -h $DB_ENDPOINT -U ecovolt_admin -d $DB_NAME -f 001_initial_schema.sql

# 2. Add indexes
psql -h $DB_ENDPOINT -U ecovolt_admin -d $DB_NAME -f 002_add_indexes.sql

# 3. Seed data (optional for dev)
psql -h $DB_ENDPOINT -U ecovolt_admin -d $DB_NAME -f 003_seed_data.sql
```

### Step 2: Verify Database Setup

```bash
# Connect to database
psql -h $DB_ENDPOINT -U ecovolt_admin -d $DB_NAME

# Verify tables
\dt

# Check sample data
SELECT COUNT(*) FROM stations;
SELECT COUNT(*) FROM bikes;
SELECT COUNT(*) FROM users;

# Exit
\q
```

---

## Infrastructure Deployment

### Step 1: Initialize Terraform

```bash
# Navigate to project root
cd /path/to/project-ecovolt

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
```

### Step 2: Plan Deployment

```bash
# Create deployment plan
terraform plan \
  -var-file="environments/dev.tfvars" \
  -out=dev.tfplan

# Review the plan carefully
# Verify resource counts and configurations
```

### Step 3: Deploy Infrastructure

```bash
# Apply the plan
terraform apply dev.tfplan

# This will create:
# - VPC and networking (subnets, NAT gateways, etc.)
# - RDS PostgreSQL database
# - DynamoDB tables (batteries, telemetry, notifications)
# - Cognito User Pool
# - Lambda functions (API handler, IoT processor)
# - API Gateway with WAF
# - SNS topics
# - IoT Core rules
# - CloudWatch log groups
# - IAM roles and policies
```

**Expected Duration:** 15-20 minutes

### Step 4: Capture Outputs

```bash
# Save important outputs
terraform output > deployment-outputs.txt

# Key outputs to note:
terraform output api_gateway_invoke_url
terraform output cognito_user_pool_id
terraform output cognito_client_id
terraform output db_endpoint
```

---

## Post-Deployment Verification

### 1. Verify Lambda Functions

```bash
# List Lambda functions
aws lambda list-functions \
  --query 'Functions[?starts_with(FunctionName, `ecovolt-dev`)].FunctionName'

# Test API handler
aws lambda invoke \
  --function-name ecovolt-dev-api-handler \
  --payload '{"httpMethod":"GET","path":"/health"}' \
  response.json

# Check response
cat response.json
```

### 2. Verify API Gateway

```bash
# Get API Gateway URL
API_URL=$(terraform output -raw api_gateway_invoke_url)

# Test health endpoint
curl -X GET "${API_URL}/health"

# Expected response:
# {"status":"healthy"}
```

### 3. Verify Database Connectivity

```bash
# Check Lambda can connect to database
aws lambda invoke \
  --function-name ecovolt-dev-api-handler \
  --payload '{"httpMethod":"GET","path":"/stations"}' \
  response.json

# Check response
cat response.json
```

### 4. Verify DynamoDB Tables

```bash
# List DynamoDB tables
aws dynamodb list-tables \
  --query 'TableNames[?starts_with(@, `ecovolt-dev`)]'

# Verify batteries table
aws dynamodb describe-table \
  --table-name ecovolt-dev-batteries \
  --query 'Table.{Name:TableName,Status:TableStatus,ItemCount:ItemCount}'
```

### 5. Verify Cognito User Pool

```bash
# Get User Pool details
POOL_ID=$(terraform output -raw cognito_user_pool_id)

aws cognito-idp describe-user-pool \
  --user-pool-id $POOL_ID \
  --query 'UserPool.{Name:Name,Status:Status,Id:Id}'
```

### 6. Test User Registration

```bash
API_URL=$(terraform output -raw api_gateway_invoke_url)
CLIENT_ID=$(terraform output -raw cognito_client_id)

# Register a test user
curl -X POST "${API_URL}/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!",
    "name": "Test User",
    "phone": "+233XXXXXXXXX"
  }'
```

### 7. Verify WAF

```bash
# Check WAF Web ACL
aws wafv2 list-web-acls \
  --scope REGIONAL \
  --region $AWS_REGION \
  --query 'WebACLs[?starts_with(Name, `ecovolt-dev`)]'

# Check WAF metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name AllowedRequests \
  --dimensions Name=WebACL,Value=ecovolt-dev-api-gateway-waf \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

### 8. Check CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups \
  --log-group-name-prefix /aws/lambda/ecovolt-dev

# Tail API handler logs
aws logs tail /aws/lambda/ecovolt-dev-api-handler --follow
```

---

## Endpoint Testing

### Public Endpoints (No Auth Required)

```bash
API_URL=$(terraform output -raw api_gateway_invoke_url)

# Health check
curl "${API_URL}/health"

# List stations
curl "${API_URL}/stations"

# Find nearby stations
curl "${API_URL}/stations/nearby?lat=5.6037&lng=-0.1870&radius=10"

# Get station details
curl "${API_URL}/stations/STN-{id}"
```

### Authenticated Endpoints

```bash
# 1. Register user
curl -X POST "${API_URL}/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "rider@example.com",
    "password": "SecurePass123!",
    "name": "John Doe",
    "phone": "+233XXXXXXXXX"
  }'

# 2. Confirm email (check email for code)
curl -X POST "${API_URL}/auth/confirm" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "rider@example.com",
    "confirmation_code": "123456"
  }'

# 3. Login
TOKEN=$(curl -X POST "${API_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "rider@example.com",
    "password": "SecurePass123!"
  }' | jq -r '.token')

# 4. Get profile
curl "${API_URL}/profile" \
  -H "Authorization: Bearer $TOKEN"

# 5. Get wallet
curl "${API_URL}/wallet" \
  -H "Authorization: Bearer $TOKEN"
```

---

## Troubleshooting

### Lambda Function Errors

**Issue:** Lambda function timing out

```bash
# Check Lambda configuration
aws lambda get-function-configuration \
  --function-name ecovolt-dev-api-handler

# Increase timeout if needed
aws lambda update-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --timeout 60
```

**Issue:** Lambda can't connect to database

```bash
# Verify Lambda is in VPC
aws lambda get-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --query 'VpcConfig'

# Check security group rules
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --query 'SecurityGroups[0].IpPermissions'
```

### API Gateway Errors

**Issue:** 403 Forbidden from WAF

```bash
# Check WAF logs
aws logs tail /aws/wafv2/ecovolt-dev-api-gateway --follow

# Temporarily disable WAF for testing
aws wafv2 update-web-acl \
  --id xxx \
  --scope REGIONAL \
  --default-action Allow={}
```

**Issue:** CORS errors

```bash
# Verify CORS configuration
aws apigateway get-integration-response \
  --rest-api-id xxx \
  --resource-id xxx \
  --http-method OPTIONS \
  --status-code 200
```

### Database Connection Issues

**Issue:** Can't connect to RDS

```bash
# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier ecovolt-dev \
  --query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}'

# Verify security group
aws ec2 describe-security-groups \
  --group-ids sg-xxxxx \
  --query 'SecurityGroups[0].IpPermissions'

# Test connection from Lambda subnet
# (requires bastion host or VPN)
psql -h $DB_ENDPOINT -U ecovolt_admin -d ecovolt
```

### DynamoDB Issues

**Issue:** Table not found

```bash
# Verify table exists
aws dynamodb describe-table \
  --table-name ecovolt-dev-batteries

# Check IAM permissions
aws iam get-role-policy \
  --role-name ecovolt-dev-lambda-execution \
  --policy-name ecovolt-dev-lambda-dynamodb
```

---

## Rollback Procedure

If deployment fails or issues arise:

```bash
# 1. Destroy infrastructure
terraform destroy \
  -var-file="environments/dev.tfvars"

# 2. Review errors
cat terraform.log

# 3. Fix issues in configuration

# 4. Re-deploy
terraform apply \
  -var-file="environments/dev.tfvars"
```

---

## Monitoring and Maintenance

### CloudWatch Dashboards

```bash
# Create custom dashboard
aws cloudwatch put-dashboard \
  --dashboard-name ecovolt-dev-overview \
  --dashboard-body file://dashboard-config.json
```

### Set Up Alarms

```bash
# Lambda errors alarm
aws cloudwatch put-metric-alarm \
  --alarm-name ecovolt-dev-lambda-errors \
  --alarm-description "Alert on Lambda errors" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=FunctionName,Value=ecovolt-dev-api-handler
```

### Regular Maintenance

1. **Weekly:**
   - Review CloudWatch logs for errors
   - Check API Gateway metrics
   - Monitor DynamoDB capacity

2. **Monthly:**
   - Review and rotate secrets
   - Update Lambda runtime if needed
   - Review WAF blocked requests
   - Optimize database queries

3. **Quarterly:**
   - Security audit
   - Cost optimization review
   - Performance testing
   - Disaster recovery drill

---

## Next Steps

After successful deployment:

1. ✅ Configure custom domain name for API Gateway
2. ✅ Set up CloudWatch dashboards
3. ✅ Configure SNS for alerts
4. ✅ Deploy mobile application
5. ✅ Deploy admin portal
6. ✅ Perform load testing
7. ✅ Security audit
8. ✅ Documentation review

---

## Support

For issues or questions:
- Check logs: `aws logs tail /aws/lambda/ecovolt-dev-api-handler --follow`
- Review Terraform state: `terraform show`
- Consult troubleshooting guide above

---

**Last Updated:** 2024-11-24  
**Version:** 1.0.0
