#!/usr/bin/env python3
"""
Fix Admin Client ID - Add Missing Environment Variable to Lambda

This script adds the COGNITO_ADMIN_CLIENT_ID environment variable
to the ecovolt-dev-api-handler Lambda function
"""

import boto3
import json
import sys

# Configuration
FUNCTION_NAME = "ecovolt-dev-api-handler"
REGION = "eu-central-1"
ADMIN_CLIENT_ID = "2h0hsagipne3d9l1phtk4ig29a"

# Colors
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
RED = '\033[0;31m'
NC = '\033[0m'  # No Color

def main():
    print(f"{YELLOW}========================================{NC}")
    print(f"{YELLOW}Fix Admin Client ID{NC}")
    print(f"{YELLOW}========================================{NC}")
    print()
    print(f"Function: {FUNCTION_NAME}")
    print(f"Region: {REGION}")
    print(f"Admin Client ID to add: {ADMIN_CLIENT_ID}")
    print()

    # Create Lambda client
    lambda_client = boto3.client('lambda', region_name=REGION)

    try:
        # Get current function configuration
        print(f"{YELLOW}📥 Fetching current environment variables...{NC}")
        response = lambda_client.get_function_configuration(FunctionName=FUNCTION_NAME)

        current_env = response['Environment']['Variables']

        # Check if COGNITO_ADMIN_CLIENT_ID already exists
        if 'COGNITO_ADMIN_CLIENT_ID' in current_env:
            existing_value = current_env['COGNITO_ADMIN_CLIENT_ID']
            print(f"{YELLOW}⚠️  COGNITO_ADMIN_CLIENT_ID already exists with value: {existing_value}{NC}")

            if existing_value == ADMIN_CLIENT_ID:
                print(f"{GREEN}✅ Already set to correct value! No update needed.{NC}")
                return

            user_input = input(f"Do you want to update it to {ADMIN_CLIENT_ID}? (y/n) ")
            if user_input.lower() != 'y':
                print(f"{RED}❌ Aborted{NC}")
                sys.exit(1)

        # Add COGNITO_ADMIN_CLIENT_ID
        print(f"{YELLOW}➕ Adding COGNITO_ADMIN_CLIENT_ID...{NC}")
        new_env = current_env.copy()
        new_env['COGNITO_ADMIN_CLIENT_ID'] = ADMIN_CLIENT_ID

        # Update Lambda function
        print(f"{YELLOW}🔄 Updating Lambda function...{NC}")
        lambda_client.update_function_configuration(
            FunctionName=FUNCTION_NAME,
            Environment={'Variables': new_env}
        )

        print(f"{GREEN}✅ Lambda function updated successfully!{NC}")
        print()

        # Verify the update
        print(f"{YELLOW}🔍 Verifying update...{NC}")
        updated_response = lambda_client.get_function_configuration(FunctionName=FUNCTION_NAME)
        updated_env = updated_response['Environment']['Variables']

        if updated_env.get('COGNITO_ADMIN_CLIENT_ID') == ADMIN_CLIENT_ID:
            print(f"{GREEN}✅ Verification successful!{NC}")
            print()
            print("Environment variables:")
            print(json.dumps({
                'COGNITO_APP_CLIENT_ID': updated_env.get('COGNITO_APP_CLIENT_ID'),
                'COGNITO_ADMIN_CLIENT_ID': updated_env.get('COGNITO_ADMIN_CLIENT_ID'),
                'COGNITO_USER_POOL_ID': updated_env.get('COGNITO_USER_POOL_ID')
            }, indent=2))
            print()
            print(f"{GREEN}========================================{NC}")
            print(f"{GREEN}Fix Applied Successfully!{NC}")
            print(f"{GREEN}========================================{NC}")
            print()
            print("You can now test your admin dashboard:")
            print()
            print("curl 'https://sakyhorixe.execute-api.eu-central-1.amazonaws.com/v1/admin/dashboard' \\")
            print("  -H 'Authorization: Bearer YOUR_JWT_TOKEN'")
            print()
        else:
            print(f"{RED}❌ Verification failed!{NC}")
            print(f"Expected: {ADMIN_CLIENT_ID}")
            print(f"Got: {updated_env.get('COGNITO_ADMIN_CLIENT_ID')}")
            sys.exit(1)

    except Exception as e:
        print(f"{RED}❌ Error: {str(e)}{NC}")
        sys.exit(1)

if __name__ == '__main__':
    main()
