# Root Variables

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "Primary AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "dr_region" {
  description = "Disaster recovery region"
  type        = string
  default     = "eu-west-1"
}

# Networking
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "data_subnet_cidrs" {
  description = "Data subnet CIDRs"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateways"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN gateway"
  type        = bool
  default     = false
}

# Security
variable "enable_cloudtrail" {
  description = "Enable CloudTrail"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty"
  type        = bool
  default     = true
}

# Database
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "ecovolt"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "ecovolt_admin"
}

# Password is auto-generated in database module using random_password
# and stored in AWS Secrets Manager

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "RDS max allocated storage for auto-scaling (GB)"
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = true
}

# Compute
variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = true
}

# Monitoring
variable "alarm_email_addresses" {
  description = "Email addresses for alarms"
  type        = list(string)
  default     = []
}

variable "alarm_phone_numbers" {
  description = "Phone numbers for SMS alarms"
  type        = list(string)
  default     = []
}

# Billing
variable "overall_monthly_budget" {
  description = "Overall monthly budget (USD)"
  type        = number
  default     = 1000
}

variable "budget_alert_email_addresses" {
  description = "Email addresses for budget alerts"
  type        = list(string)
  default     = []
}

variable "budget_alert_phone_numbers" {
  description = "Phone numbers for budget SMS alerts"
  type        = list(string)
  default     = []
}

variable "service_budgets" {
  description = "Service-specific budgets"
  type = object({
    compute   = number
    storage   = number
    database  = number
    iot       = number
    transfer  = number
    analytics = number
  })
  default = {
    compute   = 300
    storage   = 100
    database  = 200
    iot       = 150
    transfer  = 50
    analytics = 100
  }
}

# Content Delivery
variable "enable_cloudfront" {
  description = "Enable CloudFront distribution"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Custom domain name for the application (e.g., ecovolt.thekloudwiz.com)"
  type        = string
  default     = "ecovolt.thekloudwiz.com"
}

# Compliance
variable "enable_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = true
}

# Disaster Recovery
variable "enable_s3_replication" {
  description = "Enable S3 cross-region replication"
  type        = bool
  default     = false
}

# Tags
variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Cognito Variables
variable "enable_cognito_mfa" {
  description = "Enable MFA for Cognito user pool"
  type        = bool
  default     = false
}

variable "enable_cognito_advanced_security" {
  description = "Enable advanced security features for Cognito"
  type        = bool
  default     = true
}

variable "create_separate_admin_pool" {
  description = "Create separate user pool for admins"
  type        = bool
  default     = false
}

variable "create_cognito_identity_pool" {
  description = "Create Cognito Identity Pool for AWS resource access"
  type        = bool
  default     = false
}

variable "mobile_app_callback_urls" {
  description = "OAuth callback URLs for mobile app"
  type        = list(string)
  default     = ["ecovolt://callback"]
}

variable "mobile_app_logout_urls" {
  description = "OAuth logout URLs for mobile app"
  type        = list(string)
  default     = ["ecovolt://logout"]
}

variable "admin_portal_callback_urls" {
  description = "OAuth callback URLs for admin portal"
  type        = list(string)
  default     = ["https://admin.ecovolt.thekloudwiz.com/callback"]
}

variable "admin_portal_logout_urls" {
  description = "OAuth logout URLs for admin portal"
  type        = list(string)
  default     = ["https://admin.ecovolt.thekloudwiz.com/logout"]
}

# DynamoDB Variables
variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "enable_dynamodb_pitr" {
  description = "Enable point-in-time recovery for DynamoDB tables"
  type        = bool
  default     = true
}

variable "enable_bike_status_ttl" {
  description = "Enable TTL for bike status table"
  type        = bool
  default     = false
}

variable "enable_swap_events_ttl" {
  description = "Enable TTL for swap events table (90 days)"
  type        = bool
  default     = true
}

# WAF Variables
variable "enable_waf_cloudfront" {
  description = "Enable WAF for CloudFront distribution"
  type        = bool
  default     = true
}

variable "enable_waf_api_gateway" {
  description = "Enable WAF for API Gateway"
  type        = bool
  default     = true
}

variable "enable_waf_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

variable "waf_cloudfront_rate_limit" {
  description = "Rate limit for CloudFront WAF (requests per 5 minutes per IP)"
  type        = number
  default     = 2000
}

variable "waf_api_gateway_rate_limit" {
  description = "Rate limit for API Gateway WAF (requests per 5 minutes per IP)"
  type        = number
  default     = 1000
}

variable "waf_blocked_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
}

# ElastiCache Variables
variable "enable_elasticache" {
  description = "Enable ElastiCache Redis cluster"
  type        = bool
  default     = false
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes in the cluster"
  type        = number
  default     = 2
}

variable "redis_multi_az" {
  description = "Enable Multi-AZ for Redis"
  type        = bool
  default     = true
}

variable "redis_auth_token_enabled" {
  description = "Enable Redis AUTH token"
  type        = bool
  default     = true
}

variable "redis_auth_token" {
  description = "Redis AUTH token (password)"
  type        = string
  default     = ""
  sensitive   = true
}

# ========================================
# Analytics Variables
# ========================================

variable "enable_firehose_transformation" {
  description = "Enable Lambda transformation for Firehose data"
  type        = bool
  default     = false
}

# ========================================
# DNS Variables
# ========================================

variable "root_domain" {
  description = "Root domain name (e.g., thekloudwiz.com)"
  type        = string
}

variable "subdomain_prefix" {
  description = "Subdomain prefix for this project (e.g., ecovolt)"
  type        = string
  default     = "ecovolt"
}



# ========================================
# Admin Portal Variables
# ========================================

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_All, PriceClass_200, PriceClass_100)"
  type        = string
  default     = "PriceClass_100" # US, Canada, Europe
}
