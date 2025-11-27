# Fix for Bikes and Stations Pages

**Date:** November 27, 2025
**Issue:** Bikes page shows DynamoDB ResourceNotFoundException, Stations shows white page

---

## 🐛 Root Cause Analysis

### Bikes Page Error
```
Error: An error occurred (ResourceNotFoundException) when calling the Query operation: Requested resource not found
```

**Root causes identified:**
1. ❌ Lambda env var pointed to non-existent table: `dev-bike-telemetry`
2. ✅ Actual DynamoDB table is: `ecovolt-dev-bike-status`
3. ❌ Code queried with key `bike_id`, but table uses `bikeId`
4. ❌ No error handling when telemetry data is missing

### Stations Page (White Screen)
- ✅ **API endpoint works perfectly** (returns 200 OK with 8 stations)
- ❌ **Frontend rendering issue** (not a backend problem)

---

## ✅ Fixes Applied

### 1. Backend Code Fix (`application/backend/api/admin.py`)

**File:** `application/backend/api/admin.py` (lines 1115-1156)

**Changes:**
- ✅ Updated default table name: `ecovolt-dev-bike-status` (not `ecovolt-dev-bike-telemetry`)
- ✅ Fixed query key: `bikeId` (not `bike_id`) to match DynamoDB schema
- ✅ Fixed attribute names: `batteryLevel`, `lastUpdated` (not `battery_level`, `timestamp`)
- ✅ Added try-except block: Gracefully handle missing telemetry without crashing
- ✅ Set `latest_telemetry: null` when data unavailable

**Code snippet:**
```python
# Get latest telemetry (gracefully handle missing table or data)
try:
    # Try with bikeId key (matches DynamoDB table schema)
    telemetry_items = DynamoDBHelper.query(
        table_name=telemetry_table,
        key_condition='bikeId = :bikeId',
        expression_values={':bikeId': bike['bike_id']}
    )

    if telemetry_items:
        telemetry_items.sort(key=lambda x: x.get('lastUpdated', 0), reverse=True)
        latest = telemetry_items[0]
        bike_data['latest_telemetry'] = {
            'battery_level': latest.get('batteryLevel'),
            'location': latest.get('location'),
            'timestamp': latest.get('lastUpdated')
        }
except Exception as telemetry_error:
    # Log but don't fail - telemetry is optional
    print(f"Could not fetch telemetry for bike {bike['bike_id']}: {str(telemetry_error)}")
    bike_data['latest_telemetry'] = None
```

### 2. Terraform Infrastructure Fix (`infra/modules/compute/main.tf`)

**Files changed:**
- `infra/modules/compute/main.tf` (lines 382-383, 459-460)

**Changes:**
- ✅ Changed from hardcoded table names to dynamic lookup from DynamoDB module
- ✅ Lambda now gets correct table name: `ecovolt-dev-bike-status`
- ✅ Applied to both API handler and IoT processor Lambdas

**Before:**
```hcl
DYNAMODB_BATTERIES_TABLE = "${var.environment}-batteries"
DYNAMODB_TELEMETRY_TABLE = "${var.environment}-bike-telemetry"  # ❌ Table doesn't exist
```

**After:**
```hcl
DYNAMODB_BATTERIES_TABLE = lookup(var.dynamodb_table_names, "battery_inventory", "${var.environment}-batteries")
DYNAMODB_TELEMETRY_TABLE = lookup(var.dynamodb_table_names, "bike_status", "${var.environment}-bike-status")  # ✅ Correct table
```

---

## 🚀 Deployment Steps

### Step 1: Build Lambda Package (Linux-compatible)

```bash
cd /Users/thekloudwiz/project-ecovolt

# Build Lambda package using Docker (ensures Linux compatibility)
./scripts/build_lambda_package_docker.sh
```

**This will:**
- Use AWS Lambda Python 3.11 container
- Install dependencies for Linux
- Create `lambda-deployment.zip`

### Step 2: Deploy Lambda Code

```bash
# Deploy to API Handler Lambda
aws lambda update-function-code \
  --function-name ecovolt-dev-api-handler \
  --zip-file fileb://lambda-deployment.zip \
  --region eu-central-1

# Wait for deployment to complete
aws lambda wait function-updated-v2 \
  --function-name ecovolt-dev-api-handler \
  --region eu-central-1

# Deploy to IoT Processor Lambda (if needed)
aws lambda update-function-code \
  --function-name ecovolt-dev-iot-processor \
  --zip-file fileb://lambda-deployment.zip \
  --region eu-central-1
```

### Step 3: Apply Terraform Changes (Update Environment Variables)

```bash
cd /Users/thekloudwiz/project-ecovolt/infra

# Plan to see what will change
terraform plan -var-file="environments/dev.tfvars"

# Apply the changes (updates Lambda environment variables)
terraform apply -var-file="environments/dev.tfvars"
```

**Expected changes:**
- `DYNAMODB_TELEMETRY_TABLE` will change from `dev-bike-telemetry` → `ecovolt-dev-bike-status`

### Step 4: Verify Bikes Endpoint

```bash
# Test bikes endpoint
curl 'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/admin/bikes?page=1&page_size=20' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' | python3 -m json.tool

# Should return:
# {
#   "bikes": [...],
#   "pagination": {...}
# }
```

