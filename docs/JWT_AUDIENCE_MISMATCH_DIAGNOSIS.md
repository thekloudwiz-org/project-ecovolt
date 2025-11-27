# JWT Audience Mismatch - Diagnostic Report

**Date:** November 27, 2025
**Issue:** Admin dashboard returns 401 "Invalid or expired token"
**Correlation ID:** REQ-818e23a1-8523-4a02-90d3-5ee358f7d99a

---

## 🔴 ROOT CAUSE IDENTIFIED

### The Problem: **JWT Audience Mismatch**

**CloudWatch Log Error:**
```
Invalid token: Audience doesn't match any configured client ID
```

**What's Happening:**

Your admin portal is authenticating with Cognito and getting a valid JWT token, but the Lambda function is **rejecting** it because the token's `aud` (audience) claim doesn't match the configured client IDs.

---

## 📊 The Mismatch

### JWT Token Audience (From Your Login)
```json
{
  "aud": "2h0hsagipne3d9l1phtk4ig29a",
  "cognito:groups": ["admins"],
  "email": "admin@ecovolt.com",
  "iss": "https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_Vh37Fd4ul"
}
```

**Token Client ID:** `2h0hsagipne3d9l1phtk4ig29a` ✅ (Admin Portal Client)

### Lambda Environment Variables
```json
{
  "COGNITO_APP_CLIENT_ID": "5a0ppsv5ko1j5r5i4rjir13f6h",
  "COGNITO_ADMIN_CLIENT_ID": null,
  "COGNITO_USER_POOL_ID": "eu-central-1_Vh37Fd4ul"
}
```

