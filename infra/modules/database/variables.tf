# Database Module - Variables

variable "project_name" {
  description = "Project name used in resource naming (e.g., 'ecovolt')"
  type        = string
  default     = "ecovolt"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group"
  type        = string
}

variable "data_subnet_ids" {
  description = "List of data subnet IDs for RDS and ElastiCache subnet groups"
  type        = list(string)

  validation {
    condition     = length(var.data_subnet_ids) >= 2
    error_message = "At least 2 data subnets are required for Multi-AZ deployment."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets for security group ingress rules"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption at rest"
  type        = string
}

# RDS Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "ecovolt"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_username" {
  description = "Master username for RDS instance"
  type        = string
  default     = "ecovolt_admin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "Username must start with a letter and contain only alphanumeric characters and underscores."
  }
}

# Password is now auto-generated using random_password resource
# No need for db_password variable

# Secrets Manager rotation settings
variable "enable_secret_rotation" {
  description = "Enable automatic rotation of database credentials"
  type        = bool
  default     = false # Disabled by default for dev, enable for prod
}

variable "secret_rotation_days" {
  description = "Number of days between automatic credential rotations"
  type        = number
  default     = 30

  validation {
    condition     = var.secret_rotation_days >= 1 && var.secret_rotation_days <= 365
    error_message = "Rotation days must be between 1 and 365."
  }
}

variable "db_instance_class" {
  description = "RDS instance type (e.g., db.t3.micro, db.r5.large)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "Allocated storage must be between 20 GB and 65536 GB."
  }
}

variable "db_max_allocated_storage" {
  description = "Maximum storage size in GB for auto-scaling (0 to disable)"
  type        = number
  default     = 100

  validation {
    condition     = var.db_max_allocated_storage == 0 || var.db_max_allocated_storage >= 20
    error_message = "Maximum allocated storage must be 0 (disabled) or at least 20 GB."
  }
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups (0-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_period >= 0 && var.db_backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "db_backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.15"
}

variable "db_parameter_family" {
  description = "PostgreSQL parameter group family"
  type        = string
  default     = "postgres15"
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when deleting (set to false for production)"
  type        = bool
  default     = false
}

variable "db_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "db_performance_insights_retention_period" {
  description = "Performance Insights retention period in days (7, 731, or multiples of 31)"
  type        = number
  default     = 7

  validation {
    condition     = var.db_performance_insights_retention_period == 7 || var.db_performance_insights_retention_period == 731 || (var.db_performance_insights_retention_period % 31 == 0 && var.db_performance_insights_retention_period > 0)
    error_message = "Performance Insights retention must be 7, 731, or a multiple of 31 days."
  }
}

# ElastiCache Configuration
variable "elasticache_node_type" {
  description = "ElastiCache node type (e.g., cache.t3.micro, cache.r5.large)"
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_num_cache_nodes" {
  description = "Number of cache nodes in the cluster"
  type        = number
  default     = 2

  validation {
    condition     = var.elasticache_num_cache_nodes >= 1 && var.elasticache_num_cache_nodes <= 20
    error_message = "Number of cache nodes must be between 1 and 20."
  }
}

variable "elasticache_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "elasticache_parameter_family" {
  description = "Redis parameter group family"
  type        = string
  default     = "redis7"
}

variable "elasticache_port" {
  description = "Port for ElastiCache Redis"
  type        = number
  default     = 6379
}

variable "elasticache_snapshot_retention_limit" {
  description = "Number of days to retain automatic snapshots (0-35)"
  type        = number
  default     = 5

  validation {
    condition     = var.elasticache_snapshot_retention_limit >= 0 && var.elasticache_snapshot_retention_limit <= 35
    error_message = "Snapshot retention limit must be between 0 and 35 days."
  }
}

variable "elasticache_snapshot_window" {
  description = "Daily time range for automatic snapshots (UTC)"
  type        = string
  default     = "05:00-06:00"
}

variable "elasticache_maintenance_window" {
  description = "Weekly time range for maintenance (UTC)"
  type        = string
  default     = "sun:06:00-sun:07:00"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ElastiCache (Redis) Variables
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

variable "redis_engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "redis_family" {
  description = "Redis parameter group family"
  type        = string
  default     = "redis7"
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

variable "redis_snapshot_retention_limit" {
  description = "Number of days to retain Redis snapshots"
  type        = number
  default     = 5
}

variable "redis_snapshot_window" {
  description = "Daily time range for Redis snapshots (UTC)"
  type        = string
  default     = "03:00-05:00"
}

variable "redis_maintenance_window" {
  description = "Weekly time range for Redis maintenance (UTC)"
  type        = string
  default     = "sun:05:00-sun:07:00"
}

variable "redis_notification_topic_arn" {
  description = "SNS topic ARN for Redis notifications"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "alarm_sns_topic_arns" {
  description = "List of SNS topic ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}
