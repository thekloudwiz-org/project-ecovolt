# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

We take the security of EcoVolt seriously. If you discover a security vulnerability, please follow these steps:

### 1. **Do NOT** create a public GitHub issue

Security vulnerabilities should not be publicly disclosed until they have been addressed.

### 2. Report privately

Please report security vulnerabilities by emailing:
- **Email:** security@ecovolt.io
- **Subject:** [SECURITY] Brief description of the issue

### 3. Include in your report

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact
- Suggested fix (if any)
- Your contact information

### 4. Response timeline

- **Initial Response:** Within 48 hours
- **Status Update:** Within 7 days
- **Fix Timeline:** Depends on severity
  - Critical: 1-7 days
  - High: 7-14 days
  - Medium: 14-30 days
  - Low: 30-90 days

## Security Measures

### Infrastructure Security

- ✅ All infrastructure defined as code (Terraform)
- ✅ No hardcoded credentials in code
- ✅ AWS Secrets Manager for sensitive data
- ✅ IAM roles with least privilege
- ✅ VPC isolation for resources
- ✅ Encryption at rest (KMS)
- ✅ Encryption in transit (TLS 1.2+)

### Application Security

- ✅ AWS Cognito for authentication
- ✅ JWT token validation
- ✅ API Gateway rate limiting
- ✅ Input validation and sanitization
- ✅ SQL injection prevention (parameterized queries)
- ✅ XSS protection (Content Security Policy)

### CI/CD Security

- ✅ GitHub Actions with OIDC (no long-lived credentials)
- ✅ Automated security scanning (tfsec, Checkov)
- ✅ Dependency vulnerability scanning (Dependabot)
- ✅ Code scanning (CodeQL)
- ✅ Secret scanning enabled

### Monitoring & Detection

- ✅ AWS CloudTrail (all API calls logged)
- ✅ AWS GuardDuty (threat detection)
- ✅ AWS Config (compliance monitoring)
- ✅ CloudWatch alarms for anomalies
- ✅ Automated alerting (SNS)

## Security Best Practices

### For Contributors

1. **Never commit secrets**
   - Use `.env.example` for templates
   - Store actual secrets in AWS Secrets Manager
   - Use GitHub Secrets for CI/CD

2. **Keep dependencies updated**
   - Review Dependabot alerts
   - Update dependencies regularly
   - Test after updates

3. **Follow secure coding practices**
   - Input validation
   - Output encoding
   - Parameterized queries
   - Least privilege principle

4. **Review security scan results**
   - Address tfsec findings
   - Fix Checkov violations
   - Resolve CodeQL alerts

### For Deployers

1. **Rotate credentials regularly**
   - Database passwords: Every 90 days
   - API keys: Every 90 days
   - IAM access keys: Every 90 days

2. **Monitor security alerts**
   - GuardDuty findings
   - CloudWatch alarms
   - AWS Config compliance

3. **Keep infrastructure updated**
   - Apply security patches
   - Update Terraform providers
   - Update Lambda runtimes

4. **Review access logs**
   - CloudTrail logs
   - API Gateway logs
   - Application logs

## Known Security Considerations

### Public Information

The following information is intentionally public and does not pose a security risk:

- ✅ Cognito User Pool ID (public by design)
- ✅ Cognito Client ID (public by design)
- ✅ API Gateway URL (public endpoint)
- ✅ CloudFront distribution domain (public CDN)

These are **not secrets** and are meant to be used by frontend applications.

### What IS Secret

The following should **never** be committed or shared publicly:

- ❌ AWS Access Keys / Secret Keys
- ❌ Database passwords
- ❌ Private keys / certificates
- ❌ API keys for third-party services
- ❌ JWT signing keys
- ❌ Encryption keys

## Vulnerability Disclosure Policy

We follow responsible disclosure:

1. **Report received** → We acknowledge within 48 hours
2. **Investigation** → We verify and assess severity
3. **Fix developed** → We create and test a fix
4. **Fix deployed** → We deploy to production
5. **Public disclosure** → After fix is deployed (coordinated with reporter)

## Security Hall of Fame

We recognize security researchers who help us improve:

- *No reports yet - be the first!*

## Contact

- **Security Email:** security@ecovolt.io
- **General Contact:** info@ecovolt.io
- **GitHub:** https://github.com/thekloudwiz-org/project-ecovolt

## Additional Resources

- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [GitHub Security Features](https://docs.github.com/en/code-security)

---

**Last Updated:** November 30, 2025  
**Version:** 1.0
