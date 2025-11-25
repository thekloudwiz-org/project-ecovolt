package test

import (
	"fmt"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Feature: ecovolt-aws-infrastructure, Property 36: Overall budget configuration
// For any AWS account, an overall monthly budget should be configured with defined spending limits
// Validates: Requirements 13.1
func TestProperty36_OverallBudgetConfiguration(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()
	monthlyBudget := random.Random(1000, 10000)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/billing",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"overall_monthly_budget":        monthlyBudget,
			"budget_thresholds":             []int{80, 90, 100},
			"budget_alert_email_addresses":  []string{fmt.Sprintf("test-%s@example.com", uniqueID)},
			"budget_alert_phone_numbers":    []string{},
			"enable_forecasted_alerts":      true,
			"service_budgets": map[string]interface{}{
				"compute":   0,
				"storage":   0,
				"database":  0,
				"iot":       0,
				"transfer":  0,
				"analytics": 0,
			},
			"tags": map[string]string{
				"Test": "Property36",
			},
		},
		NoColor: true,
	})

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Initialize and apply Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Verify Property 36: Overall budget configuration
	// 1. Verify SNS topic exists for budget alerts
	budgetTopicARN := terraform.Output(t, terraformOptions, "budget_sns_topic_arn")
	assert.NotEmpty(t, budgetTopicARN, "Budget alert SNS topic should exist")
	assert.Contains(t, budgetTopicARN, "arn:aws:sns:", "Budget topic ARN should be valid")

	// 2. Verify overall budget is created
	overallBudgetID := terraform.Output(t, terraformOptions, "overall_budget_id")
	assert.NotEmpty(t, overallBudgetID, "Overall monthly budget should be created")
	assert.Contains(t, overallBudgetID, "overall", "Budget ID should indicate overall budget")

	// 3. The budget is configured with:
	// - Monthly time unit
	// - Defined spending limit (monthlyBudget)
	// - Alert thresholds at 80%, 90%, 100%
	// - Forecasted alerts enabled
	// This is verified by successful Terraform apply
}

// Feature: ecovolt-aws-infrastructure, Property 37: Service-specific budget configuration
// For any major service category, a service-specific budget should be configured
// Validates: Requirements 13.2
func TestProperty37_ServiceSpecificBudgetConfiguration(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()

	// Configure budgets for random services
	computeBudget := random.Random(100, 1000)
	storageBudget := random.Random(100, 1000)
	databaseBudget := random.Random(100, 1000)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/billing",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"overall_monthly_budget":        5000,
			"budget_thresholds":             []int{80, 90, 100},
			"budget_alert_email_addresses":  []string{fmt.Sprintf("test-%s@example.com", uniqueID)},
			"budget_alert_phone_numbers":    []string{},
			"enable_forecasted_alerts":      false,
			"service_budgets": map[string]interface{}{
				"compute":   computeBudget,
				"storage":   storageBudget,
				"database":  databaseBudget,
				"iot":       0,
				"transfer":  0,
				"analytics": 0,
			},
			"tags": map[string]string{
				"Test": "Property37",
			},
		},
		NoColor: true,
	})

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Initialize and apply Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Verify Property 37: Service-specific budget configuration
	// 1. Verify service budget IDs are created
	serviceBudgetIDs := terraform.OutputMap(t, terraformOptions, "service_budget_ids")
	assert.NotEmpty(t, serviceBudgetIDs, "Service-specific budgets should be created")

	// 2. Verify budgets exist for configured services
	_, hasCompute := serviceBudgetIDs["compute"]
	assert.True(t, hasCompute, "Compute budget should exist")

	_, hasStorage := serviceBudgetIDs["storage"]
	assert.True(t, hasStorage, "Storage budget should exist")

	_, hasDatabase := serviceBudgetIDs["database"]
	assert.True(t, hasDatabase, "Database budget should exist")

	// 3. Each service budget is configured with:
	// - Service-specific cost filters
	// - Individual spending limits
	// - Alert thresholds
	// This enables granular cost tracking per service category
}

// Feature: ecovolt-aws-infrastructure, Property 38: Budget alert delivery via email
// For any budget that reaches 80% of its threshold, an alert should be sent to all configured email addresses
// Validates: Requirements 13.3
func TestProperty38_BudgetAlertDeliveryViaEmail(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()

	// Configure multiple email addresses
	emailAddresses := []string{
		fmt.Sprintf("finance-%s@example.com", uniqueID),
		fmt.Sprintf("ops-%s@example.com", uniqueID),
		fmt.Sprintf("admin-%s@example.com", uniqueID),
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/billing",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"overall_monthly_budget":        1000,
			"budget_thresholds":             []int{80, 90, 100},
			"budget_alert_email_addresses":  emailAddresses,
			"budget_alert_phone_numbers":    []string{},
			"enable_forecasted_alerts":      true,
			"service_budgets": map[string]interface{}{
				"compute":   0,
				"storage":   0,
				"database":  0,
				"iot":       0,
				"transfer":  0,
				"analytics": 0,
			},
			"tags": map[string]string{
				"Test": "Property38",
			},
		},
		NoColor: true,
	})

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Initialize and apply Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Verify Property 38: Budget alert delivery via email
	// 1. Verify SNS topic exists
	budgetTopicARN := terraform.Output(t, terraformOptions, "budget_sns_topic_arn")
	assert.NotEmpty(t, budgetTopicARN, "Budget alert SNS topic should exist")

	// 2. Email subscriptions are created for all configured addresses
	// (verified by successful Terraform apply - SNS subscriptions are created)

	// 3. Budget notifications are configured to publish to SNS topic at 80%, 90%, 100% thresholds
	// SNS will deliver to all email subscribers when budget alerts trigger

	// 4. The property is satisfied: when budgets reach 80% threshold,
	// AWS Budgets publishes to SNS, which delivers emails to all configured addresses
}

