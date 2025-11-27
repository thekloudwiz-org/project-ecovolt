# Database Migration Lambda Function
# Runs SQL migrations from within VPC with access to RDS

# CloudWatch Log Group for migration Lambda
resource "aws_cloudwatch_log_group" "db_migrator" {
  name              = "/aws/lambda/${local.name_prefix}-db-migrator"
  retention_in_days = var.lambda_log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db-migrator-logs"
    }
  )
}

# Lambda function for database migrations
resource "aws_lambda_function" "db_migrator" {
  filename         = data.archive_file.api_handler.output_path
  function_name    = "${local.name_prefix}-db-migrator"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "functions.db_migrator.handler"
  source_code_hash = data.archive_file.api_handler.output_base64sha256
  runtime          = var.lambda_runtime
  memory_size      = 1024 # More memory for pip install and database operations
  timeout          = 600  # 10 minutes for pip install + migrations

  # Ephemeral storage for pip install
  ephemeral_storage {
    size = 1024 # 1 GB for pip packages
  }

  # VPC configuration - needs access to RDS
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Environment variables
  environment {
    variables = {
      ENVIRONMENT      = var.environment
      DB_HOST          = var.db_endpoint
      DB_NAME          = var.db_name
      DB_USER          = local.db_creds["username"]
      DB_PASS          = local.db_creds["password"]
      MIGRATION_BUCKET = "" # Will be set via workflow
      MIGRATION_PREFIX = "migrations/${var.environment}/"
      LOG_LEVEL        = "INFO"
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
      Name = "${local.name_prefix}-db-migrator"
    }
  )

  depends_on = [
    aws_cloudwatch_log_group.db_migrator,
    aws_iam_role_policy.lambda_basic_execution,
    aws_iam_role_policy.lambda_vpc_execution
  ]
}

# IAM policy for S3 access (to read migration files)
resource "aws_iam_role_policy" "lambda_s3_migrations" {
  name = "${local.name_prefix}-lambda-s3-migrations"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::*-deployment-bucket/migrations/*",
          "arn:aws:s3:::*-deployment-bucket"
        ]
      }
    ]
  })
}
