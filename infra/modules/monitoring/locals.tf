# Monitoring Module - Local Values

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Module      = "monitoring"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )

  # SNS topic names
  alarm_topic_name          = "${local.name_prefix}-alarms"
  critical_alarm_topic_name = "${local.name_prefix}-critical-alarms"

  # Dashboard name
  dashboard_name = "${local.name_prefix}-dashboard"

  # Alarm name prefixes
  lambda_alarm_prefix      = "${local.name_prefix}-lambda"
  api_gateway_alarm_prefix = "${local.name_prefix}-api"
  database_alarm_prefix    = "${local.name_prefix}-db"
  kinesis_alarm_prefix     = "${local.name_prefix}-kinesis"
}
