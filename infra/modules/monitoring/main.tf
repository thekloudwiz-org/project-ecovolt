# Monitoring Module - Main Configuration
# Creates CloudWatch alarms, SNS topics, and dashboards

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# SNS Topics for Alarm Notifications
# ============================================================================

# General alarm topic
resource "aws_sns_topic" "alarms" {
  name = local.alarm_topic_name

  tags = merge(
    local.common_tags,
    {
      Name = local.alarm_topic_name
    }
  )
}

# Critical alarm topic
resource "aws_sns_topic" "critical_alarms" {
  name = local.critical_alarm_topic_name

  tags = merge(
    local.common_tags,
    {
      Name = local.critical_alarm_topic_name
    }
  )
}

# Email subscriptions for general alarms
resource "aws_sns_topic_subscription" "alarm_email" {
  count = length(var.alarm_email_addresses)

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email_addresses[count.index]
}

# Email subscriptions for critical alarms
resource "aws_sns_topic_subscription" "critical_alarm_email" {
  count = length(var.alarm_email_addresses)

  topic_arn = aws_sns_topic.critical_alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email_addresses[count.index]
}

# SMS subscriptions for critical alarms
resource "aws_sns_topic_subscription" "critical_alarm_sms" {
  count = length(var.alarm_phone_numbers)

  topic_arn = aws_sns_topic.critical_alarms.arn
  protocol  = "sms"
  endpoint  = var.alarm_phone_numbers[count.index]
}

# ============================================================================
# Lambda Function Alarms
# ============================================================================

# Lambda Errors Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = length(var.lambda_function_names)

  alarm_name          = "${local.lambda_alarm_prefix}-${var.lambda_function_names[count.index]}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "Lambda function ${var.lambda_function_names[count.index]} error rate exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_names[count.index]
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# Lambda Duration Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count = length(var.lambda_function_names)

  alarm_name          = "${local.lambda_alarm_prefix}-${var.lambda_function_names[count.index]}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = var.lambda_duration_threshold
  alarm_description   = "Lambda function ${var.lambda_function_names[count.index]} duration exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_names[count.index]
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# Lambda Throttles Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count = length(var.lambda_function_names)

  alarm_name          = "${local.lambda_alarm_prefix}-${var.lambda_function_names[count.index]}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda function ${var.lambda_function_names[count.index]} is being throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_names[count.index]
  }

  alarm_actions = [aws_sns_topic.critical_alarms.arn]

  tags = local.common_tags
}

# ============================================================================
# API Gateway Alarms
# ============================================================================

# API Gateway 4xx Errors
resource "aws_cloudwatch_metric_alarm" "api_4xx_errors" {
  count = var.enable_api_gateway_monitoring ? 1 : 0

  alarm_name          = "${local.api_gateway_alarm_prefix}-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = var.api_4xx_error_threshold
  alarm_description   = "API Gateway 4xx error rate exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_id
    Stage   = var.api_gateway_stage_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# API Gateway 5xx Errors
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  count = var.enable_api_gateway_monitoring ? 1 : 0

  alarm_name          = "${local.api_gateway_alarm_prefix}-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = var.api_5xx_error_threshold
  alarm_description   = "API Gateway 5xx error rate exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_id
    Stage   = var.api_gateway_stage_name
  }

  alarm_actions = [aws_sns_topic.critical_alarms.arn]

  tags = local.common_tags
}

# API Gateway Latency
resource "aws_cloudwatch_metric_alarm" "api_latency" {
  count = var.enable_api_gateway_monitoring ? 1 : 0

  alarm_name          = "${local.api_gateway_alarm_prefix}-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Average"
  threshold           = var.api_latency_threshold
  alarm_description   = "API Gateway latency exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_id
    Stage   = var.api_gateway_stage_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# ============================================================================
# Database Alarms
# ============================================================================

# Database CPU Utilization
resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  count = var.enable_database_monitoring ? 1 : 0

  alarm_name          = "${local.database_alarm_prefix}-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.db_cpu_threshold
  alarm_description   = "Database CPU utilization exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# Database Connections
resource "aws_cloudwatch_metric_alarm" "db_connections" {
  count = var.enable_database_monitoring ? 1 : 0

  alarm_name          = "${local.database_alarm_prefix}-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.db_connections_threshold
  alarm_description   = "Database connections exceeded threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# Database Free Storage Space
resource "aws_cloudwatch_metric_alarm" "db_storage" {
  count = var.enable_database_monitoring ? 1 : 0

  alarm_name          = "${local.database_alarm_prefix}-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  alarm_description   = "Database free storage space below threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  alarm_actions = [aws_sns_topic.critical_alarms.arn]

  tags = local.common_tags
}

# ============================================================================
# Kinesis Alarms
# ============================================================================

# Kinesis Iterator Age
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {


  alarm_name          = "${local.kinesis_alarm_prefix}-iterator-age"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.kinesis_iterator_age_threshold
  alarm_description   = "Kinesis iterator age exceeded threshold - processing lag detected"
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = var.kinesis_stream_name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]

  tags = local.common_tags
}

# ============================================================================
# CloudWatch Dashboard
# ============================================================================

resource "aws_cloudwatch_dashboard" "main" {
  count = var.enable_dashboard ? 1 : 0

  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = concat(
      # Lambda widgets
      length(var.lambda_function_names) > 0 ? [
        {
          type = "metric"
          properties = {
            metrics = [
              for fn in var.lambda_function_names : [
                "AWS/Lambda", "Invocations", "FunctionName", fn
              ]
            ]
            period = 300
            stat   = "Sum"
            region = data.aws_region.current.name
            title  = "Lambda Invocations"
          }
        },
        {
          type = "metric"
          properties = {
            metrics = [
              for fn in var.lambda_function_names : [
                "AWS/Lambda", "Errors", "FunctionName", fn
              ]
            ]
            period = 300
            stat   = "Sum"
            region = data.aws_region.current.name
            title  = "Lambda Errors"
          }
        }
      ] : [],
      # API Gateway widgets
      var.api_gateway_id != "" ? [
        {
          type = "metric"
          properties = {
            metrics = [
              ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_id],
              ["AWS/ApiGateway", "4XXError", "ApiName", var.api_gateway_id],
              ["AWS/ApiGateway", "5XXError", "ApiName", var.api_gateway_id]
            ]
            period = 300
            stat   = "Sum"
            region = data.aws_region.current.name
            title  = "API Gateway Requests"
          }
        }
      ] : [],
      # Database widgets
      var.db_instance_id != "" ? [
        {
          type = "metric"
          properties = {
            metrics = [
              ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id],
              ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_id]
            ]
            period = 300
            stat   = "Average"
            region = data.aws_region.current.name
            title  = "Database Metrics"
          }
        }
      ] : []
    )
  })
}
