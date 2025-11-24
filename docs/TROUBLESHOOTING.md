# Troubleshooting Guide

## Common Issues and Solutions

### Terraform Issues

#### Issue: State Lock Error
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Check who has the lock
terraform force-unlock <lock-id>

# If using S3 backend, check DynamoDB
aws dynamodb scan --table-name ecovolt-terraform-locks
```

#### Issue: Resource Already Exists
```
Error: resource already exists
```

**Solution:**
```bash
# Import existing resource
terraform import module.networking.aws_vpc.main vpc-xxxxx

# Or remove from state if it shouldn't be managed
terraform state rm module.networking.aws_vpc.main
```

#### Issue: Module Not Found
```
Error: Module not installed
```

**Solution:**
```bash
terraform init -upgrade
terraform get -update
```

### Database Issues

#### Issue: Cannot Connect to RDS
**Symptoms:** Connection timeout, connection refused

**Solutions:**
1. Check security group rules:
```bash
aws ec2 describe-security-groups --group-ids <sg-id>
```

2. Verify Lambda is in correct subnets:
```bash
aws lambda get-function-configuration --function-name <function-name>
```

3. Check NAT Gateway (if Lambda needs internet):
```bash
aws ec2 describe-nat-gateways
```

4. Test connectivity from Lambda:
```python
import socket
socket.create_connection(('db-endpoint', 5432), timeout=5)
```

#### Issue: Database Storage Full
**Symptoms:** Write errors, slow queries

**Solutions:**
1. Check storage:
```bash
aws rds describe-db-instances --db-instance-identifier <instance-id> \
  --query 'DBInstances[0].[AllocatedStorage,MaxAllocatedStorage]'
```

2. Increase max allocated storage:
```bash
# Update in terraform
db_max_allocated_storage = 500

terraform apply
```

3. Clean up old data:
```sql
-- Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Vacuum and analyze
VACUUM ANALYZE;
```

### Lambda Issues

#### Issue: Lambda Timeout
**Symptoms:** Task timed out after X seconds

**Solutions:**
1. Increase timeout:
```hcl
lambda_timeout = 60  # seconds
```

2. Optimize code:
- Reduce cold start time
- Use connection pooling
- Cache frequently accessed data

3. Check CloudWatch Logs:
```bash
aws logs tail /aws/lambda/<function-name> --follow
```

#### Issue: Lambda Out of Memory
**Symptoms:** Process exited before completing request

**Solutions:**
1. Increase memory:
```hcl
lambda_memory_size = 512  # MB
```

2. Profile memory usage:
```python
import tracemalloc
tracemalloc.start()
# ... your code ...
print(tracemalloc.get_traced_memory())
```

#### Issue: Lambda Cannot Access VPC Resources
**Symptoms:** Connection timeout to RDS/ElastiCache

**Solutions:**
1. Verify Lambda has ENI in correct subnets
2. Check security group rules
3. Ensure NAT Gateway exists (if internet access needed)
4. Wait for ENI creation (can take 1-2 minutes)

### API Gateway Issues

#### Issue: 502 Bad Gateway
**Symptoms:** API returns 502 error

**Solutions:**
1. Check Lambda function errors:
```bash
aws logs filter-log-events \
  --log-group-name /aws/lambda/<function-name> \
  --filter-pattern "ERROR"
```

2. Verify Lambda integration:
```bash
aws apigateway get-integration \
  --rest-api-id <api-id> \
  --resource-id <resource-id> \
  --http-method GET
```

3. Check Lambda permissions:
```bash
aws lambda get-policy --function-name <function-name>
```

#### Issue: 403 Forbidden
**Symptoms:** API returns 403 error

**Solutions:**
1. Check API key requirement
2. Verify IAM authorization
3. Check resource policy
4. Review CORS configuration

### IoT Issues

#### Issue: Device Cannot Connect
**Symptoms:** Connection refused, authentication failed

**Solutions:**
1. Verify certificate is active:
```bash
aws iot describe-certificate --certificate-id <cert-id>
```

2. Check IoT policy:
```bash
aws iot get-policy --policy-name <policy-name>
```

3. Verify thing exists:
```bash
aws iot describe-thing --thing-name <thing-name>
```

4. Test connection:
```bash
mosquitto_pub -h <iot-endpoint> \
  --cert device.cert.pem \
  --key device.private.key \
  --cafile AmazonRootCA1.pem \
  -t "test/topic" -m "test message"
