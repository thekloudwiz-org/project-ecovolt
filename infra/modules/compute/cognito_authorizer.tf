# Cognito Authorizer for API Gateway
# Secures API endpoints with JWT token validation

resource "aws_api_gateway_authorizer" "cognito" {
  count = var.enable_cognito_authorizer ? 1 : 0

  name          = "${var.project_name}-${var.environment}-cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]

  # Identity source (where to find the token)
  identity_source = "method.request.header.Authorization"

  # Cache settings
  authorizer_result_ttl_in_seconds = 300 # 5 minutes
}

# Example: Protected API resource (stations)
resource "aws_api_gateway_resource" "stations" {
  count = var.enable_cognito_authorizer ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "stations"
}

# GET /stations (requires authentication)
resource "aws_api_gateway_method" "stations_get" {
  count = var.enable_cognito_authorizer ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.stations[0].id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito[0].id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

# Integration with Lambda
resource "aws_api_gateway_integration" "stations_get" {
  count = var.enable_cognito_authorizer ? 1 : 0

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.stations[0].id
  http_method             = aws_api_gateway_method.stations_get[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# Lambda permission for stations endpoint
resource "aws_lambda_permission" "api_gateway_stations" {
  count = var.enable_cognito_authorizer ? 1 : 0

  statement_id  = "AllowAPIGatewayInvokeStations"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# Example: User profile resource
resource "aws_api_gateway_resource" "profile" {
  count = var.enable_cognito_authorizer ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "profile"
}

# GET /profile (requires authentication)
resource "aws_api_gateway_method" "profile_get" {
  count = var.enable_cognito_authorizer ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.profile[0].id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito[0].id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

# Integration with Lambda
resource "aws_api_gateway_integration" "profile_get" {
  count = var.enable_cognito_authorizer ? 1 : 0

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.profile[0].id
  http_method             = aws_api_gateway_method.profile_get[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}
