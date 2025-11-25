# Amazon Cognito User Pools Module
# Provides user authentication for mobile app and admin portal

# Customer User Pool
resource "aws_cognito_user_pool" "customers" {
  name = "${var.project_name}-${var.environment}-customers"

  # Username configuration
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  # MFA configuration
  mfa_configuration = var.enable_mfa ? "OPTIONAL" : "OFF"

  dynamic "software_token_mfa_configuration" {
    for_each = var.enable_mfa ? [1] : []
    content {
      enabled = true
    }
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User attributes
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = false

    string_attribute_constraints {
      min_length = 5
      max_length = 255
    }
  }

  schema {
    name                = "name"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 255
    }
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 10
      max_length = 20
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = var.enable_advanced_security ? "ENFORCED" : "OFF"
  }

  # Deletion protection
  deletion_protection = var.environment == "prod" ? "ACTIVE" : "INACTIVE"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-customers-pool"
    }
  )
}

# Admin User Pool (optional - can use same pool with groups)
resource "aws_cognito_user_pool" "admins" {
  count = var.create_separate_admin_pool ? 1 : 0

  name = "${var.project_name}-${var.environment}-admins"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 3
  }

  # MFA required for admins
  mfa_configuration = "ON"

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  deletion_protection = var.environment == "prod" ? "ACTIVE" : "INACTIVE"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-admins-pool"
    }
  )
}

# User Pool Domain for hosted UI
resource "aws_cognito_user_pool_domain" "customers" {
  domain       = "${var.project_name}-${var.environment}-customers"
  user_pool_id = aws_cognito_user_pool.customers.id
}

resource "aws_cognito_user_pool_domain" "admins" {
  count = var.create_separate_admin_pool ? 1 : 0

  domain       = "${var.project_name}-${var.environment}-admins"
  user_pool_id = aws_cognito_user_pool.admins[0].id
}

# App Client for Mobile App
resource "aws_cognito_user_pool_client" "mobile_app" {
  name         = "${var.project_name}-mobile-app"
  user_pool_id = aws_cognito_user_pool.customers.id

  generate_secret = false # Public client (mobile app)

  # OAuth configuration
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.mobile_app_callback_urls
  logout_urls                          = var.mobile_app_logout_urls

  # Token validity
  id_token_validity      = 60  # 60 minutes
  access_token_validity  = 60  # 60 minutes
  refresh_token_validity = 30  # 30 days

  token_validity_units {
    id_token      = "minutes"
    access_token  = "minutes"
    refresh_token = "days"
  }

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Read and write attributes
  read_attributes = [
    "email",
    "email_verified",
    "name",
    "phone_number",
    "phone_number_verified"
  ]

  write_attributes = [
    "email",
    "name",
    "phone_number"
  ]

  # Authentication flows
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}

# App Client for Admin Portal
resource "aws_cognito_user_pool_client" "admin_portal" {
  name         = "${var.project_name}-admin-portal"
  user_pool_id = var.create_separate_admin_pool ? aws_cognito_user_pool.admins[0].id : aws_cognito_user_pool.customers.id

  generate_secret = false # Public client (browser-based SPA)

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = var.admin_portal_callback_urls
  logout_urls                          = var.admin_portal_logout_urls
  
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Token validity
  id_token_validity      = 60  # 60 minutes
  access_token_validity  = 60  # 60 minutes
  refresh_token_validity = 7   # 7 days

  token_validity_units {
    id_token      = "minutes"
    access_token  = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"

  read_attributes = [
    "email",
    "email_verified",
    "name",
    "phone_number"
  ]

  write_attributes = [
    "email",
    "name",
    "phone_number"
  ]
}

# User Groups
resource "aws_cognito_user_group" "customers" {
  name         = "customers"
  user_pool_id = aws_cognito_user_pool.customers.id
  description  = "Regular customers using the mobile app"
  precedence   = 10
}

resource "aws_cognito_user_group" "admins" {
  name         = "admins"
  user_pool_id = var.create_separate_admin_pool ? aws_cognito_user_pool.admins[0].id : aws_cognito_user_pool.customers.id
  description  = "System administrators"
  precedence   = 1
}

resource "aws_cognito_user_group" "operators" {
  name         = "operators"
  user_pool_id = var.create_separate_admin_pool ? aws_cognito_user_pool.admins[0].id : aws_cognito_user_pool.customers.id
  description  = "Station operators"
  precedence   = 5
}

# Identity Pool for AWS resource access (optional)
resource "aws_cognito_identity_pool" "main" {
  count = var.create_identity_pool ? 1 : 0

  identity_pool_name               = "${var.project_name}-${var.environment}-identity-pool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.mobile_app.id
    provider_name           = aws_cognito_user_pool.customers.endpoint
    server_side_token_check = true
  }

  tags = var.tags
}

# IAM role for authenticated users (if identity pool is created)
resource "aws_iam_role" "authenticated" {
  count = var.create_identity_pool ? 1 : 0

  name = "${var.project_name}-${var.environment}-cognito-authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main[0].id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Attach policy to authenticated role
resource "aws_iam_role_policy" "authenticated" {
  count = var.create_identity_pool ? 1 : 0

  name = "authenticated-policy"
  role = aws_iam_role.authenticated[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mobileanalytics:PutEvents",
          "cognito-sync:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach roles to identity pool
resource "aws_cognito_identity_pool_roles_attachment" "main" {
  count = var.create_identity_pool ? 1 : 0

  identity_pool_id = aws_cognito_identity_pool.main[0].id

  roles = {
    authenticated = aws_iam_role.authenticated[0].arn
  }
}

# CloudWatch Log Group for Cognito
resource "aws_cloudwatch_log_group" "cognito" {
  name              = "/aws/cognito/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}
