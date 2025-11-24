# Security Module - Local Values
# Defines uniform naming convention: <environment>-<project>-<resource>

locals {
  # Base naming prefix
  name_prefix = "${var.environment}-${var.project_name}"

  # KMS naming
  kms_key_alias = "alias/${local.name_prefix}-main"

  # CloudTrail naming
  cloudtrail_name        = "${local.name_prefix}-cloudtrail"
  cloudtrail_bucket_name = var.cloudtrail_bucket_name != "" ? var.cloudtrail_bucket_name : "${local.name_prefix}-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  cloudtrail_log_group   = "/aws/cloudtrail/${local.name_prefix}"

  # GuardDuty naming
  guardduty_detector_name = "${local.name_prefix}-guardduty"

  # IAM role naming
  cloudtrail_role_name = "${local.name_prefix}-cloudtrail-role"

  # SSM Parameter Store paths
  ssm_prefix = "/${var.environment}/${var.project_name}/security"

  # Common tags
  common_tags = merge(
    var.tags,
    {
      Module      = "security"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}
