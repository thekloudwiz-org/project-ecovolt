#!/bin/bash
# Quick setup for EcoVolt CI/CD prerequisites

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BUCKET_NAME="ecovolt-deployments"
REGION="us-east-1"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}EcoVolt CI/CD Prerequisites Setup${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
echo -e "${BLUE}🔐 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    echo "Please run: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS Account: $ACCOUNT_ID${NC}"
echo ""

# Create deployment bucket
echo -e "${BLUE}📦 Creating S3 bucket: $BUCKET_NAME${NC}"
if aws s3 ls s3://$BUCKET_NAME 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Bucket already exists${NC}"
else
    aws s3 mb s3://$BUCKET_NAME --region $REGION
    echo -e "${GREEN}✅ Bucket created${NC}"
fi

# Enable versioning
echo -e "${BLUE}🔄 Enabling versioning...${NC}"
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled
echo -e "${GREEN}✅ Versioning enabled${NC}"

# Block public access
echo -e "${BLUE}🔒 Blocking public access...${NC}"
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo -e "${GREEN}✅ Public access blocked${NC}"

# Add lifecycle policy
echo -e "${BLUE}🗑️  Adding lifecycle policy (delete old versions after 30 days)...${NC}"
cat > /tmp/lifecycle-policy.json << 'EOF'
{
  "Rules": [
    {
      "Id": "DeleteOldLambdaPackages",
      "Status": "Enabled",
      "Prefix": "backend/",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 30
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket $BUCKET_NAME \
  --lifecycle-configuration file:///tmp/lifecycle-policy.json
echo -e "${GREEN}✅ Lifecycle policy added${NC}"

# Create folder structure
echo -e "${BLUE}📁 Creating folder structure...${NC}"
aws s3api put-object --bucket $BUCKET_NAME --key backend/dev/ || true
aws s3api put-object --bucket $BUCKET_NAME --key backend/staging/ || true
aws s3api put-object --bucket $BUCKET_NAME --key backend/prod/ || true
echo -e "${GREEN}✅ Folder structure created${NC}"

# Add bucket tagging
echo -e "${BLUE}🏷️  Adding tags...${NC}"
aws s3api put-bucket-tagging \
  --bucket $BUCKET_NAME \
  --tagging 'TagSet=[{Key=Project,Value=EcoVolt},{Key=ManagedBy,Value=Script},{Key=Purpose,Value=CI-CD-Deployments}]'
echo -e "${GREEN}✅ Tags added${NC}"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "  Bucket: ${GREEN}s3://$BUCKET_NAME${NC}"
echo -e "  Region: ${GREEN}$REGION${NC}"
echo -e "  Versioning: ${GREEN}Enabled${NC}"
echo -e "  Public Access: ${GREEN}Blocked${NC}"
echo -e "  Lifecycle: ${GREEN}30 days retention${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo ""
echo -e "${BLUE}1. Configure GitHub Secrets:${NC}"
echo "   Go to: GitHub Repository → Settings → Secrets and variables → Actions"
echo ""
echo "   Add these secrets:"
echo -e "   ${YELLOW}AWS_ROLE_ARN_DEV${NC}"
echo "   Value: arn:aws:iam::$ACCOUNT_ID:role/GitHubActions-EcoVolt-Dev"
echo ""
echo -e "   ${YELLOW}AWS_ROLE_ARN_STAGING${NC}"
echo "   Value: arn:aws:iam::$ACCOUNT_ID:role/GitHubActions-EcoVolt-Staging"
echo ""
echo -e "   ${YELLOW}AWS_ROLE_ARN_PROD${NC}"
echo "   Value: arn:aws:iam::$ACCOUNT_ID:role/GitHubActions-EcoVolt-Prod"
echo ""
echo -e "   ${YELLOW}DEPLOYMENT_BUCKET${NC}"
echo "   Value: $BUCKET_NAME"
echo ""
echo -e "${BLUE}2. Create GitHub Environments:${NC}"
echo "   Go to: GitHub Repository → Settings → Environments"
echo "   Create: dev, staging, prod"
echo ""
echo -e "${BLUE}3. Test the Pipeline:${NC}"
echo "   git add ."
echo "   git commit -m \"test: Trigger CI/CD\""
echo "   git push origin dev"
echo ""
echo -e "${BLUE}4. Monitor Deployment:${NC}"
echo "   GitHub Actions: https://github.com/thekloudwiz-org/project-ecovolt/actions"
echo ""
echo -e "${GREEN}🎉 You're all set!${NC}"
