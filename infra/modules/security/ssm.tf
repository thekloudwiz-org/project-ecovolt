# Security Module - SSM Parameter Store
# Stores security resource identifiers for cross-module reference

# KMS Key ID
resource "aws_ssm_parameter" "kms_key_id" {
  name        = "${local.ssm_prefix}/kms_key_id"
  description = "KMS key ID for ${var.environment} ${var.project_name}"
  type        = "String"
  value       = aws_kms_key.main.key_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-kms-key-id-param"
    }
  )
}

# KMS Key ARN
resource "aws_ssm_parameter" "kms_key_arn" {
  name        = "${local.ssm_prefix}/kms_key_arn"
  description = "KMS key ARN for ${var.environment} ${var.project_name}"
  type        = "String"
  value       = aws_kms_key.main.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-kms-key-arn-param"
    }
  )
}

# Lambda Execution Role ARN
resource "aws_ssm_parameter" "lambda_execution_role_arn" {
  name        = "${local.ssm_prefix}/lambda_execution_role_arn"
  description = "Lambda execution role ARN for ${var.environment} ${var.project_name}"
  type        = "String"
  value       = aws_iam_role.lambda_execution.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-lambda-role-arn-param"
    }
  )
}

# ECS Task Execution Role ARN
resource "aws_ssm_parameter" "ecs_task_execution_role_arn" {
  name        = "${local.ssm_prefix}/ecs_task_execution_role_arn"
  description = "ECS task execution role ARN for ${var.environment} ${var.project_name}"
  type        = "String"
  value       = aws_iam_role.ecs_task_execution.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-ecs-role-arn-param"
    }
  )
}

# CloudTrail ARN (if enabled)
resource "aws_ssm_parameter" "cloudtrail_arn" {
  count = var.enable_cloudtrail ? 1 : 0

  name        = "${local.ssm_prefix}/cloudtrail_arn"
  description = "CloudTrail ARN for ${var.environment} ${var.project_name}"
  type        = "String"
  value       = aws_cloudtrail.main[0].arn

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-cloudtrail-arn-param"
    }
  )
}

# GuardDuty Detector ID (if enabled)
resource "aws_ssm_parameter" "guardduty_detector_id" {
  count = var.enable_guardduty ? 1 : 0

  name        = "${local.ssm_prefix}/guardduty_detector_id"
  description = "GuardDuty detector ID for ${var.environment} ${var.project_name}"
  type        = "String"
  value       = aws_guardduty_detector.main[0].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-guardduty-id-param"
    }
  )
}
