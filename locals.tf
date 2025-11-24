# Root Local Values

locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "TheKloudWiz"
      Repository  = "project-ecovolt"
    },
    var.additional_tags
  )
}
