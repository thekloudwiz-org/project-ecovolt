# Data Sources for Dynamic Resource Discovery

# Get available availability zones in the primary region
data "aws_availability_zones" "available" {
  state = "available"

  # Exclude local zones and wavelength zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Get available availability zones in the DR region
data "aws_availability_zones" "dr_available" {
  provider = aws.dr
  state    = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get DR region details
data "aws_region" "dr" {
  provider = aws.dr
}
