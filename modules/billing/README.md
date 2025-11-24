# Billing Module

Creates AWS Budgets and SNS notifications for cost monitoring and alerting.

## Features

- Overall monthly budget with configurable limits
- Service-specific budgets (compute, storage, database, IoT, data transfer, analytics)
- Multi-threshold alerts (80%, 90%, 100%)
- Forecasted budget alerts for proactive cost management
- Email and SMS notifications

## Usage

```hcl
module "billing" {
  source = "./modules/billing"

  project_name           = "ecovolt"
  environment            = "prod"
  overall_monthly_budget = 10000

  budget_alert_email_addresses = ["thekloudwiz+ecovolt@gmail.com"]
  budget_alert_phone_numbers   = ["+1234567890"]

  service_budgets = {
    compute   = 3000
    storage   = 1000
    database  = 2000
    iot       = 1500
    transfer  = 500
    analytics = 1000
  }
}
```

## Properties Validated

- Property 36: Overall budget configuration (Requirements 13.1)
- Property 37: Service-specific budgets (Requirements 13.2)
- Property 38: Email alert delivery (Requirements 13.3)
- Property 39: SMS alert delivery (Requirements 13.4)
- Property 40: Forecasted alerts (Requirements 13.5)
