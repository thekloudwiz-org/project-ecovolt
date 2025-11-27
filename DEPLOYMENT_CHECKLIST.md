# 🚀 Deployment Checklist - Bikes & Stations Fix

**Date:** November 27, 2025
**Status:** Ready for deployment

---

## ✅ Pre-Deployment Verification

### Infrastructure Changes Complete
- ✅ DynamoDB table: `ecovolt-dev-bike-status` exists with `bikeId` hash key
- ✅ Terraform state: Already tracking bike_status table
- ✅ Backend code: Updated to use `bikeId` and correct table name
- ✅ Terraform config: Uses `bike_status` lookup from DynamoDB module
- ✅ All terminology: Consistently uses "bike" instead of "vehicle"

### Current Terraform Plan
```
Plan: 0 to add, 2 to change, 0 to destroy
```
The 2 changes are monitoring dashboard updates (not critical).

---

## 🚀 Deployment Steps

### Step 1: Build Lambda Package (Docker - Linux Compatible)

```bash
cd /Users/thekloudwiz/project-ecovolt

# Build using Docker for Linux compatibility
./scripts/build_lambda_package_docker.sh

# Expected output:
# - Package built successfully
# - Location: lambda-deployment.zip
# - Size: ~XX MB
```

**Why Docker?**
- Your local environment is macOS
- AWS Lambda runs on Linux
- Docker ensures binary compatibility

---

### Step 2: Deploy Backend Code to Lambda

```bash
# Deploy to API Handler Lambda
aws lambda update-function-code \
  --function-name ecovolt-dev-api-handler \
  --zip-file fileb://lambda-deployment.zip \
  --region eu-central-1

# Expected output:
# {
#   "FunctionName": "ecovolt-dev-api-handler",
#   "LastUpdateStatus": "InProgress",
#   ...
# }

# Wait for deployment to complete
echo "Waiting for Lambda deployment to complete..."
aws lambda wait function-updated-v2 \
  --function-name ecovolt-dev-api-handler \
  --region eu-central-1

echo "✅ API Handler deployed successfully"

# Deploy to IoT Processor Lambda (if needed)
aws lambda update-function-code \
  --function-name ecovolt-dev-iot-processor \
  --zip-file fileb://lambda-deployment.zip \
  --region eu-central-1

echo "✅ IoT Processor deployed successfully"
```

---

### Step 3: Apply Terraform Changes (Optional - Minor Dashboard Updates)

```bash
cd /Users/thekloudwiz/project-ecovolt/infra

# Review plan (should show 0 infrastructure changes, 2 monitoring updates)
terraform plan -var-file="environments/dev.tfvars"

# Apply changes
terraform apply -var-file="environments/dev.tfvars"
```

**Note:** This step is optional since there are no critical infrastructure changes.

---

### Step 4: Verify Bikes Endpoint

```bash
# Test bikes endpoint
curl -s 'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/admin/bikes?page=1&page_size=20' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  | python3 -m json.tool

# Expected response (200 OK):
# {
#   "bikes": [
#     {
#       "bike_id": "BIKE-001",
#       "user_id": "...",
#       "battery_id": "BAT-001",
#       "model": "...",
#       "status": "active",
#       "battery_level": 85,
#       "odometer": 1234.5,
#       "last_swap": "2025-11-26T10:30:00",
#       "created_at": "2025-01-15T08:00:00",
#       "latest_telemetry": null
#     },
#     ...
#   ],
#   "pagination": {
#     "page": 1,
#     "page_size": 20,
#     "total_count": 5,
#     "total_pages": 1,
#     "has_next": false,
#     "has_prev": false
#   }
# }
```

**Success criteria:**
- ✅ HTTP 200 OK status
- ✅ Returns bikes array
- ✅ Pagination metadata present
- ✅ No ResourceNotFoundException error

---

### Step 5: Verify Lambda Environment Variables

```bash
# Check that Lambda has correct table name
aws lambda get-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --region eu-central-1 \
  --query 'Environment.Variables.DYNAMODB_TELEMETRY_TABLE' \
  --output text

# Expected: ecovolt-dev-bike-status
```

---

### Step 6: Check CloudWatch Logs

```bash
# Monitor logs for errors
aws logs tail /aws/lambda/ecovolt-dev-api-handler \
  --region eu-central-1 \
  --since 5m \
  --follow

# Look for:
# ✅ "auth_success" events
# ✅ "request_completed" with status_code: 200
# ❌ NO "ResourceNotFoundException" errors
# ⚠️  "Could not fetch telemetry" is OK (table is empty)
```

---

### Step 7: Test in Browser

Open admin portal and test both pages:

