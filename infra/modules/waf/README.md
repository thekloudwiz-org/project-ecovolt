# WAF Module

This module creates AWS WAF Web ACLs to protect CloudFront distributions and API Gateway endpoints from common web exploits and attacks.

## Features

- **CloudFront Web ACL**: Protects CDN and static assets
- **API Gateway Web ACL**: Protects backend APIs
- **AWS Managed Rules**: Core, Known Bad Inputs, SQL Injection, Linux OS, IP Reputation
- **Rate Limiting**: Prevents DDoS attacks
- **Geographic Blocking**: Optional country-based blocking
- **CloudWatch Logging**: Full request logging
- **CloudWatch Alarms**: Alerts for blocked requests

## Usage

```hcl
module "waf" {
  source = "./modules/waf"

  project_name = "ecovolt"
  environment  = "prod"

  # Enable WAF for both CloudFront and API Gateway
  enable_cloudfront_waf   = true
  enable_api_gateway_waf  = true
  enable_waf_logging      = true

  # Rate limits
  cloudfront_rate_limit   = 2000  # requests per 5 min per IP
  api_gateway_rate_limit  = 1000  # requests per 5 min per IP

  # Geographic blocking (optional)
  blocked_countries = ["CN", "RU"]  # Block China and Russia

  # Monitoring
  alarm_sns_topic_arns = [module.monitoring.sns_topic_arn]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }

  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
```

## AWS Managed Rule Sets

### 1. Core Rule Set (AWSManagedRulesCommonRuleSet)
Protects against common threats:
- SQL injection
- Cross-site scripting (XSS)
- Local file inclusion (LFI)
- Remote file inclusion (RFI)
- PHP injection
- Command injection
- Session fixation

### 2. Known Bad Inputs (AWSManagedRulesKnownBadInputsRuleSet)
Blocks requests with patterns known to be malicious:
- Invalid or malformed requests
- Known attack patterns
- Exploit attempts

### 3. SQL Injection (AWSManagedRulesSQLiRuleSet)
Specialized protection against SQL injection attacks:
- SQL syntax detection
- SQL comment detection
- SQL function detection

### 4. Linux Operating System (AWSManagedRulesLinuxRuleSet)
Protects against Linux-specific exploits:
- Local file inclusion
- Command injection
- Path traversal

### 5. IP Reputation List (AWSManagedRulesAmazonIpReputationList)
Blocks requests from known malicious IP addresses:
- Botnet IPs
- Tor exit nodes
- Known attackers

## Rate Limiting

### CloudFront Rate Limit
**Default**: 2,000 requests per 5 minutes per IP

**Recommended Settings**:
- **Development**: 5,000 (relaxed for testing)
- **Staging**: 2,000 (production-like)
- **Production**: 2,000 (strict)

### API Gateway Rate Limit
**Default**: 1,000 requests per 5 minutes per IP

**Recommended Settings**:
- **Development**: 2,000 (relaxed for testing)
- **Staging**: 1,000 (production-like)
- **Production**: 1,000 (strict)

**Rate Limit Response**: HTTP 429 with JSON error message

## Geographic Blocking

Block traffic from specific countries using ISO 3166-1 alpha-2 codes:

```hcl
blocked_countries = ["CN", "RU", "KP"]  # China, Russia, North Korea
```

**Common Use Cases**:
- Compliance requirements
- Reduce attack surface
- Geographic restrictions

**Note**: Use with caution - may block legitimate users.

## Rule Exclusions

Exclude specific rules if they cause false positives:

```hcl
cloudfront_rule_exclusions = [
  "SizeRestrictions_BODY",
  "GenericRFI_BODY"
]

api_gateway_rule_exclusions = [
  "CrossSiteScripting_BODY"
]
```

**When to Exclude**:
- False positives blocking legitimate traffic
- Specific application requirements
- After thorough testing

## Logging

### CloudWatch Logs
WAF logs all requests (allowed and blocked) to CloudWatch:

**Log Format**:
```json
{
  "timestamp": 1234567890,
  "formatVersion": 1,
  "webaclId": "arn:aws:wafv2:...",
  "terminatingRuleId": "RateLimitRule",
  "terminatingRuleType": "RATE_BASED",
  "action": "BLOCK",
  "httpRequest": {
    "clientIp": "1.2.3.4",
    "country": "US",
    "uri": "/api/stations",
    "method": "GET"
  }
}
```

**Redacted Fields**:
- Authorization headers
- Cookies

### Log Retention
**Default**: 30 days

**Recommended**:
- **Development**: 7 days
- **Staging**: 30 days
- **Production**: 90 days

## Monitoring

### CloudWatch Metrics

**Available Metrics**:
- `AllowedRequests`: Requests allowed by WAF
- `BlockedRequests`: Requests blocked by WAF
- `CountedRequests`: Requests counted (not blocked)
- `PassedRequests`: Requests passed to origin

