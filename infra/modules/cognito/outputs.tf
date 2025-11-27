# Cognito Module Outputs

# Customer User Pool
output "customer_user_pool_id" {
  description = "ID of the customer user pool"
  value       = aws_cognito_user_pool.customers.id
}

output "customer_user_pool_arn" {
  description = "ARN of the customer user pool"
  value       = aws_cognito_user_pool.customers.arn
}

output "customer_user_pool_endpoint" {
  description = "Endpoint of the customer user pool"
  value       = aws_cognito_user_pool.customers.endpoint
}

output "customer_user_pool_domain" {
  description = "Domain of the customer user pool"
  value       = aws_cognito_user_pool_domain.customers.domain
}

# Admin User Pool
output "admin_user_pool_id" {
  description = "ID of the admin user pool (if created)"
  value       = var.create_separate_admin_pool ? aws_cognito_user_pool.admins[0].id : null
}

output "admin_user_pool_arn" {
  description = "ARN of the admin user pool (if created)"
  value       = var.create_separate_admin_pool ? aws_cognito_user_pool.admins[0].arn : null
}

# App Clients
output "mobile_app_client_id" {
  description = "ID of the mobile app client"
  value       = aws_cognito_user_pool_client.mobile_app.id
}

output "mobile_app_client_secret" {
  description = "Secret of the mobile app client (empty for public clients)"
  value       = ""
  sensitive   = true
}

output "admin_portal_client_id" {
  description = "ID of the admin portal client"
  value       = aws_cognito_user_pool_client.admin_portal.id
}

output "admin_portal_client_secret" {
  description = "Secret of the admin portal client"
  value       = aws_cognito_user_pool_client.admin_portal.client_secret
  sensitive   = true
}

# Identity Pool
output "identity_pool_id" {
  description = "ID of the identity pool (if created)"
  value       = var.create_identity_pool ? aws_cognito_identity_pool.main[0].id : null
}

# User Groups
output "customer_group_name" {
  description = "Name of the customer user group"
  value       = aws_cognito_user_group.customers.name
}

output "admin_group_name" {
  description = "Name of the admin user group"
  value       = aws_cognito_user_group.admins.name
}

output "operator_group_name" {
  description = "Name of the operator user group"
  value       = aws_cognito_user_group.operators.name
}

# For API Gateway integration
output "customer_user_pool_arn_for_authorizer" {
  description = "ARN to use for API Gateway Cognito authorizer"
  value       = aws_cognito_user_pool.customers.arn
}

# JWKS JSON for JWT verification (fetched automatically by Terraform)
output "customer_user_pool_jwks_json" {
  description = "JWKS JSON for verifying JWT tokens from customer user pool"
  value       = data.http.customer_jwks.response_body
  sensitive   = false
}

output "admin_user_pool_jwks_json" {
  description = "JWKS JSON for verifying JWT tokens from admin user pool (if created)"
  value       = var.create_separate_admin_pool ? data.http.admin_jwks[0].response_body : null
  sensitive   = false
}
