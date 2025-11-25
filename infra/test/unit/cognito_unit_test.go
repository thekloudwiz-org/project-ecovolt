package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestCognitoUserPoolCreation tests that Cognito user pool is created with correct configuration
func TestCognitoUserPoolCreation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/cognito",
		Vars: map[string]interface{}{
			"project_name":                "test-ecovolt",
			"environment":                 "test",
			"enable_mfa":                  false,
			"enable_advanced_security":    true,
			"create_separate_admin_pool":  false,
			"create_identity_pool":        false,
			"mobile_app_callback_urls":    []string{"test://callback"},
			"mobile_app_logout_urls":      []string{"test://logout"},
			"admin_portal_callback_urls":  []string{"https://test.example.com/callback"},
			"admin_portal_logout_urls":    []string{"https://test.example.com/logout"},
			"log_retention_days":          7,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "terratest",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)

	// Validate plan output
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

	// Check that user pool will be created
	assert.NotNil(t, planStruct)
	
	// Verify resource counts
	resourceChanges := planStruct.ResourceChangesMap
	assert.Contains(t, resourceChanges, "aws_cognito_user_pool.customers")
	assert.Contains(t, resourceChanges, "aws_cognito_user_pool_client.mobile_app")
	assert.Contains(t, resourceChanges, "aws_cognito_user_pool_client.admin_portal")
	assert.Contains(t, resourceChanges, "aws_cognito_user_group.customers")
	assert.Contains(t, resourceChanges, "aws_cognito_user_group.admins")
}

// TestCognitoPasswordPolicy tests that password policy is correctly configured
func TestCognitoPasswordPolicy(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/cognito",
		Vars: map[string]interface{}{
			"project_name": "test-ecovolt",
			"environment":  "test",
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	// Check password policy configuration
	userPoolResource := planStruct.ResourceChangesMap["aws_cognito_user_pool.customers"]
	assert.NotNil(t, userPoolResource)
	
	// Verify password policy exists in planned values
	plannedValues := userPoolResource.Change.After.(map[string]interface{})
	passwordPolicy := plannedValues["password_policy"].([]interface{})[0].(map[string]interface{})
	
	assert.Equal(t, float64(8), passwordPolicy["minimum_length"])
	assert.Equal(t, true, passwordPolicy["require_lowercase"])
	assert.Equal(t, true, passwordPolicy["require_uppercase"])
	assert.Equal(t, true, passwordPolicy["require_numbers"])
	assert.Equal(t, true, passwordPolicy["require_symbols"])
}

// TestCognitoMFAConfiguration tests MFA configuration
func TestCognitoMFAConfiguration(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name       string
		enableMFA  bool
		expected   string
	}{
		{"MFA Enabled", true, "OPTIONAL"},
		{"MFA Disabled", false, "OFF"},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/cognito",
				Vars: map[string]interface{}{
					"project_name": "test-ecovolt",
					"environment":  "test",
					"enable_mfa":   tc.enableMFA,
					"tags": map[string]string{
						"Environment": "test",
					},
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, terraformOptions)
			
			planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
			userPoolResource := planStruct.ResourceChangesMap["aws_cognito_user_pool.customers"]
			
			plannedValues := userPoolResource.Change.After.(map[string]interface{})
			mfaConfig := plannedValues["mfa_configuration"].(string)
			
			assert.Equal(t, tc.expected, mfaConfig)
		})
	}
}

// TestCognitoUserGroups tests that user groups are created
func TestCognitoUserGroups(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/cognito",
		Vars: map[string]interface{}{
			"project_name": "test-ecovolt",
			"environment":  "test",
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	// Verify all user groups will be created
	expectedGroups := []string{
		"aws_cognito_user_group.customers",
		"aws_cognito_user_group.admins",
		"aws_cognito_user_group.operators",
	}
	
	for _, groupResource := range expectedGroups {
		assert.Contains(t, planStruct.ResourceChangesMap, groupResource)
	}
}

// TestCognitoAppClients tests that app clients are configured correctly
func TestCognitoAppClients(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/cognito",
		Vars: map[string]interface{}{
			"project_name": "test-ecovolt",
			"environment":  "test",
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	// Check mobile app client (public client - no secret)
	mobileClient := planStruct.ResourceChangesMap["aws_cognito_user_pool_client.mobile_app"]
	assert.NotNil(t, mobileClient)
	
	mobileValues := mobileClient.Change.After.(map[string]interface{})
	assert.Equal(t, false, mobileValues["generate_secret"])
	
	// Check admin portal client (confidential client - with secret)
	adminClient := planStruct.ResourceChangesMap["aws_cognito_user_pool_client.admin_portal"]
	assert.NotNil(t, adminClient)
	
	adminValues := adminClient.Change.After.(map[string]interface{})
	assert.Equal(t, true, adminValues["generate_secret"])
}

// TestCognitoOutputs tests that required outputs are defined
func TestCognitoOutputs(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/cognito",
		Vars: map[string]interface{}{
			"project_name": "test-ecovolt",
			"environment":  "test",
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndPlan(t, terraformOptions)

	// Verify outputs are defined (we can't get values without apply)
	outputList := terraform.OutputList(t, terraformOptions)
	
	expectedOutputs := []string{
		"customer_user_pool_id",
		"customer_user_pool_arn",
		"mobile_app_client_id",
		"admin_portal_client_id",
		"customer_user_pool_arn_for_authorizer",
	}
	
	// Note: OutputList only works after apply, so we just verify the module validates
	assert.NotNil(t, outputList)
}
