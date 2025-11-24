# GitHub Actions OIDC IAM Role Configuration
# This file can be used in a separate Terraform configuration to manage
# the IAM role and permissions for GitHub Actions CI/CD pipeline

# ============================================================================
# OIDC Provider (create once per AWS account)
# ============================================================================

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name        = "GitHub Actions OIDC Provider"
    ManagedBy   = "Terraform"
    Environment = "all"
  }
}

# ============================================================================
# IAM Role for GitHub Actions (Development)
# ============================================================================

resource "aws_iam_role" "github_actions_dev" {
  name        = "GitHubActions-EcoVolt-Dev"
  description = "Role for GitHub Actions to deploy EcoVolt development infrastructure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:thekloudwiz-org/project-ecovolt:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "GitHub Actions EcoVolt Dev Role"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# IAM Policy for EcoVolt Infrastructure Management
# ============================================================================

resource "aws_iam_policy" "ecovolt_infrastructure" {
  name        = "EcoVolt-Infrastructure-Management"
  description = "Permissions for managing EcoVolt infrastructure via Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Permissions"
        Effect = "Allow"
        Action = ["ec2:*"]
        Resource = "*"
      },
      {
        Sid    = "RDSPermissions"
        Effect = "Allow"
        Action = ["rds:*"]
        Resource = "*"
      },
      {
        Sid    = "DynamoDBPermissions"
        Effect = "Allow"
        Action = ["dynamodb:*"]
        Resource = "*"
      },
      {
        Sid    = "S3Permissions"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = "*"
      },
      {
        Sid    = "LambdaPermissions"
        Effect = "Allow"
        Action = ["lambda:*"]
        Resource = "*"
      },
      {
        Sid    = "IAMPermissions"
        Effect = "Allow"
        Action = ["iam:*"]
        Resource = "*"
      },
      {
        Sid    = "APIGatewayPermissions"
        Effect = "Allow"
        Action = ["apigateway:*"]
        Resource = "*"
      },
      {
        Sid    = "CognitoPermissions"
        Effect = "Allow"
        Action = [
          "cognito-idp:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchPermissions"
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSPermissions"
        Effect = "Allow"
        Action = ["sns:*"]
        Resource = "*"
      },
      {
        Sid    = "SQSPermissions"
        Effect = "Allow"
        Action = ["sqs:*"]
        Resource = "*"
      },
      {
        Sid    = "KinesisPermissions"
        Effect = "Allow"
        Action = [
          "kinesis:*",
          "firehose:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "IoTPermissions"
        Effect = "Allow"
        Action = ["iot:*"]
        Resource = "*"
      },
      {
        Sid    = "SecretsManagerPermissions"
        Effect = "Allow"
        Action = ["secretsmanager:*"]
        Resource = "*"
      },
      {
        Sid    = "SSMPermissions"
        Effect = "Allow"
        Action = ["ssm:*"]
        Resource = "*"
      },
      {
        Sid    = "KMSPermissions"
        Effect = "Allow"
        Action = ["kms:*"]
        Resource = "*"
      },
      {
        Sid    = "ElastiCachePermissions"
        Effect = "Allow"
        Action = ["elasticache:*"]
        Resource = "*"
      },
      {
        Sid    = "CloudFrontPermissions"
        Effect = "Allow"
        Action = ["cloudfront:*"]
        Resource = "*"
      },
      {
        Sid    = "Route53Permissions"
        Effect = "Allow"
        Action = ["route53:*"]
        Resource = "*"
      },
      {
        Sid    = "ACMPermissions"
        Effect = "Allow"
        Action = ["acm:*"]
        Resource = "*"
      },
      {
        Sid    = "WAFPermissions"
        Effect = "Allow"
        Action = ["wafv2:*"]
        Resource = "*"
      },
      {
        Sid    = "GluePermissions"
        Effect = "Allow"
        Action = ["glue:*"]
        Resource = "*"
      },
      {
        Sid    = "AthenaPermissions"
        Effect = "Allow"
        Action = ["athena:*"]
        Resource = "*"
      },
      {
        Sid    = "EventsPermissions"
        Effect = "Allow"
        Action = ["events:*"]
        Resource = "*"
      },
      {
        Sid    = "BackupPermissions"
        Effect = "Allow"
        Action = ["backup:*"]
        Resource = "*"
      },
      {
        Sid    = "ConfigPermissions"
        Effect = "Allow"
        Action = ["config:*"]
        Resource = "*"
      },
      {
        Sid    = "GuardDutyPermissions"
        Effect = "Allow"
        Action = ["guardduty:*"]
        Resource = "*"
      },
      {
        Sid    = "SecurityHubPermissions"
        Effect = "Allow"
        Action = ["securityhub:*"]
        Resource = "*"
      },
      {
        Sid    = "CloudTrailPermissions"
        Effect = "Allow"
        Action = ["cloudtrail:*"]
        Resource = "*"
      },
      {
        Sid    = "XRayPermissions"
        Effect = "Allow"
        Action = ["xray:*"]
        Resource = "*"
      },
      {
        Sid    = "GreengrassPermissions"
        Effect = "Allow"
        Action = ["greengrass:*"]
        Resource = "*"
      },
      {
        Sid    = "STSPermissions"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Sid    = "ResourceGroupsPermissions"
        Effect = "Allow"
        Action = [
          "resource-groups:*",
          "tag:*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name      = "EcoVolt Infrastructure Management Policy"
    ManagedBy = "Terraform"
  }
}

# ============================================================================
# Attach Policy to Dev Role
# ============================================================================

resource "aws_iam_role_policy_attachment" "github_actions_dev" {
  role       = aws_iam_role.github_actions_dev.name
  policy_arn = aws_iam_policy.ecovolt_infrastructure.arn
}

# ============================================================================
# IAM Role for GitHub Actions (Staging)
# ============================================================================

resource "aws_iam_role" "github_actions_staging" {
  name        = "GitHubActions-EcoVolt-Staging"
  description = "Role for GitHub Actions to deploy EcoVolt staging infrastructure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:thekloudwiz-org/project-ecovolt:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "GitHub Actions EcoVolt Staging Role"
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_staging" {
  role       = aws_iam_role.github_actions_staging.name
  policy_arn = aws_iam_policy.ecovolt_infrastructure.arn
}

# ============================================================================
# IAM Role for GitHub Actions (Production)
# ============================================================================

resource "aws_iam_role" "github_actions_prod" {
  name        = "GitHubActions-EcoVolt-Prod"
  description = "Role for GitHub Actions to deploy EcoVolt production infrastructure"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:thekloudwiz-org/project-ecovolt:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "GitHub Actions EcoVolt Prod Role"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_prod" {
  role       = aws_iam_role.github_actions_prod.name
  policy_arn = aws_iam_policy.ecovolt_infrastructure.arn
}

# ============================================================================
# Outputs
# ============================================================================

output "github_actions_dev_role_arn" {
  description = "ARN of the GitHub Actions Dev IAM role"
  value       = aws_iam_role.github_actions_dev.arn
}

output "github_actions_staging_role_arn" {
  description = "ARN of the GitHub Actions Staging IAM role"
  value       = aws_iam_role.github_actions_staging.arn
}

output "github_actions_prod_role_arn" {
  description = "ARN of the GitHub Actions Prod IAM role"
  value       = aws_iam_role.github_actions_prod.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "infrastructure_policy_arn" {
  description = "ARN of the EcoVolt infrastructure management policy"
  value       = aws_iam_policy.ecovolt_infrastructure.arn
}
