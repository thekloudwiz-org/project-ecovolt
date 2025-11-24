# Compute Module - Outputs

# ============================================================================
# Lambda Function Outputs
# ============================================================================

output "api_handler_function_name" {
  description = "API handler Lambda function name"
  value       = aws_lambda_function.api_handler.function_name
}

output "api_handler_function_arn" {
  description = "API handler Lambda function ARN"
  value       = aws_lambda_function.api_handler.arn
}

output "api_handler_invoke_arn" {
  description = "API handler Lambda function invoke ARN"
  value       = aws_lambda_function.api_handler.invoke_arn
}

output "iot_processor_function_name" {
  description = "IoT processor Lambda function name"
  value       = aws_lambda_function.iot_processor.function_name
}

output "iot_processor_function_arn" {
  description = "IoT processor Lambda function ARN"
  value       = aws_lambda_function.iot_processor.arn
}

output "db_migrator_function_name" {
  description = "Database migrator Lambda function name"
  value       = aws_lambda_function.db_migrator.function_name
}

output "db_migrator_function_arn" {
  description = "Database migrator Lambda function ARN"
  value       = aws_lambda_function.db_migrator.arn
}

output "lambda_execution_role_arn" {
  description = "Lambda execution IAM role ARN"
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

# ============================================================================
# API Gateway Outputs
# ============================================================================

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_root_resource_id" {
  description = "API Gateway root resource ID"
  value       = aws_api_gateway_rest_api.main.root_resource_id
}

output "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_stage_name" {
  description = "API Gateway stage name"
  value       = aws_api_gateway_stage.main.stage_name
}

output "api_gateway_deployment_id" {
  description = "API Gateway deployment ID"
  value       = aws_api_gateway_deployment.main.id
}

# ============================================================================
# CloudWatch Log Group Outputs
# ============================================================================

output "api_handler_log_group_name" {
  description = "API handler Lambda log group name"
  value       = aws_cloudwatch_log_group.api_handler.name
}

output "iot_processor_log_group_name" {
  description = "IoT processor Lambda log group name"
  value       = aws_cloudwatch_log_group.iot_processor.name
}

output "api_gateway_log_group_name" {
  description = "API Gateway log group name"
  value       = var.enable_api_gateway_access_logs ? aws_cloudwatch_log_group.api_gateway[0].name : null
}

# ============================================================================
# SSM Parameter Store Outputs
# ============================================================================

output "ssm_api_gateway_url_parameter" {
  description = "SSM Parameter name for API Gateway URL"
  value       = aws_ssm_parameter.api_gateway_url.name
}

output "ssm_api_gateway_id_parameter" {
  description = "SSM Parameter name for API Gateway ID"
  value       = aws_ssm_parameter.api_gateway_id.name
}

output "ssm_parameter_prefix" {
  description = "SSM Parameter Store prefix for compute resources"
  value       = local.ssm_prefix
}

# ============================================================================
# SNS Topic Outputs
# ============================================================================

output "notifications_topic_arn" {
  description = "SNS topic ARN for application notifications"
  value       = aws_sns_topic.notifications.arn
}

output "notifications_topic_name" {
  description = "SNS topic name for application notifications"
  value       = aws_sns_topic.notifications.name
}

# ============================================================================
# WAF Outputs
# ============================================================================

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.api_gateway.id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.api_gateway.arn
}

output "waf_log_group_name" {
  description = "WAF CloudWatch log group name"
  value       = aws_cloudwatch_log_group.waf.name
}
