# Security Module

This module creates comprehensive security infrastructure including KMS encryption keys, CloudTrail API logging, GuardDuty threat detection, and base IAM roles following least-privilege principles.

## Features

- **KMS Customer Managed Keys**: Encryption keys with automatic rotation
- **CloudTrail**: Multi-region API call logging with S3 and CloudWatch integration
- **GuardDuty**: Threat detection and continuous security monitoring
- **Base IAM Roles**: Least-privilege roles for Lambda and ECS services
- **Encryption at Rest**: S3 bucket encryption for CloudTrail logs
- **Log Lifecycle Management**: Automatic archival to Glacier and expiration
- **SSM Parameter Store**: Secure storage of resource identifiers

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Infrastructure                   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  KMS Key                              │   │
│  │  - Customer Managed                                   │   │
│  │  - Automatic Rotation                                 │   │
│  │  - Multi-service Access                               │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                    │
│                          ▼                                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  CloudTrail                           │   │
│  │  - Multi-region Trail                                 │   │
│  │  - S3 Bucket (encrypted)                              │   │
│  │  - CloudWatch Logs                                    │   │
│  │  - Log File Validation                                │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  GuardDuty                            │   │
│  │  - Threat Detection                                   │   │
│  │  - 15-minute Findings                                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Base IAM Roles                           │   │
│  │  - Lambda Execution (Logs only)                       │   │
│  │  - ECS Task Execution                                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## Usage

```hcl
module "security" {
  source = "./modules/security"

  project_name                  = "ecovolt"
  environment                   = "prod"
  enable_cloudtrail             = true
  enable_guardduty              = true
  enable_kms_key_rotation       = true
  cloudtrail_log_retention_days = 90

  tags = {
    Project   = "EcoVolt"
    ManagedBy = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | "ecovolt" | no |
| environment | Environment name | string | - | yes |
| kms_key_admins | List of IAM principal ARNs for KMS key administration | list(string) | [] | no |
| enable_cloudtrail | Enable CloudTrail for API logging | bool | true | no |
| cloudtrail_bucket_name | S3 bucket name for CloudTrail logs | string | "" | no |
| enable_guardduty | Enable GuardDuty for threat detection | bool | true | no |
| cloudtrail_log_retention_days | Days to retain CloudTrail logs in S3 | number | 90 | no |
| enable_kms_key_rotation | Enable automatic KMS key rotation | bool | true | no |
| tags | Common tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| kms_key_id | KMS key ID |
| kms_key_arn | KMS key ARN |
| kms_key_alias | KMS key alias |
| cloudtrail_arn | CloudTrail trail ARN |
| cloudtrail_bucket_name | S3 bucket name for CloudTrail logs |
| cloudtrail_log_group_name | CloudWatch Log Group name for CloudTrail |
| guardduty_detector_id | GuardDuty detector ID |
| lambda_execution_role_arn | IAM role ARN for Lambda execution |
| lambda_execution_role_name | IAM role name for Lambda execution |
| ecs_task_execution_role_arn | IAM role ARN for ECS task execution |
| ecs_task_execution_role_name | IAM role name for ECS task execution |
| ssm_kms_key_id_parameter | SSM Parameter name for KMS key ID |
| ssm_kms_key_arn_parameter | SSM Parameter name for KMS key ARN |
| ssm_parameter_prefix | SSM Parameter Store prefix |

## Security Features

### KMS Encryption

The module creates a customer-managed KMS key with:
- **Automatic Rotation**: Keys rotate annually when enabled
- **Multi-Service Access**: Configured for CloudTrail, S3, RDS, DynamoDB, Lambda, Kinesis
- **CloudWatch Logs Integration**: Supports log encryption
- **Least Privilege**: Service-specific permissions

### CloudTrail Logging

CloudTrail configuration includes:
- **Multi-Region Trail**: Captures events from all regions
- **Management Events**: Logs all control plane operations
- **Data Events**: Logs S3 object operations and Lambda invocations
- **Log File Validation**: Ensures log integrity
- **Encrypted Storage**: S3 bucket encrypted with KMS
- **CloudWatch Integration**: Real-time log streaming
- **Lifecycle Management**: Automatic archival to Glacier

### GuardDuty Threat Detection

GuardDuty provides:
- **Continuous Monitoring**: 24/7 threat detection
- **Machine Learning**: Anomaly detection
- **Threat Intelligence**: AWS and third-party feeds
- **Finding Frequency**: 15-minute updates
- **Multi-Account Support**: Ready for organization-wide deployment

### IAM Roles (Least Privilege)

Base IAM roles follow least-privilege principles:

**Lambda Execution Role**:
- CloudWatch Logs access only (CreateLogGroup, CreateLogStream, PutLogEvents)
- No additional permissions by default
- Extend with specific policies as needed

**ECS Task Execution Role**:
- ECR image pull permissions
- CloudWatch Logs access
- Secrets Manager access (via AWS managed policy)

## Naming Convention

All resources follow: `<environment>-<project>-<resource>`

Examples:
- KMS Key Alias: `alias/prod-ecovolt-main`
- CloudTrail: `prod-ecovolt-cloudtrail`
- S3 Bucket: `prod-ecovolt-cloudtrail-logs-123456789012`
- IAM Role: `prod-ecovolt-lambda-execution-role`

## SSM Parameter Store

Security resource identifiers are stored in SSM Parameter Store:

- KMS Key ID: `/<environment>/<project>/security/kms_key_id`
- KMS Key ARN: `/<environment>/<project>/security/kms_key_arn`
- Lambda Role ARN: `/<environment>/<project>/security/lambda_execution_role_arn`
- ECS Role ARN: `/<environment>/<project>/security/ecs_task_execution_role_arn`
- CloudTrail ARN: `/<environment>/<project>/security/cloudtrail_arn`
- GuardDuty ID: `/<environment>/<project>/security/guardduty_detector_id`

Example usage:
```hcl
data "aws_ssm_parameter" "kms_key_arn" {
  name = "/prod/ecovolt/security/kms_key_arn"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_ssm_parameter.kms_key_arn.value
    }
  }
}
```

## Cost Considerations

- **KMS Key**: $1/month per key + $0.03 per 10,000 requests
- **CloudTrail**: First trail free, $2 per 100,000 management events
- **S3 Storage**: Standard storage rates + Glacier for archived logs
- **GuardDuty**: $4.50 per million CloudTrail events analyzed
- **CloudWatch Logs**: $0.50 per GB ingested + storage costs

To reduce costs in non-production:
- Set `enable_cloudtrail = false` for dev environments
- Set `enable_guardduty = false` for dev environments
- Reduce `cloudtrail_log_retention_days` for faster archival

## Compliance

This module helps meet compliance requirements:

- **HIPAA**: Encryption at rest and in transit, audit logging
- **PCI DSS**: CloudTrail logging, encryption, access controls
- **SOC 2**: Audit trails, encryption, threat detection
- **GDPR**: Data encryption, access logging, security monitoring

## Examples

### Development Environment (Minimal)
```hcl
module "security" {
  source = "./modules/security"

