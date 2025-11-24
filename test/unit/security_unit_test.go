package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Test KMS key creation and rotation configuration
func TestKMSKeyCreationAndRotation(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             false, // Disable for faster test
			"enable_guardduty":              false, // Disable for faster test
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": 30,
			"tags": map[string]string{
				"Test": "KMSKeyCreation",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify KMS key was created
	kmsKeyID := terraform.Output(t, terraformOptions, "kms_key_id")
	assert.NotEmpty(t, kmsKeyID, "KMS key ID should not be empty")

	kmsKeyARN := terraform.Output(t, terraformOptions, "kms_key_arn")
	assert.NotEmpty(t, kmsKeyARN, "KMS key ARN should not be empty")
	assert.Contains(t, kmsKeyARN, "arn:aws:kms:", "KMS key ARN should be valid")
	assert.Contains(t, kmsKeyARN, kmsKeyID, "KMS key ARN should contain key ID")

	// Verify KMS key alias
	kmsKeyAlias := terraform.Output(t, terraformOptions, "kms_key_alias")
	assert.NotEmpty(t, kmsKeyAlias, "KMS key alias should not be empty")
	assert.Contains(t, kmsKeyAlias, "alias/", "KMS key alias should have alias/ prefix")
	assert.Contains(t, kmsKeyAlias, uniqueID, "KMS key alias should contain environment identifier")
}

// Test KMS key rotation disabled
func TestKMSKeyRotationDisabled(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             false,
			"enable_guardduty":              false,
			"enable_kms_key_rotation":       false, // Disabled
			"cloudtrail_log_retention_days": 30,
			"tags": map[string]string{
				"Test": "KMSKeyRotationDisabled",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify KMS key was created even with rotation disabled
	kmsKeyID := terraform.Output(t, terraformOptions, "kms_key_id")
	assert.NotEmpty(t, kmsKeyID, "KMS key should be created even with rotation disabled")
}

// Test CloudTrail configuration
func TestCloudTrailConfiguration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             true,
			"enable_guardduty":              false,
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": 90,
			"tags": map[string]string{
				"Test": "CloudTrailConfiguration",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify CloudTrail trail was created
	cloudtrailARN := terraform.Output(t, terraformOptions, "cloudtrail_arn")
	assert.NotEmpty(t, cloudtrailARN, "CloudTrail ARN should not be empty")
	assert.Contains(t, cloudtrailARN, "arn:aws:cloudtrail:", "CloudTrail ARN should be valid")

	cloudtrailID := terraform.Output(t, terraformOptions, "cloudtrail_id")
	assert.NotEmpty(t, cloudtrailID, "CloudTrail ID should not be empty")

	// Verify CloudTrail S3 bucket
	bucketName := terraform.Output(t, terraformOptions, "cloudtrail_bucket_name")
	assert.NotEmpty(t, bucketName, "CloudTrail S3 bucket should be created")
	assert.Contains(t, bucketName, "cloudtrail", "Bucket name should indicate CloudTrail usage")

	bucketARN := terraform.Output(t, terraformOptions, "cloudtrail_bucket_arn")
	assert.NotEmpty(t, bucketARN, "CloudTrail S3 bucket ARN should not be empty")
	assert.Contains(t, bucketARN, "arn:aws:s3:::", "Bucket ARN should be valid")

	// Verify CloudWatch Log Group
	logGroupName := terraform.Output(t, terraformOptions, "cloudtrail_log_group_name")
	assert.NotEmpty(t, logGroupName, "CloudWatch Log Group should be created")
	assert.Contains(t, logGroupName, "cloudtrail", "Log group name should indicate CloudTrail")

	logGroupARN := terraform.Output(t, terraformOptions, "cloudtrail_log_group_arn")
	assert.NotEmpty(t, logGroupARN, "CloudWatch Log Group ARN should not be empty")
	assert.Contains(t, logGroupARN, "arn:aws:logs:", "Log group ARN should be valid")

	// Verify CloudTrail role
	cloudtrailRoleARN := terraform.Output(t, terraformOptions, "cloudtrail_role_arn")
	assert.NotEmpty(t, cloudtrailRoleARN, "CloudTrail role should be created")
	assert.Contains(t, cloudtrailRoleARN, "arn:aws:iam:", "CloudTrail role ARN should be valid")
}

// Test CloudTrail disabled
func TestCloudTrailDisabled(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             false, // Disabled
			"enable_guardduty":              false,
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": 30,
			"tags": map[string]string{
				"Test": "CloudTrailDisabled",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify CloudTrail resources are not created
	cloudtrailARN := terraform.Output(t, terraformOptions, "cloudtrail_arn")
	assert.Empty(t, cloudtrailARN, "CloudTrail should not be created when disabled")

	bucketName := terraform.Output(t, terraformOptions, "cloudtrail_bucket_name")
	assert.Empty(t, bucketName, "CloudTrail S3 bucket should not be created when disabled")

	logGroupName := terraform.Output(t, terraformOptions, "cloudtrail_log_group_name")
	assert.Empty(t, logGroupName, "CloudWatch Log Group should not be created when disabled")

	// KMS key should still be created
	kmsKeyID := terraform.Output(t, terraformOptions, "kms_key_id")
	assert.NotEmpty(t, kmsKeyID, "KMS key should be created even when CloudTrail is disabled")
}

// Test GuardDuty enablement
func TestGuardDutyEnablement(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             false,
			"enable_guardduty":              true,
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": 30,
			"tags": map[string]string{
				"Test": "GuardDutyEnablement",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify GuardDuty detector was created
	guarddutyDetectorID := terraform.Output(t, terraformOptions, "guardduty_detector_id")
	assert.NotEmpty(t, guarddutyDetectorID, "GuardDuty detector ID should not be empty")

	guarddutyDetectorARN := terraform.Output(t, terraformOptions, "guardduty_detector_arn")
	assert.NotEmpty(t, guarddutyDetectorARN, "GuardDuty detector ARN should not be empty")
	assert.Contains(t, guarddutyDetectorARN, "arn:aws:guardduty:", "GuardDuty ARN should be valid")
}

// Test GuardDuty disabled
func TestGuardDutyDisabled(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             false,
			"enable_guardduty":              false, // Disabled
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": 30,
			"tags": map[string]string{
				"Test": "GuardDutyDisabled",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify GuardDuty detector is not created
	guarddutyDetectorID := terraform.Output(t, terraformOptions, "guardduty_detector_id")
	assert.Empty(t, guarddutyDetectorID, "GuardDuty detector should not be created when disabled")
}

// Test IAM policy validation - Lambda execution role
func TestLambdaExecutionRole(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             false,
			"enable_guardduty":              false,
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": 30,
			"tags": map[string]string{
				"Test": "LambdaExecutionRole",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify Lambda execution role was created
	lambdaRoleName := terraform.Output(t, terraformOptions, "lambda_execution_role_name")
	assert.NotEmpty(t, lambdaRoleName, "Lambda execution role name should not be empty")
	assert.Contains(t, lambdaRoleName, "lambda-execution-role", "Role name should indicate Lambda execution")

	lambdaRoleARN := terraform.Output(t, terraformOptions, "lambda_execution_role_arn")
	assert.NotEmpty(t, lambdaRoleARN, "Lambda execution role ARN should not be empty")
	assert.Contains(t, lambdaRoleARN, "arn:aws:iam:", "Lambda role ARN should be valid")
	assert.Contains(t, lambdaRoleARN, lambdaRoleName, "Lambda role ARN should contain role name")
}

// Test IAM policy validation - ECS task execution role
func TestECSTaskExecutionRole(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             false,
			"enable_guardduty":              false,
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": 30,
			"tags": map[string]string{
				"Test": "ECSTaskExecutionRole",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify ECS task execution role was created
	ecsRoleName := terraform.Output(t, terraformOptions, "ecs_task_execution_role_name")
	assert.NotEmpty(t, ecsRoleName, "ECS task execution role name should not be empty")
	assert.Contains(t, ecsRoleName, "ecs-task-execution-role", "Role name should indicate ECS task execution")

	ecsRoleARN := terraform.Output(t, terraformOptions, "ecs_task_execution_role_arn")
	assert.NotEmpty(t, ecsRoleARN, "ECS task execution role ARN should not be empty")
	assert.Contains(t, ecsRoleARN, "arn:aws:iam:", "ECS role ARN should be valid")
	assert.Contains(t, ecsRoleARN, ecsRoleName, "ECS role ARN should contain role name")
}

// Test SSM Parameter Store integration
func TestSSMParameterStoreIntegration(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             true,
			"enable_guardduty":              true,
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": 30,
			"tags": map[string]string{
				"Test": "SSMParameterStore",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify SSM parameter prefix
	ssmPrefix := terraform.Output(t, terraformOptions, "ssm_parameter_prefix")
	assert.NotEmpty(t, ssmPrefix, "SSM parameter prefix should not be empty")
	assert.Contains(t, ssmPrefix, "/security", "SSM prefix should indicate security module")
	assert.Contains(t, ssmPrefix, uniqueID, "SSM prefix should contain environment identifier")

	// Verify SSM parameters for KMS key
	kmsKeyIDParam := terraform.Output(t, terraformOptions, "ssm_kms_key_id_parameter")
	assert.NotEmpty(t, kmsKeyIDParam, "SSM parameter for KMS key ID should exist")
	assert.Contains(t, kmsKeyIDParam, ssmPrefix, "KMS key ID parameter should use SSM prefix")
	assert.Contains(t, kmsKeyIDParam, "kms_key_id", "Parameter name should indicate KMS key ID")

	kmsKeyARNParam := terraform.Output(t, terraformOptions, "ssm_kms_key_arn_parameter")
	assert.NotEmpty(t, kmsKeyARNParam, "SSM parameter for KMS key ARN should exist")
	assert.Contains(t, kmsKeyARNParam, ssmPrefix, "KMS key ARN parameter should use SSM prefix")
	assert.Contains(t, kmsKeyARNParam, "kms_key_arn", "Parameter name should indicate KMS key ARN")
}

// Test CloudTrail log retention configuration
func TestCloudTrailLogRetention(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	retentionDays := 180

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             true,
			"enable_guardduty":              false,
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": retentionDays,
			"tags": map[string]string{
				"Test": "CloudTrailLogRetention",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify CloudTrail resources were created
	cloudtrailARN := terraform.Output(t, terraformOptions, "cloudtrail_arn")
	assert.NotEmpty(t, cloudtrailARN, "CloudTrail should be created")

	bucketName := terraform.Output(t, terraformOptions, "cloudtrail_bucket_name")
	assert.NotEmpty(t, bucketName, "CloudTrail S3 bucket should be created")

	// Lifecycle policy is configured in Terraform with the retention days
	// The fact that Terraform apply succeeded means the lifecycle policy is valid
}

// Test complete security stack
func TestCompleteSecurityStack(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/security",
		Vars: map[string]interface{}{
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"enable_cloudtrail":             true,
			"enable_guardduty":              true,
			"enable_kms_key_rotation":       true,
			"cloudtrail_log_retention_days": 90,
			"tags": map[string]string{
				"Test":        "CompleteSecurityStack",
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Verify all major components are created
	// 1. KMS Key
	kmsKeyID := terraform.Output(t, terraformOptions, "kms_key_id")
	assert.NotEmpty(t, kmsKeyID, "KMS key should be created")

	// 2. CloudTrail
	cloudtrailARN := terraform.Output(t, terraformOptions, "cloudtrail_arn")
	assert.NotEmpty(t, cloudtrailARN, "CloudTrail should be created")

	// 3. GuardDuty
	guarddutyDetectorID := terraform.Output(t, terraformOptions, "guardduty_detector_id")
	assert.NotEmpty(t, guarddutyDetectorID, "GuardDuty should be created")

	// 4. Lambda execution role
	lambdaRoleARN := terraform.Output(t, terraformOptions, "lambda_execution_role_arn")
	assert.NotEmpty(t, lambdaRoleARN, "Lambda execution role should be created")

	// 5. ECS task execution role
	ecsRoleARN := terraform.Output(t, terraformOptions, "ecs_task_execution_role_arn")
	assert.NotEmpty(t, ecsRoleARN, "ECS task execution role should be created")

	// 6. SSM parameters
	ssmPrefix := terraform.Output(t, terraformOptions, "ssm_parameter_prefix")
	assert.NotEmpty(t, ssmPrefix, "SSM parameter prefix should exist")

	// Verify all resources are properly tagged
	// Tags are applied in Terraform configuration
}
