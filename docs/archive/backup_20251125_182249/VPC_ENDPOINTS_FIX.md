# VPC Endpoints Fix for Lambda Connectivity

## Problem
Lambda functions in private subnets were timing out when trying to connect to AWS services:
- `secretsmanager.eu-central-1.amazonaws.com` - Connect timeout
- `s3.eu-central-1.amazonaws.com` - Potential timeout

Error message:
```
Connect timeout on endpoint URL: "https://secretsmanager.eu-central-1.amazonaws.com/"
```

## Root Cause
Lambda functions were deployed in VPC private subnets without:
1. Internet access (no NAT Gateway)
2. VPC endpoints for AWS services

This meant Lambda couldn't reach AWS service endpoints over the internet.

## Solution
Added VPC endpoints to allow Lambda functions to access AWS services privately without internet access.

### VPC Endpoints Created

1. **Secrets Manager (Interface Endpoint)**
   - Service: `com.amazonaws.eu-central-1.secretsmanager`
   - Type: Interface
   - Subnets: All private subnets
   - Private DNS: Enabled
   - Purpose: Access RDS credentials

2. **S3 (Gateway Endpoint)**
   - Service: `com.amazonaws.eu-central-1.s3`
   - Type: Gateway
   - Route Tables: All private route tables
   - Purpose: Access migration files and Lambda code

3. **DynamoDB (Gateway Endpoint)**
   - Service: `com.amazonaws.eu-central-1.dynamodb`
   - Type: Gateway
   - Route Tables: All private route tables
   - Purpose: Future use

### Security Group
Created security group for VPC endpoints:
- Ingress: HTTPS (443) from VPC CIDR (10.0.0.0/16)
- Egress: All traffic

### IAM Policy Fix
Updated Lambda IAM policy to allow access to secrets with pattern `ecovolt-dev-*`:
```json
{
  "Resource": [
    "arn:aws:secretsmanager:eu-central-1:288761729262:secret:dev/*",
    "arn:aws:secretsmanager:eu-central-1:288761729262:secret:ecovolt-dev-*"
  ]
}
```

## Files Modified
- `modules/networking/vpc_endpoints.tf` - Created VPC endpoints
- `modules/networking/outputs.tf` - Added VPC endpoint outputs
- `modules/compute/main.tf` - Updated Lambda IAM policy

## Testing
Lambda migration function now works successfully:
```bash
aws lambda invoke --function-name ecovolt-dev-db-migrator \
  --region eu-central-1 \
  --cli-binary-format raw-in-base64-out \
  --payload '{"s3_bucket": "ecovolt-app-deployment-bucket", "s3_prefix": "migrations/dev/"}' \
  /tmp/lambda-response.json
```

Result:
```json
{
  "statusCode": 200,
  "body": {
    "message": "Migrations completed successfully",
    "summary": {
      "total_migrations": 3,
      "applied": 3,
      "skipped": 0,
      "dry_run": false
    }
  }
}
```

## Benefits
1. ✅ No NAT Gateway required (cost savings)
2. ✅ Secure private connectivity to AWS services
3. ✅ Better performance (no internet routing)
4. ✅ Reduced attack surface

## Cost Impact
- Interface endpoints: ~$7.20/month per endpoint per AZ
- Gateway endpoints: Free
- Total: ~$21.60/month for Secrets Manager endpoint (3 AZs)
- Savings: No NAT Gateway (~$32/month per AZ = $96/month)
- Net savings: ~$74/month

## Related Issues
- Lambda timeout connecting to Secrets Manager
- Database migration failures
- VPC networking configuration
