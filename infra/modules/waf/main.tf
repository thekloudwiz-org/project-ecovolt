# AWS WAF Module
# Provides web application firewall protection for CloudFront and API Gateway

# ============================================================================
# CloudFront Web ACL
# ============================================================================

resource "aws_wafv2_web_acl" "cloudfront" {
  count = var.enable_cloudfront_waf ? 1 : 0

  name  = "${var.project_name}-${var.environment}-cloudfront-waf"
  scope = "CLOUDFRONT"

  # Must be created in us-east-1 for CloudFront
  provider = aws.us-east-1

  default_action {
    allow {}
  }

  # AWS Managed Rules - Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"

        # Exclude specific rules if needed
        dynamic "rule_action_override" {
          for_each = var.cloudfront_rule_exclusions
          content {
            name = rule_action_override.value
            action_to_use {
              count {}
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - SQL Injection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-sqli"
      sampled_requests_enabled   = true
    }
  }

  # Rate-based rule to prevent DDoS
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.cloudfront_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # Geographic blocking (optional)
  dynamic "rule" {
    for_each = length(var.blocked_countries) > 0 ? [1] : []
    content {
      name     = "GeoBlockingRule"
      priority = 5

      action {
        block {}
      }

      statement {
        geo_match_statement {
          country_codes = var.blocked_countries
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.project_name}-${var.environment}-geo-block"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-cloudfront-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-cloudfront-waf"
    }
  )
}

# ============================================================================
# API Gateway Web ACL
# ============================================================================

resource "aws_wafv2_web_acl" "api_gateway" {
  count = var.enable_api_gateway_waf ? 1 : 0

  name  = "${var.project_name}-${var.environment}-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rules - Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"

        dynamic "rule_action_override" {
          for_each = var.api_gateway_rule_exclusions
          content {
            name = rule_action_override.value
            action_to_use {
              count {}
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-api-common-rules"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-api-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - SQL Injection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-api-sqli"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Linux Operating System
  rule {
    name     = "AWSManagedRulesLinuxRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesLinuxRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-api-linux"
      sampled_requests_enabled   = true
    }
  }

  # Rate-based rule for API protection
  rule {
    name     = "APIRateLimitRule"
    priority = 5

    action {
      block {
        custom_response {
          response_code            = 429
          custom_response_body_key = "rate_limit_response"
        }
      }
    }

    statement {
      rate_based_statement {
        limit              = var.api_gateway_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-api-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  # IP reputation list (AWS managed)
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}-${var.environment}-api-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  # Custom response body for rate limiting
  custom_response_body {
    key = "rate_limit_response"
    content = jsonencode({
      error   = "Too Many Requests"
      message = "You have exceeded the rate limit. Please try again later."
    })
    content_type = "APPLICATION_JSON"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-api-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-api-waf"
    }
  )
}

# ============================================================================
# WAF Logging Configuration
# ============================================================================

# CloudWatch Log Group for CloudFront WAF
resource "aws_cloudwatch_log_group" "cloudfront_waf" {
  count = var.enable_cloudfront_waf && var.enable_waf_logging ? 1 : 0

  name              = "/aws/wafv2/cloudfront/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch Log Group for API Gateway WAF
resource "aws_cloudwatch_log_group" "api_gateway_waf" {
  count = var.enable_api_gateway_waf && var.enable_waf_logging ? 1 : 0

  name              = "/aws/wafv2/regional/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Logging configuration for CloudFront WAF
resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  count = var.enable_cloudfront_waf && var.enable_waf_logging ? 1 : 0

  resource_arn = aws_wafv2_web_acl.cloudfront[0].arn

  log_destination_configs = [
    aws_cloudwatch_log_group.cloudfront_waf[0].arn
  ]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

# Logging configuration for API Gateway WAF
resource "aws_wafv2_web_acl_logging_configuration" "api_gateway" {
  count = var.enable_api_gateway_waf && var.enable_waf_logging ? 1 : 0

  resource_arn = aws_wafv2_web_acl.api_gateway[0].arn

  log_destination_configs = [
    aws_cloudwatch_log_group.api_gateway_waf[0].arn
  ]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

# ============================================================================
# CloudWatch Alarms
# ============================================================================

# Alarm for blocked requests (CloudFront)
resource "aws_cloudwatch_metric_alarm" "cloudfront_blocked_requests" {
  count = var.enable_cloudfront_waf && length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-waf-blocked"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.blocked_requests_threshold
  alarm_description   = "CloudFront WAF blocked requests exceeded threshold"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    WebACL = aws_wafv2_web_acl.cloudfront[0].name
    Region = "us-east-1"
    Rule   = "ALL"
  }

  tags = var.tags
}

# Alarm for blocked requests (API Gateway)
resource "aws_cloudwatch_metric_alarm" "api_gateway_blocked_requests" {
  count = var.enable_api_gateway_waf && length(var.alarm_sns_topic_arns) > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-api-waf-blocked"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.blocked_requests_threshold
  alarm_description   = "API Gateway WAF blocked requests exceeded threshold"
  alarm_actions       = var.alarm_sns_topic_arns

  dimensions = {
    WebACL = aws_wafv2_web_acl.api_gateway[0].name
    Region = data.aws_region.current.name
    Rule   = "ALL"
  }

  tags = var.tags
}

# Data source for current region
data "aws_region" "current" {}
