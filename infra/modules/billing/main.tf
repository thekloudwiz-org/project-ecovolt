# Billing Module - Main Configuration
# Creates AWS Budgets and SNS notifications for cost monitoring

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(
    var.tags,
    {
      Module      = "billing"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )

  budget_alert_topic_name = "${local.name_prefix}-budget-alerts"
}

# ============================================================================
# SNS Topic for Budget Alerts
# ============================================================================

resource "aws_sns_topic" "budget_alerts" {
  name = local.budget_alert_topic_name

  tags = merge(
    local.common_tags,
    {
      Name = local.budget_alert_topic_name
    }
  )
}

# Email subscriptions
resource "aws_sns_topic_subscription" "budget_email" {
  count = length(var.budget_alert_email_addresses)

  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.budget_alert_email_addresses[count.index]
}

# SMS subscriptions
resource "aws_sns_topic_subscription" "budget_sms" {
  count = length(var.budget_alert_phone_numbers)

  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "sms"
  endpoint  = var.budget_alert_phone_numbers[count.index]
}

# ============================================================================
# Overall Monthly Budget
# ============================================================================

resource "aws_budgets_budget" "overall" {
  name              = "${local.name_prefix}-overall-monthly"
  budget_type       = "COST"
  limit_amount      = var.overall_monthly_budget
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  # Actual spend notifications
  dynamic "notification" {
    for_each = var.budget_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
    }
  }

  # Forecasted spend notifications
  dynamic "notification" {
    for_each = var.enable_forecasted_alerts ? var.budget_thresholds : []
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
    }
  }

  cost_types {
    include_credit             = false
    include_discount           = true
    include_other_subscription = true
    include_recurring          = true
    include_refund             = false
    include_subscription       = true
    include_support            = true
    include_tax                = true
    include_upfront            = true
    use_blended                = false
  }
}

# ============================================================================
# Service-Specific Budgets
# ============================================================================

# Compute Services Budget (EC2, ECS, Fargate, Lambda)
resource "aws_budgets_budget" "compute" {
  count = var.service_budgets.compute > 0 ? 1 : 0

  name              = "${local.name_prefix}-compute"
  budget_type       = "COST"
  limit_amount      = var.service_budgets.compute
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filter {
    name   = "Service"
    values = ["Amazon Elastic Compute Cloud - Compute", "Amazon EC2 Container Service", "AWS Lambda"]
  }

  dynamic "notification" {
    for_each = var.budget_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
    }
  }
}

# Storage Services Budget (S3, EBS, EFS)
resource "aws_budgets_budget" "storage" {
  count = var.service_budgets.storage > 0 ? 1 : 0

  name              = "${local.name_prefix}-storage"
  budget_type       = "COST"
  limit_amount      = var.service_budgets.storage
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filter {
    name   = "Service"
    values = ["Amazon Simple Storage Service", "Amazon Elastic Block Store", "Amazon Elastic File System"]
  }

  dynamic "notification" {
    for_each = var.budget_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
    }
  }
}

# Database Services Budget (RDS, Timestream, ElastiCache)
resource "aws_budgets_budget" "database" {
  count = var.service_budgets.database > 0 ? 1 : 0

  name              = "${local.name_prefix}-database"
  budget_type       = "COST"
  limit_amount      = var.service_budgets.database
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filter {
    name   = "Service"
    values = ["Amazon Relational Database Service", "Amazon Timestream", "Amazon ElastiCache"]
  }

  dynamic "notification" {
    for_each = var.budget_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
    }
  }
}

# IoT Services Budget
resource "aws_budgets_budget" "iot" {
  count = var.service_budgets.iot > 0 ? 1 : 0

  name              = "${local.name_prefix}-iot"
  budget_type       = "COST"
  limit_amount      = var.service_budgets.iot
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filter {
    name   = "Service"
    values = ["AWS IoT", "AWS IoT Greengrass"]
  }

  dynamic "notification" {
    for_each = var.budget_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
    }
  }
}

# Data Transfer Budget
resource "aws_budgets_budget" "transfer" {
  count = var.service_budgets.transfer > 0 ? 1 : 0

  name              = "${local.name_prefix}-data-transfer"
  budget_type       = "COST"
  limit_amount      = var.service_budgets.transfer
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filter {
    name   = "UsageType"
    values = ["DataTransfer-Out-Bytes", "DataTransfer-Regional-Bytes"]
  }

  dynamic "notification" {
    for_each = var.budget_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
    }
  }
}

# Analytics Services Budget (Kinesis, Athena, Glue)
resource "aws_budgets_budget" "analytics" {
  count = var.service_budgets.analytics > 0 ? 1 : 0

  name              = "${local.name_prefix}-analytics"
  budget_type       = "COST"
  limit_amount      = var.service_budgets.analytics
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filter {
    name   = "Service"
    values = ["Amazon Kinesis", "Amazon Athena", "AWS Glue"]
  }

  dynamic "notification" {
    for_each = var.budget_thresholds
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts.arn]
    }
  }
}