  project_name                  = "ecovolt"
  environment                   = "dev"
  enable_cloudtrail             = false  # Cost savings
  enable_guardduty              = false  # Cost savings
  enable_kms_key_rotation       = true
  cloudtrail_log_retention_days = 30

  tags = {
    Environment = "Development"
  }
}
```

### Production Environment (Full Security)
```hcl
module "security" {
  source = "./modules/security"

  project_name                  = "ecovolt"
  environment                   = "prod"
  enable_cloudtrail             = true
  enable_guardduty              = true
  enable_kms_key_rotation       = true
  cloudtrail_log_retention_days = 365  # 1 year retention

  kms_key_admins = [
    "arn:aws:iam::123456789012:user/admin",
    "arn:aws:iam::123456789012:role/SecurityAdmin"
  ]

  tags = {
    Environment = "Production"
    Compliance  = "Required"
  }
}
```

## Extending IAM Roles

The base IAM roles can be extended with additional policies:

```hcl
# Add DynamoDB access to Lambda role
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda-dynamodb-access"
  role = module.security.lambda_execution_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/my-table"
      }
    ]
  })
}
```

## Troubleshooting

### CloudTrail Not Logging
- Verify S3 bucket policy allows CloudTrail writes
- Check IAM role has CloudWatch Logs permissions
- Allow 15 minutes for initial log delivery
- Verify trail is enabled and multi-region

### KMS Key Access Denied
- Verify service principals are in key policy
- Check IAM policies grant kms:Decrypt permissions
- Verify encryption context matches (for CloudTrail)
- Check key is not pending deletion

### GuardDuty No Findings
- GuardDuty requires time to establish baseline (24-48 hours)
- Verify detector is enabled
- Check finding frequency setting
- Review CloudTrail is delivering logs

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## References

- [AWS KMS Documentation](https://docs.aws.amazon.com/kms/)
- [AWS CloudTrail Documentation](https://docs.aws.amazon.com/cloudtrail/)
- [AWS GuardDuty Documentation](https://docs.aws.amazon.com/guardduty/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)
