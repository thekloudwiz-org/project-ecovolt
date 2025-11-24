# Disaster Recovery Procedures

## Overview

This document outlines disaster recovery (DR) procedures for the EcoVolt AWS Infrastructure.

**Recovery Objectives:**
- RTO (Recovery Time Objective): 1 hour
- RPO (Recovery Point Objective): 15 minutes

## DR Architecture

### Primary Region: us-east-1
- Full infrastructure deployment
- RDS Multi-AZ for high availability
- Automated backups enabled

### DR Region: us-west-2
- RDS read replica (optional)
- S3 cross-region replication (optional)
- Standby infrastructure (can be deployed on-demand)

## Backup Strategy

### Automated Backups

#### RDS Database
- **Frequency**: Continuous (transaction logs)
- **Retention**: 7 days
- **Backup Window**: 03:00-04:00 UTC
- **Point-in-Time Recovery**: Yes

#### S3 Data
- **Versioning**: Enabled
- **Replication**: Cross-region (if enabled)
- **Lifecycle**: Glacier after 90 days

#### Configuration
- **Terraform State**: S3 with versioning
- **Infrastructure Code**: Git repository

### Manual Backups

#### Before Major Changes
```bash
# Backup RDS
aws rds create-db-snapshot \
  --db-instance-identifier ecovolt-prod \
  --db-snapshot-identifier ecovolt-prod-manual-$(date +%Y%m%d-%H%M%S)

# Backup Terraform state
terraform state pull > backup-$(date +%Y%m%d-%H%M%S).tfstate
```

## Disaster Scenarios

### Scenario 1: Database Failure

#### Detection
- CloudWatch alarm: DatabaseConnections = 0
- Application errors: Connection timeout
- RDS console shows instance unavailable

#### Recovery Steps

**If Multi-AZ Enabled (Automatic):**
1. AWS automatically fails over to standby (1-2 minutes)
2. Monitor CloudWatch for failover completion
3. Verify application connectivity

**If Single-AZ or Multi-AZ Fails:**
```bash
# 1. Restore from latest automated backup
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ecovolt-prod-restored \
  --db-snapshot-identifier <latest-snapshot>

# 2. Wait for instance to be available
aws rds wait db-instance-available \
  --db-instance-identifier ecovolt-prod-restored

# 3. Update application configuration
# Point applications to new endpoint

# 4. Verify data integrity
psql -h <new-endpoint> -U ecovolt_admin -d ecovolt -c "SELECT COUNT(*) FROM vehicles;"
```

**Estimated Recovery Time:** 15-30 minutes

### Scenario 2: Regional Failure

#### Detection
- Multiple service failures in primary region
- AWS Health Dashboard shows regional issues
- Route 53 health checks failing

#### Recovery Steps

**Phase 1: Assess (5 minutes)**
```bash
# Check AWS Service Health
aws health describe-events --filter eventTypeCategories=issue

# Check resource status
aws rds describe-db-instances --region us-east-1
aws lambda list-functions --region us-east-1
```

**Phase 2: Activate DR Region (30 minutes)**
```bash
# 1. Deploy infrastructure to DR region
cd terraform
terraform workspace select dr
terraform apply -var-file=environments/prod-dr.tfvars

# 2. Promote RDS read replica (if exists)
aws rds promote-read-replica \
  --db-instance-identifier ecovolt-prod-dr \
  --region us-west-2

# 3. Update Route 53 to point to DR region
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch file://dr-failover.json

# 4. Verify services in DR region
curl https://api-dr-ecovolt.thekloudwiz.com/health
```

**Phase 3: Verify (15 minutes)**
- Test API endpoints
- Verify database connectivity
- Check IoT device connectivity
- Monitor CloudWatch metrics

**Phase 4: Communicate**
- Notify stakeholders
- Update status page
- Document incident

**Estimated Recovery Time:** 45-60 minutes

### Scenario 3: Data Corruption

#### Detection
- Application reports incorrect data
- Database integrity check fails
- User reports data issues

#### Recovery Steps

**Point-in-Time Recovery:**
```bash
# 1. Identify corruption time
# Review application logs and user reports

# 2. Restore to point before corruption
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier ecovolt-prod \
  --target-db-instance-identifier ecovolt-prod-pitr \
  --restore-time 2024-01-01T12:00:00Z

# 3. Verify restored data
psql -h <restored-endpoint> -U ecovolt_admin -d ecovolt

# 4. If verified, promote restored instance
# Rename instances or update application config
```

**Estimated Recovery Time:** 30-45 minutes

### Scenario 4: Accidental Deletion

#### Detection
- Resources missing from AWS console
- Terraform state shows resources deleted
- Application errors: Resource not found

#### Recovery Steps

**Terraform State Recovery:**
```bash
# 1. Restore Terraform state from backup
aws s3 cp s3://ecovolt-terraform-state/backup/terraform.tfstate.backup ./

# 2. Review what was deleted
terraform plan

# 3. Re-create deleted resources
terraform apply

# 4. Verify resources
terraform state list
```

