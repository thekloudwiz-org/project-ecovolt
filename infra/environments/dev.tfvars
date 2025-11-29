# Development Environment Configuration
# Cycle error fixed: Removed explicit depends_on from IoT module

environment = "dev"
aws_region  = "eu-central-1"
dr_region   = "eu-west-1"

# Networking - Minimal for dev
# NAT Gateway disabled - Lambda architecture restructured
# Auth Lambda outside VPC, Business Lambda inside VPC
enable_nat_gateway = false
enable_vpn_gateway = false

# Database - Minimal for dev
db_instance_class        = "db.t3.micro"
db_allocated_storage     = 20
db_max_allocated_storage = 50
db_multi_az              = false
# db_deletion_protection = false
# Password is auto-generated and stored in Secrets Manager

# Compute
lambda_runtime      = "python3.11"
enable_xray_tracing = false

# Monitoring
alarm_email_addresses = ["thekloudwiz+ecovolt@gmail.com"]
# enable_dashboard = true

# Billing - Lower budgets for dev
overall_monthly_budget = 200

service_budgets = {
  compute   = 50
  storage   = 20
  database  = 30
  iot       = 30
  transfer  = 10
  analytics = 20
}

budget_alert_email_addresses = ["thekloudwiz+ecovolt@gmail.com"]

# Features - Minimal for dev
enable_cloudfront     = false
enable_config         = false
enable_s3_replication = false

# Cognito - Basic settings for dev
enable_cognito_mfa               = false
enable_cognito_advanced_security = false
create_separate_admin_pool       = false
create_cognito_identity_pool     = false

# DynamoDB - On-demand for dev
dynamodb_billing_mode  = "PAY_PER_REQUEST"
enable_dynamodb_pitr   = false
enable_bike_status_ttl = false
enable_swap_events_ttl = true

# WAF - Basic protection for dev
enable_waf_cloudfront      = false
enable_waf_api_gateway     = true
enable_waf_logging         = false
waf_cloudfront_rate_limit  = 5000
waf_api_gateway_rate_limit = 2000

# ElastiCache - Minimal for dev
enable_elasticache       = false
redis_node_type          = "cache.t3.micro"
redis_num_cache_nodes    = 1
redis_multi_az           = false
redis_auth_token_enabled = false

additional_tags = {
  CostCenter = "Development"
}

# DNS Configuration
root_domain      = "thekloudwiz.com"
subdomain_prefix = "ecovolt"

# Admin Portal Configuration
cloudfront_price_class = "PriceClass_100"
