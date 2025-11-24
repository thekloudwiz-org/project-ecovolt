#!/bin/bash
# Script to verify OIDC setup for GitHub Actions
# Organization: thekloudwiz-org

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== EcoVolt OIDC Setup Verification ===${NC}\n"

# Get repository name
echo -e "${YELLOW}Enter your repository name (e.g., ecovolt-infrastructure):${NC}"
read REPO_NAME

if [ -z "$REPO_NAME" ]; then
    echo -e "${RED}Error: Repository name is required${NC}"
    exit 1
fi

FULL_REPO="thekloudwiz-org/$REPO_NAME"
echo -e "${GREEN}✓ Using repository: $FULL_REPO${NC}\n"

# Check if OIDC provider exists
echo -e "${BLUE}1. Checking OIDC Provider...${NC}"
OIDC_ARN=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[?contains(Arn, 'token.actions.githubusercontent.com')].Arn" --output text)

if [ -z "$OIDC_ARN" ]; then
    echo -e "${RED}✗ OIDC provider not found${NC}"
    echo -e "${YELLOW}Creating OIDC provider...${NC}"
    
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
    
    echo -e "${GREEN}✓ OIDC provider created${NC}"
else
    echo -e "${GREEN}✓ OIDC provider exists: $OIDC_ARN${NC}"
fi

echo ""

# Check IAM roles
echo -e "${BLUE}2. Checking IAM Roles...${NC}"

for ENV in dev staging prod; do
    echo -e "${YELLOW}Checking $ENV role...${NC}"
    
    # Try common role names
    ROLE_NAMES=(
        "github-actions-$ENV"
        "GitHubActions-$ENV"
        "ecovolt-github-actions-$ENV"
        "GithubActionsRole-$ENV"
    )
    
    ROLE_FOUND=false
    for ROLE_NAME in "${ROLE_NAMES[@]}"; do
        if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
            ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
            echo -e "${GREEN}✓ Found role: $ROLE_NAME${NC}"
            echo -e "  ARN: $ROLE_ARN"
            
            # Check trust policy
            TRUST_POLICY=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.AssumeRolePolicyDocument' --output json)
            
            if echo "$TRUST_POLICY" | grep -q "token.actions.githubusercontent.com"; then
                echo -e "${GREEN}  ✓ Trust policy includes GitHub OIDC${NC}"
                
                if echo "$TRUST_POLICY" | grep -q "$FULL_REPO"; then
                    echo -e "${GREEN}  ✓ Trust policy includes your repository${NC}"
                else
                    echo -e "${YELLOW}  ⚠ Trust policy does NOT include your repository${NC}"
                    echo -e "${YELLOW}  Update the trust policy to include: repo:$FULL_REPO:*${NC}"
                fi
            else
                echo -e "${RED}  ✗ Trust policy does NOT include GitHub OIDC${NC}"
            fi
            
            ROLE_FOUND=true
            break
        fi
    done
    
    if [ "$ROLE_FOUND" = false ]; then
        echo -e "${RED}✗ No role found for $ENV environment${NC}"
        echo -e "${YELLOW}  Tried: ${ROLE_NAMES[*]}${NC}"
    fi
    
    echo ""
done

# Summary
echo -e "${BLUE}=== Summary ===${NC}\n"
echo -e "Repository: ${GREEN}$FULL_REPO${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Add GitHub secrets with the role ARNs shown above"
echo "2. Ensure trust policies include: repo:$FULL_REPO:*"
echo "3. Test with a PR to the dev branch"
echo ""
echo -e "${BLUE}To add GitHub secrets:${NC}"
echo "gh secret set AWS_ROLE_ARN_DEV --body \"<DEV_ROLE_ARN>\""
echo "gh secret set AWS_ROLE_ARN_STAGING --body \"<STAGING_ROLE_ARN>\""
echo "gh secret set AWS_ROLE_ARN_PROD --body \"<PROD_ROLE_ARN>\""
echo ""
