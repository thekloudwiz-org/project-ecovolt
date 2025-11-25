# Compute Module - Local Values

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Module      = "compute"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  )

  # Lambda function names
  api_handler_function_name       = "${local.name_prefix}-api-handler"
  data_transformer_function_name  = "${local.name_prefix}-data-transformer"

  # API Gateway names
  api_gateway_name = "${local.name_prefix}-${var.api_gateway_name}"
  api_gateway_log_group_name = "/aws/apigateway/${local.api_gateway_name}"

  # Lambda log group names
  api_handler_log_group       = "/aws/lambda/${local.api_handler_function_name}"
  data_transformer_log_group  = "/aws/lambda/${local.data_transformer_function_name}"

  # Security group names
  lambda_sg_name = "${local.name_prefix}-lambda-sg"

  # IAM role names
  lambda_execution_role_name = "${local.name_prefix}-lambda-execution-role"
  api_gateway_role_name      = "${local.name_prefix}-api-gateway-role"

  # SSM Parameter Store paths
  ssm_prefix                = "/${var.project_name}/${var.environment}/compute"
  ssm_api_gateway_url_path  = "${local.ssm_prefix}/api_gateway/url"
  ssm_api_gateway_id_path   = "${local.ssm_prefix}/api_gateway/id"
}
