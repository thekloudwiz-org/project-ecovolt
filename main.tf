# EcoVolt AWS Infrastructure - Main Configuration
# This file orchestrates all infrastructure modules

# Networking Module
module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  data_subnet_cidrs    = var.data_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  enable_vpn_gateway   = var.enable_vpn_gateway
  environment          = var.environment

  tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name           = var.project_name
  environment            = var.environment
  enable_cloudtrail      = var.enable_cloudtrail
  enable_guardduty       = var.enable_guardduty
  enable_kms_key_rotation = true

  tags = local.common_tags
}

# Cognito Module (User Authentication)
module "cognito" {
  source = "./modules/cognito"

  project_name = var.project_name
  environment  = var.environment

  # Security settings
  enable_mfa               = var.enable_cognito_mfa
  enable_advanced_security = var.enable_cognito_advanced_security
  create_separate_admin_pool = var.create_separate_admin_pool
  create_identity_pool     = var.create_cognito_identity_pool

  # OAuth callback URLs
  mobile_app_callback_urls   = var.mobile_app_callback_urls
  mobile_app_logout_urls     = var.mobile_app_logout_urls
  admin_portal_callback_urls = var.admin_portal_callback_urls
  admin_portal_logout_urls   = var.admin_portal_logout_urls

  tags = local.common_tags
}

# DynamoDB Module (Operational Data)
module "dynamodb" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  # Billing mode
  billing_mode = var.dynamodb_billing_mode

  # Encryption
  kms_key_arn = module.security.kms_key_arn

  # Backup and recovery
  enable_point_in_time_recovery = var.enable_dynamodb_pitr

  # TTL settings
  enable_vehicle_status_ttl = var.enable_vehicle_status_ttl
  enable_swap_events_ttl    = var.enable_swap_events_ttl

  tags = local.common_tags
}

# IoT Module
module "iot" {
  source = "./modules/iot"

  project_name                 = var.project_name
  environment                  = var.environment
  telemetry_kinesis_stream_arn = module.analytics.kinesis_stream_arn
  enable_logging               = true
  enable_fleet_indexing        = true

  tags = local.common_tags

  depends_on = [
    module.analytics
  ]
}

# Analytics Module
module "analytics" {
  source = "./modules/analytics"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn

  tags = local.common_tags
}

# Database Module
module "database" {
  source = "./modules/database"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  data_subnet_ids       = module.networking.data_subnet_ids
  private_subnet_cidrs  = module.networking.private_subnet_cidrs
  kms_key_arn           = module.security.kms_key_arn
  
  # RDS Configuration
  db_name                  = var.db_name
  db_username              = var.db_username
  # Password is auto-generated in the module
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_multi_az              = var.db_multi_az

  # ElastiCache Configuration
  enable_elasticache       = var.enable_elasticache
  redis_node_type          = var.redis_node_type
  redis_num_cache_nodes    = var.redis_num_cache_nodes
  redis_multi_az           = var.redis_multi_az
  redis_auth_token_enabled = var.redis_auth_token_enabled
  redis_auth_token         = var.redis_auth_token

  tags = local.common_tags

  depends_on = [ module.networking, module.security, module.analytics ]
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  private_subnet_ids     = module.networking.private_subnet_ids
  
  db_endpoint            = module.database.db_address  # Use address (hostname only) instead of endpoint (hostname:port)
  db_name                = module.database.db_name
  db_security_group_id   = module.database.db_security_group_id
  db_secret_arn          = module.database.db_secret_arn
  kinesis_stream_arn     = module.analytics.kinesis_stream_arn
  
  lambda_runtime            = var.lambda_runtime
  enable_xray_tracing       = var.enable_xray_tracing

  # Cognito integration
  enable_cognito_authorizer = true  # Cognito user pool is always created
  cognito_user_pool_arn     = module.cognito.customer_user_pool_arn_for_authorizer
  cognito_user_pool_id      = module.cognito.customer_user_pool_id
  cognito_client_id         = module.cognito.mobile_app_client_id

  # DynamoDB integration
  dynamodb_table_arns    = module.dynamodb.all_table_arns
  dynamodb_stream_arns   = module.dynamodb.all_table_stream_arns
  dynamodb_table_names   = module.dynamodb.all_table_names

  # IoT integration
  iot_endpoint           = module.iot.iot_endpoint

  tags = local.common_tags

  depends_on = [ module.networking, module.analytics, module.iot ]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  project_name              = var.project_name
  environment               = var.environment
  alarm_email_addresses     = var.alarm_email_addresses
  alarm_phone_numbers       = var.alarm_phone_numbers
  
  lambda_function_names     = [module.compute.api_handler_function_name]
  api_gateway_id            = module.compute.api_gateway_id
  api_gateway_stage_name    = module.compute.api_gateway_stage_name
  db_instance_id            = module.database.db_instance_id
  kinesis_stream_name       = module.analytics.kinesis_stream_name

  tags = local.common_tags

  depends_on = [ module.networking, module.compute, module.security, module.analytics, module.database ]
}

# Billing Module
module "billing" {
  source = "./modules/billing"

  project_name                 = var.project_name
  environment                  = var.environment
  overall_monthly_budget       = var.overall_monthly_budget
  budget_alert_email_addresses = var.budget_alert_email_addresses
  budget_alert_phone_numbers   = var.budget_alert_phone_numbers
  service_budgets              = var.service_budgets

  tags = local.common_tags
}

# Edge Computing Module (IoT Greengrass)
module "edge_computing" {
  source = "./modules/edge-computing"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# Content Delivery Module
module "content_delivery" {
  source = "./modules/content-delivery"

  project_name      = var.project_name
  environment       = var.environment
  enable_cloudfront = var.enable_cloudfront
  domain_name       = var.domain_name

  tags = local.common_tags
}

# WAF Module (Web Application Firewall)
module "waf" {
  source = "./modules/waf"

  project_name = var.project_name
  environment  = var.environment

  # Enable WAF for CloudFront and API Gateway
  enable_cloudfront_waf   = var.enable_waf_cloudfront
  enable_api_gateway_waf  = var.enable_waf_api_gateway
  enable_waf_logging      = var.enable_waf_logging

  # Rate limits
  cloudfront_rate_limit  = var.waf_cloudfront_rate_limit
  api_gateway_rate_limit = var.waf_api_gateway_rate_limit

  # Geographic blocking (optional)
  blocked_countries = var.waf_blocked_countries

  tags = local.common_tags

  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}

# Compliance Module
module "compliance" {
  source = "./modules/compliance"

  project_name  = var.project_name
  environment   = var.environment
  enable_config = var.enable_config

  tags = local.common_tags
}

# Disaster Recovery Module
module "disaster_recovery" {
  source = "./modules/disaster-recovery"

  project_name           = var.project_name
  environment            = var.environment
  primary_region         = var.aws_region
  dr_region              = var.dr_region
  enable_s3_replication  = var.enable_s3_replication

  tags = local.common_tags
}
