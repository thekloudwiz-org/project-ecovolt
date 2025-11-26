# DNS Module - Route53 and ACM Certificates

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Domain names based on environment
  base_domain = var.environment == "prod" ? "${var.subdomain_prefix}.${var.root_domain}" : "${var.environment}-${var.subdomain_prefix}.${var.root_domain}"

  # Service domains
  api_domain = var.environment == "prod" ? "api.${var.subdomain_prefix}.${var.root_domain}" : "${var.environment}-api.${var.subdomain_prefix}.${var.root_domain}"

  admin_domain = var.environment == "prod" ? "admin.${var.subdomain_prefix}.${var.root_domain}" : "${var.environment}-admin.${var.subdomain_prefix}.${var.root_domain}"

  # Certificate domains - specific certificates for better security
  cert_domains = var.use_wildcard_certificate ? ["*.${local.base_domain}"] : [local.api_domain, local.admin_domain]

  common_tags = merge(var.tags, {
    Module      = "dns"
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Data source to automatically look up hosted zone by domain name
data "aws_route53_zone" "main" {
  name         = var.root_domain
  private_zone = false
}

# Local for hosted zone ID
locals {
  hosted_zone_id = data.aws_route53_zone.main.zone_id
}

# ACM Certificate (must be in us-east-1 for CloudFront)
# Using specific domains for better security
resource "aws_acm_certificate" "main" {
  provider = aws.us-east-1

  domain_name               = local.cert_domains[0]
  subject_alternative_names = length(local.cert_domains) > 1 ? slice(local.cert_domains, 1, length(local.cert_domains)) : []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-certificate"
    Type = var.use_wildcard_certificate ? "wildcard" : "specific"
  })
}

# Route53 records for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.hosted_zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "main" {
  provider = aws.us-east-1

  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  timeouts {
    create = "10m"
  }
}

# Store certificate ARN in SSM Parameter Store
resource "aws_ssm_parameter" "certificate_arn" {
  name        = "/${var.project_name}/${var.environment}/acm/certificate-arn"
  description = "ACM certificate ARN for ${var.environment} environment"
  type        = "String"
  value       = aws_acm_certificate.main.arn

  tags = local.common_tags
}

# Store domain names in SSM for reference
resource "aws_ssm_parameter" "api_domain" {
  name        = "/${var.project_name}/${var.environment}/dns/api-domain"
  description = "API domain name for ${var.environment} environment"
  type        = "String"
  value       = local.api_domain

  tags = local.common_tags
}

resource "aws_ssm_parameter" "admin_domain" {
  name        = "/${var.project_name}/${var.environment}/dns/admin-domain"
  description = "Admin portal domain name for ${var.environment} environment"
  type        = "String"
  value       = local.admin_domain

  tags = local.common_tags
}


terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.us-east-1]
    }
  }
}
