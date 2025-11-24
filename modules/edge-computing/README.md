# Edge Computing Module

Provides foundational resources for AWS IoT Greengrass edge computing.

## Note

Greengrass V2 requires manual device provisioning and component deployment through the AWS console or CLI. This module creates the cloud-side IAM roles and S3 storage needed for Greengrass operations.

## Usage

```hcl
module "edge_computing" {
  source       = "./modules/edge-computing"
  project_name = "ecovolt"
  environment  = "prod"
}
```

## Manual Steps Required

1. Install Greengrass Core software on edge devices
2. Provision device certificates
3. Deploy components for edge processing
4. Configure local logging and monitoring
