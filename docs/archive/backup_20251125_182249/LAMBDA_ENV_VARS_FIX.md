# Lambda Environment Variables Fix

## Problem
Lambda functions in the compute module had empty environment variables for critical configuration values:
- `DB_SECRET_ARN` - Database credentials from Secrets Manager
- `COGNITO_USER_POOL_ID` - Cognito user pool for authentication
- `COGNITO_CLIENT_ID` - Cognito client for mobile app
- `SNS_TOPIC_ARN` - SNS topic for push notifications
- `IOT_ENDPOINT` - IoT Core endpoint for device communication

Additionally, there was a circular dependency between modules:
- Compute module depended on Monitoring module (for SNS topic)
- Monitoring module depended on Compute module (for Lambda/API Gateway metrics)
- DynamoDB module also depended on Monitoring module (for alarms)

## Solution

### 1. Fixed Missing Environment Variables
Updated `main.tf` to pass the required outputs to the compute module:

```hcl
module "compute" {
  # ... existing config ...
  
  # Database integration
  db_secret_arn          = module.database.db_secret_arn
  
  # Cognito integration
  cognito_user_pool_id   = module.cognito.customer_user_pool_id
  cognito_client_id      = module.cognito.mobile_app_client_id
  
  # IoT integration
  iot_endpoint           = module.iot.iot_endpoint
}
```

### 2. Broke Circular Dependency
Created a dedicated SNS topic for application notifications within the compute module itself:

**modules/compute/main.tf:**
```hcl
resource "aws_sns_topic" "notifications" {
  name = "${local.name_prefix}-notifications"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-notifications"
    }
  )
}
```

Lambda functions now reference this local SNS topic:
```hcl
environment {
  variables = {
    SNS_TOPIC_ARN = aws_sns_topic.notifications.arn
    # ... other vars ...
  }
}
```

### 3. Made Monitoring Dependencies Optional
Updated DynamoDB and WAF modules to have optional alarm SNS topics:

**modules/dynamodb/variables.tf:**
```hcl
variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []  # Made optional
}
```

**modules/waf/variables.tf:**
```hcl
variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []  # Made optional
}
```

### 4. Updated Module Dependencies
Removed circular dependencies in `main.tf`:

```hcl
# Compute module no longer depends on monitoring
module "compute" {
  depends_on = [ module.networking, module.analytics, module.iot ]
}

# DynamoDB module no longer needs monitoring SNS topic
module "dynamodb" {
  # Removed: alarm_sns_topic_arns = [module.monitoring.alarm_topic_arn]
}

# WAF module no longer needs monitoring SNS topic
module "waf" {
  # Removed: alarm_sns_topic_arns = [module.monitoring.alarm_topic_arn]
}
```

## Benefits

1. **Lambda functions now have all required environment variables** - No more empty strings
2. **No circular dependencies** - Terraform can now properly plan and apply
3. **Separation of concerns** - Application notifications (compute) vs monitoring alarms (monitoring)
4. **Flexible monitoring** - Alarms can be added later without blocking initial deployment

## Files Modified

- `main.tf` - Updated module calls to pass required variables and remove circular dependencies
- `modules/compute/main.tf` - Added SNS topic and updated Lambda environment variables
- `modules/compute/variables.tf` - Removed `sns_topic_arn` variable (no longer needed)
- `modules/compute/outputs.tf` - Added outputs for the new SNS notifications topic
- `modules/dynamodb/variables.tf` - Made `alarm_sns_topic_arns` optional
- `modules/waf/variables.tf` - Made `alarm_sns_topic_arns` optional

## Validation

Configuration validated successfully:
```bash
$ terraform validate
Success! The configuration is valid.
```

## Next Steps

If you want to connect monitoring alarms to the DynamoDB and WAF modules later, you can:

1. Add the monitoring SNS topic ARN after both modules are created
2. Use `terraform apply -target` to update specific modules
3. Or create a separate monitoring configuration pass after initial infrastructure deployment
