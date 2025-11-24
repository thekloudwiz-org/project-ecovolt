# Security Module - Outputs

output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.main.arn
}

output "kms_key_alias" {
  description = "KMS key alias"
  value       = aws_kms_alias.main.name
}

output "cloudtrail_arn" {
  description = "CloudTrail trail ARN (if enabled)"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_id" {
  description = "CloudTrail trail ID (if enabled)"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].id : null
}

output "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs (if enabled)"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].id : null
}

output "cloudtrail_bucket_arn" {
  description = "S3 bucket ARN for CloudTrail logs (if enabled)"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].arn : null
}

output "cloudtrail_log_group_name" {
  description = "CloudWatch Log Group name for CloudTrail (if enabled)"
  value       = var.enable_cloudtrail ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

output "cloudtrail_log_group_arn" {
  description = "CloudWatch Log Group ARN for CloudTrail (if enabled)"
  value       = var.enable_cloudtrail ? aws_cloudwatch_log_group.cloudtrail[0].arn : null
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID (if enabled)"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "guardduty_detector_arn" {
  description = "GuardDuty detector ARN (if enabled)"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].arn : null
}

output "lambda_execution_role_arn" {
  description = "IAM role ARN for Lambda execution (base role with CloudWatch Logs access)"
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_execution_role_name" {
  description = "IAM role name for Lambda execution"
  value       = aws_iam_role.lambda_execution.name
}

output "ecs_task_execution_role_arn" {
  description = "IAM role ARN for ECS task execution"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_execution_role_name" {
  description = "IAM role name for ECS task execution"
  value       = aws_iam_role.ecs_task_execution.name
}

output "cloudtrail_role_arn" {
  description = "IAM role ARN for CloudTrail (if enabled)"
  value       = var.enable_cloudtrail ? aws_iam_role.cloudtrail[0].arn : null
}

# SSM Parameter Store Paths
output "ssm_kms_key_id_parameter" {
  description = "SSM Parameter name for KMS key ID"
  value       = aws_ssm_parameter.kms_key_id.name
}

output "ssm_kms_key_arn_parameter" {
  description = "SSM Parameter name for KMS key ARN"
  value       = aws_ssm_parameter.kms_key_arn.name
}

output "ssm_parameter_prefix" {
  description = "SSM Parameter Store prefix for security resources"
  value       = local.ssm_prefix
}