**S3 Object Recovery:**
```bash
# List deleted objects (if versioning enabled)
aws s3api list-object-versions \
  --bucket ecovolt-prod-data \
  --prefix path/to/deleted/

# Restore specific version
aws s3api copy-object \
  --copy-source ecovolt-prod-data/path/to/file?versionId=<version-id> \
  --bucket ecovolt-prod-data \
  --key path/to/file
```

**Estimated Recovery Time:** 15-30 minutes

## Testing DR Procedures

### Quarterly DR Drill

**Schedule:** First Saturday of each quarter, 02:00 UTC

**Procedure:**
```bash
# 1. Announce drill to team
# 2. Simulate regional failure
# 3. Execute failover to DR region
# 4. Run verification tests
# 5. Failback to primary region
# 6. Document lessons learned
```

**Test Checklist:**
- [ ] RDS failover works
- [ ] Application connects to DR database
- [ ] IoT devices can connect to DR endpoint
- [ ] API Gateway responds in DR region
- [ ] CloudWatch alarms trigger correctly
- [ ] Team can access DR resources
- [ ] Documentation is up-to-date

### Monthly Backup Verification

```bash
# Test RDS restore
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ecovolt-test-restore \
  --db-snapshot-identifier <latest-snapshot>

# Verify data
psql -h <test-endpoint> -U ecovolt_admin -d ecovolt -c "SELECT COUNT(*) FROM vehicles;"

# Clean up
aws rds delete-db-instance \
  --db-instance-identifier ecovolt-test-restore \
  --skip-final-snapshot
```

## Failback Procedures

### Returning to Primary Region

**Prerequisites:**
- Primary region fully operational
- Root cause identified and resolved
- Data synchronized between regions

**Steps:**
```bash
# 1. Verify primary region health
aws health describe-events --region us-east-1

# 2. Deploy/update infrastructure in primary
terraform apply -var-file=environments/prod.tfvars

# 3. Sync data from DR to primary
# Use DMS or pg_dump/restore

# 4. Update Route 53 to primary region
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch file://primary-failback.json

# 5. Monitor for issues
# Watch CloudWatch metrics for 24 hours

# 6. Decommission DR resources (optional)
terraform destroy -var-file=environments/prod-dr.tfvars
```

## Communication Plan

### Incident Response Team
- **Incident Commander**: CTO
- **Technical Lead**: Senior DevOps Engineer
- **Database Lead**: Senior Database Administrator
- **Communications**: Product Manager

### Notification Channels
1. **Critical**: PagerDuty → On-call engineer
2. **High**: Slack #incidents channel
3. **Medium**: Email to engineering team
4. **Low**: Status page update

### Status Page Updates
```
Template:
[INVESTIGATING] We are investigating issues with [service]
[IDENTIFIED] We have identified the issue and are working on a fix
[MONITORING] A fix has been implemented and we are monitoring
[RESOLVED] The issue has been resolved
```

## Post-Incident Review

### Within 24 Hours
1. Document timeline of events
2. Identify root cause
3. List what went well
4. List what needs improvement

### Within 1 Week
1. Conduct post-mortem meeting
2. Create action items
3. Update runbooks
4. Update DR procedures

### Template
```markdown
# Incident Post-Mortem

## Summary
[Brief description]

## Timeline
- HH:MM - Event occurred
- HH:MM - Detected
- HH:MM - Response started
- HH:MM - Resolved

## Root Cause
[Technical explanation]

## Impact
- Duration: X hours
- Users affected: X
- Data loss: Yes/No

## What Went Well
- [Item 1]
- [Item 2]

## What Needs Improvement
- [Item 1]
- [Item 2]

## Action Items
- [ ] [Action 1] - Owner: [Name] - Due: [Date]
- [ ] [Action 2] - Owner: [Name] - Due: [Date]
```

## Contact Information

### AWS Support
- **Account ID**: [Your Account ID]
- **Support Plan**: Business/Enterprise
- **Phone**: 1-800-xxx-xxxx
- **Portal**: https://console.aws.amazon.com/support/

### Internal Contacts
- **On-Call Engineer**: [Phone/Slack]
- **CTO**: [Phone/Email]
- **AWS TAM**: [Email] (if Enterprise support)

## Appendix

### DR Failover JSON (Route 53)
```json
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "api.ecovolt.thekloudwiz.com",
      "Type": "A",
      "SetIdentifier": "DR",
      "Failover": "SECONDARY",
      "AliasTarget": {
        "HostedZoneId": "Z1234567890ABC",
        "DNSName": "api-dr.ecovolt.thekloudwiz.com",
        "EvaluateTargetHealth": true
      }
    }
  }]
}
```

### Useful Commands
```bash
# Check RDS snapshots
aws rds describe-db-snapshots --db-instance-identifier ecovolt-prod

# Check S3 replication status
aws s3api get-bucket-replication --bucket ecovolt-prod-data

# Check Route 53 health
aws route53 get-health-check-status --health-check-id <id>

# List all resources in region
aws resourcegroupstaggingapi get-resources --region us-east-1
```
