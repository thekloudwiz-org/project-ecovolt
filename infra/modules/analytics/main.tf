# Analytics Module - Main Configuration
# Creates analytics pipeline for telemetry data processing

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Kinesis Data Stream for telemetry ingestion
resource "aws_kinesis_stream" "telemetry" {
  name             = local.kinesis_stream_name
  shard_count      = var.kinesis_shard_count
  retention_period = var.kinesis_retention_hours

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
    "WriteProvisionedThroughputExceeded",
    "ReadProvisionedThroughputExceeded",
    "IteratorAgeMilliseconds"
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  encryption_type = var.kms_key_arn != "" ? "KMS" : "NONE"
  kms_key_id      = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = merge(
    local.common_tags,
    {
      Name = local.kinesis_stream_name
    }
  )
}

# ============================================================================
# DEPRECATION NOTICE: Amazon Timestream for LiveAnalytics
# ============================================================================
# Amazon Timestream for LiveAnalytics is deprecated as of June 20, 2025.
# AWS recommends using Amazon Timestream for InfluxDB or alternative solutions.
# 
# For this IoT telemetry use case, we're using DynamoDB with TTL instead:
# - More cost-effective for IoT workloads
# - Better integration with existing DynamoDB tables in the dynamodb module
# - Simpler operational model
# - Native support for time-series data with TTL
#
# The telemetry data is now stored in DynamoDB tables created in the 
# dynamodb module (bike_telemetry, station_telemetry, swap_events)
# ============================================================================

# NOTE: Timestream resources have been removed due to deprecation
# If you need advanced time-series analytics, consider:
# 1. Amazon Timestream for InfluxDB (AWS recommended)
# 2. Amazon OpenSearch Service (for complex analytics)
# 3. Amazon Athena + S3 (for historical analysis)
#
# Current implementation uses DynamoDB tables with TTL for telemetry storage

# S3 Bucket for Data Lake
resource "aws_s3_bucket" "data_lake" {
  bucket = local.s3_bucket_name

  tags = merge(
    local.common_tags,
    {
      Name    = local.s3_bucket_name
      Purpose = "DataLake"
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "archive-old-data"
    status = "Enabled"

    filter {}

    transition {
      days          = var.s3_lifecycle_glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.s3_lifecycle_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555 # ~7 years
    }
  }

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Glue Database for Data Catalog
resource "aws_glue_catalog_database" "data_lake" {
  name        = local.glue_database_name
  description = "Data catalog for EcoVolt telemetry data lake"

  tags = merge(
    local.common_tags,
    {
      Name = local.glue_database_name
    }
  )
}

# IAM Role for Lambda Stream Processor
resource "aws_iam_role" "lambda_processor" {
  name = local.lambda_processor_role_name

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

# IAM Policy for Lambda Stream Processor
resource "aws_iam_role_policy" "lambda_processor" {
  name = "${local.name_prefix}-lambda-processor-policy"
  role = aws_iam_role.lambda_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:GetRecords",
          "kinesis:GetShardIterator",
          "kinesis:DescribeStream",
          "kinesis:ListShards",
          "kinesis:ListStreams"
        ]
        Resource = aws_kinesis_stream.telemetry.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.data_lake.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_stream_processor_name}:*"
      }
    ]
  })
}

# Lambda Function for Kinesis Stream Processing
resource "aws_lambda_function" "stream_processor" {
  filename      = "${path.module}/lambda/stream_processor.zip"
  function_name = local.lambda_stream_processor_name
  role          = aws_iam_role.lambda_processor.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 256

  environment {
    variables = {
      # Telemetry data is now stored in DynamoDB tables (see dynamodb module)
      # Tables: bike_telemetry, station_telemetry, swap_events
      DATA_LAKE_BUCKET = aws_s3_bucket.data_lake.id
      KINESIS_STREAM   = aws_kinesis_stream.telemetry.name
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.lambda_stream_processor_name
    }
  )
}

# Lambda Event Source Mapping for Kinesis
resource "aws_lambda_event_source_mapping" "kinesis_processor" {
  event_source_arn                   = aws_kinesis_stream.telemetry.arn
  function_name                      = aws_lambda_function.stream_processor.arn
  starting_position                  = "LATEST"
  batch_size                         = 100
  maximum_batching_window_in_seconds = 5

  depends_on = [aws_iam_role_policy.lambda_processor]
}

# IAM Role for Lambda Data Transformer
resource "aws_iam_role" "lambda_transformer" {
  name = local.lambda_transformer_role_name

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

# IAM Policy for Lambda Data Transformer
resource "aws_iam_role_policy" "lambda_transformer" {
  name = "${local.name_prefix}-lambda-transformer-policy"
  role = aws_iam_role.lambda_transformer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.data_lake.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.lambda_transformer_name}:*"
      }
    ]
  })
}

# Lambda Function for Data Transformation
resource "aws_lambda_function" "data_transformer" {
  filename      = "${path.module}/lambda/data_transformer.zip"
  function_name = local.lambda_transformer_name
  role          = aws_iam_role.lambda_transformer.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 512

  environment {
    variables = {
      DATA_LAKE_BUCKET = aws_s3_bucket.data_lake.id
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.lambda_transformer_name
    }
  )
}

# IAM Role for Glue Crawler
resource "aws_iam_role" "glue_crawler" {
  count = var.enable_glue_crawler ? 1 : 0
  name  = local.glue_crawler_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for Glue Crawler
resource "aws_iam_role_policy" "glue_crawler" {
  count = var.enable_glue_crawler ? 1 : 0
  name  = "${local.name_prefix}-glue-crawler-policy"
  role  = aws_iam_role.glue_crawler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:*",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Glue Crawler for Data Lake
resource "aws_glue_crawler" "data_lake" {
  count         = var.enable_glue_crawler ? 1 : 0
  name          = local.glue_crawler_name
  role          = aws_iam_role.glue_crawler[0].arn
  database_name = aws_glue_catalog_database.data_lake.name

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.id}/raw/"
  }

  schedule = "cron(0 2 * * ? *)" # Run daily at 2 AM UTC

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.glue_crawler_name
    }
  )

  depends_on = [aws_iam_role_policy.glue_crawler]
}

# S3 Bucket for Athena Query Results
resource "aws_s3_bucket" "athena_results" {
  count  = var.enable_athena ? 1 : 0
  bucket = local.athena_output_bucket

  tags = merge(
    local.common_tags,
    {
      Name    = local.athena_output_bucket
      Purpose = "AthenaResults"
    }
  )
}

# S3 Bucket Encryption for Athena Results
resource "aws_s3_bucket_server_side_encryption_configuration" "athena_results" {
  count  = var.enable_athena ? 1 : 0
  bucket = aws_s3_bucket.athena_results[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block for Athena Results
resource "aws_s3_bucket_public_access_block" "athena_results" {
  count  = var.enable_athena ? 1 : 0
  bucket = aws_s3_bucket.athena_results[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle for Athena Results
resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  count  = var.enable_athena ? 1 : 0
  bucket = aws_s3_bucket.athena_results[0].id

  rule {
    id     = "delete-old-results"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# Athena Workgroup
resource "aws_athena_workgroup" "analytics" {
  count = var.enable_athena ? 1 : 0
  name  = local.athena_workgroup_name

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results[0].id}/results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.athena_workgroup_name
    }
  )
}
