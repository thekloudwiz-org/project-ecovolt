# Database Module

This module creates and manages database resources for the EcoVolt AWS Infrastructure, including:
- Amazon RDS PostgreSQL instance with Multi-AZ deployment
- Amazon ElastiCache Redis cluster for caching
- Security groups for database access control
- Automated backups and point-in-time recovery
- Storage auto-scaling
- Encryption at rest and in transit

## Features

### RDS PostgreSQL
- **Multi-AZ Deployment**: High availability with automatic failover
- **Automated Backups**: Point-in-time recovery with configurable retention
- **Storage Auto-Scaling**: Automatically increases storage when utilization exceeds 80%
- **Encryption**: Data encrypted at rest using KMS and in transit using TLS
- **Enhanced Monitoring**: 60-second granularity monitoring via CloudWatch
- **Performance Insights**: Query performance analysis and tuning
- **Optimized Parameters**: Pre-configured parameter group for production workloads

### ElastiCache Redis
- **Caching Layer**: High-performance in-memory caching
- **Automated Snapshots**: Daily backups with configurable retention
- **Multi-Node Support**: Configurable number of cache nodes
- **Optimized Parameters**: LRU eviction policy and connection timeout settings
- **Note**: For enhanced encryption (at-rest and in-transit), consider using ElastiCache Replication Group instead of Cluster

### Security
- **Network Isolation**: Deployed in data subnets with no internet access
- **Security Groups**: Least-privilege access from private subnets only
- **Encryption**: KMS encryption for data at rest, TLS for data in transit
- **Deletion Protection**: Prevents accidental database deletion in production

## Usage

```hcl
module "database" {
  source = "./modules/database"

  project_name = "ecovolt"
  environment  = "prod"

  # Network configuration
  vpc_id                = module.networking.vpc_id
  data_subnet_ids       = module.networking.data_subnet_ids
  private_subnet_cidrs  = module.networking.private_subnet_cidrs

  # Encryption
  kms_key_arn = module.security.kms_key_arn

  # RDS configuration
  db_name                  = "ecovolt"
  db_username              = "ecovolt_admin"
  db_password              = var.db_password # From Secrets Manager or secure source
  db_instance_class        = "db.r5.large"
  db_allocated_storage     = 100
  db_max_allocated_storage = 500
  db_multi_az              = true
  db_backup_retention_period = 7

  # ElastiCache configuration
  elasticache_node_type        = "cache.r5.large"
  elasticache_num_cache_nodes  = 2

  tags = {
    Terraform   = "true"
    Environment = "prod"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Project name used in resource naming | `string` | `"ecovolt"` | no |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_id | VPC ID for security group | `string` | n/a | yes |
| data_subnet_ids | List of data subnet IDs | `list(string)` | n/a | yes |
| private_subnet_cidrs | CIDR blocks of private subnets | `list(string)` | n/a | yes |
| kms_key_arn | KMS key ARN for encryption | `string` | n/a | yes |
| db_name | Database name | `string` | `"ecovolt"` | no |
| db_username | Master username | `string` | `"ecovolt_admin"` | no |
| db_password | Master password | `string` | n/a | yes |
| db_instance_class | RDS instance type | `string` | `"db.t3.micro"` | no |
| db_allocated_storage | Allocated storage in GB | `number` | `20` | no |
| db_max_allocated_storage | Max storage for auto-scaling | `number` | `100` | no |
| db_multi_az | Enable Multi-AZ deployment | `bool` | `true` | no |
| db_backup_retention_period | Backup retention in days | `number` | `7` | no |
| elasticache_node_type | ElastiCache node type | `string` | `"cache.t3.micro"` | no |
| elasticache_num_cache_nodes | Number of cache nodes | `number` | `2` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_endpoint | RDS instance connection endpoint |
| db_port | RDS instance port |
| db_name | Database name |
| db_security_group_id | Security group ID for RDS |
| elasticache_endpoint | ElastiCache cluster endpoint |
| elasticache_port | ElastiCache cluster port |
| elasticache_security_group_id | Security group ID for ElastiCache |

## Storage Auto-Scaling

The RDS instance is configured with storage auto-scaling. When storage utilization exceeds 80%, AWS automatically increases the allocated storage up to the `db_max_allocated_storage` limit. This ensures the database never runs out of space and prevents downtime.

**Property 23: Database storage auto-scaling** - Validates Requirements 6.4

## Automated Backups

RDS automated backups are enabled with:
- Configurable retention period (default: 7 days)
- Point-in-time recovery capability
- Automated backup window during low-traffic hours
- Final snapshot on deletion (production)

**Property 6: Automated backup configuration** - Validates Requirements 12.2

## Encryption

RDS data is encrypted:
- **At Rest**: Using AWS KMS customer-managed keys
- **In Transit**: Using TLS 1.2+ for all connections
- **Performance Insights**: Encrypted using KMS
- **Backups**: Automatically encrypted with the same KMS key

**Note**: ElastiCache cluster mode has limited encryption support. For full encryption (at-rest and in-transit), consider using ElastiCache Replication Group in future enhancements.

## High Availability

- **Multi-AZ Deployment**: Synchronous replication to standby instance in different AZ
- **Automatic Failover**: Typically completes within 1-2 minutes
- **Read Replicas**: Can be added for read scaling (not included in this module)

## Monitoring

- **Enhanced Monitoring**: 60-second granularity metrics
- **Performance Insights**: Query performance analysis
- **CloudWatch Logs**: PostgreSQL logs, upgrade logs
- **CloudWatch Alarms**: Can be configured in monitoring module

## Security Best Practices

1. **Network Isolation**: Databases deployed in data subnets with no internet access
2. **Least Privilege**: Security groups allow access only from private subnets
3. **Encryption**: All data encrypted at rest and in transit
4. **Deletion Protection**: Enabled by default for production
5. **Password Management**: Use AWS Secrets Manager for password rotation
6. **Audit Logging**: All connections and queries logged

## Cost Optimization

- Use appropriate instance sizes for your workload
- Enable storage auto-scaling to avoid over-provisioning
- Use Multi-AZ only for production environments
- Consider Reserved Instances for predictable workloads
- Monitor Performance Insights to optimize queries

## Maintenance

- **Backup Window**: Default 03:00-04:00 UTC (configurable)
- **Maintenance Window**: Default Sunday 04:00-05:00 UTC (configurable)
- **Auto Minor Version Upgrade**: Enabled for security patches
- **Apply Immediately**: Disabled for production (uses maintenance window)

## Connection Information

Database connection information is stored in SSM Parameter Store:
- RDS Endpoint: `/{project_name}/{environment}/database/rds/endpoint`
- RDS Port: `/{project_name}/{environment}/database/rds/port`
- RDS Database Name: `/{project_name}/{environment}/database/rds/database_name`
- ElastiCache Endpoint: `/{project_name}/{environment}/database/elasticache/endpoint`
- ElastiCache Port: `/{project_name}/{environment}/database/elasticache/port`

Lambda functions and other services can retrieve these values from SSM Parameter Store.

## Example: Connecting from Lambda

```python
import boto3
import psycopg2

