# Compute Module - Main Configuration
# Creates Lambda functions and API Gateway for backend services

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ============================================================================
# Security Group for Lambda Functions
# ============================================================================

resource "aws_security_group" "lambda" {
  name        = local.lambda_sg_name
  description = "Security group for Lambda functions with VPC access"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = local.lambda_sg_name
    }
  )
}

# Egress rule - allow all outbound traffic
resource "aws_security_group_rule" "lambda_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda.id
  description       = "Allow all outbound traffic"
}

# Allow Lambda to access RDS if database is configured
resource "aws_security_group_rule" "lambda_to_rds" {

  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = var.db_security_group_id
  description              = "Allow Lambda functions to access RDS"

  depends_on = [aws_security_group.lambda]
}

# ============================================================================
# IAM Role for Lambda Execution
# ============================================================================

resource "aws_iam_role" "lambda_execution" {
  name = local.lambda_execution_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Basic Lambda execution policy (CloudWatch Logs)
resource "aws_iam_role_policy" "lambda_basic_execution" {
  name = "${local.name_prefix}-lambda-basic-execution"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
      }
    ]
  })
}

# VPC access policy for Lambda
resource "aws_iam_role_policy" "lambda_vpc_execution" {
  name = "${local.name_prefix}-lambda-vpc-execution"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Resource = "*"
      }
    ]
  })
}

# X-Ray tracing policy
resource "aws_iam_role_policy" "lambda_xray" {
  count = var.enable_xray_tracing ? 1 : 0

  name = "${local.name_prefix}-lambda-xray"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# DynamoDB access policy
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${local.name_prefix}-lambda-dynamodb"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.environment}-*"
        ]
      }
    ]
  })
}

# SNS publish policy for notifications
resource "aws_iam_role_policy" "lambda_sns" {
  name = "${local.name_prefix}-lambda-sns"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:CreateTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes"
        ]
        Resource = [
          "arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.environment}-*"
        ]
      }
    ]
  })
}

