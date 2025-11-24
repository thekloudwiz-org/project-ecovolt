# Database Module - SSM Parameter Store
# Store database connection information in SSM Parameter Store for easy access by other services

# RDS Endpoint
resource "aws_ssm_parameter" "rds_endpoint" {
  name        = local.ssm_rds_endpoint_path
  description = "RDS PostgreSQL instance endpoint"
  type        = "String"
  value       = aws_db_instance.main.endpoint

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-endpoint"
    }
  )
}

# RDS Port
resource "aws_ssm_parameter" "rds_port" {
  name        = local.ssm_rds_port_path
  description = "RDS PostgreSQL instance port"
  type        = "String"
  value       = tostring(aws_db_instance.main.port)

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-port"
    }
  )
}

# RDS Database Name
resource "aws_ssm_parameter" "rds_database_name" {
  name        = local.ssm_rds_database_name_path
  description = "RDS PostgreSQL database name"
  type        = "String"
  value       = aws_db_instance.main.db_name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-rds-database-name"
    }
  )
}

# Note: ElastiCache SSM parameters are now in elasticache.tf
# This keeps the Redis replication group configuration self-contained
