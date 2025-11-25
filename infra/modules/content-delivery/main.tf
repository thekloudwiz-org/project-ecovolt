# Content Delivery Module - CloudFront and S3

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Module      = "content-delivery"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# S3 Bucket for Static Assets
resource "aws_s3_bucket" "static_assets" {
  bucket = "${local.name_prefix}-static-assets"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket                  = aws_s3_bucket.static_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "main" {
  count   = var.enable_cloudfront ? 1 : 0
  comment = "OAI for ${local.name_prefix}"
}

# S3 Bucket Policy for CloudFront
resource "aws_s3_bucket_policy" "static_assets" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.static_assets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontAccess"
      Effect = "Allow"
      Principal = {
        AWS = aws_cloudfront_origin_access_identity.main[0].iam_arn
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.static_assets.arn}/*"
    }]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  count   = var.enable_cloudfront ? 1 : 0
  enabled = true
  comment = "${local.name_prefix} CDN"

  # Custom domain aliases (requires ACM certificate in us-east-1)
  aliases = var.domain_name != "" ? [var.domain_name] : []

  origin {
    domain_name = aws_s3_bucket.static_assets.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.static_assets.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main[0].cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.static_assets.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # Use default CloudFront certificate if no custom domain
    # For custom domain, you'll need to provide ACM certificate ARN
    cloudfront_default_certificate = var.domain_name == ""
    # Uncomment and set when you have ACM certificate:
    # acm_certificate_arn      = var.acm_certificate_arn
    # ssl_support_method       = "sni-only"
    # minimum_protocol_version = "TLSv1.2_2021"
  }

  price_class = var.price_class
  tags        = local.common_tags
}
