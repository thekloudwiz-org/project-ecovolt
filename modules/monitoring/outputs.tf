# Monitoring Module - Outputs

# SNS Topic Outputs
output "alarm_topic_arn" {
  description = "SNS topic ARN for general alarms"
  value       = aws_sns_topic.alarms.arn
}

output "critical_alarm_topic_arn" {
  description = "SNS topic ARN for critical alarms"
  value       = aws_sns_topic.critical_alarms.arn
}

output "alarm_topic_name" {
  description = "SNS topic name for general alarms"
  value       = aws_sns_topic.alarms.name
}

output "critical_alarm_topic_name" {
  description = "SNS topic name for critical alarms"
  value       = aws_sns_topic.critical_alarms.name
}

# Dashboard Outputs
output "dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_name : null
}

output "dashboard_arn" {
  description = "CloudWatch dashboard ARN"
  value       = var.enable_dashboard ? aws_cloudwatch_dashboard.main[0].dashboard_arn : null
}

# Alarm Outputs
output "lambda_error_alarm_arns" {
  description = "Lambda error alarm ARNs"
  value       = aws_cloudwatch_metric_alarm.lambda_errors[*].arn
}

output "lambda_duration_alarm_arns" {
  description = "Lambda duration alarm ARNs"
  value       = aws_cloudwatch_metric_alarm.lambda_duration[*].arn
}

output "lambda_throttle_alarm_arns" {
  description = "Lambda throttle alarm ARNs"
  value       = aws_cloudwatch_metric_alarm.lambda_throttles[*].arn
}

output "api_4xx_alarm_arn" {
  description = "API Gateway 4xx error alarm ARN"
  value       = var.api_gateway_id != "" ? aws_cloudwatch_metric_alarm.api_4xx_errors[0].arn : null
}

output "api_5xx_alarm_arn" {
  description = "API Gateway 5xx error alarm ARN"
  value       = var.api_gateway_id != "" ? aws_cloudwatch_metric_alarm.api_5xx_errors[0].arn : null
}

output "api_latency_alarm_arn" {
  description = "API Gateway latency alarm ARN"
  value       = var.api_gateway_id != "" ? aws_cloudwatch_metric_alarm.api_latency[0].arn : null
}

output "db_cpu_alarm_arn" {
  description = "Database CPU alarm ARN"
  value       = var.db_instance_id != "" ? aws_cloudwatch_metric_alarm.db_cpu[0].arn : null
}

output "db_connections_alarm_arn" {
  description = "Database connections alarm ARN"
  value       = var.db_instance_id != "" ? aws_cloudwatch_metric_alarm.db_connections[0].arn : null
}

output "db_storage_alarm_arn" {
  description = "Database storage alarm ARN"
  value       = var.db_instance_id != "" ? aws_cloudwatch_metric_alarm.db_storage[0].arn : null
}

output "kinesis_iterator_age_alarm_arn" {
  description = "Kinesis iterator age alarm ARN"
  value       = aws_cloudwatch_metric_alarm.kinesis_iterator_age.arn
}
