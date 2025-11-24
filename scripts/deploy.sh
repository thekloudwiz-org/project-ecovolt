#!/bin/bash
# EcoVolt Deployment Script
# Automates the deployment of EcoVolt infrastructure to AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="."
BACKEND_DIR="application/backend"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}EcoVolt Deployment Script${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v terraform &> /dev/null; then
    print_error "Terraform not found. Please install Terraform."
    exit 1
fi
print_status "Terraform found: $(terraform version | head -n1)"

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install AWS CLI."
    exit 1
fi
print_status "AWS CLI found: $(aws --version)"

if ! command -v python3 &> /dev/null; then
    print_error "Python 3 not found. Please install Python 3.11+."
    exit 1
fi
print_status "Python found: $(python3 --version)"

# Verify AWS credentials
echo ""
echo -e "${BLUE}Verifying AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Run 'aws configure'."
    exit 1
fi
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)
print_status "AWS Account: $AWS_ACCOUNT"
print_status "AWS Region: $AWS_REGION"

# Confirm deployment
echo ""
echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}Ready to deploy to ${ENVIRONMENT}${NC}"
echo -e "${YELLOW}AWS Account: $AWS_ACCOUNT${NC}"
echo -e "${YELLOW}AWS Region: $AWS_REGION${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo ""
read -p "Continue with deployment? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Initialize Terraform
echo ""
echo -e "${BLUE}Initializing Terraform...${NC}"
cd $TERRAFORM_DIR
terraform init
print_status "Terraform initialized"

# Validate Terraform configuration
echo ""
echo -e "${BLUE}Validating Terraform configuration...${NC}"
terraform validate
print_status "Terraform configuration valid"

# Create Terraform plan
echo ""
echo -e "${BLUE}Creating Terraform plan...${NC}"
terraform plan \
    -var-file="environments/${ENVIRONMENT}.tfvars" \
    -out="${ENVIRONMENT}.tfplan"
print_status "Terraform plan created"

# Review plan
echo ""
echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}Please review the Terraform plan above${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo ""
read -p "Apply this plan? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled."
    rm "${ENVIRONMENT}.tfplan"
    exit 0
fi

# Apply Terraform plan
echo ""
echo -e "${BLUE}Applying Terraform plan...${NC}"
terraform apply "${ENVIRONMENT}.tfplan"
print_status "Infrastructure deployed"

# Clean up plan file
rm "${ENVIRONMENT}.tfplan"

# Capture outputs
echo ""
echo -e "${BLUE}Capturing deployment outputs...${NC}"
terraform output > "deployment-outputs-${ENVIRONMENT}.txt"
print_status "Outputs saved to deployment-outputs-${ENVIRONMENT}.txt"

# Get key outputs
API_URL=$(terraform output -raw api_gateway_invoke_url 2>/dev/null || echo "N/A")
DB_ENDPOINT=$(terraform output -raw db_endpoint 2>/dev/null || echo "N/A")
COGNITO_POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "N/A")

# Display summary
echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${BLUE}Key Endpoints:${NC}"
echo -e "  API Gateway URL: ${GREEN}$API_URL${NC}"
echo -e "  Database Endpoint: ${GREEN}$DB_ENDPOINT${NC}"
echo -e "  Cognito Pool ID: ${GREEN}$COGNITO_POOL_ID${NC}"
echo ""

# Check if database migrations are needed
if [ "$DB_ENDPOINT" != "N/A" ]; then
    echo -e "${YELLOW}=========================================${NC}"
    echo -e "${YELLOW}Next Steps:${NC}"
    echo -e "${YELLOW}=========================================${NC}"
    echo ""
    echo "1. Run database migrations:"
    echo -e "   ${BLUE}cd $BACKEND_DIR/migrations${NC}"
    echo -e "   ${BLUE}psql -h $DB_ENDPOINT -U ecovolt_admin -d ecovolt -f 001_initial_schema.sql${NC}"
    echo -e "   ${BLUE}psql -h $DB_ENDPOINT -U ecovolt_admin -d ecovolt -f 002_add_indexes.sql${NC}"
    echo -e "   ${BLUE}psql -h $DB_ENDPOINT -U ecovolt_admin -d ecovolt -f 003_seed_data.sql${NC}"
    echo ""
    echo "2. Test the API:"
    echo -e "   ${BLUE}curl ${API_URL}/health${NC}"
    echo ""
    echo "3. View logs:"
    echo -e "   ${BLUE}aws logs tail /aws/lambda/ecovolt-${ENVIRONMENT}-api-handler --follow${NC}"
    echo ""
fi

echo -e "${GREEN}Deployment script completed successfully!${NC}"
