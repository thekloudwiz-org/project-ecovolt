# Lambda-Based Database Migration Solution

## Problem

GitHub Actions runners cannot connect to RDS PostgreSQL database because:
- RDS is in a private subnet (10.0.21.100)
- No public access configured (security best practice)
- Connection timeout when trying to run `psql` from GitHub Actions

## Solution

Implemented a Lambda-based migration system that runs inside the VPC with access to RDS.

### Architecture

```
GitHub Actions
    ↓
    1. Upload migrations to S3
    ↓
    2. Invoke Migration Lambda
    ↓
Migration Lambda (in VPC)
    ↓
    3. Download migrations from S3
    ↓
    4. Connect to RDS (private subnet)
    ↓
    5. Apply migrations
    ↓
    6. Track in schema_migrations table
```

### Components

#### 1. Migration Lambda Function

**File:** `application/backend/functions/db_migrator.py`

**Features:**
- Runs inside VPC with RDS access
- Fetches credentials from Secrets Manager
- Downloads migration files from S3
- Tracks applied migrations
- Supports dry-run mode
- Comprehensive error handling

**Environment Variables:**
- `DB_SECRET_ARN` - ARN of database credentials secret
- `MIGRATION_BUCKET` - S3 bucket for migration files
- `MIGRATION_PREFIX` - S3 prefix for migrations
- `ENVIRONMENT` - Environment name (dev/staging/prod)

#### 2. Terraform Configuration

**File:** `modules/compute/db_migrator.tf`

**Resources:**
- Lambda function with VPC configuration
- CloudWatch Log Group
- IAM policies for S3 and Secrets Manager access

**Configuration:**
- Memory: 512 MB (for database operations)
- Timeout: 300 seconds (5 minutes)
- Runtime: Python 3.11
- VPC: Private subnets with RDS access

#### 3. GitHub Actions Workflow

**File:** `.github/workflows/backend-reusable.yml`

**Steps:**
1. Upload migration files to S3
2. Invoke migration Lambda function
3. Check response and display results
4. Fail deployment if migrations fail

### Usage

#### Automated (CI/CD)

Migrations run automatically during backend deployment:

```yaml
- name: Upload migrations to S3
- name: Run database migrations via Lambda
```

#### Manual Invocation

Invoke the Lambda function directly:

```bash
aws lambda invoke \
  --function-name ecovolt-dev-db-migrator \
  --payload '{"s3_bucket":"deployment-bucket","s3_prefix":"migrations/dev/"}' \
  response.json

cat response.json | jq '.'
```

#### Dry Run

Test migrations without applying:

```bash
aws lambda invoke \
  --function-name ecovolt-dev-db-migrator \
  --payload '{"s3_bucket":"deployment-bucket","s3_prefix":"migrations/dev/","dry_run":true}' \
  response.json
```

### Migration Flow

1. **Upload Phase**
   ```bash
   aws s3 sync application/backend/migrations/ \
     s3://deployment-bucket/migrations/dev/
   ```

2. **Invocation Phase**
   ```bash
   aws lambda invoke \
     --function-name ecovolt-dev-db-migrator \
     --payload '{"s3_bucket":"...","s3_prefix":"..."}'
   ```

3. **Execution Phase** (inside Lambda)
   - Connect to RDS using Secrets Manager credentials
   - Create `schema_migrations` table if needed
   - Get list of applied migrations
   - Download migration files from S3
   - Apply pending migrations in order
   - Record successful migrations
   - Return summary

### Security

1. **Network Security**
   - Lambda runs in private subnet
   - No public internet access required
   - RDS remains in private subnet

2. **Credential Management**
   - Credentials stored in Secrets Manager
   - Lambda uses IAM role for access
   - No credentials in code or environment

3. **IAM Permissions**
   - Lambda execution role has minimal permissions
   - S3 read-only access to migration files
   - Secrets Manager read-only access
   - VPC network interface management

### Monitoring

#### CloudWatch Logs

View migration logs:
```bash
aws logs tail /aws/lambda/ecovolt-dev-db-migrator --follow
```

#### Lambda Metrics

Monitor in CloudWatch:
- Invocations
- Duration
- Errors
- Throttles

#### Database Tracking

Check applied migrations:
```sql
SELECT * FROM schema_migrations ORDER BY applied_at DESC;
```

### Troubleshooting

#### Lambda Not Found

**Error:** `Migration Lambda function not found`

**Solution:** Deploy infrastructure first:
```bash
terraform apply
```

#### Connection Timeout

**Error:** `Connection to RDS timed out`

**Check:**
1. Lambda is in correct VPC subnets
2. Security groups allow Lambda → RDS traffic
3. RDS is running and accessible

#### Migration Failed

**Error:** `Failed to apply migration`

**Check:**
1. SQL syntax in migration file
2. Database permissions
3. CloudWatch logs for detailed error
4. Existing schema conflicts

#### S3 Access Denied

**Error:** `Access Denied` when reading from S3

**Check:**
1. Lambda IAM role has S3 read permissions
2. S3 bucket policy allows Lambda access
3. Migration files exist in S3

### Benefits

✅ **Secure** - No public RDS access needed
✅ **Reliable** - Runs in same VPC as RDS
✅ **Automated** - Integrated with CI/CD
✅ **Tracked** - Full audit trail in database
✅ **Scalable** - Handles large migration files
✅ **Monitored** - CloudWatch logs and metrics
✅ **Testable** - Dry-run mode available

### Comparison with Direct Connection

| Aspect | Direct Connection | Lambda-Based |
|--------|------------------|--------------|
| Network Access | Requires public RDS or VPN | Works with private RDS |
| Security | Less secure (public access) | More secure (VPC only) |
| Setup | Simple | Requires Lambda deployment |
| Reliability | Depends on network | Consistent VPC access |
| Monitoring | Limited | Full CloudWatch integration |
| Cost | Free (GitHub Actions) | ~$0.20 per 1M requests |

### Next Steps

1. **Deploy Infrastructure**
   ```bash
   terraform apply
   ```

2. **Verify Lambda Creation**
   ```bash
   aws lambda get-function --function-name ecovolt-dev-db-migrator
   ```

3. **Test Migration**
   - Push code to trigger workflow
   - Check GitHub Actions logs
   - Verify migrations in database

4. **Monitor**
   - Check CloudWatch logs
   - Query schema_migrations table
   - Review Lambda metrics

## Files Modified/Created

### Created
- `application/backend/functions/db_migrator.py` - Migration Lambda function
- `modules/compute/db_migrator.tf` - Terraform configuration
- `docs/LAMBDA_MIGRATION_SOLUTION.md` - This document

### Modified
- `.github/workflows/backend-reusable.yml` - Updated to use Lambda
- `modules/compute/outputs.tf` - Added migration Lambda outputs

### Dependencies
- `psycopg2-binary==2.9.9` - Already in requirements.txt
- `boto3` - Already in requirements.txt

## Cost Estimate

**Lambda Execution:**
- Memory: 512 MB
- Duration: ~10 seconds per migration run
- Requests: ~10 per month (deployments)
- Cost: < $0.01 per month

**S3 Storage:**
- Migration files: < 1 MB
- Cost: < $0.01 per month

**Total: < $0.02 per month**

## Conclusion

The Lambda-based migration solution provides a secure, reliable, and cost-effective way to run database migrations against RDS in a private subnet. It integrates seamlessly with the existing CI/CD pipeline and maintains all security best practices.
