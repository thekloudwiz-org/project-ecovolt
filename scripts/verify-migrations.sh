#!/bin/bash
# Verify Database Migrations
# Checks if migrations were successfully applied

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-eu-central-1}

echo "🔍 Verifying migrations for environment: $ENVIRONMENT"
echo ""

# 1. Check Lambda function exists
echo "1️⃣  Checking Lambda function..."
if aws lambda get-function --function-name "ecovolt-${ENVIRONMENT}-db-migrator" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Lambda function exists${NC}"
else
    echo -e "${RED}❌ Lambda function not found${NC}"
    exit 1
fi

# 2. Check CloudWatch logs
echo ""
echo "2️⃣  Checking recent CloudWatch logs..."
RECENT_LOGS=$(aws logs filter-log-events \
    --log-group-name "/aws/lambda/ecovolt-${ENVIRONMENT}-db-migrator" \
    --start-time $(($(date +%s) - 3600))000 \
    --region "$AWS_REGION" \
    --query 'events[*].message' \
    --output text 2>/dev/null || echo "")

if [ -n "$RECENT_LOGS" ]; then
    echo -e "${GREEN}✅ Found recent logs${NC}"
    echo "$RECENT_LOGS" | grep -E "(Migration Summary|applied successfully|Skipping)" | tail -10
else
    echo -e "${YELLOW}⚠️  No recent logs found (Lambda may not have been invoked yet)${NC}"
fi

# 3. Check S3 migration files
echo ""
echo "3️⃣  Checking S3 migration files..."
BUCKET=$(aws ssm get-parameter \
    --name "/ecovolt/${ENVIRONMENT}/deployment/bucket" \
    --query Parameter.Value \
    --output text \
    --region "$AWS_REGION" 2>/dev/null || echo "")

if [ -n "$BUCKET" ]; then
    MIGRATION_COUNT=$(aws s3 ls "s3://${BUCKET}/migrations/${ENVIRONMENT}/" --region "$AWS_REGION" 2>/dev/null | grep -c ".sql" || echo "0")
    if [ "$MIGRATION_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Found $MIGRATION_COUNT migration file(s) in S3${NC}"
        aws s3 ls "s3://${BUCKET}/migrations/${ENVIRONMENT}/" --region "$AWS_REGION" | grep ".sql"
    else
        echo -e "${YELLOW}⚠️  No migration files found in S3${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not determine S3 bucket${NC}"
fi

# 4. Test Lambda invocation (dry-run)
echo ""
echo "4️⃣  Testing Lambda invocation (dry-run)..."
if [ -n "$BUCKET" ]; then
    RESPONSE=$(aws lambda invoke \
        --function-name "ecovolt-${ENVIRONMENT}-db-migrator" \
        --payload "{\"s3_bucket\":\"${BUCKET}\",\"s3_prefix\":\"migrations/${ENVIRONMENT}/\",\"dry_run\":true}" \
        --cli-binary-format raw-in-base64-out \
        --region "$AWS_REGION" \
        /tmp/migration-test.json 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Lambda invocation successful${NC}"
        cat /tmp/migration-test.json | jq '.' 2>/dev/null || cat /tmp/migration-test.json
    else
        echo -e "${RED}❌ Lambda invocation failed${NC}"
        echo "$RESPONSE"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping Lambda test (no S3 bucket)${NC}"
fi

# 5. Summary
echo ""
echo "========================================="
echo "📊 Verification Summary"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"
echo ""
echo "Next steps:"
echo "1. Check GitHub Actions workflow logs"
echo "2. Query database: SELECT * FROM schema_migrations;"
echo "3. Verify table counts match seed data"
echo ""
echo "To connect to database:"
echo "  ./scripts/run-migrations.sh $ENVIRONMENT $AWS_REGION"
