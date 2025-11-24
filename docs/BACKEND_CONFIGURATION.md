# Terraform Backend Configuration

## Overview

The EcoVolt infrastructure uses a shared S3 bucket for Terraform state management with environment-specific state files.

## Backend Details

- **S3 Bucket**: `thekloudwiz-tf-state-bucket`
- **Region**: `eu-central-1`
- **Encryption**: Enabled (AES-256)
- **State Locking**: DynamoDB table `terraform-state-locks`

## State File Structure

```
thekloudwiz-tf-state-bucket/
└── project-ecovolt/
    ├── dev-tf.state
    ├── staging-tf.state
    └── prod-tf.state
```

## Environment-Specific Keys

| Environment | State File Key |
|-------------|----------------|
| Dev | `project-ecovolt/dev-tf.state` |
| Staging | `project-ecovolt/staging-tf.state` |
| Production | `project-ecovolt/prod-tf.state` |

## Local Development

### Initialize for Specific Environment

```bash
# Dev environment
make init-dev
# or
terraform init -backend-config="key=project-ecovolt/dev-tf.state"

# Staging environment
make init-staging
# or
terraform init -backend-config="key=project-ecovolt/staging-tf.state"

# Production environment
make init-prod
# or
terraform init -backend-config="key=project-ecovolt/prod-tf.state"
```

### Switch Between Environments

```bash
# Reinitialize with different backend key
terraform init -reconfigure -backend-config="key=project-ecovolt/staging-tf.state"
```

## CI/CD Configuration

The GitHub Actions workflows automatically configure the correct backend key based on the environment:

```yaml
- name: Terraform Init
  run: |
    terraform init \
      -backend-config="key=project-ecovolt/${{ inputs.environment }}-tf.state"
```

## Backend Configuration File

The `backend.tf` file contains the base configuration:

```hcl
terraform {
  backend "s3" {
    bucket         = "thekloudwiz-tf-state-bucket"
    key            = "project-ecovolt/dev-tf.state"  # Override per environment
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
```

## State Locking

State locking prevents concurrent modifications using DynamoDB:

- **Table**: `terraform-state-locks`
- **Primary Key**: `LockID` (String)
- **Purpose**: Prevents race conditions during `terraform apply`

### Check Lock Status

```bash
# List locks
aws dynamodb scan \
  --table-name terraform-state-locks \
  --region eu-central-1

# Force unlock (use with caution!)
terraform force-unlock LOCK_ID
```

## State Management Commands

### View Current State

```bash
# List resources
terraform state list

# Show specific resource
terraform state show aws_vpc.main

# Show all state
terraform show
```

### Pull State Locally

```bash
# Download current state
terraform state pull > terraform.tfstate.backup
```

### Push State (Dangerous!)

```bash
# Upload state (use with extreme caution)
terraform state push terraform.tfstate
```

### Move Resources

```bash
# Move resource to different address
terraform state mv aws_instance.old aws_instance.new

# Move resource to different module
terraform state mv aws_instance.web module.compute.aws_instance.web
```

### Remove Resources

```bash
# Remove from state (doesn't destroy resource)
terraform state rm aws_instance.old
```

## Backup and Recovery

### Manual Backup

```bash
# Download state file
aws s3 cp s3://thekloudwiz-tf-state-bucket/project-ecovolt/prod-tf.state ./backup/prod-tf.state.$(date +%Y%m%d)

# List all versions (if versioning enabled)
aws s3api list-object-versions \
  --bucket thekloudwiz-tf-state-bucket \
  --prefix project-ecovolt/prod-tf.state
```

### Restore from Backup

```bash
# Upload backup (use with caution!)
aws s3 cp ./backup/prod-tf.state.20240115 s3://thekloudwiz-tf-state-bucket/project-ecovolt/prod-tf.state

# Then reinitialize
terraform init -reconfigure
```

## S3 Bucket Configuration

### Required Bucket Settings

