# Content Delivery Module

CloudFront CDN and S3 bucket for static asset delivery.

## Features

- S3 bucket with versioning and encryption
- CloudFront distribution with HTTPS
- Origin Access Identity for secure S3 access
- Configurable caching and TTL

## Usage

```hcl
module "content_delivery" {
  source       = "./modules/content-delivery"
  project_name = "ecovolt"
  environment  = "prod"
}
```
