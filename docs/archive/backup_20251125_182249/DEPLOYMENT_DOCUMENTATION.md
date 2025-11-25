# EcoVolt Deployment Documentation

## Overview

This document provides comprehensive instructions for deploying the EcoVolt Application Suite to production environments.

## Architecture Components

1. **Backend API** - AWS Lambda functions behind API Gateway
2. **Mobile Application** - React Native app for iOS and Android
3. **Admin Portal** - React web application
4. **Infrastructure** - AWS services (RDS, DynamoDB, Cognito, IoT Core, SNS)

## Prerequisites

### Required Tools
- AWS CLI (v2.x)
- Terraform (v1.5+)
- Node.js (v18+)
- Python (v3.11+)
- Expo CLI (for mobile app)
- Git

### AWS Account Requirements
- AWS account with appropriate permissions
- IAM user with AdministratorAccess or equivalent
- AWS CLI configured with credentials

### Required AWS Services
- API Gateway
- Lambda
- RDS PostgreSQL
- DynamoDB
- Cognito
- IoT Core
- SNS
- CloudWatch
- Secrets Manager
- S3 (for static hosting)
- CloudFront (optional, for CDN)

## Environment Setup

### 1. Clone Repository
```bash
git clone https://github.com/your-org/ecovolt.git
cd ecovolt
```

### 2. Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (e.g., eu-central-1)
```

### 3. Set Environment Variables
```bash
export TF_VAR_environment=production
export TF_VAR_aws_region=eu-central-1
export TF_VAR_db_password=<secure-password>
```

## Backend Deployment

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Review Infrastructure Plan
```bash
terraform plan -var-file=environments/prod.tfvars -out=prod.tfplan
```

### Step 3: Apply Infrastructure
```bash
terraform apply prod.tfplan
```

This will create:
- VPC with public and private subnets
- RDS PostgreSQL database
- DynamoDB tables
- Lambda functions
- API Gateway
- Cognito User Pool
- IoT Core configuration
- SNS topics
- CloudWatch log groups

### Step 4: Run Database Migrations
```bash
# Connect to RDS instance
psql -h <rds-endpoint> -U ecovolt_admin -d ecovolt

# Run migration scripts
\i application/backend/migrations/001_initial_schema.sql
\i application/backend/migrations/002_indexes.sql
\i application/backend/migrations/003_seed_data.sql
```

### Step 5: Deploy Lambda Functions
```bash
# Package Lambda functions
cd application/backend
./scripts/package_lambdas.sh

# Deploy via Terraform
terraform apply -target=module.compute
```

### Step 6: Configure API Gateway
```bash
# API Gateway is configured via Terraform
# Get API endpoint
terraform output api_gateway_url
```

### Step 7: Verify Deployment
```bash
# Test API health endpoint
curl https://<api-gateway-url>/v1/health

# Expected response:
# {"status": "healthy", "version": "1.0.0"}
```

## Mobile Application Deployment

### iOS Deployment

#### Step 1: Configure Environment
```bash
cd application/mobile/EcoVolt
cp .env.example .env
# Edit .env with production values
```

#### Step 2: Install Dependencies
```bash
npm install
```

#### Step 3: Build for iOS
```bash
# Using Expo
expo build:ios

# Or using EAS Build
eas build --platform ios --profile production
```

#### Step 4: Submit to App Store
```bash
# Download IPA file
# Upload to App Store Connect
# Submit for review
```

### Android Deployment

#### Step 1: Build for Android
```bash
# Using Expo
expo build:android

# Or using EAS Build
eas build --platform android --profile production
```

#### Step 2: Submit to Play Store
```bash
# Download APK/AAB file
# Upload to Google Play Console
# Submit for review
```

## Admin Portal Deployment

### Step 1: Configure Environment
```bash
cd application/admin-portal
cp .env.example .env
# Edit .env with production values
```

### Step 2: Build for Production
```bash
npm install
npm run build
```

### Step 3: Deploy to S3
```bash
# Create S3 bucket
aws s3 mb s3://ecovolt-admin-portal

# Enable static website hosting
aws s3 website s3://ecovolt-admin-portal \
  --index-document index.html \
  --error-document index.html

# Upload build files
aws s3 sync dist/ s3://ecovolt-admin-portal --delete

# Set bucket policy for public read
aws s3api put-bucket-policy \
  --bucket ecovolt-admin-portal \
  --policy file://bucket-policy.json
```

### Step 4: Configure CloudFront (Optional)
```bash
# Create CloudFront distribution
aws cloudfront create-distribution \
  --origin-domain-name ecovolt-admin-portal.s3.amazonaws.com \
  --default-root-object index.html
```

## Post-Deployment Configuration

### 1. Configure Cognito User Pool

#### Create Admin User
```bash
aws cognito-idp admin-create-user \
  --user-pool-id <user-pool-id> \
  --username admin@ecovolt.com \
  --user-attributes Name=email,Value=admin@ecovolt.com \
  --temporary-password TempPass123!
```

#### Add User to Admin Group
```bash
aws cognito-idp admin-add-user-to-group \
  --user-pool-id <user-pool-id> \
  --username admin@ecovolt.com \
  --group-name admin
```

### 2. Configure IoT Core

#### Create IoT Thing Types
```bash
# Create bike thing type
aws iot create-thing-type \
  --thing-type-name EcoVoltBike

# Create station thing type
aws iot create-thing-type \
  --thing-type-name EcoVoltStation
```

#### Create IoT Policy
```bash
aws iot create-policy \
  --policy-name EcoVoltDevicePolicy \
  --policy-document file://iot-policy.json