```

#### Issue: Messages Not Routing
**Symptoms:** Messages published but not received

**Solutions:**
1. Check IoT Rules:
```bash
aws iot get-topic-rule --rule-name <rule-name>
```

2. Verify Kinesis stream:
```bash
aws kinesis describe-stream --stream-name <stream-name>
```

3. Check CloudWatch Logs for rule errors:
```bash
aws logs tail /aws/iot/rules/<rule-name> --follow
```

### Monitoring Issues

#### Issue: No Metrics in CloudWatch
**Symptoms:** Dashboard shows no data

**Solutions:**
1. Wait 5-10 minutes for metrics to appear
2. Verify resources are generating metrics
3. Check metric namespace and dimensions
4. Ensure CloudWatch agent is running (if custom metrics)

#### Issue: Alarms Not Triggering
**Symptoms:** Threshold exceeded but no notification

**Solutions:**
1. Check alarm state:
```bash
aws cloudwatch describe-alarms --alarm-names <alarm-name>
```

2. Verify SNS subscription:
```bash
aws sns list-subscriptions-by-topic --topic-arn <topic-arn>
```

3. Confirm email/SMS subscription
4. Check SNS delivery logs

### Cost Issues

#### Issue: Unexpected High Costs
**Symptoms:** AWS bill higher than expected

**Solutions:**
1. Check Cost Explorer:
```bash
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics BlendedCost
```

2. Review top services:
- Data transfer costs
- NAT Gateway usage
- RDS instance hours
- Lambda invocations

3. Enable cost allocation tags
4. Set up budget alerts

#### Issue: Budget Alerts Not Working
**Symptoms:** No alerts despite exceeding threshold

**Solutions:**
1. Verify budget exists:
```bash
aws budgets describe-budgets --account-id <account-id>
```

2. Check SNS subscriptions confirmed
3. Verify email addresses correct
4. Check spam folder

### Security Issues

#### Issue: GuardDuty Findings
**Symptoms:** Security alerts in GuardDuty

**Solutions:**
1. Review findings:
```bash
aws guardduty list-findings --detector-id <detector-id>
```

2. Investigate and remediate
3. Update security groups
4. Rotate compromised credentials

#### Issue: Config Non-Compliant Resources
**Symptoms:** AWS Config shows non-compliant resources

**Solutions:**
1. Review compliance:
```bash
aws configservice describe-compliance-by-config-rule
```

2. Fix non-compliant resources
3. Update Config rules if needed

### Performance Issues

#### Issue: Slow API Response
**Symptoms:** High latency in API Gateway

**Solutions:**
1. Check Lambda duration:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=<function-name> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

2. Enable X-Ray tracing
3. Optimize database queries
4. Add caching (ElastiCache)
5. Use provisioned concurrency

#### Issue: Kinesis Processing Lag
**Symptoms:** High iterator age

**Solutions:**
1. Check iterator age:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name GetRecords.IteratorAgeMilliseconds \
  --dimensions Name=StreamName,Value=<stream-name> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 300 \
  --statistics Maximum
```

2. Increase shard count
3. Optimize Lambda processing
4. Increase Lambda concurrency

## Diagnostic Commands

### Check Overall Health
```bash
# Check all alarms
aws cloudwatch describe-alarms --state-value ALARM

# Check recent errors in Lambda
aws logs filter-log-events \
  --log-group-name /aws/lambda/ecovolt-prod-api-handler \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000

# Check API Gateway errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name 5XXError \
  --dimensions Name=ApiName,Value=ecovolt-prod-api \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --period 300 \
  --statistics Sum
```

### Check Resource Status
```bash
# RDS status
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]'

# Lambda functions
aws lambda list-functions --query 'Functions[*].[FunctionName,Runtime,LastModified]'

# IoT things
aws iot list-things --query 'things[*].[thingName,thingTypeName]'
```

### Check Costs
```bash
# Current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

## Getting Help

### AWS Support
1. Open AWS Support case
2. Provide:
   - Account ID
   - Region
   - Resource IDs
   - Error messages
   - CloudWatch logs

### Community Resources
- AWS Forums
- Stack Overflow (tag: amazon-web-services)
- AWS re:Post

### Internal Escalation
1. Check runbooks
2. Contact on-call engineer
3. Escalate to senior team if needed
