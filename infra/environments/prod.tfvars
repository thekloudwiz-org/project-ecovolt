# Production Environment Configuration

environment = "prod"
aws_region  = "eu-central-1"
dr_region   = "eu-west-1"

# Networking - Full HA
enable_nat_gateway = true
enable_vpn_gateway = false

# Database - Production sizing
db_instance_class        = "db.r5.large"
db_allocated_storage     = 100
db_max_allocated_storage = 500
db_multi_az              = true
# db_deletion_protection = false

# Compute
lambda_runtime      = "python3.11"
enable_xray_tracing = true

# Monitoring
alarm_email_addresses = ["thekloudwiz+ecovolt@gmail.com", "thekloudwiz+ecovolt@gmail.com"]
alarm_phone_numbers   = ["+233549379885"]
# enable_dashboard = true

# Billing - Production budgets
overall_monthly_budget = 2500

service_budgets = {
  compute   = 600
  storage   = 300
  database  = 500
  iot       = 400
  transfer  = 200
  analytics = 300
}

budget_alert_email_addresses = ["thekloudwiz+ecovolt@gmail.com", "thekloudwiz+ecovolt@gmail.com"]
budget_alert_phone_numbers   = ["+1234567890"]

# Features - Full production
enable_cloudfront     = true
enable_config         = true
enable_s3_replication = true

additional_tags = {
  CostCenter  = "Production"
  Compliance  = "Required"
  Criticality = "High"
}
