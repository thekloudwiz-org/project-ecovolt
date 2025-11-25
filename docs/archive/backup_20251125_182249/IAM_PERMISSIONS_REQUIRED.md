# EcoVolt Infrastructure - Required IAM Permissions

This document lists all AWS service permissions required for the GitHub Actions OIDC role to successfully plan and apply the EcoVolt Terraform infrastructure.

## Complete IAM Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2Permissions",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "VPCPermissions",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "RDSPermissions",
      "Effect": "Allow",
      "Action": [
        "rds:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DynamoDBPermissions",
      "Effect": "Allow",
      "Action": [
        "dynamodb:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3Permissions",
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LambdaPermissions",
      "Effect": "Allow",
      "Action": [
        "lambda:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "APIGatewayPermissions",
      "Effect": "Allow",
      "Action": [
        "apigateway:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CognitoPermissions",
      "Effect": "Allow",
      "Action": [
        "cognito-idp:*",
        "cognito-identity:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:*",
        "logs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SNSPermissions",
      "Effect": "Allow",
      "Action": [
        "sns:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SQSPermissions",
      "Effect": "Allow",
      "Action": [
        "sqs:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KinesisPermissions",
      "Effect": "Allow",
      "Action": [
        "kinesis:*",
        "firehose:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IoTPermissions",
      "Effect": "Allow",
      "Action": [
        "iot:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecretsManagerPermissions",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SSMPermissions",
      "Effect": "Allow",
      "Action": [
        "ssm:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "KMSPermissions",
      "Effect": "Allow",
      "Action": [
        "kms:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ElastiCachePermissions",
      "Effect": "Allow",
      "Action": [
        "elasticache:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudFrontPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudfront:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Route53Permissions",
      "Effect": "Allow",
      "Action": [
        "route53:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ACMPermissions",
      "Effect": "Allow",
      "Action": [
        "acm:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "WAFPermissions",
      "Effect": "Allow",
      "Action": [
        "wafv2:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "GluePermissions",
      "Effect": "Allow",
      "Action": [
        "glue:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AthenaPermissions",
      "Effect": "Allow",
      "Action": [
        "athena:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EventsPermissions",
      "Effect": "Allow",
      "Action": [
        "events:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "BackupPermissions",
      "Effect": "Allow",
      "Action": [
        "backup:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ConfigPermissions",
      "Effect": "Allow",
      "Action": [
        "config:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "GuardDutyPermissions",
      "Effect": "Allow",
      "Action": [
        "guardduty:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SecurityHubPermissions",
      "Effect": "Allow",
      "Action": [
        "securityhub:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudTrailPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudtrail:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "XRayPermissions",
      "Effect": "Allow",
      "Action": [
        "xray:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "GreengrassPermissions",
      "Effect": "Allow",
      "Action": [
        "greengrass:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "STSPermissions",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole",
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ResourceGroupsPermissions",
      "Effect": "Allow",
      "Action": [
        "resource-groups:*",
        "tag:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Service-by-Service Breakdown

### Core Infrastructure
- **EC2/VPC**: `ec2:*` - VPC, subnets, security groups, NAT gateways, internet gateways
- **IAM**: `iam:*` - Roles, policies, instance profiles for all services

### Compute & API
- **Lambda**: `lambda:*` - API handlers, IoT processors, stream processors
- **API Gateway**: `apigateway:*` - REST APIs, authorizers, deployments
- **Cognito**: `cognito-idp:*`, `cognito-identity:*` - User pools, identity pools

### Data Storage
- **RDS**: `rds:*` - PostgreSQL database, parameter groups, subnet groups
- **DynamoDB**: `dynamodb:*` - Tables for sessions, cache, real-time data
- **ElastiCache**: `elasticache:*` - Redis clusters for caching
- **S3**: `s3:*` - Data lake, backups, logs, static assets

### Analytics & Streaming
- **Kinesis**: `kinesis:*`, `firehose:*` - Data streams, Firehose delivery
- **Glue**: `glue:*` - Data catalog, crawlers, ETL jobs
- **Athena**: `athena:*` - Query engine for data lake

### IoT & Edge
- **IoT Core**: `iot:*` - Thing registry, rules, certificates
- **Greengrass**: `greengrass:*` - Edge computing for charging stations

### Security & Compliance
- **KMS**: `kms:*` - Encryption keys for all services
- **Secrets Manager**: `secretsmanager:*` - Database passwords, API keys
- **WAF**: `wafv2:*` - Web application firewall rules
- **GuardDuty**: `guardduty:*` - Threat detection
- **Security Hub**: `securityhub:*` - Security posture management
- **Config**: `config:*` - Resource compliance tracking
- **CloudTrail**: `cloudtrail:*` - Audit logging

### Monitoring & Observability
- **CloudWatch**: `cloudwatch:*`, `logs:*` - Metrics, alarms, log groups
- **X-Ray**: `xray:*` - Distributed tracing
- **SNS**: `sns:*` - Alarm notifications
- **SQS**: `sqs:*` - Dead letter queues

### Content Delivery
- **CloudFront**: `cloudfront:*` - CDN distributions
- **Route53**: `route53:*` - DNS management
- **ACM**: `acm:*` - SSL/TLS certificates

### Disaster Recovery
- **Backup**: `backup:*` - Automated backup plans
- **EventBridge**: `events:*` - Event-driven automation

### Configuration Management
- **SSM Parameter Store**: `ssm:*` - Configuration parameters
- **Resource Groups**: `resource-groups:*`, `tag:*` - Resource organization

### Identity
- **STS**: `sts:AssumeRole`, `sts:GetCallerIdentity` - Role assumption for OIDC

## Terraform-Specific Requirements

### State Management (S3 Backend)
The Terraform state is stored in S3, so the role needs:
- `s3:GetObject` - Read state file
- `s3:PutObject` - Write state file
- `s3:ListBucket` - List state bucket
- `dynamodb:GetItem` - Read state lock
- `dynamodb:PutItem` - Acquire state lock
- `dynamodb:DeleteItem` - Release state lock

These are included in the `s3:*` and `dynamodb:*` permissions above.

## Minimal Permissions (Production Recommendation)

For production, consider using more restrictive permissions with resource-level constraints:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "dynamodb:*",
        "s3:*",
        "lambda:*",
        "iam:*",
        "apigateway:*",
        "cognito-idp:*",
        "cognito-identity:*",
        "cloudwatch:*",
        "logs:*",
        "sns:*",
        "sqs:*",
        "kinesis:*",
        "firehose:*",
        "iot:*",
        "secretsmanager:*",
        "ssm:*",
        "kms:*",
        "elasticache:*",
        "cloudfront:*",
        "route53:*",
        "acm:*",
        "wafv2:*",
        "glue:*",
        "athena:*",
        "events:*",
        "backup:*",
        "config:*",
        "guardduty:*",
        "securityhub:*",
        "cloudtrail:*",
        "xray:*",
        "greengrass:*",
        "sts:AssumeRole",
        "sts:GetCallerIdentity",
        "resource-groups:*",
        "tag:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## How to Apply These Permissions

1. **Create/Update the IAM Role** for GitHub Actions OIDC
2. **Attach an inline policy** or **managed policy** with the permissions above
3. **Update the trust policy** to allow GitHub Actions to assume the role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
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

## Verification

After applying permissions, test with:

```bash
# Test Terraform plan
terraform plan -var-file=environments/dev.tfvars

# Check for any permission errors in the output
```

## Notes

- These permissions use wildcard (`*`) for actions within each service as requested
- For production, consider adding resource-level restrictions
- Some services (like IAM) require broad permissions for Terraform to manage resources
- The `sts:GetCallerIdentity` permission is used by Terraform AWS provider for validation

---

**Last Updated**: 2024-11-24  
**Terraform Version**: 1.14.0  
**AWS Provider Version**: ~> 5.0
