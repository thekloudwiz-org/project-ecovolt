# Authentication Lambda Function
# Runs outside VPC to access Cognito (which doesn't support VPC endpoints with ManagedLogin)
# Handles only authentication endpoints: register, login, confirm, refresh

# CloudWatch Log Group for auth Lambda
resource "aws_cloudwatch_log_group" "auth_handler" {
  name              = "/aws/lambda/${local.name_prefix}-auth-handler"
  retention_in_days = var.lambda_log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-auth-handler-logs"
    }
  )
}

# Auth Handler Lambda Function (outside VPC)
resource "aws_lambda_function" "auth_handler" {
  filename         = data.archive_file.api_handler.output_path
  function_name    = "${local.name_prefix}-auth-handler"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "functions.auth_handler.handler"
  source_code_hash = data.archive_file.api_handler.output_base64sha256
  runtime          = var.lambda_runtime
  memory_size      = 256 # Auth operations are lightweight
  timeout          = 30  # Shorter timeout for auth

  # No VPC configuration - runs outside VPC for Cognito access
  # This saves costs (no ENI charges) and improves cold start time

  # Environment variables
  environment {
    variables = {
      ENVIRONMENT             = var.environment
      COGNITO_USER_POOL_ID    = var.cognito_user_pool_id
      COGNITO_APP_CLIENT_ID   = var.cognito_client_id
      COGNITO_ADMIN_CLIENT_ID = var.cognito_admin_client_id
      COGNITO_JWK_KEYS        = var.cognito_jwks_json
      LOG_LEVEL               = "INFO"
    }
  }

  # X-Ray tracing
  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  # Ignore changes to code - managed by backend workflow
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-auth-handler"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.auth_handler,
    aws_iam_role_policy.lambda_basic_execution
  ]
}

# Lambda permission for API Gateway to invoke auth handler
resource "aws_lambda_permission" "api_gateway_auth" {
  statement_id  = "AllowAPIGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}