ssm = boto3.client('ssm')

# Get connection parameters from SSM
endpoint = ssm.get_parameter(Name='/ecovolt/prod/database/rds/endpoint')['Parameter']['Value']
port = ssm.get_parameter(Name='/ecovolt/prod/database/rds/port')['Parameter']['Value']
dbname = ssm.get_parameter(Name='/ecovolt/prod/database/rds/database_name')['Parameter']['Value']

# Get password from Secrets Manager
secrets = boto3.client('secretsmanager')
password = secrets.get_secret_value(SecretId='ecovolt/prod/database/password')['SecretString']

# Connect to database
conn = psycopg2.connect(
    host=endpoint.split(':')[0],
    port=port,
    dbname=dbname,
    user='ecovolt_admin',
    password=password,
    sslmode='require'
)
```

## Disaster Recovery

- **Automated Backups**: Daily backups with 7-day retention
- **Point-in-Time Recovery**: Restore to any point within retention period
- **Final Snapshot**: Created before deletion (production)
- **Cross-Region Replication**: Can be configured for DR (not included in this module)

## Troubleshooting

### Connection Issues
- Verify security group allows access from your source
- Check that source is in private subnets
- Verify VPC routing and network ACLs
- Ensure TLS is enabled for connections

### Performance Issues
- Check Performance Insights for slow queries
- Review Enhanced Monitoring metrics
- Consider increasing instance size
- Add read replicas for read-heavy workloads

### Storage Issues
- Verify auto-scaling is enabled
- Check max_allocated_storage limit
- Monitor storage utilization in CloudWatch
- Review backup retention period

## References

- [Amazon RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html)
- [Amazon ElastiCache for Redis](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/WhatIs.html)
- [RDS Storage Auto-Scaling](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PIOPS.StorageTypes.html#USER_PIOPS.Autoscaling)
- [RDS Backup and Restore](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_CommonTasks.BackupRestore.html)