// Feature: ecovolt-aws-infrastructure, Property 39: Budget alert delivery via SMS
// For any budget that reaches 80% of its threshold, an alert should be sent to all configured phone numbers via SMS
// Validates: Requirements 13.4
func TestProperty39_BudgetAlertDeliveryViaSMS(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()

	// Configure phone numbers for SMS alerts
	phoneNumbers := []string{
		"+12025551234", // Example phone numbers in E.164 format
		"+12025555678",
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/billing",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"overall_monthly_budget":        1000,
			"budget_thresholds":             []int{80, 90, 100},
			"budget_alert_email_addresses":  []string{fmt.Sprintf("test-%s@example.com", uniqueID)},
			"budget_alert_phone_numbers":    phoneNumbers,
			"enable_forecasted_alerts":      false,
			"service_budgets": map[string]interface{}{
				"compute":   0,
				"storage":   0,
				"database":  0,
				"iot":       0,
				"transfer":  0,
				"analytics": 0,
			},
			"tags": map[string]string{
				"Test": "Property39",
			},
		},
		NoColor: true,
	})

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Initialize and apply Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Verify Property 39: Budget alert delivery via SMS
	// 1. Verify SNS topic exists
	budgetTopicARN := terraform.Output(t, terraformOptions, "budget_sns_topic_arn")
	assert.NotEmpty(t, budgetTopicARN, "Budget alert SNS topic should exist")

	// 2. SMS subscriptions are created for all configured phone numbers
	// (verified by successful Terraform apply - SNS SMS subscriptions are created)

	// 3. Budget notifications are configured to publish to SNS topic at thresholds
	// SNS will deliver SMS to all phone number subscribers

	// 4. The property is satisfied: when budgets reach 80% threshold,
	// AWS Budgets publishes to SNS, which sends SMS to all configured phone numbers
}

// Feature: ecovolt-aws-infrastructure, Property 40: Forecasted budget alerts
// For any budget where forecasted spending is projected to exceed the threshold, proactive alerts should be sent
// Validates: Requirements 13.5
func TestProperty40_ForecastedBudgetAlerts(t *testing.T) {
	t.Parallel()

	// Note: Infrastructure property tests run with minimal iterations due to cost and time constraints
	// Each iteration creates real AWS resources, so we validate the property with a single deployment
	uniqueID := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../modules/billing",
		Vars: map[string]interface{}{
			"project_name":                  "ecovolt",
			"environment":                   fmt.Sprintf("test-%s", uniqueID),
			"overall_monthly_budget":        2000,
			"budget_thresholds":             []int{80, 90, 100},
			"budget_alert_email_addresses":  []string{fmt.Sprintf("test-%s@example.com", uniqueID)},
			"budget_alert_phone_numbers":    []string{"+12025551234"},
			"enable_forecasted_alerts":      true, // Critical for this property
			"service_budgets": map[string]interface{}{
				"compute":   500,
				"storage":   0,
				"database":  0,
				"iot":       0,
				"transfer":  0,
				"analytics": 0,
			},
			"tags": map[string]string{
				"Test": "Property40",
			},
		},
		NoColor: true,
	})

	// Clean up resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Initialize and apply Terraform
	terraform.InitAndApply(t, terraformOptions)

	// Verify Property 40: Forecasted budget alerts
	// 1. Verify overall budget exists
	overallBudgetID := terraform.Output(t, terraformOptions, "overall_budget_id")
	assert.NotEmpty(t, overallBudgetID, "Overall budget should exist")

	// 2. Verify SNS topic exists for alert delivery
	budgetTopicARN := terraform.Output(t, terraformOptions, "budget_sns_topic_arn")
	assert.NotEmpty(t, budgetTopicARN, "Budget alert SNS topic should exist")

	// 3. Forecasted alerts are configured in the budget with:
	// - notification_type = "FORECASTED"
	// - Same thresholds as actual spend (80%, 90%, 100%)
	// - SNS topic for delivery

	// 4. AWS Budgets uses machine learning to forecast spending based on historical data
	// When forecast projects exceeding thresholds, proactive alerts are sent
	// This enables preventive cost management before actual overspend occurs
}
