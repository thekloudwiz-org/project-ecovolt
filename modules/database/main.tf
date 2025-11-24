# Database Module - Main Configuration
# Creates RDS PostgreSQL and ElastiCache Redis resources

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# RDS PostgreSQL
# ============================================================================

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = local.db_subnet_group_name
  subnet_ids = var.data_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = local.db_subnet_group_name
    }
  )
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name   = local.db_parameter_group_name
  family = var.db_parameter_family

  # Optimized settings for PostgreSQL
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # Log queries taking longer than 1 second
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name  = "log_temp_files"
    value = "0" # Log all temporary files
  }

  parameter {
    name  = "log_autovacuum_min_duration"
    value = "0" # Log all autovacuum operations
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.db_parameter_group_name
    }
  )
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = local.db_security_group_name
  description = "Security group for RDS PostgreSQL instance - allows access from private subnets only"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = local.db_security_group_name
    }
  )
}

# Security Group Rule - Ingress from private subnets
resource "aws_security_group_rule" "rds_ingress_private" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = var.private_subnet_cidrs
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL access from private subnets"
}

# Security Group Rule - Egress (allow all outbound)
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier     = local.db_instance_identifier
  engine         = "postgres"
  engine_version = var.db_engine_version

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  # Storage auto-scaling
  max_allocated_storage = var.db_max_allocated_storage

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_master_password.result
  port     = 5432

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # High availability
  multi_az = var.db_multi_az

  # Backup configuration
  backup_retention_period = var.db_backup_retention_period
  backup_window           = var.db_backup_window
  maintenance_window      = var.db_maintenance_window
  skip_final_snapshot     = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${local.db_instance_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Encryption
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Parameter group
  parameter_group_name = aws_db_parameter_group.main.name

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled          = var.db_performance_insights_enabled
  performance_insights_retention_period = var.db_performance_insights_enabled ? var.db_performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.db_performance_insights_enabled ? var.kms_key_arn : null

  # Deletion protection
  deletion_protection = var.db_deletion_protection

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  # Storage type
  storage_type = "gp3"

  # Apply changes immediately (set to false for production to use maintenance window)
  apply_immediately = var.environment == "prod" ? false : true

  tags = merge(
    local.common_tags,
    {
      Name = local.db_instance_identifier
    }
  )

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
      password
    ]
  }
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach AWS managed policy for RDS Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ============================================================================
# ElastiCache Redis
# ============================================================================

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = local.elasticache_subnet_group_name
  subnet_ids = var.data_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = local.elasticache_subnet_group_name
    }
  )
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "main" {
  name   = local.elasticache_parameter_group_name
  family = var.elasticache_parameter_family

  # Optimized settings for Redis
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.elasticache_parameter_group_name
    }
  )
}

# Security Group for ElastiCache
resource "aws_security_group" "elasticache" {
  name        = local.elasticache_security_group_name
  description = "Security group for ElastiCache Redis cluster - allows access from private subnets only"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = local.elasticache_security_group_name
    }
  )
}

# Security Group Rule - Ingress from private subnets
resource "aws_security_group_rule" "elasticache_ingress_private" {
  type              = "ingress"
  from_port         = var.elasticache_port
  to_port           = var.elasticache_port
  protocol          = "tcp"
  cidr_blocks       = var.private_subnet_cidrs
  security_group_id = aws_security_group.elasticache.id
  description       = "Allow Redis access from private subnets"
}

# Security Group Rule - Egress (allow all outbound)
resource "aws_security_group_rule" "elasticache_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elasticache.id
  description       = "Allow all outbound traffic"
}

# Note: ElastiCache cluster implementation moved to elasticache.tf
# This file only contains supporting resources (subnet group, parameter group, security group)
# The actual Redis replication group is in elasticache.tf for proper multi-node support
