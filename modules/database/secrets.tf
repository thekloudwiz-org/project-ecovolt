# Database Secrets Management
# Handles automatic password generation and rotation using AWS Secrets Manager

# Generate random password for RDS
resource "random_password" "db_master_password" {
  length  = 32
  special = true
  # Exclude characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store RDS credentials in Secrets Manager
resource "random_id" "secret_suffix" {
  byte_length = 2
}

resource "aws_secretsmanager_secret" "db_master_credentials" {
  name        = "${var.project_name}-${var.environment}-rds-master-credentials-${random_id.secret_suffix.hex}"
  description = "Master credentials for RDS PostgreSQL database"

  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-rds-master-credentials"
    }
  )
}

# Store the credentials as JSON
resource "aws_secretsmanager_secret_version" "db_master_credentials" {
  secret_id = aws_secretsmanager_secret.db_master_credentials.id
  secret_string = jsonencode({
    username            = var.db_username
    password            = random_password.db_master_password.result
    engine              = "postgres"
    host                = aws_db_instance.main.address
    port                = aws_db_instance.main.port
    dbname              = var.db_name
    dbInstanceIdentifier = aws_db_instance.main.id
  })

  depends_on = [aws_db_instance.main]
}

# Enable automatic rotation for the secret
resource "aws_secretsmanager_secret_rotation" "db_master_credentials" {
  count = var.enable_secret_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.db_master_credentials.id
  rotation_lambda_arn = aws_lambda_function.rotate_secret[0].arn

  rotation_rules {
    automatically_after_days = var.secret_rotation_days
  }

  depends_on = [
    aws_secretsmanager_secret_version.db_master_credentials,
    aws_lambda_permission.allow_secret_manager_call_lambda[0]
  ]
}

# IAM Role for Secrets Manager rotation Lambda
resource "aws_iam_role" "secrets_rotation" {
  count = var.enable_secret_rotation ? 1 : 0

  name = "${var.project_name}-${var.environment}-secrets-rotation-role"

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

# IAM Policy for Secrets Manager rotation
resource "aws_iam_role_policy" "secrets_rotation" {
  count = var.enable_secret_rotation ? 1 : 0

  name = "${var.project_name}-${var.environment}-secrets-rotation-policy"
  role = aws_iam_role.secrets_rotation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.db_master_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetRandomPassword"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DetachNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-rotate-rds-secret:*"
      }
    ]
  })
}

# Lambda function for secret rotation
resource "aws_lambda_function" "rotate_secret" {
  count = var.enable_secret_rotation ? 1 : 0

  filename      = "${path.module}/lambda/rotate_secret.zip"
  function_name = "${var.project_name}-${var.environment}-rotate-rds-secret"
  role          = aws_iam_role.secrets_rotation[0].arn
  handler       = "rotate_secret.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30

  vpc_config {
    subnet_ids         = var.data_subnet_ids
    security_group_ids = [aws_security_group.rds.id]
  }

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${data.aws_region.current.name}.amazonaws.com"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-rotate-rds-secret"
    }
  )
}

# Lambda permission for Secrets Manager
resource "aws_lambda_permission" "allow_secret_manager_call_lambda" {
  count = var.enable_secret_rotation ? 1 : 0

  function_name = aws_lambda_function.rotate_secret[0].function_name
  statement_id  = "AllowExecutionFromSecretsManager"
  action        = "lambda:InvokeFunction"
  principal     = "secretsmanager.amazonaws.com"
}

# ============================================================================
# SSM Parameter Store - Non-sensitive database information
# ============================================================================

# Database endpoint
resource "aws_ssm_parameter" "db_endpoint" {
  name        = "/${var.project_name}/${var.environment}/database/endpoint"
  description = "RDS database endpoint"
  type        = "String"
  value       = aws_db_instance.main.address

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-endpoint"
    }
  )
}

# Database port
resource "aws_ssm_parameter" "db_port" {
  name        = "/${var.project_name}/${var.environment}/database/port"
  description = "RDS database port"
  type        = "String"
  value       = tostring(aws_db_instance.main.port)

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-port"
    }
  )
}

# Database name
resource "aws_ssm_parameter" "db_name" {
  name        = "/${var.project_name}/${var.environment}/database/name"
  description = "RDS database name"
  type        = "String"
  value       = var.db_name

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-name"
    }
  )
}

# Database username
resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project_name}/${var.environment}/database/username"
  description = "RDS database username"
  type        = "String"
  value       = var.db_username

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-username"
    }
  )
}

# Database connection string (without password)
resource "aws_ssm_parameter" "db_connection_string" {
  name        = "/${var.project_name}/${var.environment}/database/connection-string"
  description = "RDS database connection string template (password from Secrets Manager)"
  type        = "String"
  value       = "postgresql://${var.db_username}:PASSWORD_FROM_SECRETS_MANAGER@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.db_name}"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-connection-string"
    }
  )
}

# Secret ARN for easy reference
resource "aws_ssm_parameter" "db_secret_arn" {
  name        = "/${var.project_name}/${var.environment}/database/secret-arn"
  description = "ARN of the Secrets Manager secret containing database credentials"
  type        = "String"
  value       = aws_secretsmanager_secret.db_master_credentials.arn

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-db-secret-arn"
    }
  )
}