**Bikes Page:**
```
https://dev-admin.ecovolt.thekloudwiz.com/bikes
```
- ✅ Should load without errors
- ✅ Should display list of bikes
- ✅ "latest_telemetry" may be null (expected)

**Stations Page:**
```
https://dev-admin.ecovolt.thekloudwiz.com/stations
```
- ⚠️ If white page persists, check browser console for frontend errors
- ✅ API returns 8 stations correctly
- 🔍 Issue is frontend React component rendering

---

## 🧪 Post-Deployment Verification

### Lambda Function
- [ ] Code deployed successfully
- [ ] No deployment errors in CloudWatch
- [ ] Function is in "Active" state
- [ ] Environment variable `DYNAMODB_TELEMETRY_TABLE` = `ecovolt-dev-bike-status`

### API Endpoints
- [ ] `/admin/bikes` returns 200 OK
- [ ] `/admin/bikes` returns bikes array with pagination
- [ ] `/admin/stations` returns 200 OK (already working)
- [ ] `/admin/dashboard` returns 200 OK (already working)

### DynamoDB
- [ ] Table `ecovolt-dev-bike-status` exists
- [ ] Table has hash key `bikeId`
- [ ] Table has GSIs: `UserBikesIndex`, `BatteryLevelIndex`

### CloudWatch Logs
- [ ] No `ResourceNotFoundException` errors
- [ ] No `Invalid or expired token` errors
- [ ] Shows `auth_success` events
- [ ] Shows `request_completed` with status 200

---

## 🔍 Troubleshooting

### If Bikes Endpoint Returns 500 Error

**Check CloudWatch logs:**
```bash
aws logs tail /aws/lambda/ecovolt-dev-api-handler \
  --region eu-central-1 \
  --filter-pattern "ERROR" \
  --since 10m
```

**Common issues:**
1. Lambda still has old code → Redeploy
2. Environment variable not updated → Run terraform apply
3. DynamoDB table doesn't exist → Check table list

### If Stations Page Shows White Screen

**The API works, so this is a frontend issue:**

1. **Open browser DevTools (F12)**
2. **Check Console tab for errors**
3. **Possible issues:**
   - React component crash
   - Missing error boundary
   - State management issue
   - JSON parsing error

**File to check:**
```
application/admin-portal/src/pages/Stations.tsx
```

**Quick frontend fix:**
Add error boundary or try-catch in the component render method.

---

## 📊 Deployment Summary

### What Was Fixed

| Issue | Fix | Status |
|-------|-----|--------|
| Bikes endpoint 500 error | Updated table name + query key | ✅ Ready |
| ResourceNotFoundException | Changed to `bikeId` key | ✅ Ready |
| Terminology inconsistency | All "vehicle" → "bike" | ✅ Complete |
| Missing error handling | Added try-except for telemetry | ✅ Complete |
| Stations white page | Frontend issue (API works) | 🔍 Needs investigation |

### What's Deployed

**Backend Code:**
- ✅ Query uses `bikeId` key
- ✅ Graceful error handling
- ✅ Correct table name

**Infrastructure:**
- ✅ DynamoDB table exists with correct schema
- ✅ Terraform state aligned
- ✅ Lambda env vars configured

---

## 🎯 Expected Results

After deployment:

**Bikes Page:**
```json
{
  "bikes": [...],
  "pagination": {...}
}
```
✅ **200 OK** - List of bikes returned

**Stations Page:**
- Backend: ✅ **200 OK** - 8 stations returned
- Frontend: 🔍 May need React component fix

**Dashboard:**
✅ **200 OK** - Already working

---

## 📝 Next Steps After Deployment

1. ✅ Deploy Lambda code (Step 1-2)
2. ✅ Verify bikes endpoint (Step 4)
3. 🔍 If Stations page still white:
   - Investigate frontend component
   - Check browser console
   - Review `Stations.tsx` React code

4. 📊 (Optional) Populate bike telemetry data:
   - Insert sample records into `ecovolt-dev-bike-status` table
   - Test that `latest_telemetry` appears in bikes response

---

## ⏱️ Estimated Time

- Build Lambda package: ~2 minutes
- Deploy Lambda: ~1 minute
- Terraform apply: ~2 minutes (optional)
- Verification: ~2 minutes

**Total: ~5-7 minutes**

---

## ✅ Success Criteria

Deployment is successful when:

1. ✅ Bikes endpoint returns 200 OK
2. ✅ Bikes list displays in admin portal
3. ✅ No ResourceNotFoundException errors in logs
4. ✅ Lambda environment variable points to `ecovolt-dev-bike-status`
5. ✅ DynamoDB queries use `bikeId` key

---

**Ready to deploy!** 🚀

Use the commands above to build and deploy the Lambda package.

---

*Deployment checklist by Senior Lead Architect*
*Date: November 27, 2025*