# Secrets Manager access policy
resource "aws_iam_role_policy" "lambda_secrets" {
  name = "${local.name_prefix}-lambda-secrets"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.environment}/*",
          "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${local.name_prefix}-*"
        ]
      }
    ]
  })
}

# SSM Parameter Store access policy
resource "aws_iam_role_policy" "lambda_ssm" {
  name = "${local.name_prefix}-lambda-ssm"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.environment}/*"
        ]
      }
    ]
  })
}

# IoT Core access policy
resource "aws_iam_role_policy" "lambda_iot" {
  name = "${local.name_prefix}-lambda-iot"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Publish",
          "iot:Subscribe",
          "iot:Connect",
          "iot:Receive"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/${var.environment}/*",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:client/${var.environment}-*"
        ]
      }
    ]
  })
}

# Kinesis stream processing policy

# ============================================================================
# SNS Topic for Application Notifications
# ============================================================================

resource "aws_sns_topic" "notifications" {
  name = "${local.name_prefix}-notifications"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-notifications"
    }
  )
}

# ============================================================================
# Lambda Functions
# ============================================================================

# CloudWatch Log Groups (created before Lambda functions)
resource "aws_cloudwatch_log_group" "api_handler" {
  name              = local.api_handler_log_group
  retention_in_days = var.lambda_log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-api-handler-logs"
    }
  )
}

# Create ZIP archives for Lambda functions
# Package the entire backend application
data "archive_file" "api_handler" {
  type        = "zip"
  source_dir  = "${path.root}/application/backend"
  output_path = "${path.module}/lambda/api_handler.zip"

  excludes = [
    "tests",
    "venv",
    "__pycache__",
    "*.pyc",
    "*.pyo",
    "*.md",
    ".git",
    ".gitignore",
    "*.sh"
  ]
}


# API Handler Lambda Function
resource "aws_lambda_function" "api_handler" {
  filename         = data.archive_file.api_handler.output_path
  function_name    = local.api_handler_function_name
  role             = aws_iam_role.lambda_execution.arn
  handler          = "functions.api_handler.handler"
  source_code_hash = data.archive_file.api_handler.output_base64sha256
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  # VPC configuration
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Environment variables
  environment {
    variables = {
      ENVIRONMENT                  = var.environment
      DB_ENDPOINT                  = var.db_endpoint
      DB_NAME                      = var.db_name
      DB_SECRET_ARN                = var.db_secret_arn
      COGNITO_USER_POOL_ID         = var.cognito_user_pool_id
      COGNITO_CLIENT_ID            = var.cognito_client_id
      DYNAMODB_BATTERIES_TABLE     = "${var.environment}-batteries"
      DYNAMODB_TELEMETRY_TABLE     = "${var.environment}-vehicle-telemetry"
      DYNAMODB_NOTIFICATIONS_TABLE = "${var.environment}-notifications"
      SNS_TOPIC_ARN                = aws_sns_topic.notifications.arn
      IOT_ENDPOINT                 = var.iot_endpoint
      LOG_LEVEL                    = "INFO"
    }
  }

  # X-Ray tracing
  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  # Reserved concurrent executions
  reserved_concurrent_executions = var.lambda_reserved_concurrent_executions > 0 ? var.lambda_reserved_concurrent_executions : null

  # Ignore changes to code - managed by backend workflow
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.api_handler_function_name
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.api_handler,
    aws_iam_role_policy.lambda_basic_execution,
    aws_iam_role_policy.lambda_vpc_execution
  ]
}

# IoT Processor Lambda Function
resource "aws_cloudwatch_log_group" "iot_processor" {
  name              = "/aws/lambda/${local.name_prefix}-iot-processor"
  retention_in_days = var.lambda_log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-iot-processor-logs"
    }
  )
}

resource "aws_lambda_function" "iot_processor" {
  filename         = data.archive_file.api_handler.output_path
  function_name    = "${local.name_prefix}-iot-processor"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "functions.iot_processor.handler"
  source_code_hash = data.archive_file.api_handler.output_base64sha256
  runtime          = var.lambda_runtime
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout

  # VPC configuration
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Environment variables
  environment {
    variables = {
      ENVIRONMENT                  = var.environment
      DB_ENDPOINT                  = var.db_endpoint
      DB_NAME                      = var.db_name
      DB_SECRET_ARN                = var.db_secret_arn
      DYNAMODB_BATTERIES_TABLE     = "${var.environment}-batteries"
      DYNAMODB_TELEMETRY_TABLE     = "${var.environment}-vehicle-telemetry"
      DYNAMODB_NOTIFICATIONS_TABLE = "${var.environment}-notifications"
      SNS_TOPIC_ARN                = aws_sns_topic.notifications.arn
      IOT_ENDPOINT                 = var.iot_endpoint
      LOG_LEVEL                    = "INFO"
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
      source_code_hash,
      last_modified
    ]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-iot-processor"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.iot_processor,
    aws_iam_role_policy.lambda_basic_execution,
    aws_iam_role_policy.lambda_vpc_execution
  ]
}

# IoT Rule to trigger Lambda
resource "aws_iot_topic_rule" "telemetry" {
  name        = "${replace(var.environment, "-", "_")}_telemetry_processor"
  description = "Process IoT telemetry data from bikes and stations"
  enabled     = true
  sql         = "SELECT * FROM '${var.environment}/telemetry/#'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.iot_processor.arn
  }

  tags = local.common_tags
}

# Lambda permission for IoT Rule
resource "aws_lambda_permission" "iot_rule" {
  statement_id  = "AllowIoTRuleInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.iot_processor.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.telemetry.arn
}

# ============================================================================
# API Gateway
# ============================================================================

# REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = local.api_gateway_name
  description = "EcoVolt Backend API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.api_gateway_name
    }
  )
}

# API Gateway CloudWatch Log Group
resource "aws_cloudwatch_log_group" "api_gateway" {
  count = var.enable_api_gateway_access_logs ? 1 : 0

  name              = local.api_gateway_log_group_name
  retention_in_days = var.lambda_log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-api-gateway-logs"
    }
  )
}

# IAM Role for API Gateway CloudWatch Logs
resource "aws_iam_role" "api_gateway_cloudwatch" {
  count = var.enable_api_gateway_access_logs ? 1 : 0

  name = local.api_gateway_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach managed policy for API Gateway CloudWatch Logs
resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  count = var.enable_api_gateway_access_logs ? 1 : 0

  role       = aws_iam_role.api_gateway_cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

# API Gateway Account (for CloudWatch Logs)
resource "aws_api_gateway_account" "main" {
  count = var.enable_api_gateway_access_logs ? 1 : 0

  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch[0].arn

  depends_on = [aws_iam_role_policy_attachment.api_gateway_cloudwatch]
}

# Root resource (/)
# API Gateway automatically creates this, so we use data source
data "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  path        = "/"
}

# Proxy resource to catch all paths
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# GET method on proxy resource
resource "aws_api_gateway_method" "proxy_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "proxy_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# POST method on proxy resource
resource "aws_api_gateway_method" "proxy_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "POST"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "proxy_post" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# PUT method on proxy resource
resource "aws_api_gateway_method" "proxy_put" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "PUT"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "proxy_put" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# DELETE method on proxy resource
resource "aws_api_gateway_method" "proxy_delete" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "DELETE"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "proxy_delete" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# GET method on root resource
resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_rest_api.main.root_resource_id
  http_method             = aws_api_gateway_method.root_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# CORS configuration for proxy resource
resource "aws_api_gateway_method" "proxy_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "proxy_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "proxy_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.proxy.id
  http_method = aws_api_gateway_method.proxy_options.http_method
  status_code = aws_api_gateway_method_response.proxy_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Correlation-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.proxy_options]
}

# CORS configuration for root resource
resource "aws_api_gateway_method" "root_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "root_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "root_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  status_code = aws_api_gateway_method_response.root_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Correlation-ID'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.root_options]
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy_get.id,
      aws_api_gateway_method.proxy_post.id,
      aws_api_gateway_method.proxy_put.id,
      aws_api_gateway_method.proxy_delete.id,
      aws_api_gateway_integration.proxy_get.id,
      aws_api_gateway_integration.proxy_post.id,
      aws_api_gateway_integration.proxy_put.id,
      aws_api_gateway_integration.proxy_delete.id,
      aws_api_gateway_method.root_get.id,
      aws_api_gateway_integration.root_get.id,
      aws_api_gateway_method.proxy_options.id,
      aws_api_gateway_integration.proxy_options.id,
      aws_api_gateway_method.root_options.id,
      aws_api_gateway_integration.root_options.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.proxy_get,
    aws_api_gateway_integration.proxy_post,
    aws_api_gateway_integration.proxy_put,
    aws_api_gateway_integration.proxy_delete,
    aws_api_gateway_integration.root_get,
    aws_api_gateway_integration_response.proxy_options,
    aws_api_gateway_integration_response.root_options
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.api_gateway_stage_name

  # Access logs
  dynamic "access_log_settings" {
    for_each = var.enable_api_gateway_access_logs ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        caller         = "$context.identity.caller"
        user           = "$context.identity.user"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
      })
    }
  }

  # X-Ray tracing
  xray_tracing_enabled = var.enable_xray_tracing

  tags = merge(
    local.common_tags,
    {
      Name = "${local.api_gateway_name}-${var.api_gateway_stage_name}"
    }
  )
}

# API Gateway Method Settings (throttling, logging)
resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    # Throttling
    throttling_burst_limit = var.api_gateway_throttle_burst_limit
    throttling_rate_limit  = var.api_gateway_throttle_rate_limit

    # Logging
    logging_level      = var.enable_api_gateway_execution_logs ? "INFO" : "OFF"
    data_trace_enabled = var.enable_api_gateway_execution_logs
    metrics_enabled    = true
  }
}
