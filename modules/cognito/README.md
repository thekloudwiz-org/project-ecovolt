# Cognito Module

This module creates Amazon Cognito User Pools for user authentication in the EcoVolt application.

## Features

- **Customer User Pool**: For mobile app users
- **Admin User Pool** (optional): Separate pool for administrators
- **User Groups**: customers, admins, operators
- **MFA Support**: Optional for customers, required for admins
- **OAuth 2.0**: Authorization code and implicit flows
- **Identity Pool** (optional): For AWS resource access
- **Advanced Security**: Compromised credentials detection

## Usage

```hcl
module "cognito" {
  source = "./modules/cognito"

  project_name = "ecovolt"
  environment  = "prod"

  # Security settings
  enable_mfa              = true
  enable_advanced_security = true
  create_separate_admin_pool = true

  # OAuth callback URLs
  mobile_app_callback_urls = ["ecovolt://callback"]
  admin_portal_callback_urls = ["https://admin.ecovolt.thekloudwiz.com/callback"]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## User Pool Configuration

### Customer User Pool
- **Username**: Email address
- **Password Policy**: 8+ characters, mixed case, numbers, symbols
- **MFA**: Optional (TOTP)
- **Auto-verify**: Email
- **Token Validity**: 60 minutes (access/ID), 30 days (refresh)

### Admin User Pool (if separate)
- **Username**: Email address
- **Password Policy**: 12+ characters, mixed case, numbers, symbols
- **MFA**: Required (TOTP)
- **Advanced Security**: Enforced
- **Token Validity**: 60 minutes (access/ID), 7 days (refresh)

## User Groups

### customers
- **Precedence**: 10
- **Description**: Regular customers using the mobile app
- **Permissions**: Access to customer APIs

### admins
- **Precedence**: 1
- **Description**: System administrators
- **Permissions**: Full access to admin APIs

### operators
- **Precedence**: 5
- **Description**: Station operators
- **Permissions**: Station management APIs

## App Clients

### Mobile App Client
- **Type**: Public client (no secret)
- **OAuth Flows**: Authorization code, implicit
- **Auth Flows**: SRP, refresh token, user password
- **Scopes**: email, openid, profile

### Admin Portal Client
- **Type**: Confidential client (with secret)
- **OAuth Flows**: Authorization code only
- **Auth Flows**: SRP, refresh token
- **Scopes**: email, openid, profile

## Integration with API Gateway

Use the `customer_user_pool_arn_for_authorizer` output to configure API Gateway Cognito authorizer:

```hcl
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [module.cognito.customer_user_pool_arn_for_authorizer]
}
```

## Security Features

### Advanced Security Mode
When enabled, Cognito detects:
- Compromised credentials
- Unusual sign-in activity
- Account takeover attempts

### MFA Options
- **TOTP**: Time-based one-time passwords (Google Authenticator, Authy)
- **SMS**: Text message codes (requires SNS configuration)

### Password Policy
- Minimum length: 8 characters (customers), 12 characters (admins)
- Requires: uppercase, lowercase, numbers, symbols
- Temporary password validity: 7 days (customers), 3 days (admins)

## User Attributes

### Required Attributes
- **email**: User's email address (username)
- **name**: User's full name

### Optional Attributes
- **phone_number**: User's phone number (for SMS MFA)

## Hosted UI

Cognito provides a hosted UI for authentication at:
- Customers: `https://{project_name}-{environment}-customers.auth.{region}.amazoncognito.com`
- Admins: `https://{project_name}-{environment}-admins.auth.{region}.amazoncognito.com`

## Identity Pool (Optional)

When `create_identity_pool = true`, creates a Cognito Identity Pool that allows authenticated users to access AWS resources directly (e.g., S3, DynamoDB).

**Use Cases**:
- Direct S3 uploads from mobile app
- Client-side encryption
- Temporary AWS credentials

## Outputs

| Output | Description |
|--------|-------------|
| `customer_user_pool_id` | Customer user pool ID |
| `customer_user_pool_arn` | Customer user pool ARN |
| `mobile_app_client_id` | Mobile app client ID |
| `admin_portal_client_id` | Admin portal client ID |
| `admin_portal_client_secret` | Admin portal client secret (sensitive) |

## Cost Estimation

### Free Tier
- 50,000 MAUs (Monthly Active Users)
- Advanced security features included

### Pricing (after free tier)
- **MAUs**: $0.0055 per MAU
- **Advanced Security**: $0.05 per MAU
- **SMS MFA**: $0.00645 per SMS (US)

**Example**:
- 10,000 MAUs: ~$0 (within free tier)
- 100,000 MAUs: ~$275/month
- 1,000,000 MAUs: ~$5,500/month

## Best Practices

1. **Separate Admin Pool**: Use separate user pool for admins in production
2. **Enable MFA**: Require MFA for admins, optional for customers
3. **Advanced Security**: Enable for production environments
4. **Token Expiry**: Short-lived access tokens (60 min), longer refresh tokens
5. **Deletion Protection**: Enable for production user pools
6. **Monitoring**: Monitor sign-in attempts, failed authentications
7. **Backup**: Export user data regularly for disaster recovery

## Monitoring

### CloudWatch Metrics
- `SignInSuccesses`: Successful sign-ins
- `SignInThrottles`: Throttled sign-in attempts
- `TokenRefreshSuccesses`: Successful token refreshes
- `UserAuthenticationFailures`: Failed authentication attempts

### CloudWatch Logs
- User pool logs: `/aws/cognito/{project_name}-{environment}`

## Troubleshooting

### Common Issues

**Issue**: Users can't sign in
- Check password policy compliance
- Verify email is verified
- Check user pool status

**Issue**: OAuth callback fails
- Verify callback URLs match exactly
- Check app client configuration
- Ensure OAuth flows are enabled

**Issue**: MFA not working
- Verify MFA is enabled in user pool
- Check user has enrolled MFA device
- Verify TOTP time sync

## References

- [Amazon Cognito Documentation](https://docs.aws.amazon.com/cognito/)
- [Cognito User Pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html)
- [OAuth 2.0 Flows](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-authentication-flow.html)
