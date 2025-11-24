# Database Module - Outputs

# ============================================================================
# RDS Outputs
# ============================================================================

output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_endpoint" {
  description = "RDS instance connection endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_address" {
  description = "RDS instance hostname"
  value       = aws_db_instance.main.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "Master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_security_group_id" {
  description = "Security group ID for RDS instance"
  value       = aws_security_group.rds.id
}

output "db_subnet_group_name" {
  description = "RDS subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "db_parameter_group_name" {
  description = "RDS parameter group name"
  value       = aws_db_parameter_group.main.name
}

output "db_multi_az" {
  description = "Whether Multi-AZ is enabled"
  value       = aws_db_instance.main.multi_az
}

output "db_backup_retention_period" {
  description = "Backup retention period in days"
  value       = aws_db_instance.main.backup_retention_period
}

output "db_storage_encrypted" {
  description = "Whether storage encryption is enabled"
  value       = aws_db_instance.main.storage_encrypted
}

output "db_max_allocated_storage" {
  description = "Maximum storage for auto-scaling"
  value       = aws_db_instance.main.max_allocated_storage
}

# ============================================================================
# ElastiCache Outputs (from elasticache.tf replication group)
# ============================================================================

output "elasticache_security_group_id" {
  description = "Security group ID for ElastiCache cluster"
  value       = aws_security_group.elasticache.id
}

output "elasticache_subnet_group_name" {
  description = "ElastiCache subnet group name"
  value       = aws_elasticache_subnet_group.main.name
}

output "elasticache_parameter_group_name" {
  description = "ElastiCache parameter group name"
  value       = aws_elasticache_parameter_group.main.name
}

# ElastiCache Outputs
output "redis_primary_endpoint" {
  description = "Redis primary endpoint address"
  value       = var.enable_elasticache ? aws_elasticache_replication_group.redis[0].primary_endpoint_address : null
}

output "redis_reader_endpoint" {
  description = "Redis reader endpoint address"
  value       = var.enable_elasticache && var.redis_multi_az ? aws_elasticache_replication_group.redis[0].reader_endpoint_address : null
}

output "redis_port" {
  description = "Redis port"
  value       = var.enable_elasticache ? 6379 : null
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = var.enable_elasticache ? aws_security_group.redis[0].id : null
}

output "redis_replication_group_id" {
  description = "Redis replication group ID"
  value       = var.enable_elasticache ? aws_elasticache_replication_group.redis[0].id : null
}

# Secrets Manager outputs
output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_master_credentials.arn
}

output "db_secret_name" {
  description = "Name of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_master_credentials.name
}

# SSM Parameter Store outputs
output "db_endpoint_parameter" {
  description = "SSM parameter name for database endpoint"
  value       = aws_ssm_parameter.db_endpoint.name
}

output "db_port_parameter" {
  description = "SSM parameter name for database port"
  value       = aws_ssm_parameter.db_port.name
}

output "db_name_parameter" {
  description = "SSM parameter name for database name"
  value       = aws_ssm_parameter.db_name.name
}

output "db_username_parameter" {
  description = "SSM parameter name for database username"
  value       = aws_ssm_parameter.db_username.name
}

output "db_connection_string_parameter" {
  description = "SSM parameter name for database connection string template"
  value       = aws_ssm_parameter.db_connection_string.name
}