**Dimensions**:
- `WebACL`: Web ACL name
- `Region`: AWS region
- `Rule`: Specific rule name

### CloudWatch Alarms

**Blocked Requests Alarm**:
- Triggers when blocked requests exceed threshold
- Default threshold: 100 requests in 5 minutes
- Sends notification to SNS topic

**Use Cases**:
- Detect ongoing attacks
- Monitor false positives
- Capacity planning

## Integration

### CloudFront Integration

```hcl
resource "aws_cloudfront_distribution" "main" {
  # ... other configuration ...

  web_acl_id = module.waf.cloudfront_web_acl_arn

  # ... other configuration ...
}
```

### API Gateway Integration

```hcl
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = aws_api_gateway_stage.main.arn
  web_acl_arn  = module.waf.api_gateway_web_acl_arn
}
```

## Cost Estimation

### Pricing Components

**Web ACL**: $5.00 per month per Web ACL  
**Rules**: $1.00 per month per rule  
**Requests**: $0.60 per million requests

### Example Costs

**Development** (low traffic):
- 2 Web ACLs: $10/month
- 12 rules (6 per ACL): $12/month
- 1M requests: $0.60/month
- **Total**: ~$23/month

**Staging** (moderate traffic):
- 2 Web ACLs: $10/month
- 12 rules: $12/month
- 10M requests: $6/month
- **Total**: ~$28/month

**Production** (high traffic):
- 2 Web ACLs: $10/month
- 12 rules: $12/month
- 100M requests: $60/month
- **Total**: ~$82/month

### Cost Optimization

1. **Consolidate Rules**: Use managed rule groups instead of individual rules
2. **Sampling**: Enable sampled requests instead of logging all requests
3. **Log Retention**: Reduce retention period for non-production
4. **Geographic Blocking**: Reduce traffic from unwanted regions

## Testing

### Test Blocked Requests

```bash
# Test SQL injection (should be blocked)
curl -X GET "https://api.ecovolt.thekloudwiz.com/stations?id=1' OR '1'='1"

# Test XSS (should be blocked)
curl -X GET "https://api.ecovolt.thekloudwiz.com/stations?name=<script>alert('xss')</script>"

# Test rate limiting (should be blocked after threshold)
for i in {1..2000}; do
  curl -X GET "https://api.ecovolt.thekloudwiz.com/health"
done
```

### Check WAF Logs

```bash
# Query CloudWatch Logs
aws logs filter-log-events \
  --log-group-name /aws/wafv2/regional/ecovolt-prod \
  --filter-pattern '{ $.action = "BLOCK" }' \
  --start-time $(date -u -d '1 hour ago' +%s)000
```

### Monitor Metrics

```bash
# Get blocked requests count
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=ecovolt-prod-api-waf Name=Region,Value=us-east-1 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## Troubleshooting

### False Positives

**Issue**: Legitimate requests being blocked

**Solution**:
1. Check WAF logs to identify blocking rule
2. Analyze request pattern
3. Add rule exclusion if appropriate
4. Test thoroughly before deploying

### High Blocked Request Rate

**Issue**: Unusually high number of blocked requests

**Possible Causes**:
- Ongoing attack (expected)
- False positives (needs tuning)
- Misconfigured application

**Actions**:
1. Review WAF logs
2. Identify attack patterns
3. Adjust rate limits if needed
4. Consider additional rules

### Rate Limit Too Strict

**Issue**: Legitimate users hitting rate limits

**Solution**:
1. Analyze traffic patterns
2. Increase rate limit threshold
3. Consider per-user rate limiting (requires custom solution)
4. Implement caching to reduce requests

## Best Practices

1. **Start in Count Mode**: Test rules without blocking first
2. **Monitor Logs**: Regularly review blocked requests
3. **Tune Rules**: Adjust based on false positives
4. **Use Managed Rules**: Leverage AWS expertise
5. **Enable Logging**: Essential for troubleshooting
6. **Set Alarms**: Get notified of attacks
7. **Regular Updates**: AWS updates managed rules automatically
8. **Test Changes**: Always test in staging first
9. **Document Exclusions**: Keep track of why rules were excluded
10. **Review Regularly**: Periodic security audits

## Security Considerations

### Defense in Depth
WAF is one layer of security. Also implement:
- API authentication (Cognito)
- Input validation in application
- Rate limiting at application level
- DDoS protection (AWS Shield)
- Network security (Security Groups, NACLs)

### Compliance
WAF helps meet compliance requirements:
- PCI DSS: Requirement 6.6 (Web Application Firewall)
- OWASP Top 10: Protection against common vulnerabilities
- GDPR: Security measures for data protection

## References

- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)
- [AWS Managed Rules](https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups.html)
- [WAF Best Practices](https://docs.aws.amazon.com/waf/latest/developerguide/waf-chapter.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
