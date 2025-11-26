# Admin Portal Module - S3 + CloudFront for React App

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(var.tags, {
    Module      = "admin-portal"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# S3 Bucket for Admin Portal
resource "aws_s3_bucket" "admin_portal" {
  bucket = "${local.name_prefix}-admin-portal"
  tags   = local.common_tags
}

# Enable versioning for rollback capability
resource "aws_s3_bucket_versioning" "admin_portal" {
  bucket = aws_s3_bucket.admin_portal.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "admin_portal" {
  bucket = aws_s3_bucket.admin_portal.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access (CloudFront will access via OAI)
resource "aws_s3_bucket_public_access_block" "admin_portal" {
  bucket                  = aws_s3_bucket.admin_portal.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket for backups
resource "aws_s3_bucket" "admin_portal_backups" {
  bucket = "${local.name_prefix}-admin-portal-backups"
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "admin_portal_backups" {
  bucket = aws_s3_bucket.admin_portal_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle policy for backups (keep for 30 days)
resource "aws_s3_bucket_lifecycle_configuration" "admin_portal_backups" {
  bucket = aws_s3_bucket.admin_portal_backups.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "admin_portal" {
  comment = "OAI for ${local.name_prefix} admin portal"
}

# S3 Bucket Policy for CloudFront
resource "aws_s3_bucket_policy" "admin_portal" {
  bucket = aws_s3_bucket.admin_portal.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontAccess"
      Effect = "Allow"
      Principal = {
        AWS = aws_cloudfront_origin_access_identity.admin_portal.iam_arn
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.admin_portal.arn}/*"
    }]
  })
}

# CloudFront Distribution for Admin Portal
resource "aws_cloudfront_distribution" "admin_portal" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.name_prefix} Admin Portal"
  default_root_object = "index.html"
  price_class         = var.price_class

  # Custom domain aliases (optional)
  aliases = var.domain_name != "" ? [var.domain_name] : []

  origin {
    domain_name = aws_s3_bucket.admin_portal.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.admin_portal.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.admin_portal.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = "S3-${aws_s3_bucket.admin_portal.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400    # 1 day
    max_ttl     = 31536000 # 1 year
  }

  # Custom error response for SPA routing
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == ""
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : null
  }

  tags = local.common_tags
}

# WAF Web ACL Association (optional)
resource "aws_wafv2_web_acl_association" "admin_portal" {
  count        = var.waf_web_acl_arn != "" ? 1 : 0
  resource_arn = aws_cloudfront_distribution.admin_portal.arn
  web_acl_arn  = var.waf_web_acl_arn
}


# Route53 A record for admin portal (if domain is provided)
resource "aws_route53_record" "admin_portal" {
  count = var.domain_name != "" && var.hosted_zone_id != "" ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.admin_portal.domain_name
    zone_id                = aws_cloudfront_distribution.admin_portal.hosted_zone_id
    evaluate_target_health = false
  }
}
