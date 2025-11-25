# Database Module - Local Values

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Module      = "database"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )

  # RDS naming
  db_subnet_group_name    = "${local.name_prefix}-rds-subnet-group"
  db_parameter_group_name = "${local.name_prefix}-rds-parameter-group"
  db_instance_identifier  = "${local.name_prefix}-postgres"
  db_security_group_name  = "${local.name_prefix}-rds-sg"

  # ElastiCache naming
  elasticache_subnet_group_name    = "${local.name_prefix}-elasticache-subnet-group"
  elasticache_parameter_group_name = "${local.name_prefix}-elasticache-parameter-group"
  elasticache_cluster_id           = "${local.name_prefix}-redis"
  elasticache_security_group_name  = "${local.name_prefix}-elasticache-sg"

  # SSM Parameter Store paths
  ssm_prefix                     = "/${var.project_name}/${var.environment}/database"
  ssm_rds_endpoint_path          = "${local.ssm_prefix}/rds/endpoint"
  ssm_rds_port_path              = "${local.ssm_prefix}/rds/port"
  ssm_rds_database_name_path     = "${local.ssm_prefix}/rds/database_name"
  ssm_elasticache_endpoint_path  = "${local.ssm_prefix}/elasticache/endpoint"
  ssm_elasticache_port_path      = "${local.ssm_prefix}/elasticache/port"
}
