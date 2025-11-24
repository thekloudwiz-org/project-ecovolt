# Billing Module - Outputs

output "budget_alert_topic_arn" {
  description = "SNS topic ARN for budget alerts"
  value       = aws_sns_topic.budget_alerts.arn
}

output "overall_budget_id" {
  description = "Overall budget ID"
  value       = aws_budgets_budget.overall.id
}

output "compute_budget_id" {
  description = "Compute services budget ID"
  value       = var.service_budgets.compute > 0 ? aws_budgets_budget.compute[0].id : null
}

output "storage_budget_id" {
  description = "Storage services budget ID"
  value       = var.service_budgets.storage > 0 ? aws_budgets_budget.storage[0].id : null
}

output "database_budget_id" {
  description = "Database services budget ID"
  value       = var.service_budgets.database > 0 ? aws_budgets_budget.database[0].id : null
}

output "iot_budget_id" {
  description = "IoT services budget ID"
  value       = var.service_budgets.iot > 0 ? aws_budgets_budget.iot[0].id : null
}

output "transfer_budget_id" {
  description = "Data transfer budget ID"
  value       = var.service_budgets.transfer > 0 ? aws_budgets_budget.transfer[0].id : null
}

output "analytics_budget_id" {
  description = "Analytics services budget ID"
  value       = var.service_budgets.analytics > 0 ? aws_budgets_budget.analytics[0].id : null
}