### Step 5: Verify Stations (Frontend Fix)

The Stations API works correctly. If the frontend shows a white page:

1. **Check browser console for JavaScript errors:**
   - Open Developer Tools (F12)
   - Check Console tab for errors

2. **Possible frontend issues:**
   - Missing error handling in Stations component
   - JSON parsing error
   - State management issue

3. **Frontend file to check:**
   ```
   application/admin-portal/src/pages/Stations.tsx
   ```

---

## 📊 Current DynamoDB Tables

| Table Name | Purpose | Hash Key |
|------------|---------|----------|
| `ecovolt-dev-battery-inventory` | Battery tracking at stations | `batteryId` |
| `ecovolt-dev-stations` | Station locations and details | `stationId` |
| `ecovolt-dev-swap-events` | Battery swap transactions | `swapId` |
| `ecovolt-dev-user-profiles` | User profiles (DynamoDB) | `userId` |
| `ecovolt-dev-bike-status` | **bike telemetry** | `bikeId` |

**Note:** There is NO `dev-bike-telemetry` or `ecovolt-dev-bike-telemetry` table.

---

## 🧪 Testing After Deployment

### Test 1: Bikes Endpoint (Backend)

```bash
# Should return 200 OK with bikes list
curl -s 'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/admin/bikes?page=1&page_size=20' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  | python3 -m json.tool
```

**Expected response:**
```json
{
  "bikes": [
    {
      "bike_id": "BIKE-001",
      "user_id": "user123",
      "battery_id": "BAT-001",
      "model": "EcoVolt Model X",
      "status": "active",
      "battery_level": 85,
      "odometer": 1234.5,
      "last_swap": "2025-11-26T10:30:00",
      "created_at": "2025-01-15T08:00:00",
      "latest_telemetry": null  // Will be null until telemetry data is populated
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total_count": 5,
    "total_pages": 1,
    "has_next": false,
    "has_prev": false
  }
}
```

### Test 2: Stations Endpoint (Already Working)

```bash
# Should return 200 OK with 8 stations
curl -s 'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/admin/stations?page=1&page_size=20' \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  | python3 -m json.tool
```

**Status:** ✅ Already returns 8 stations correctly

### Test 3: CloudWatch Logs

```bash
# Check for errors
aws logs tail /aws/lambda/ecovolt-dev-api-handler \
  --region eu-central-1 \
  --since 5m \
  --filter-pattern 'ERROR'

# Check bikes endpoint logs
aws logs tail /aws/lambda/ecovolt-dev-api-handler \
  --region eu-central-1 \
  --since 5m \
  --filter-pattern 'bikes'
```

**Expected after fix:**
- ✅ No ResourceNotFoundException errors
- ✅ "Could not fetch telemetry" messages are OK (telemetry table is empty)
- ✅ Status code: 200

---

## 🔍 Frontend Investigation (Stations White Page)

Since the API works, the white page is a frontend issue. Check:

### File to Investigate:
```
application/admin-portal/src/pages/Stations.tsx
```

### Common Issues:

1. **Missing error boundary:**
   - React component crashes without error handling
   - Add try-catch or Error Boundary

2. **State management:**
   - Check if `useState` or `useEffect` has issues
   - Verify data fetching logic

3. **Conditional rendering:**
   - Check if component returns null/undefined in some cases
   - Add loading states

### Quick Frontend Fix Template:

```typescript
// In Stations.tsx or similar
try {
  // Existing stations rendering code
  return (
    <div>
      {stations.map(station => (
        <StationCard key={station.station_id} station={station} />
      ))}
    </div>
  );
} catch (error) {
  console.error('Error rendering stations:', error);
  return (
    <div>
      <p>Error loading stations. Please refresh the page.</p>
      <p>{error.message}</p>
    </div>
  );
}
```

---

## 📝 Summary of Changes

### Backend (`admin.py`)
- ✅ Fixed telemetry table name
- ✅ Fixed DynamoDB query key name
- ✅ Fixed attribute name mappings
- ✅ Added graceful error handling

### Infrastructure (`main.tf`)
- ✅ Dynamic table name lookup from DynamoDB module
- ✅ Correct table name: `ecovolt-dev-bike-status`

### Deployment
- ✅ Use Docker-based build for Linux compatibility
- ✅ Deploy via AWS Lambda update-function-code
- ✅ Apply Terraform to update environment variables

---

## ⚠️ Known Limitations

1. **Telemetry data is empty:** The `bike_status` table has no data yet
   - Bikes will return `"latest_telemetry": null`
   - This is expected and won't cause errors

2. **Stations frontend:** White page is a frontend rendering issue
   - API works correctly (returns 8 stations)
   - Need to check React component

---

## 🎯 Next Steps

1. ✅ Deploy Lambda code (Docker build + AWS CLI)
2. ✅ Apply Terraform changes (environment variables)
3. ✅ Verify bikes endpoint returns 200 OK
4. 🔍 Investigate Stations frontend component (white page)
5. 📊 (Optional) Populate bike_status table with telemetry data

---

*Fix documented by Senior Lead Architect*
*Date: November 27, 2025*
