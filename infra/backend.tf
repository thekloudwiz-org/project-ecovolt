# Terraform Backend Configuration
# State files are stored in S3 with DynamoDB for state locking

terraform {
  backend "s3" {
    bucket         = "thekloudwiz-tf-state-bucket"
    key            = "project-ecovolt/dev-tf.state"  # Override per environment
    region         = "eu-central-1"
    encrypt        = true
    use_lockfile = true
    
    # Workspace configuration
    workspace_key_prefix = "project-ecovolt"
  }
}

# Backend configuration notes:
# - The 'key' parameter should be overridden per environment during init
# - Use: terraform init -backend-config="key=project-ecovolt/dev-tf.state"
# - Or use workspace_key_prefix for automatic environment separation
#
# Environment-specific keys:
# - Dev:     project-ecovolt/dev-tf.state
# - Staging: project-ecovolt/staging-tf.state
# - Prod:    project-ecovolt/prod-tf.state