**Configured Client IDs:**
- Mobile App: `5a0ppsv5ko1j5r5i4rjir13f6h` ❌ (doesn't match)
- Admin Portal: `null` ❌ (NOT CONFIGURED!)

---

## 🔍 How JWT Verification Works

The backend code (`utils/auth.py` line 40-54) tries to verify the token:

```python
# Try both client IDs (mobile app and admin portal)
for client_id in [APP_CLIENT_ID, ADMIN_CLIENT_ID]:
    try:
        claims = jwt.decode(
            token,
            signing_key,
            algorithms=["RS256"],
            audience=client_id,  # ⬅️ MUST MATCH token's "aud" claim
            options={"verify_exp": True}
        )
        break
    except jwt.InvalidAudienceError:
        continue  # ⬅️ YOUR ISSUE: Both client IDs fail, so token is rejected
```

**Current Flow:**
1. Lambda checks token against `5a0ppsv5ko1j5r5i4rjir13f6h` → ❌ Doesn't match `2h0hsagipne3d9l1phtk4ig29a`
2. Lambda checks token against `null` → ❌ Can't verify against null
3. Token rejected as invalid → 401 Unauthorized

---

## ✅ THE FIX

You need to add the admin portal client ID to the Lambda configuration.

### Option 1: Update Lambda Environment Variable (RECOMMENDED) ⭐

Update the Lambda function to include the admin client ID:

```bash
aws lambda update-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --region eu-central-1 \
  --environment "Variables={
    ENVIRONMENT=dev,
    COGNITO_USER_POOL_ID=eu-central-1_Vh37Fd4ul,
    COGNITO_APP_CLIENT_ID=5a0ppsv5ko1j5r5i4rjir13f6h,
    COGNITO_ADMIN_CLIENT_ID=2h0hsagipne3d9l1phtk4ig29a,
    DB_HOST=<YOUR_DB_HOST>,
    DB_NAME=<YOUR_DB_NAME>,
    DB_USER=<YOUR_DB_USER>,
    DB_PASS=<YOUR_DB_PASSWORD>,
    DYNAMODB_TELEMETRY_TABLE=<YOUR_TABLE>,
    DYNAMODB_NOTIFICATIONS_TABLE=<YOUR_TABLE>,
    SNS_NOTIFICATIONS_TOPIC_ARN=<YOUR_ARN>
  }"
```

**⚠️ IMPORTANT:** You need to include ALL existing environment variables when updating, not just the ones you're changing. Otherwise, you'll overwrite the others.

### Option 2: Update via Terraform (BETTER for Production)

**File:** `infra/modules/compute/main.tf`

Find the `aws_lambda_function.api_handler` resource and update the environment variables:

```hcl
resource "aws_lambda_function" "api_handler" {
  # ... existing config ...

  environment {
    variables = {
      ENVIRONMENT              = var.environment
      COGNITO_USER_POOL_ID     = var.cognito_user_pool_id
      COGNITO_APP_CLIENT_ID    = var.cognito_client_id
      COGNITO_ADMIN_CLIENT_ID  =   # ✅ ADD THIS

      # ... rest of variables ...
    }
  }
}
```

Then you need to define the variable:

**File:** `infra/modules/compute/variables.tf`

```hcl
variable "cognito_admin_client_id" {
  description = "Cognito App Client ID for admin portal"
  type        = string
  default     = "2h0hsagipne3d9l1phtk4ig29a"  # Your admin client ID
}
```

Then deploy:

```bash
cd infra
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

---

## 🧪 Quick Fix for Testing (Use AWS Console)

1. Go to AWS Lambda Console
2. Select function: `ecovolt-dev-api-handler`
3. Configuration → Environment variables → Edit
4. Add new variable:
   - **Key:** `COGNITO_ADMIN_CLIENT_ID`
   - **Value:** `2h0hsagipne3d9l1phtk4ig29a`
5. Save

**Test immediately:**

```bash
curl -s 'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/admin/dashboard' \
  -H 'Authorization: Bearer eyJraWQiOiIxV3BMS2pzb1RhV1F2Q081QlhZclNBK2pMZ1wvOFwvY2wxa2VWeFowUzFUam89IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJiMzM0MzgxMi0xMGIxLTcwMzUtYTZhNi03MWEzM2M5MzA5YjciLCJjb2duaXRvOmdyb3VwcyI6WyJhZG1pbnMivar.cognito_admin_client_idXSwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC5ldS1jZW50cmFsLTEuYW1hem9uYXdzLmNvbVwvZXUtY2VudHJhbC0xX1ZoMzdGZDR1bCIsImNvZ25pdG86dXNlcm5hbWUiOiJiMzM0MzgxMi0xMGIxLTcwMzUtYTZhNi03MWEzM2M5MzA5YjciLCJvcmlnaW5fanRpIjoiMDFhYTkwZjItMDI5MS00NDc0LTlhZTMtYzQ4MTI2OTI2MDQ5IiwiYXVkIjoiMmgwaHNhZ2lwbmUzZDlsMXBodGs0aWcyOWEiLCJldmVudF9pZCI6IjM2NmRiYTQ1LTk2ZDItNGJkMC05OWJjLTkzMjZlMDQxODk1MyIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzY0MjIxNzczLCJleHAiOjE3NjQyMjUzNzMsImlhdCI6MTc2NDIyMTc3MywianRpIjoiMDlmYzQ5MjEtZmY0Yy00ZDcyLThmOWYtMWZjM2RmM2U5NmM2IiwiZW1haWwiOiJhZG1pbkBlY292b2x0LmNvbSJ9.IxxzYh20GKe6362jePRkxEXQjxIlDbJDExLa9ZPWiC2Dx4-kpFwZKPx5JznBjIwYJH7tBGQgmD7lrPjwQVxKnu7RIR0WF0OwQDva1F5e77YktBjghJlvSfZlcL-MHOmMUBNxqp9CL_S6PZKGFmkoP4weuayVl8EWRcYkQLImcjsc_L7ggzSq_XCsPxiwtu4n51vQejWtXFKu5xPCvb27hri0ATK4xhYfzlbU6RhocW-j7q0m3pZCXqjvOilFeox06KcONMQuexpZNLjvAtxsuMwGQnwE2-3mE7njScCZs263Kg0GRt89SqoZaR-B2Z7illP7mhQuX1SYXKaWclBImg' | jq .
```

Expected: Dashboard data instead of 401 error

---

## 🔎 How to Find Your Cognito Client IDs

If you need to find the correct client IDs:

```bash
# List all app clients for your User Pool
aws cognito-idp list-user-pool-clients \
  --user-pool-id eu-central-1_Vh37Fd4ul \
  --region eu-central-1

# Get details for a specific client
aws cognito-idp describe-user-pool-client \
  --user-pool-id eu-central-1_Vh37Fd4ul \
  --client-id 2h0hsagipne3d9l1phtk4ig29a \
  --region eu-central-1
```

**Common Setup:**
- **Mobile App Client:** `5a0ppsv5ko1j5r5i4rjir13f6h` (for mobile users)
- **Admin Portal Client:** `2h0hsagipne3d9l1phtk4ig29a` (for admin users)

---

## 📊 Verification After Fix

After adding `COGNITO_ADMIN_CLIENT_ID`, check the logs again:

```bash
# Test the endpoint
curl -s 'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/admin/dashboard' \
  -H 'Authorization: Bearer YOUR_TOKEN' | jq .

# Check CloudWatch logs
aws logs tail /aws/lambda/ecovolt-dev-api-handler --region eu-central-1 --follow
```

**Expected Log Output (SUCCESS):**
```
{"correlation_id": "REQ-...", "event": "request_received", ...}
Refreshing JWK key cache from environment...
JWK cache refreshed. 2 keys loaded.
{"event": "jwt_claims", "claims": ["sub", "cognito:groups", "email", ...]}
{"event": "admin_check", "user_id": "b3343812-...", "groups": ["admins"], ...}
{"correlation_id": "REQ-...", "event": "auth_success", ...}
{"correlation_id": "REQ-...", "event": "handler_invoked", ...}
{"correlation_id": "REQ-...", "event": "request_completed", "status_code": 200}
```

**No more:** `Invalid token: Audience doesn't match`

---

## 📝 Summary

| Item | Current Value | Correct Value |
|------|--------------|---------------|
| JWT Token `aud` | `2h0hsagipne3d9l1phtk4ig29a` | ✅ Correct (from admin portal login) |
| `COGNITO_APP_CLIENT_ID` | `5a0ppsv5ko1j5r5i4rjir13f6h` | ✅ Correct (for mobile app) |
| `COGNITO_ADMIN_CLIENT_ID` | `null` ❌ | Should be `2h0hsagipne3d9l1phtk4ig29a` |

**Fix:** Add `COGNITO_ADMIN_CLIENT_ID=2h0hsagipne3d9l1phtk4ig29a` to Lambda environment variables.

---

## ⚠️ Additional Issues Found

While diagnosing, I noticed the Lambda is using the **ORIGINAL** `utils/auth.py` file, not the **FIXED** version I created earlier.

**Evidence:** Logs show it's loading JWK keys from environment (good!), but I haven't seen evidence that you:
1. Replaced `utils/auth.py` with `utils/auth_fixed.py`
2. Replaced `utils/db.py` with `utils/db_fixed.py`
3. Redeployed the Lambda code

**Next Steps:**
1. **Fix the immediate issue:** Add `COGNITO_ADMIN_CLIENT_ID` environment variable
2. **Deploy the fixed backend code:** Use the fixed `auth.py` and `db.py` files
3. **Update Terraform:** Make the fix permanent by updating Terraform config

---

**Status:** 🟡 **Quick fix available via AWS Console** → Should work in 2 minutes
**Long-term fix:** 🔴 **Update Terraform configuration**

---

*Diagnostic completed by Senior Lead Architect & QA Engineer*
*Date: November 27, 2025*