1. **Versioning**: Enabled (recommended)
2. **Encryption**: AES-256 or KMS
3. **Access**: Private (no public access)
4. **Lifecycle**: Optional (keep old versions for 90 days)

### Verify Bucket Configuration

```bash
# Check versioning
aws s3api get-bucket-versioning --bucket thekloudwiz-tf-state-bucket

# Check encryption
aws s3api get-bucket-encryption --bucket thekloudwiz-tf-state-bucket

# Check public access block
aws s3api get-public-access-block --bucket thekloudwiz-tf-state-bucket
```

## DynamoDB Table Configuration

### Required Table Settings

- **Table Name**: `terraform-state-locks`
- **Primary Key**: `LockID` (String)
- **Billing Mode**: PAY_PER_REQUEST (recommended)
- **Region**: `eu-central-1`

### Verify Table Exists

```bash
# Describe table
aws dynamodb describe-table \
  --table-name terraform-state-locks \
  --region eu-central-1
```

### Create Table (if needed)

```bash
aws dynamodb create-table \
  --table-name terraform-state-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

## IAM Permissions Required

Your IAM role/user needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketVersioning"
      ],
      "Resource": "arn:aws:s3:::thekloudwiz-tf-state-bucket"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::thekloudwiz-tf-state-bucket/project-ecovolt/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:eu-central-1:*:table/terraform-state-locks"
    }
  ]
}
```

## Troubleshooting

### Error: "Failed to get existing workspaces"

**Cause**: Backend not initialized or incorrect bucket name

**Solution**:
```bash
terraform init -reconfigure -backend-config="key=project-ecovolt/dev-tf.state"
```

### Error: "Error locking state"

**Cause**: Another process has a lock or stale lock

**Solution**:
```bash
# Check for locks
aws dynamodb scan --table-name terraform-state-locks --region eu-central-1

# Force unlock (if safe)
terraform force-unlock LOCK_ID
```

### Error: "Access Denied" on S3

**Cause**: Insufficient IAM permissions

**Solution**: Verify IAM role has permissions listed above

### Error: "State file not found"

**Cause**: Wrong backend key or first-time initialization

**Solution**:
```bash
# Verify correct key
terraform init -backend-config="key=project-ecovolt/dev-tf.state"
```

## Best Practices

1. ✅ **Never commit state files** to git (already in `.gitignore`)
2. ✅ **Always use backend** (don't use local state)
3. ✅ **Enable S3 versioning** for state file history
4. ✅ **Use separate state files** per environment
5. ✅ **Regular backups** of state files
6. ✅ **State locking** to prevent concurrent modifications
7. ✅ **Least privilege** IAM permissions for state access
8. ✅ **Encrypt state files** at rest and in transit

## Migration from Local State

If you have local state files:

```bash
# 1. Backup local state
cp terraform.tfstate terraform.tfstate.backup

# 2. Configure backend
# (already done in backend.tf)

# 3. Initialize with migration
terraform init -migrate-state -backend-config="key=project-ecovolt/dev-tf.state"

# 4. Verify migration
terraform state list

# 5. Remove local state (after verification)
rm terraform.tfstate terraform.tfstate.backup
```

## State File Security

### Sensitive Data in State

State files may contain sensitive data:
- Database passwords
- API keys
- Private keys
- Resource IDs

### Security Measures

1. **Encryption**: S3 bucket encryption enabled
2. **Access Control**: Restrict S3 bucket access
3. **Versioning**: Track changes and enable rollback
4. **Audit**: CloudTrail logs for S3 access
5. **Secrets**: Use AWS Secrets Manager for sensitive values

## Monitoring

### CloudWatch Alarms

Set up alarms for:
- S3 bucket access
- DynamoDB table throttling
- State file modifications

### CloudTrail

Monitor state file access:
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=thekloudwiz-tf-state-bucket \
  --region eu-central-1
```

## References

- [Terraform S3 Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [State Locking](https://www.terraform.io/docs/language/state/locking.html)
- [State Management](https://www.terraform.io/docs/cli/state/index.html)
