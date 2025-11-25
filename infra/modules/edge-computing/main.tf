# Edge Computing Module - IoT Greengrass Configuration
# Note: Greengrass V2 requires manual device setup and certificate provisioning
# This module creates the cloud-side resources

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Module      = "edge-computing"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# IAM Role for Greengrass Core Devices
resource "aws_iam_role" "greengrass_core" {
  name = "${local.name_prefix}-greengrass-core-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "greengrass.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

# Attach Greengrass policy
resource "aws_iam_role_policy_attachment" "greengrass_core" {
  role       = aws_iam_role.greengrass_core.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGreengrassResourceAccessRolePolicy"
}

# S3 Bucket for Greengrass Components
resource "aws_s3_bucket" "greengrass_components" {
  bucket = "${local.name_prefix}-greengrass-components"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "greengrass_components" {
  bucket = aws_s3_bucket.greengrass_components.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Note: Greengrass V2 core devices and components are typically managed
# through AWS IoT Greengrass console or CLI after initial setup
# This module provides the foundational IAM and S3 resources