```

### 3. Configure SNS Topics

#### Create SNS Topic for Notifications
```bash
aws sns create-topic --name ecovolt-notifications

# Subscribe Lambda function
aws sns subscribe \
  --topic-arn <topic-arn> \
  --protocol lambda \
  --notification-endpoint <lambda-arn>
```

### 4. Seed Initial Data

#### Create Sample Stations
```bash
# Run seed script
python application/backend/scripts/seed_stations.py
```

#### Create Sample Bikes
```bash
python application/backend/scripts/seed_bikes.py
```

## Monitoring and Logging

### CloudWatch Dashboards

#### Create Dashboard
```bash
aws cloudwatch put-dashboard \
  --dashboard-name EcoVolt-Production \
  --dashboard-body file://cloudwatch-dashboard.json
```

### CloudWatch Alarms

#### API Error Rate Alarm
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name ecovolt-api-errors \
  --alarm-description "Alert on high API error rate" \
  --metric-name 5XXError \
  --namespace AWS/ApiGateway \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

#### Database Connection Alarm
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name ecovolt-db-connections \
  --alarm-description "Alert on high DB connections" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

### Log Groups

All Lambda functions automatically create CloudWatch log groups:
- `/aws/lambda/ecovolt-api-handler`
- `/aws/lambda/ecovolt-iot-processor`
- `/aws/lambda/ecovolt-stream-processor`

## Backup and Disaster Recovery

### Database Backups

#### Automated Backups
RDS automated backups are configured via Terraform:
- Backup retention: 7 days
- Backup window: 03:00-04:00 UTC
- Maintenance window: Sun 04:00-05:00 UTC

#### Manual Snapshot
```bash
aws rds create-db-snapshot \
  --db-instance-identifier ecovolt-db \
  --db-snapshot-identifier ecovolt-db-snapshot-$(date +%Y%m%d)
```

### DynamoDB Backups

#### Enable Point-in-Time Recovery
```bash
aws dynamodb update-continuous-backups \
  --table-name ecovolt-telemetry \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true
```

#### Create On-Demand Backup
```bash
aws dynamodb create-backup \
  --table-name ecovolt-telemetry \
  --backup-name ecovolt-telemetry-backup-$(date +%Y%m%d)
```

## Rollback Procedures

### Backend Rollback

#### Revert to Previous Terraform State
```bash
# List state versions
terraform state list

# Revert to previous version
terraform apply -var-file=environments/prod.tfvars -target=<resource>
```

#### Rollback Lambda Function
```bash
# List function versions
aws lambda list-versions-by-function \
  --function-name ecovolt-api-handler

# Update alias to previous version
aws lambda update-alias \
  --function-name ecovolt-api-handler \
  --name production \
  --function-version <previous-version>
```

### Mobile App Rollback

#### iOS
- Submit new build with previous version to App Store
- Expedited review if critical

#### Android
- Upload previous APK version to Play Store
- Rollout to percentage of users first

### Admin Portal Rollback

```bash
# Restore previous S3 version
aws s3 sync s3://ecovolt-admin-portal-backup/ s3://ecovolt-admin-portal/

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/*"
```

## Security Checklist

- [ ] All secrets stored in AWS Secrets Manager
- [ ] Database encryption at rest enabled
- [ ] SSL/TLS certificates configured
- [ ] WAF rules configured on API Gateway
- [ ] VPC security groups properly configured
- [ ] IAM roles follow least privilege principle
- [ ] CloudWatch logging enabled for all services
- [ ] Cognito MFA enabled for admin users
- [ ] API rate limiting configured
- [ ] Regular security audits scheduled

## Performance Optimization

### Lambda Optimization
- Provisioned concurrency for API handler
- Memory allocation: 1024 MB
- Timeout: 30 seconds
- Reserved concurrent executions: 100

### Database Optimization
- Read replicas for analytics queries
- Connection pooling configured
- Query performance monitoring enabled
- Indexes on frequently queried columns

### API Gateway Optimization
- Caching enabled (5 minutes TTL)
- Compression enabled
- Throttling: 1000 requests/second

## Troubleshooting

### Common Issues

#### Lambda Timeout
```bash
# Increase timeout
aws lambda update-function-configuration \
  --function-name ecovolt-api-handler \
  --timeout 60
```

#### Database Connection Issues
```bash
# Check security group rules
aws ec2 describe-security-groups \
  --group-ids <security-group-id>

# Verify Lambda VPC configuration
aws lambda get-function-configuration \
  --function-name ecovolt-api-handler
```

#### API Gateway 502 Errors
```bash
# Check Lambda logs
aws logs tail /aws/lambda/ecovolt-api-handler --follow

# Check API Gateway logs
aws logs tail /aws/apigateway/ecovolt-api --follow
```

## Maintenance Windows

### Scheduled Maintenance
- **Database**: Sundays 04:00-05:00 UTC
- **Application**: Saturdays 02:00-04:00 UTC

### Maintenance Procedures
1. Notify users 48 hours in advance
2. Enable maintenance mode
3. Perform updates
4. Run smoke tests
5. Disable maintenance mode
6. Monitor for issues

## Support Contacts

- **DevOps Team**: devops@ecovolt.com
- **On-Call**: +233-XXX-XXXX
- **AWS Support**: Enterprise Support Plan

## Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [React Native Deployment Guide](https://reactnative.dev/docs/running-on-device)

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2024-01-15 | 1.0.0 | Initial production deployment |
