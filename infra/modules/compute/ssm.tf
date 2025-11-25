# Compute Module - SSM Parameter Store
# Store API Gateway information in SSM Parameter Store for easy access by other services

# API Gateway URL
resource "aws_ssm_parameter" "api_gateway_url" {
  name        = local.ssm_api_gateway_url_path
  description = "API Gateway invoke URL"
  type        = "String"
  value       = aws_api_gateway_stage.main.invoke_url

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-api-gateway-url"
    }
  )
}

# API Gateway ID
resource "aws_ssm_parameter" "api_gateway_id" {
  name        = local.ssm_api_gateway_id_path
  description = "API Gateway REST API ID"
  type        = "String"
  value       = aws_api_gateway_rest_api.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-api-gateway-id"
    }
  )
}
