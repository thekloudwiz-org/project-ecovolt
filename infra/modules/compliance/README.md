# Compliance Module

AWS Config for compliance monitoring and data lifecycle management.

## Features

- AWS Config recorder and delivery channel
- Config rules for encryption validation
- S3 bucket for configuration snapshots
- Automated compliance reporting

## Usage

```hcl
module "compliance" {
  source       = "./modules/compliance"
  project_name = "ecovolt"
  environment  = "prod"
}
```
