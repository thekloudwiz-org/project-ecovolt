# Amazon ElastiCache (Redis)
# Provides caching layer for API responses and session storage

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "redis" {
  count = var.enable_elasticache ? 1 : 0

  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = var.data_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-subnet-group"
    }
  )
}

# Security Group for ElastiCache
resource "aws_security_group" "redis" {
  count = var.enable_elasticache ? 1 : 0

  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for ElastiCache Redis cluster"
  vpc_id      = var.vpc_id

  # Allow Redis port from private subnets (Lambda functions)
  ingress {
    description = "Redis from private subnets"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-sg"
    }
  )
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "redis" {
  count = var.enable_elasticache ? 1 : 0

  name   = "${var.project_name}-${var.environment}-redis-params"
  family = var.redis_family

  # Optimize for performance
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru" # Evict least recently used keys
  }

  parameter {
    name  = "timeout"
    value = "300" # Close idle connections after 5 minutes
  }

  parameter {
    name  = "tcp-keepalive"
    value = "300"
  }

  tags = var.tags
}

# ElastiCache Replication Group (Redis Cluster)
resource "aws_elasticache_replication_group" "redis" {
  count = var.enable_elasticache ? 1 : 0

  replication_group_id = "${var.project_name}-${var.environment}-redis"
  description          = "Redis cluster for ${var.project_name} ${var.environment}"

  # Engine configuration
  engine               = "redis"
  engine_version       = var.redis_engine_version
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.redis[0].name

  # Node configuration
  node_type          = var.redis_node_type
  num_cache_clusters = var.redis_num_cache_nodes

  # Multi-AZ configuration
  automatic_failover_enabled = var.redis_multi_az
  multi_az_enabled           = var.redis_multi_az

  # Subnet and security
  subnet_group_name  = aws_elasticache_subnet_group.redis[0].name
  security_group_ids = [aws_security_group.redis[0].id]

  # Encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_auth_token_enabled && var.redis_auth_token != "" ? var.redis_auth_token : null
  kms_key_id                 = var.kms_key_arn

  # Backup configuration
  snapshot_retention_limit = var.redis_snapshot_retention_limit
  snapshot_window          = var.redis_snapshot_window

  # Maintenance
  maintenance_window     = var.redis_maintenance_window
  notification_topic_arn = var.redis_notification_topic_arn

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log[0].name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log[0].name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis"
    }
  )
}

# CloudWatch Log Groups for Redis
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  count = var.enable_elasticache ? 1 : 0

  name              = "/aws/elasticache/${var.project_name}-${var.environment}/slow-log"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  count = var.enable_elasticache ? 1 : 0

  name              = "/aws/elasticache/${var.project_name}-${var.environment}/engine-log"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch Alarms for Redis
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  count = var.enable_elasticache && length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "75"
  alarm_description   = "Redis CPU utilization is too high"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis[0].id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  count = var.enable_elasticache && length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Redis memory utilization is too high"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis[0].id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_evictions" {
  count = var.enable_elasticache && length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-redis-evictions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1000"
  alarm_description   = "Redis is evicting keys due to memory pressure"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis[0].id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "redis_replication_lag" {
  count = var.enable_elasticache && var.redis_multi_az && length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-redis-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReplicationLag"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "Redis replication lag is too high"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.redis[0].id
  }

  tags = var.tags
}

# SSM Parameter for Redis endpoint
resource "aws_ssm_parameter" "redis_endpoint" {
  count = var.enable_elasticache ? 1 : 0

  name        = "/${var.project_name}/${var.environment}/redis/endpoint"
  description = "Redis primary endpoint"
  type        = "String"
  value       = aws_elasticache_replication_group.redis[0].primary_endpoint_address

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-endpoint"
    }
  )
}

resource "aws_ssm_parameter" "redis_port" {
  count = var.enable_elasticache ? 1 : 0

  name        = "/${var.project_name}/${var.environment}/redis/port"
  description = "Redis port"
  type        = "String"
  value       = "6379"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-port"
    }
  )
}

resource "aws_ssm_parameter" "redis_reader_endpoint" {
  count = var.enable_elasticache && var.redis_multi_az ? 1 : 0

  name        = "/${var.project_name}/${var.environment}/redis/reader-endpoint"
  description = "Redis reader endpoint"
  type        = "String"
  value       = aws_elasticache_replication_group.redis[0].reader_endpoint_address

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-redis-reader-endpoint"
    }
  )
}
