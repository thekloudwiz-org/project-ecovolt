# Staging Environment Configuration

environment = "staging"
aws_region  = "eu-central-1" # Frankfurt
dr_region   = "eu-west-1"    # Ireland

# Networking - Production-like configuration
vpc_cidr           = "10.1.0.0/16"
enable_nat_gateway = true
enable_vpn_gateway = false

# Security
enable_cloudtrail = true
enable_guardduty  = true

# Database - Production-like instance for staging
db_instance_class    = "db.t3.medium"
db_allocated_storage = 50
db_multi_az          = true # Multi-AZ for staging

# Compute
enable_xray_tracing = true
lambda_runtime      = "python3.11"

# Billing - Moderate budgets for staging
overall_monthly_budget = 2000
service_budgets = {
  compute   = 600
  storage   = 150
  database  = 400
  iot       = 300
  transfer  = 100
  analytics = 200
}

# Disaster Recovery
enable_s3_replication = false # Optional for staging
