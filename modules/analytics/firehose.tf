# Amazon Kinesis Firehose
# Delivers streaming data from Kinesis Data Streams to S3 (Data Lake)

# IAM role for Firehose
resource "aws_iam_role" "firehose" {
  name = "${var.project_name}-${var.environment}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for Firehose to access Kinesis, S3, and CloudWatch
resource "aws_iam_role_policy" "firehose" {
  name = "${var.project_name}-${var.environment}-firehose-policy"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.telemetry.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.data_lake.arn,
          "${aws_s3_bucket.data_lake.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = "${aws_cloudwatch_log_group.firehose.arn}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${data.aws_region.current.name}.amazonaws.com"
          }
          StringLike = {
            "kms:EncryptionContext:aws:s3:arn" = "${aws_s3_bucket.data_lake.arn}/*"
          }
        }
      }
    ]
  })
}

# CloudWatch Log Group for Firehose
resource "aws_cloudwatch_log_group" "firehose" {
  name              = "/aws/kinesisfirehose/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch Log Stream for Firehose
resource "aws_cloudwatch_log_stream" "firehose_s3" {
  name           = "S3Delivery"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

resource "aws_cloudwatch_log_stream" "firehose_errors" {
  name           = "Errors"
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

# Kinesis Firehose Delivery Stream
resource "aws_kinesis_firehose_delivery_stream" "telemetry_to_s3" {
  name        = "${var.project_name}-${var.environment}-telemetry-to-s3"
  destination = "extended_s3"

  # Source: Kinesis Data Stream
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.telemetry.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  # Destination: S3 (Bronze layer - raw data)
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.data_lake.arn

    # Prefix for organizing data by date
    prefix              = "bronze/telemetry/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/telemetry/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"

    # Buffering configuration
    buffering_size     = var.firehose_buffer_size     # MB
    buffering_interval = var.firehose_buffer_interval # seconds

    # Compression
    compression_format = "GZIP"

    # Encryption
    s3_backup_mode = "Disabled" # We're already archiving raw data

    # CloudWatch Logging
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_s3.name
    }

    # Data transformation (optional)
    dynamic "processing_configuration" {
      for_each = var.enable_firehose_transformation ? [1] : []
      content {
        enabled = true

        processors {
          type = "Lambda"

          parameters {
            parameter_name  = "LambdaArn"
            parameter_value = "${aws_lambda_function.firehose_transformer[0].arn}:$LATEST"
          }

          parameters {
            parameter_name  = "BufferSizeInMBs"
            parameter_value = "3"
          }

          parameters {
            parameter_name  = "BufferIntervalInSeconds"
            parameter_value = "60"
          }
        }
      }
    }
  }

  tags = var.tags
}

# Lambda function for data transformation (optional)
resource "aws_lambda_function" "firehose_transformer" {
  count = var.enable_firehose_transformation ? 1 : 0

  filename      = "${path.module}/lambda/firehose_transformer.zip"
  function_name = "${var.project_name}-${var.environment}-firehose-transformer"
  role          = aws_iam_role.firehose_transformer[0].arn
  handler       = "firehose_transformer.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = var.tags
}

# IAM role for transformation Lambda
resource "aws_iam_role" "firehose_transformer" {
  count = var.enable_firehose_transformation ? 1 : 0

  name = "${var.project_name}-${var.environment}-firehose-transformer-role"

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

  tags = var.tags
}

# IAM policy for transformation Lambda
resource "aws_iam_role_policy" "firehose_transformer" {
  count = var.enable_firehose_transformation ? 1 : 0

  name = "${var.project_name}-${var.environment}-firehose-transformer-policy"
  role = aws_iam_role.firehose_transformer[0].id

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
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# CloudWatch Log Group for transformation Lambda
resource "aws_cloudwatch_log_group" "firehose_transformer" {
  count = var.enable_firehose_transformation ? 1 : 0

  name              = "/aws/lambda/${aws_lambda_function.firehose_transformer[0].function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch Alarms for Firehose
resource "aws_cloudwatch_metric_alarm" "firehose_delivery_to_s3_failed" {
  alarm_name          = "${var.project_name}-${var.environment}-firehose-delivery-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "DeliveryToS3.DataFreshness"
  namespace           = "AWS/Firehose"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "900" # 15 minutes
  alarm_description   = "Firehose delivery to S3 is delayed"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.telemetry_to_s3.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "firehose_incoming_records_failed" {
  alarm_name          = "${var.project_name}-${var.environment}-firehose-incoming-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "IncomingRecords"
  namespace           = "AWS/Firehose"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Firehose is not receiving records"
  treat_missing_data  = "breaching"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.telemetry_to_s3.name
  }

  tags = var.tags
}
