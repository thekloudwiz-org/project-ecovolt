# EcoVolt Deployment Issues and Fixes

## Issue 1: Lambda Function Missing Dependencies ✅ IDENTIFIED

### Problem
Lambda functions are returning import errors:
```
Unable to import module 'functions.api_handler': No module named 'jwt'
```

### Root Cause
The Terraform configuration packages only the Python source code without dependencies. Python packages like `PyJWT`, `boto3`, `psycopg2-binary`, etc. are not included in the deployment package.

### Solution
Build a proper Lambda deployment package that includes all dependencies:

```bash
# Option 1: Build with Docker (Recommended for production)
docker run --rm -v "$PWD":/var/task \
  public.ecr.aws/lambda/python:3.11 \
  bash -c "pip install -r application/backend/requirements.txt -t /var/task/build && \
           cp -r application/backend/* /var/task/build/"

# Option 2: Use AWS SAM CLI
sam build

# Option 3: Use Terraform with null_resource and Docker
# See updated Terraform configuration below
```

### Updated Terraform Configuration

Add to `modules/compute/main.tf`:

```hcl
# Build Lambda package with dependencies using Docker
resource "null_resource" "lambda_package" {
  triggers = {
    requirements = filemd5("${path.root}/application/backend/requirements.txt")
    source_hash  = sha256(join("", [for f in fileset("${path.root}/application/backend", "**/*.py") : filesha256("${path.root}/application/backend/${f}")]))
  }

  provisioner "local-exec" {
    command = <<EOF
      docker run --rm \
        -v "${path.root}/application/backend":/var/task \
        -v "${path.module}/lambda":/output \
        public.ecr.aws/lambda/python:3.11 \
        bash -c "
          pip install -r /var/task/requirements.txt -t /tmp/package --no-cache-dir && \
          cp -r /var/task/* /tmp/package/ && \
          cd /tmp/package && \
          zip -r /output/api_handler.zip . -x '*.pyc' '__pycache__/*' 'tests/*' '*.md'
        "
    EOF
  }
}

# Update data source to use the built package
data "archive_file" "api_handler" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/package"
  output_path = "${path.module}/lambda/api_handler.zip"
  
  depends_on = [null_resource.lambda_package]
}
```

### Immediate Fix (Manual)

1. Build package on Linux or use Docker:
```bash
./scripts/build_lambda_package_docker.sh
```

2. Deploy manually:
```bash
aws lambda update-function-code \
  --function-name ecovolt-dev-api-handler \
  --zip-file fileb://lambda-deployment.zip

aws lambda update-function-code \
  --function-name ecovolt-dev-iot-processor \
  --zip-file fileb://lambda-deployment.zip
```

---

## Issue 2: WAF Blocking All Requests ⚠️ INVESTIGATING

### Problem
All API requests return 403 Forbidden, even valid requests to public endpoints.

### Possible Causes
1. **User-Agent Rule Too Strict**: The WAF rule blocking requests without User-Agent might be too aggressive
2. **Rate Limiting**: Rate limit might be set too low
3. **AWS Managed Rules**: Core rule set might have false positives

### Investigation Steps

```bash
# Check WAF logs
aws logs tail aws-waf-logs-ecovolt-dev --follow

# Check blocked requests
aws wafv2 get-sampled-requests \
  --web-acl-arn $(terraform output -raw waf_web_acl_arn) \
  --rule-metric-name ecovolt-dev-no-user-agent \
  --scope REGIONAL \
  --time-window StartTime=$(date -u -d '10 minutes ago' +%s),EndTime=$(date -u +%s) \
  --max-items 10
```

### Temporary Fix
Disable problematic WAF rules:

```bash
# Option 1: Temporarily disable WAF
aws wafv2 disassociate-web-acl \
  --resource-arn $(terraform output -raw api_gateway_stage_arn)

# Option 2: Update WAF to COUNT mode instead of BLOCK
# Edit modules/compute/waf.tf and change action blocks to count blocks
```

### Permanent Fix
Update `modules/compute/waf.tf`:

```hcl
# Make User-Agent rule less strict
rule {
  name     = "BlockNoUserAgent"
  priority = 5

  action {
    count {}  # Change from block to count for testing
  }
  
  # ... rest of rule
}
```

---

## Issue 3: Database Not Seeded

### Problem
Database tables exist but have no data, causing empty responses from endpoints.

### Solution

```bash
# Get database credentials
DB_ENDPOINT=$(terraform output -raw db_endpoint)
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id dev/ecovolt/db-password \
  --query SecretString \
  --output text)

# Run migrations
cd application/backend/migrations
PGPASSWORD=$DB_PASSWORD psql -h $DB_ENDPOINT -U ecovolt_admin -d ecovolt -f 001_initial_schema.sql
PGPASSWORD=$DB_PASSWORD psql -h $DB_ENDPOINT -U ecovolt_admin -d ecovolt -f 002_add_indexes.sql
PGPASSWORD=$DB_PASSWORD psql -h $DB_ENDPOINT -U ecovolt_admin -d ecovolt -f 003_seed_data.sql
```

---

## Issue 4: Lambda VPC Configuration Timeout

### Problem
Lambda functions in VPC may timeout when accessing internet resources (like Cognito).

### Solution
Ensure NAT Gateway is properly configured:

```bash
# Check NAT Gateway status
aws ec2 describe-nat-gateways \
  --filter "Name=tag:Environment,Values=dev" \
  --query 'NatGateways[*].[NatGatewayId,State]' \
  --output table

# Check route tables
aws ec2 describe-route-tables \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'RouteTables[*].Routes' \
  --output table
```

---

## Testing Checklist

Once issues are resolved, run these tests:

### 1. Lambda Function Test
```bash
aws lambda invoke \
  --function-name ecovolt-dev-api-handler \
  --payload '{"httpMethod":"GET","path":"/health"}' \
  response.json && cat response.json
```

### 2. API Gateway Test
```bash
API_URL=$(terraform output -raw api_gateway_url)
curl "${API_URL}/health"
```

### 3. Database Connectivity
```bash
aws lambda invoke \
  --function-name ecovolt-dev-api-handler \
  --payload '{"httpMethod":"GET","path":"/stations"}' \
  response.json && cat response.json
```

### 4. Full Test Suite
```bash
./scripts/test_api.sh
```

---

## Next Steps

1. ✅ Build Lambda package with Docker
2. ⏳ Deploy updated Lambda functions
3. ⏳ Investigate and fix WAF blocking
4. ⏳ Run database migrations
5. ⏳ Run full test suite
6. ⏳ Document any additional issues

---

## Additional Resources

- [AWS Lambda Deployment Packages](https://docs.aws.amazon.com/lambda/latest/dg/python-package.html)
- [AWS WAF Troubleshooting](https://docs.aws.amazon.com/waf/latest/developerguide/web-acl-testing.html)
- [Lambda VPC Configuration](https://docs.aws.amazon.com/lambda/latest/dg/configuration-vpc.html)

---

**Last Updated:** 2024-11-24  
**Status:** Issues Identified, Fixes In Progress
