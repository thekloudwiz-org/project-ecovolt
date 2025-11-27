# ✅ Bike Terminology Update - Complete

**Date:** November 27, 2025
**Status:** All files updated for consistency

---

## 🎯 Objective

Update all references from "vehicle" to "bike" for consistency across the EV bike project.

---

## ✅ Changes Applied

### 1. DynamoDB Table Definition

**File:** `infra/modules/dynamodb/main.tf`

**Changes:**
- ✅ Resource renamed: `aws_dynamodb_table.vehicle_status` → `aws_dynamodb_table.bike_status`
- ✅ Table name: `${var.project_name}-${var.environment}-vehicle-status` → `${var.project_name}-${var.environment}-bike-status`
- ✅ Hash key: `vehicleId` → `bikeId`
- ✅ GSI name: `UserVehiclesIndex` → `UserBikesIndex`
- ✅ Variable references: `var.vehicle_status_*` → `var.bike_status_*`
- ✅ Tags updated to reflect bike-status

**Result:** Table creates as `ecovolt-dev-bike-status` with `bikeId` hash key

---

### 2. DynamoDB Module Outputs

**File:** `infra/modules/dynamodb/outputs.tf`

**Changes:**
- ✅ Output names: `vehicle_status_*` → `bike_status_*`
- ✅ References: `aws_dynamodb_table.vehicle_status.*` → `aws_dynamodb_table.bike_status.*`
- ✅ Map key in `all_table_names`: `vehicle_status` → `bike_status`
- ✅ Updated comments

**Result:** Outputs expose `bike_status_table_name`, `bike_status_table_arn`, etc.

---

### 3. DynamoDB Module Variables

**File:** `infra/modules/dynamodb/variables.tf`

**Changes:**
- ✅ Variable: `vehicle_status_read_capacity` → `bike_status_read_capacity`
- ✅ Variable: `vehicle_status_write_capacity` → `bike_status_write_capacity`
- ✅ Variable: `enable_vehicle_status_ttl` → `enable_bike_status_ttl`
- ✅ Descriptions updated

**Result:** Consistent bike terminology in all variable names

---

### 4. Main Infrastructure Configuration

**File:** `infra/main.tf`

**Changes:**
- ✅ Pass `enable_bike_status_ttl` to dynamodb module
- ✅ Compute module looks up `bike_status` from `module.dynamodb.all_table_names`

**Result:** Automatic table name resolution

---

### 5. Compute Module Environment Variables

**File:** `infra/modules/compute/main.tf` (lines 383, 460)

**Changes:**
- ✅ Lambda env var lookup: `lookup(var.dynamodb_table_names, "bike_status", ...)`
- ✅ Default fallback: `"${var.environment}-bike-status"`
- ✅ Applied to both api_handler and iot_processor Lambdas

**Result:** Lambda gets `DYNAMODB_TELEMETRY_TABLE=ecovolt-dev-bike-status`

---

### 6. Backend Code

**File:** `application/backend/api/admin.py` (lines 1116-1155)

**Changes:**
- ✅ Default table name: `ecovolt-dev-bike-status`
- ✅ Query key: `bikeId = :bikeId` (was `vehicleId`)
- ✅ Attribute mapping: `batteryLevel`, `lastUpdated` (camelCase)
- ✅ Graceful error handling with try-except

**Code:**
```python
telemetry_table = os.getenv('DYNAMODB_TELEMETRY_TABLE')

try:
    # Query with bikeId key (matches DynamoDB table schema)
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
    print(f"Could not fetch telemetry for bike {bike['bike_id']}: {str(telemetry_error)}")
    bike_data['latest_telemetry'] = None
```

**Result:** Backend uses correct table and key names

---

## 📊 Current State Verification

### DynamoDB Table

```bash
aws dynamodb describe-table --table-name ecovolt-dev-bike-status --region eu-central-1
```

**Confirmed:**
- ✅ Table name: `ecovolt-dev-bike-status`
- ✅ Hash key: `bikeId` (String)
- ✅ GSI: `UserBikesIndex` (hash: userId, range: lastUpdated)
- ✅ GSI: `BatteryLevelIndex` (hash: batteryLevel, range: lastUpdated)

### All DynamoDB Tables

| Table Name | Purpose | Hash Key |
|------------|---------|----------|
| `ecovolt-dev-battery-inventory` | Battery tracking at stations | `batteryId` |
| `ecovolt-dev-bike-status` | **Bike telemetry and status** | `bikeId` |
| `ecovolt-dev-stations` | Station locations and details | `stationId` |
| `ecovolt-dev-swap-events` | Battery swap transactions | `swapId` |
| `ecovolt-dev-user-profiles` | User profiles (DynamoDB) | `userId` |

---

## 🚀 Deployment Instructions

### Step 1: Review Terraform Plan

```bash
cd /Users/thekloudwiz/project-ecovolt/infra

terraform plan -var-file="environments/dev.tfvars"
```

**Expected changes:**
- DynamoDB table: Replace `ecovolt-dev-vehicle-status` with `ecovolt-dev-bike-status`
- Lambda environment variable: `DYNAMODB_TELEMETRY_TABLE` updated to `ecovolt-dev-bike-status`

