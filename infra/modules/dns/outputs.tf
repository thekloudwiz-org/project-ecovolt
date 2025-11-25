# DNS Module Outputs

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = local.hosted_zone_id
}

output "hosted_zone_name_servers" {
  description = "Name servers for the hosted zone"
  value       = data.aws_route53_zone.main.name_servers
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.main.arn
}

output "certificate_domain" {
  description = "Certificate domain name"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Certificate validation status"
  value       = aws_acm_certificate.main.status
}

output "base_domain" {
  description = "Base domain for this environment"
  value       = local.base_domain
}

output "api_domain" {
  description = "API domain name"
  value       = local.api_domain
}

output "admin_domain" {
  description = "Admin portal domain name"
  value       = local.admin_domain
}

output "ssm_certificate_arn_parameter" {
  description = "SSM parameter name for certificate ARN"
  value       = aws_ssm_parameter.certificate_arn.name
}

output "ssm_api_domain_parameter" {
  description = "SSM parameter name for API domain"
  value       = aws_ssm_parameter.api_domain.name
}

output "ssm_admin_domain_parameter" {
  description = "SSM parameter name for admin domain"
  value       = aws_ssm_parameter.admin_domain.name
}
