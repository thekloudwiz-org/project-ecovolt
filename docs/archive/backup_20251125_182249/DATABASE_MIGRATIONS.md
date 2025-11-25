# Database Migrations Guide

## Overview

The EcoVolt application uses SQL-based migrations to manage the PostgreSQL database schema. Migrations are tracked in a `schema_migrations` table to ensure each migration is applied only once.

## Migration Files

Migrations are located in `application/backend/migrations/` and are executed in alphabetical order:

1. **001_initial_schema.sql** - Creates core tables (users, stations, bikes, swaps, wallet_transactions)
2. **002_add_indexes.sql** - Adds performance indexes
3. **003_seed_data.sql** - Inserts sample data for testing/demo

## Running Migrations

### Automated (CI/CD)

Migrations run automatically during the backend deployment workflow:

```yaml
# In .github/workflows/backend-reusable.yml
- name: Run database migrations
```

The workflow:
1. Fetches database credentials from AWS Secrets Manager
2. Connects to RDS PostgreSQL
3. Creates the `schema_migrations` tracking table
4. Applies any pending migrations
5. Records applied migrations

### Manual (Local/CLI)

Use the migration script for manual execution:

```bash
# Run migrations for dev environment
./scripts/run-migrations.sh dev

# Run migrations for staging (specify region)
./scripts/run-migrations.sh staging eu-central-1

# Run migrations for production
./scripts/run-migrations.sh prod eu-central-1
```

**Prerequisites:**
- AWS CLI configured with appropriate credentials
- PostgreSQL client (`psql`) installed
- `jq` installed for JSON parsing
- Access to the target environment's Secrets Manager

### Installation of Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y postgresql-client jq awscli
```

**macOS:**
```bash
brew install postgresql jq awscli
```

**Windows (WSL):**
```bash
sudo apt-get update
sudo apt-get install -y postgresql-client jq awscli
```

## Migration Tracking

The `schema_migrations` table tracks which migrations have been applied:

```sql
CREATE TABLE schema_migrations (
    migration_id VARCHAR(50) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT NOW()
);
```

To check applied migrations:

```sql
SELECT * FROM schema_migrations ORDER BY applied_at;
```

## Creating New Migrations

### Naming Convention

Use sequential numbering with descriptive names:
- `004_add_user_preferences.sql`
- `005_add_payment_methods.sql`
- `006_add_station_inventory.sql`

### Migration Template

```sql
-- Description of what this migration does
-- Author: Your Name
-- Date: YYYY-MM-DD

-- Add your SQL statements here
CREATE TABLE IF NOT EXISTS new_table (
    id VARCHAR(50) PRIMARY KEY,
    -- columns...
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_new_table_id ON new_table(id);

-- Add comments
COMMENT ON TABLE new_table IS 'Description of the table';
```

### Best Practices

1. **Idempotent Operations** - Use `IF NOT EXISTS` and `IF EXISTS` to make migrations rerunnable
2. **Backwards Compatible** - Avoid breaking changes when possible
3. **Data Migrations** - Separate schema changes from data migrations
4. **Testing** - Test migrations on dev/staging before production
5. **Rollback Plan** - Document how to rollback if needed

## Database Schema

### Core Tables

**users**
- User accounts (riders and admins)
- Wallet balance and subscription info
- Total swaps counter

**stations**
- Battery swap station locations
- Operating hours and amenities
- Pricing configuration

**bikes**
- Electric motorcycles in the system
- Current battery and status
- Odometer and maintenance tracking

**swaps**
- Battery swap transaction history
- Links users, bikes, and stations
- Cost and duration tracking

**wallet_transactions**
- Financial transaction history
- Top-ups, swaps, refunds
- Balance tracking

### Relationships

```
users (1) ----< (N) bikes
users (1) ----< (N) swaps
users (1) ----< (N) wallet_transactions
bikes (1) ----< (N) swaps
stations (1) ----< (N) swaps
```

## Troubleshooting

### Connection Issues

**Error: Could not connect to database**

Check:
1. VPC security groups allow your IP
2. Database is in a public subnet or you're using VPN/bastion
3. Credentials are correct in Secrets Manager

**Solution for local development:**
```bash
# Use AWS Systems Manager Session Manager to create a tunnel
aws ssm start-session \
  --target <bastion-instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<rds-endpoint>"],"portNumber":["5432"],"localPortNumber":["5432"]}'
```

### Migration Failures

**Error: Migration failed to apply**

1. Check the migration SQL syntax
2. Review database logs in CloudWatch
3. Verify no conflicting schema changes
4. Check for data integrity issues

**Rollback a failed migration:**
```sql
-- Remove from tracking table
DELETE FROM schema_migrations WHERE migration_id = '004_failed_migration';

-- Manually revert changes
DROP TABLE IF EXISTS problematic_table;
```

### Duplicate Migrations

**Error: Migration already applied**

This is expected behavior. The script skips already-applied migrations automatically.

To force re-run (use with caution):
```sql
-- Remove from tracking
DELETE FROM schema_migrations WHERE migration_id = '003_seed_data';

-- Then run the migration script again
./scripts/run-migrations.sh dev
```

## Security Considerations

1. **Credentials** - Never commit database credentials to git
2. **Secrets Manager** - All credentials stored in AWS Secrets Manager
3. **IAM Permissions** - Use least-privilege IAM roles
4. **Audit Trail** - All migrations are logged with timestamps
5. **Backup** - Always backup before running migrations in production

## Production Deployment Checklist

Before running migrations in production:

- [ ] Migrations tested in dev environment
- [ ] Migrations tested in staging environment
- [ ] Database backup created
- [ ] Rollback plan documented
- [ ] Maintenance window scheduled (if needed)
- [ ] Team notified of deployment
- [ ] Monitoring alerts configured
- [ ] Post-migration verification queries prepared

## Monitoring

After applying migrations, verify:

```sql
-- Check table counts
SELECT 
    'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'stations', COUNT(*) FROM stations
UNION ALL
SELECT 'bikes', COUNT(*) FROM bikes
UNION ALL
SELECT 'swaps', COUNT(*) FROM swaps
UNION ALL
SELECT 'wallet_transactions', COUNT(*) FROM wallet_transactions;

-- Check recent migrations
SELECT * FROM schema_migrations ORDER BY applied_at DESC LIMIT 5;

-- Check database size
SELECT 
    pg_size_pretty(pg_database_size(current_database())) as database_size;
```

## Support

For issues or questions:
1. Check CloudWatch Logs for RDS
2. Review migration script output
3. Consult the team's database administrator
4. Create an issue in the project repository
