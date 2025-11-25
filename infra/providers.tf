# Terraform and Provider Configuration

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Primary AWS Provider (eu-central-1 - Frankfurt)
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "EcoVolt"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

# Secondary AWS Provider for Disaster Recovery (eu-west-1 - Ireland)
provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Project     = "EcoVolt"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Region      = "DR"
    }
  }
}

# Provider for us-east-1 (required for CloudFront WAF)
provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "EcoVolt"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Region      = "us-east-1"
    }
  }
}

provider "random" {}

provider "null" {}
