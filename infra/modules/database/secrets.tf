# Database Secrets Management
# Simple password generation and storage without rotation
# Credentials are injected into Lambda via Terraform at deploy time

# Generate random password for RDS (no special chars to avoid connection string issues)
resource "random_password" "db_master_password" {
  length  = 16
  special = false
}

# Store RDS credentials in Secrets Manager
resource "aws_secretsmanager_secret" "db_master_credentials" {
  name                           = "${var.project_name}-${var.environment}-rds-master-credentials"
  description                    = "Master credentials for RDS PostgreSQL database"
  force_overwrite_replica_secret = true

  # Immediate deletion in dev, 30-day recovery in prod
  recovery_window_in_days = var.environment == "dev" ? 0 : 30

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-rds-master-credentials"
    }
  )
}

# Store the credentials as JSON
resource "aws_secretsmanager_secret_version" "db_master_credentials" {
  secret_id = aws_secretsmanager_secret.db_master_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_master_password.result
  })
}

# ============================================================================
# SSM Parameter Store - Non-sensitive database information
# ============================================================================

# Database endpoint
resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/${var.project_name}/${var.environment}/database/endpoint"
  description = "RDS database endpoint"
  type        = "String"
  value       = aws_db_instance.main.address

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-endpoint"
    }
  )
}

# Database port
resource "aws_ssm_parameter" "db_port" {
  name        = "/${var.project_name}/${var.environment}/database/port"
  description = "RDS database port"
  type        = "String"
  value       = tostring(aws_db_instance.main.port)

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-port"
    }
  )
}

# Database name
resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.project_name}/${var.environment}/database/name"
  description = "RDS database name"
  type        = "String"
  value       = var.db_name

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-name"
    }
  )
}

# Database username
resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project_name}/${var.environment}/database/username"
  description = "RDS database username"
  type        = "String"
  value       = var.db_username

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-username"
    }
  )
}

# Database connection string (without password)
resource "aws_ssm_parameter" "db_connection_string" {
  name        = "/${var.project_name}/${var.environment}/database/connection-string"
  description = "RDS database connection string template (password from Secrets Manager)"
  type        = "String"
  value       = "postgresql://${var.db_username}:PASSWORD_FROM_SECRETS_MANAGER@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-connection-string"
    }
  )
}

# Secret ARN for easy reference
resource "aws_ssm_parameter" "db_secret_arn" {
  name        = "/${var.project_name}/${var.environment}/database/secret-arn"
  description = "ARN of the Secrets Manager secret containing database credentials"
  type        = "String"
  value       = aws_secretsmanager_secret.db_master_credentials.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-secret-arn"
    }
  )
}
