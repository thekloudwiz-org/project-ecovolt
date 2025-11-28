# InfluxDB Configuration Guide

## Current Status

✅ **InfluxDB Instance**: Running and healthy
✅ **VPC Endpoint**: Secrets Manager endpoint available
✅ **Credentials**: Stored in AWS Secrets Manager
⚠️ **Authentication**: Getting 401 errors from Lambda

## InfluxDB Details

```json
{
  "endpoint": "1pvjrgs1hr-rxjgd4ivkuvugm.timestream-influxdb.eu-central-1.on.aws",
  "port": 8086,
  "organization": "ecovolt",
  "bucket": "dev-telemetry",
  "username": "admin"
}
```

## Issue: 401 Unauthorized

The Lambda is successfully:
- ✅ Reading credentials from Secrets Manager
- ✅ Connecting to InfluxDB endpoint
- ❌ Getting rejected with 401 Unauthorized

## Possible Causes

1. **Token vs Password Authentication**
   - Current code uses `password` as token
   - InfluxDB may require a separate API token

2. **Bucket Permissions**
   - Bucket may not exist
   - User may not have write permissions

3. **Organization Mismatch**
   - Organization name may be incorrect

## Solution Steps

### Step 1: Verify InfluxDB Bucket

The Lambda expects bucket `dev-telemetry` to exist. This should have been created by Terraform during InfluxDB provisioning.

**Check Terraform:**
```bash
cd infra
terraform show | grep -A 5 "influxdb_bucket"
```

### Step 2: Generate InfluxDB API Token

InfluxDB requires an API token, not just the password. You need to:

1. **Access InfluxDB UI** (if publicly accessible) or
2. **Use InfluxDB CLI** to create a token

Since the InfluxDB instance is in a private subnet (`publicly_accessible = false`), you have two options:

#### Option A: Bastion Host (Recommended)
1. Launch EC2 bastion in public subnet
2. SSH to bastion
3. Use InfluxDB CLI to generate token:
   ```bash
   influx auth create \
     --org ecovolt \
     --all-access \
     --host https://1pvjrgs1hr-rxjgd4ivkuvugm.timestream-influxdb.eu-central-1.on.aws:8086
   ```

#### Option B: Temporarily Make Public (Not Recommended)
1. Update `infra/modules/analytics/timestream.tf`:
   ```hcl
   publicly_accessible = true  # TEMPORARILY
   ```
2. Apply Terraform
3. Access InfluxDB UI at `https://{endpoint}:8086`
4. Login with admin credentials
5. Create All-Access API Token
6. Copy token to Secrets Manager
7. Revert to `publicly_accessible = false`

### Step 3: Update Secret with API Token

```bash
# Get current secret
aws secretsmanager get-secret-value \
  --secret-id ecovolt-dev-influxdb-credentials \
  --region eu-central-1

# Update with token
aws secretsmanager put-secret-value \
  --secret-id ecovolt-dev-influxdb-credentials \
  --region eu-central-1 \
  --secret-string '{
    "username": "admin",
    "password": "p1RzUHoJjw9UKgfwxZrh5D6dAETtc9zM",
    "token": "YOUR_API_TOKEN_HERE",
    "endpoint": "1pvjrgs1hr-rxjgd4ivkuvugm.timestream-influxdb.eu-central-1.on.aws",
    "organization": "ecovolt",
    "bucket": "dev-telemetry"
  }'
```

### Step 4: Update Lambda Code to Use Token

Modify `infra/modules/analytics/lambda/stream_processor.py`:

```python
def get_influxdb_client():
    """Lazy initialization of InfluxDB client."""
    global _influxdb_client, _influxdb_write_api

    if _influxdb_client is None:
        # Get credentials from Secrets Manager
        secret = secretsmanager.get_secret_value(SecretId=INFLUXDB_SECRET_ARN)
        creds = json.loads(secret['SecretString'])

        # Initialize InfluxDB client with token
        _influxdb_client = InfluxDBClient(
            url=f"https://{INFLUXDB_ENDPOINT}:8086",
            token=creds.get('token', creds['password']),  # Try token first, fallback to password
            org=INFLUXDB_ORG
        )
        _influxdb_write_api = _influxdb_client.write_api(write_options=SYNCHRONOUS)

    return _influxdb_client, _influxdb_write_api
```

### Step 5: Rebuild and Deploy

```bash
# Rebuild Lambda
cd scripts
./build-lambdas.sh

# Deploy via Terraform or AWS CLI
aws lambda update-function-code \
  --function-name ecovolt-dev-stream-processor \
  --zip-file fileb://infra/modules/analytics/lambda/stream_processor.zip \
  --region eu-central-1
```

### Step 6: Test

```bash
# Publish test data
cd scripts/testing
./02-publish-test-data.sh bike test-001 3 2

# Check Lambda logs
sleep 10
aws logs tail /aws/lambda/ecovolt-dev-stream-processor \
  --region eu-central-1 \
  --since 2m \
  --follow
```

Look for:
- ✅ `✅ Updated current state for bike bike-test-001`
- ✅ `✅ Wrote historical metrics to InfluxDB for bike bike-test-001`
- ❌ NOT: `⚠️  Failed to write to InfluxDB: (401)`

## Alternative: Use AWS Timestream (Not InfluxDB)

If InfluxDB authentication continues to be problematic, consider migrating to AWS Timestream:

1. Create Timestream database
2. Update Lambda to use Timestream SDK
3. Simpler authentication (IAM roles)
4. Better AWS integration

## Verification Commands

```bash
# Check InfluxDB instance
aws timestream-influxdb list-db-instances --region eu-central-1

# Check secrets
aws secretsmanager list-secrets --region eu-central-1 | grep influxdb

# Check VPC endpoints
aws ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=*secretsmanager*" \
  --region eu-central-1 \
  | jq '.VpcEndpoints[] | {ServiceName, State}'

# Test Lambda locally (if needed)
# Create test event and invoke
```

## Notes

- Current pipeline **DOES WORK** for DynamoDB (current state)
- InfluxDB is **OPTIONAL** for historical time-series
- All critical functionality is operational
- InfluxDB can be configured later without affecting real-time operations

---

**Status**: ⚠️ Action Required - InfluxDB Token Configuration
**Priority**: Medium (not blocking current state operations)
**Impact**: Historical time-series data not being stored
