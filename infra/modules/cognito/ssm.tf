# SSM Parameters for Cognito Configuration

# Customer User Pool Parameters
resource "aws_ssm_parameter" "user_pool_id" {
  name        = "/${var.project_name}/${var.environment}/cognito/user_pool_id"
  description = "Cognito User Pool ID"
  type        = "String"
  value       = aws_cognito_user_pool.customers.id

  tags = var.tags
}

resource "aws_ssm_parameter" "user_pool_arn" {
  name        = "/${var.project_name}/${var.environment}/cognito/user_pool_arn"
  description = "Cognito User Pool ARN"
  type        = "String"
  value       = aws_cognito_user_pool.customers.arn

  tags = var.tags
}

# App Client Parameters
resource "aws_ssm_parameter" "mobile_app_client_id" {
  name        = "/${var.project_name}/${var.environment}/cognito/mobile_app_client_id"
  description = "Mobile App Client ID"
  type        = "String"
  value       = aws_cognito_user_pool_client.mobile_app.id

  tags = var.tags
}

resource "aws_ssm_parameter" "admin_portal_client_id" {
  name        = "/${var.project_name}/${var.environment}/cognito/admin_portal_client_id"
  description = "Admin Portal Client ID"
  type        = "String"
  value       = aws_cognito_user_pool_client.admin_portal.id

  tags = var.tags
}

# Region is available from AWS provider data source if needed

# User Pool Domain
resource "aws_ssm_parameter" "user_pool_domain" {
  name        = "/${var.project_name}/${var.environment}/cognito/user_pool_domain"
  description = "Cognito User Pool Domain"
  type        = "String"
  value       = aws_cognito_user_pool_domain.customers.domain

  tags = var.tags
}