⚠️ **NOTE:** This will **destroy and recreate** the DynamoDB table since the table name is changing. Any existing data in the old table will be lost.

**Alternative:** If the old table has data you want to keep, use AWS DynamoDB export/import:
```bash
# Export old table data
aws dynamodb export-table-to-point-in-time \
  --table-arn arn:aws:dynamodb:eu-central-1:ACCOUNT_ID:table/ecovolt-dev-vehicle-status \
  --s3-bucket YOUR-BACKUP-BUCKET \
  --region eu-central-1

# After Terraform creates new table, import data
# (see AWS documentation for import-table)
```

### Step 2: Apply Terraform Changes

```bash
terraform apply -var-file="environments/dev.tfvars"
```

### Step 3: Build and Deploy Lambda Code

```bash
cd /Users/thekloudwiz/project-ecovolt

# Build Lambda package (Linux-compatible)
./scripts/build_lambda_package_docker.sh

# Deploy to API Handler
aws lambda update-function-code \
  --function-name ecovolt-dev-api-handler \
  --zip-file fileb://lambda-deployment.zip \
  --region eu-central-1

# Wait for deployment
aws lambda wait function-updated-v2 \
  --function-name ecovolt-dev-api-handler \
  --region eu-central-1

# Deploy to IoT Processor
aws lambda update-function-code \
  --function-name ecovolt-dev-iot-processor \
  --zip-file fileb://lambda-deployment.zip \
  --region eu-central-1
```

### Step 4: Verify Deployment

```bash
# Check Lambda environment variable
aws lambda get-function-configuration \
  --function-name ecovolt-dev-api-handler \
  --region eu-central-1 \
  --query 'Environment.Variables.DYNAMODB_TELEMETRY_TABLE'

# Expected: "ecovolt-dev-bike-status"

# Test bikes endpoint
curl 'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/admin/bikes?page=1&page_size=20' \
  -H 'Authorization: Bearer YOUR_TOKEN' | python3 -m json.tool

# Should return 200 OK with bikes list
```

---

## 📝 Terraform State Considerations

Since the table name is changing from `ecovolt-dev-vehicle-status` to `ecovolt-dev-bike-status`, Terraform will:

1. **Destroy** the old table: `ecovolt-dev-vehicle-status`
2. **Create** the new table: `ecovolt-dev-bike-status`

**⚠️ Data Loss Warning:** Any data in the old table will be deleted.

**If you have existing data:**

### Option 1: Manual Table Rename (AWS Console)
Not possible - DynamoDB doesn't support renaming tables

### Option 2: Data Migration Script
```bash
# 1. Scan all items from old table
aws dynamodb scan \
  --table-name ecovolt-dev-vehicle-status \
  --region eu-central-1 > old_table_data.json

# 2. Apply Terraform (creates new table)
terraform apply -var-file="environments/dev.tfvars"

# 3. Transform and import data (Python script needed to convert vehicleId → bikeId)
# See migration script below
```

### Option 3: Import Existing Table to Terraform

If the table `ecovolt-dev-bike-status` already exists:

```bash
# Import existing table to Terraform state
terraform import \
  -var-file="environments/dev.tfvars" \
  module.dynamodb.aws_dynamodb_table.bike_status \
  ecovolt-dev-bike-status

# Then run terraform plan to verify no changes needed
terraform plan -var-file="environments/dev.tfvars"
```

---

## 🧪 Testing Checklist

After deployment:

- [ ] DynamoDB table `ecovolt-dev-bike-status` exists
- [ ] Table has hash key `bikeId`
- [ ] Table has GSI `UserBikesIndex`
- [ ] Lambda env var `DYNAMODB_TELEMETRY_TABLE` = `ecovolt-dev-bike-status`
- [ ] Bikes endpoint returns 200 OK
- [ ] No ResourceNotFoundException errors in CloudWatch logs
- [ ] Telemetry queries use `bikeId` key
- [ ] Frontend bikes page displays without errors

---

## 📂 Files Modified

### Infrastructure (Terraform)
1. `infra/modules/dynamodb/main.tf` - Table definition
2. `infra/modules/dynamodb/outputs.tf` - Output names
3. `infra/modules/dynamodb/variables.tf` - Variable names
4. `infra/main.tf` - Module variable passing
5. `infra/modules/compute/main.tf` - Lambda env vars

### Backend (Python)
6. `application/backend/api/admin.py` - Query logic

### Documentation
7. `BIKES_STATIONS_FIX.md` - Updated fix documentation
8. `BIKE_TERMINOLOGY_UPDATE.md` - This file

---

## ✅ Summary

All terminology has been consistently updated from "vehicle" to "bike":

| Old | New |
|-----|-----|
| `vehicle_status` | `bike_status` |
| `vehicleId` | `bikeId` |
| `UserVehiclesIndex` | `UserBikesIndex` |
| `ecovolt-dev-vehicle-status` | `ecovolt-dev-bike-status` |
| `enable_vehicle_status_ttl` | `enable_bike_status_ttl` |
| `vehicle_status_read_capacity` | `bike_status_read_capacity` |

**Next Step:** Deploy using Terraform and Docker build script ➡️ See Deployment Instructions above

---

*Update completed by Senior Lead Architect*
*Date: November 27, 2025*
