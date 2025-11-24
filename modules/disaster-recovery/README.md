# Disaster Recovery Module

Provides foundational resources for disaster recovery including S3 replication roles.

## Features

- IAM roles for S3 cross-region replication
- Support for RDS read replicas (configured in database module)
- Route 53 health checks and failover (configured separately)

## Usage

```hcl
module "disaster_recovery" {
  source         = "./modules/disaster-recovery"
  project_name   = "ecovolt"
  environment    = "prod"
  primary_region = "us-east-1"
  dr_region      = "us-west-2"
}
```

## Note

Full DR implementation requires:
1. RDS read replicas in DR region
2. S3 replication rules on critical buckets
3. Route 53 health checks and failover routing
4. Regular DR testing procedures
