package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestWAFWebACLCreation tests that WAF Web ACLs are created
func TestWAFWebACLCreation(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/waf",
		Vars: map[string]interface{}{
			"project_name":           "test-ecovolt",
			"environment":            "test",
			"enable_cloudfront_waf":  true,
			"enable_api_gateway_waf": true,
			"enable_waf_logging":     true,
			"cloudfront_rate_limit":  2000,
			"api_gateway_rate_limit": 1000,
			"tags": map[string]string{
				"Environment": "test",
				"ManagedBy":   "terratest",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)

	// Verify both Web ACLs will be created
	assert.Contains(t, planStruct.ResourceChangesMap, "aws_wafv2_web_acl.cloudfront[0]")
	assert.Contains(t, planStruct.ResourceChangesMap, "aws_wafv2_web_acl.api_gateway[0]")
}

// TestWAFManagedRules tests that AWS managed rules are configured
func TestWAFManagedRules(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/waf",
		Vars: map[string]interface{}{
			"project_name":           "test-ecovolt",
			"environment":            "test",
			"enable_cloudfront_waf":  false,
			"enable_api_gateway_waf": true,
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	apiGatewayWAF := planStruct.ResourceChangesMap["aws_wafv2_web_acl.api_gateway[0]"]
	assert.NotNil(t, apiGatewayWAF)
	
	plannedValues := apiGatewayWAF.Change.After.(map[string]interface{})
	rules := plannedValues["rule"].([]interface{})
	
	// Verify we have multiple rules (managed rules + rate limiting + IP reputation)
	assert.GreaterOrEqual(t, len(rules), 5, "Should have at least 5 rules")
	
	// Verify rule names
	ruleNames := make([]string, len(rules))
	for i, rule := range rules {
		ruleMap := rule.(map[string]interface{})
		ruleNames[i] = ruleMap["name"].(string)
	}
	
	assert.Contains(t, ruleNames, "AWSManagedRulesCommonRuleSet")
	assert.Contains(t, ruleNames, "AWSManagedRulesKnownBadInputsRuleSet")
	assert.Contains(t, ruleNames, "AWSManagedRulesSQLiRuleSet")
	assert.Contains(t, ruleNames, "APIRateLimitRule")
}

// TestWAFRateLimiting tests rate limiting configuration
func TestWAFRateLimiting(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name              string
		cloudfrontLimit   int
		apiGatewayLimit   int
	}{
		{"Default Limits", 2000, 1000},
		{"Custom Limits", 5000, 2000},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/waf",
				Vars: map[string]interface{}{
					"project_name":           "test-ecovolt",
					"environment":            "test",
					"enable_cloudfront_waf":  true,
					"enable_api_gateway_waf": true,
					"cloudfront_rate_limit":  tc.cloudfrontLimit,
					"api_gateway_rate_limit": tc.apiGatewayLimit,
					"tags": map[string]string{
						"Environment": "test",
					},
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, terraformOptions)
			
			planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
			
			// Check CloudFront rate limit
			cloudfrontWAF := planStruct.ResourceChangesMap["aws_wafv2_web_acl.cloudfront[0]"]
			cfValues := cloudfrontWAF.Change.After.(map[string]interface{})
			cfRules := cfValues["rule"].([]interface{})
			
			// Find rate limit rule
			for _, rule := range cfRules {
				ruleMap := rule.(map[string]interface{})
				if ruleMap["name"].(string) == "RateLimitRule" {
					statement := ruleMap["statement"].([]interface{})[0].(map[string]interface{})
					rateBasedStatement := statement["rate_based_statement"].([]interface{})[0].(map[string]interface{})
					assert.Equal(t, float64(tc.cloudfrontLimit), rateBasedStatement["limit"])
				}
			}
		})
	}
}

