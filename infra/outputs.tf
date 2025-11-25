# Root Outputs

# Networking
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

# Security
output "kms_key_arn" {
  description = "KMS key ARN"
  value       = module.security.kms_key_arn
}

# IoT
output "iot_endpoint" {
  description = "IoT Core endpoint"
  value       = module.iot.iot_endpoint
}

# Database
output "db_endpoint" {
  description = "RDS endpoint"
  value       = module.database.db_endpoint
}

output "redis_primary_endpoint" {
  description = "Redis primary endpoint"
  value       = module.database.redis_primary_endpoint
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint"
  value       = module.database.redis_reader_endpoint
}

# Compute
output "api_gateway_url" {
  description = "API Gateway URL"
  value       = module.compute.api_gateway_invoke_url
}

# Analytics
output "kinesis_stream_name" {
  description = "Kinesis stream name"
  value       = module.analytics.kinesis_stream_name
}

# Timestream output removed - deprecated service
# Telemetry data is stored in DynamoDB tables (see dynamodb module)

# Monitoring
output "alarm_topic_arn" {
  description = "SNS alarm topic ARN"
  value       = module.monitoring.alarm_topic_arn
}

# Content Delivery
output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = module.content_delivery.cloudfront_domain_name
}

output "static_assets_bucket" {
  description = "Static assets S3 bucket"
  value       = module.content_delivery.static_assets_bucket
}

# ========================================
# DNS Outputs
# ========================================

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = module.dns.certificate_arn
}

output "api_domain" {
  description = "API domain name"
  value       = module.dns.api_domain
}

output "admin_domain" {
  description = "Admin portal domain name"
  value       = module.dns.admin_domain
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.dns.hosted_zone_id
}

# ========================================
# Admin Portal Outputs
# ========================================

output "admin_portal_s3_bucket" {
  description = "S3 bucket name for admin portal"
  value       = module.admin_portal.s3_bucket_name
}

output "admin_portal_backup_bucket" {
  description = "S3 bucket name for admin portal backups"
  value       = module.admin_portal.backup_bucket_name
}

output "admin_portal_cloudfront_id" {
  description = "CloudFront distribution ID for admin portal"
  value       = module.admin_portal.cloudfront_distribution_id
}

output "admin_portal_url" {
  description = "Admin portal URL"
  value       = module.admin_portal.admin_portal_url
}

# ========================================
# Cognito Outputs
# ========================================

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.customer_user_pool_id
}

output "admin_portal_client_id" {
  description = "Admin Portal Cognito Client ID"
  value       = module.cognito.admin_portal_client_id
}

output "mobile_app_client_id" {
  description = "Mobile App Cognito Client ID"
  value       = module.cognito.mobile_app_client_id
}
