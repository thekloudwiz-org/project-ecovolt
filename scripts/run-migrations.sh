#!/bin/bash
# EcoVolt Database Migration Script
# Runs SQL migrations against RDS PostgreSQL database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if environment is provided
if [ -z "$1" ]; then
    print_error "Usage: $0 <environment> [aws-region]"
    echo "Example: $0 dev eu-central-1"
    exit 1
fi

ENVIRONMENT=$1
AWS_REGION=${2:-eu-central-1}

print_info "Running migrations for environment: $ENVIRONMENT"
print_info "AWS Region: $AWS_REGION"

# Check if required tools are installed
if ! command -v psql &> /dev/null; then
    print_error "PostgreSQL client (psql) is not installed"
    echo "Install it with: sudo apt-get install postgresql-client (Ubuntu/Debian)"
    echo "Or: brew install postgresql (macOS)"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    echo "Install it from: https://aws.amazon.com/cli/"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_error "jq is not installed"
    echo "Install it with: sudo apt-get install jq (Ubuntu/Debian)"
    echo "Or: brew install jq (macOS)"
    exit 1
fi

# Get database credentials from Secrets Manager
print_info "Fetching database credentials from Secrets Manager..."

SECRET_NAME="${ENVIRONMENT}/ecovolt/db/master"

if ! DB_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$AWS_REGION" \
    --query SecretString \
    --output text 2>&1); then
    print_error "Failed to fetch database credentials"
    echo "$DB_SECRET"
    exit 1
fi

# Parse credentials
DB_HOST=$(echo "$DB_SECRET" | jq -r '.host')
DB_PORT=$(echo "$DB_SECRET" | jq -r '.port')
DB_NAME=$(echo "$DB_SECRET" | jq -r '.dbname')
DB_USER=$(echo "$DB_SECRET" | jq -r '.username')
DB_PASSWORD=$(echo "$DB_SECRET" | jq -r '.password')

# Validate credentials
if [ -z "$DB_HOST" ] || [ "$DB_HOST" = "null" ]; then
    print_error "Invalid database credentials retrieved"
    exit 1
fi

# Set PostgreSQL password environment variable
export PGPASSWORD="$DB_PASSWORD"

print_success "Connected to database: $DB_NAME on $DB_HOST:$DB_PORT"
echo ""

# Test database connection
print_info "Testing database connection..."
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_error "Failed to connect to database"
    unset PGPASSWORD
    exit 1
fi
print_success "Database connection successful"
echo ""

# Create migrations tracking table if it doesn't exist
print_info "Setting up migrations tracking table..."
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << 'EOF'
CREATE TABLE IF NOT EXISTS schema_migrations (
    migration_id VARCHAR(50) PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT NOW()
);
EOF
print_success "Migrations tracking table ready"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MIGRATIONS_DIR="$SCRIPT_DIR/../application/backend/migrations"

# Check if migrations directory exists
if [ ! -d "$MIGRATIONS_DIR" ]; then
    print_error "Migrations directory not found: $MIGRATIONS_DIR"
    unset PGPASSWORD
    exit 1
fi

# Count total migrations
TOTAL_MIGRATIONS=$(ls -1 "$MIGRATIONS_DIR"/*.sql 2>/dev/null | wc -l)
if [ "$TOTAL_MIGRATIONS" -eq 0 ]; then
    print_warning "No migration files found in $MIGRATIONS_DIR"
    unset PGPASSWORD
    exit 0
fi

print_info "Found $TOTAL_MIGRATIONS migration file(s)"
echo ""

# Run migrations in order
APPLIED=0
SKIPPED=0
FAILED=0

for migration_file in "$MIGRATIONS_DIR"/*.sql; do
    migration_name=$(basename "$migration_file" .sql)
    
    # Check if migration has already been applied
    already_applied=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c \
        "SELECT COUNT(*) FROM schema_migrations WHERE migration_id = '$migration_name';" | tr -d ' ')
    
    if [ "$already_applied" -gt 0 ]; then
        print_warning "Skipping $migration_name (already applied)"
        ((SKIPPED++))
    else
        print_info "Applying $migration_name..."
        
        if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$migration_file" > /dev/null 2>&1; then
            # Record successful migration
            psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c \
                "INSERT INTO schema_migrations (migration_id) VALUES ('$migration_name');" > /dev/null 2>&1
            print_success "$migration_name applied successfully"
            ((APPLIED++))
        else
            print_error "Failed to apply $migration_name"
            ((FAILED++))
            unset PGPASSWORD
            exit 1
        fi
    fi
done

# Unset password
unset PGPASSWORD

echo ""
echo "========================================="
echo "📊 Migration Summary"
echo "========================================="
echo "✅ Applied: $APPLIED migration(s)"
echo "⏭️  Skipped: $SKIPPED migration(s)"
echo "❌ Failed: $FAILED migration(s)"
echo ""

if [ "$FAILED" -gt 0 ]; then
    print_error "Some migrations failed!"
    exit 1
elif [ "$APPLIED" -gt 0 ]; then
    print_success "All migrations completed successfully!"
    exit 0
else
    print_info "No new migrations to apply"
    exit 0
fi