// TestWAFGeographicBlocking tests geographic blocking configuration
func TestWAFGeographicBlocking(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name             string
		blockedCountries []string
		expectGeoRule    bool
	}{
		{"No Blocking", []string{}, false},
		{"Block Countries", []string{"CN", "RU"}, true},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/waf",
				Vars: map[string]interface{}{
					"project_name":           "test-ecovolt",
					"environment":            "test",
					"enable_cloudfront_waf":  true,
					"enable_api_gateway_waf": false,
					"blocked_countries":      tc.blockedCountries,
					"tags": map[string]string{
						"Environment": "test",
					},
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, terraformOptions)
			
			planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
			
			cloudfrontWAF := planStruct.ResourceChangesMap["aws_wafv2_web_acl.cloudfront[0]"]
			cfValues := cloudfrontWAF.Change.After.(map[string]interface{})
			cfRules := cfValues["rule"].([]interface{})
			
			// Check if geo blocking rule exists
			hasGeoRule := false
			for _, rule := range cfRules {
				ruleMap := rule.(map[string]interface{})
				if ruleMap["name"].(string) == "GeoBlockingRule" {
					hasGeoRule = true
					break
				}
			}
			
			assert.Equal(t, tc.expectGeoRule, hasGeoRule)
		})
	}
}

// TestWAFLogging tests that logging is configured
func TestWAFLogging(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/waf",
		Vars: map[string]interface{}{
			"project_name":           "test-ecovolt",
			"environment":            "test",
			"enable_cloudfront_waf":  true,
			"enable_api_gateway_waf": true,
			"enable_waf_logging":     true,
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	// Verify log groups are created
	assert.Contains(t, planStruct.ResourceChangesMap, "aws_cloudwatch_log_group.cloudfront_waf[0]")
	assert.Contains(t, planStruct.ResourceChangesMap, "aws_cloudwatch_log_group.api_gateway_waf[0]")
	
	// Verify logging configurations
	assert.Contains(t, planStruct.ResourceChangesMap, "aws_wafv2_web_acl_logging_configuration.cloudfront[0]")
	assert.Contains(t, planStruct.ResourceChangesMap, "aws_wafv2_web_acl_logging_configuration.api_gateway[0]")
}

// TestWAFCloudWatchAlarms tests that CloudWatch alarms are created
func TestWAFCloudWatchAlarms(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/waf",
		Vars: map[string]interface{}{
			"project_name":           "test-ecovolt",
			"environment":            "test",
			"enable_cloudfront_waf":  true,
			"enable_api_gateway_waf": true,
			"alarm_sns_topic_arns": []string{
				"arn:aws:sns:us-east-1:123456789012:test-topic",
			},
			"tags": map[string]string{
				"Environment": "test",
			},
		},
		NoColor: true,
	})

	defer terraform.Destroy(t, terraformOptions)
	
	planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
	
	// Verify alarms are created
	assert.Contains(t, planStruct.ResourceChangesMap, "aws_cloudwatch_metric_alarm.cloudfront_blocked_requests[0]")
	assert.Contains(t, planStruct.ResourceChangesMap, "aws_cloudwatch_metric_alarm.api_gateway_blocked_requests[0]")
}

// TestWAFConditionalResources tests that resources are created conditionally
func TestWAFConditionalResources(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name                string
		enableCloudFront    bool
		enableAPIGateway    bool
		expectedCloudFront  bool
		expectedAPIGateway  bool
	}{
		{"Both Enabled", true, true, true, true},
		{"Only CloudFront", true, false, true, false},
		{"Only API Gateway", false, true, false, true},
		{"Both Disabled", false, false, false, false},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
				TerraformDir: "../modules/waf",
				Vars: map[string]interface{}{
					"project_name":           "test-ecovolt",
					"environment":            "test",
					"enable_cloudfront_waf":  tc.enableCloudFront,
					"enable_api_gateway_waf": tc.enableAPIGateway,
					"tags": map[string]string{
						"Environment": "test",
					},
				},
				NoColor: true,
			})

			defer terraform.Destroy(t, terraformOptions)
			
			planStruct := terraform.InitAndPlanAndShowWithStruct(t, terraformOptions)
			
			// Check CloudFront resources
			_, hasCF := planStruct.ResourceChangesMap["aws_wafv2_web_acl.cloudfront[0]"]
			assert.Equal(t, tc.expectedCloudFront, hasCF)
			
			// Check API Gateway resources
			_, hasAPI := planStruct.ResourceChangesMap["aws_wafv2_web_acl.api_gateway[0]"]
			assert.Equal(t, tc.expectedAPIGateway, hasAPI)
		})
	}
}
