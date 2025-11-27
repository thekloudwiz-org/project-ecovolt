# Terraform Sync Guide - Align Manual Fix with Terraform

**Date:** November 27, 2025
**Issue:** Manual Lambda fix needs to be synced with Terraform state

---

## Current Situation

✅ **Manual Fix Applied:** `COGNITO_ADMIN_CLIENT_ID` added to Lambda via Python script
✅ **Terraform Already Configured:** Line 380 in `modules/compute/main.tf` has the variable
✅ **Auto-Configured:** Pulls admin client ID from Cognito module outputs (no hardcoding!)

**Architecture Flow:**
```
Cognito Module
└─> outputs: admin_portal_client_id
    └─> main.tf passes to Compute Module
        └─> Compute Module uses in Lambda env vars
            └─> Lambda function receives it automatically
```

---

## The Problem

The manual fix I applied works, but Terraform doesn't know about it. On the next `terraform apply`, Terraform might try to "fix" the Lambda back to its previous state (without the admin client ID if it wasn't properly deployed).

---

## Solution: Sync Terraform State

### Step 1: Verify Current Terraform Configuration

Check what Terraform thinks the admin client ID should be:

```bash
cd /Users/thekloudwiz/project-ecovolt/infra

# Check Cognito outputs
terraform output cognito_admin_portal_client_id

# Should show: 2h0hsagipne3d9l1phtk4ig29a
```

### Step 2: Apply Terraform to Sync State

Simply run a Terraform apply. Since the configuration is already correct (line 380), Terraform will:
1. Read the correct admin client ID from Cognito module
2. Compare with current Lambda state
3. Either show "No changes" (if already synced) OR update Lambda to match

```bash
cd /Users/thekloudwiz/project-ecovolt/infra

# Plan to see what Terraform wants to do
terraform plan -var-file="environments/dev.tfvars"

# Apply if it looks correct
terraform apply -var-file="environments/dev.tfvars" -auto-approve
```

### Step 3: Verify Lambda After Terraform Apply

```bash
# Check Lambda environment variables
aws lambda get-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --region eu-central-1 \
  --query 'Environment.Variables.{
    APP_CLIENT: COGNITO_APP_CLIENT_ID,
    ADMIN_CLIENT: COGNITO_ADMIN_CLIENT_ID
  }'

# Should show both client IDs
```

---

## Why This Works (No Hardcoding!)

Your infrastructure is already properly configured to automatically get the admin client ID:

### 1. Cognito Module Creates Client

**File:** `modules/cognito/main.tf`
```hcl
resource "aws_cognito_user_pool_client" "admin_portal" {
  name         = "${var.project_name}-${var.environment}-admin-portal"
  user_pool_id = aws_cognito_user_pool.customers.id
  # ... configuration ...
}
```

### 2. Cognito Module Outputs Client ID

**File:** `modules/cognito/outputs.tf` (Line 47-50)
```hcl
output "admin_portal_client_id" {
  description = "ID of the admin portal client"
  value       = aws_cognito_user_pool_client.admin_portal.id
}
```

### 3. Main Terraform Passes to Compute Module

**File:** `infra/main.tf` (Line found via grep)
```hcl
module "compute" {
  source = "./modules/compute"

  # ... other variables ...
  cognito_admin_client_id = module.cognito.admin_portal_client_id  # ✅ Auto from Cognito!
  # ... other variables ...
}
```

### 4. Compute Module Uses in Lambda

**File:** `modules/compute/main.tf` (Line 380)
```hcl
resource "aws_lambda_function" "api_handler" {
  # ... configuration ...

  environment {
    variables = {
      COGNITO_ADMIN_CLIENT_ID = var.cognito_admin_client_id  # ✅ From main.tf
      # ... other variables ...
    }
  }
}
```

**Result:** Completely automated! No hardcoding anywhere. Client ID flows from Cognito → Main → Compute → Lambda.

---

## What Happens on Next Deploy

When you run `terraform apply`:

1. **Cognito module** creates/reads admin portal client
2. **Output** exposes the client ID
3. **Main.tf** passes it to compute module
4. **Compute module** sets it in Lambda environment
5. **Lambda** automatically has the correct admin client ID

**No manual updates needed!** ✅

---

## Fix the Spacing Issue (Optional)

Line 380 has extra spacing:

**Current:**
```hcl
COGNITO_ADMIN_CLIENT_ID      =   var.cognito_admin_client_id
```

**Should be (consistent formatting):**
```hcl
COGNITO_ADMIN_CLIENT_ID      = var.cognito_admin_client_id
```

This is just cosmetic - doesn't affect functionality.

---

## Verification Checklist

After running `terraform apply`:

- [ ] Terraform plan shows either "No changes" or only Lambda environment update
- [ ] Lambda has `COGNITO_ADMIN_CLIENT_ID` set to `2h0hsagipne3d9l1phtk4ig29a`
- [ ] Admin dashboard curl still works (returns 200 OK)
- [ ] No hardcoded client IDs anywhere in Terraform code

---

## Future Deployments

Going forward:

1. **Never manually update Lambda env vars** - use Terraform
2. **Cognito client ID changes automatically propagate** - no action needed
3. **All environments (dev/staging/prod) get correct client IDs** - via same pattern

---

## Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Cognito Module | ✅ Configured | Outputs admin_portal_client_id |
| Main Terraform | ✅ Configured | Passes to compute module |
| Compute Module | ✅ Configured | Uses in Lambda env vars |
| Lambda (Manual) | ✅ Working | Added via Python script |
| Lambda (Terraform) | ⚠️ Needs Sync | Run `terraform apply` |

**Next Step:** Run `terraform apply` to sync Terraform state with manual changes.

---

*Guide created by Senior Lead Architect*
*Date: November 27, 2025*
