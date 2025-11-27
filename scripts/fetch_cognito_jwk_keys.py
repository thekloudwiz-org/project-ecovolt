#!/usr/bin/env python3
"""
Fetch Cognito JWK Keys for Lambda Environment Injection

This script fetches the public JWK keys from your Cognito User Pool
and formats them for injection into Lambda environment variables.

Usage:
    python fetch_cognito_jwk_keys.py <aws-region> <user-pool-id>

Example:
    python fetch_cognito_jwk_keys.py eu-central-1 eu-central-1_abc123
"""

import sys
import json
import urllib.request
from urllib.error import URLError, HTTPError


def fetch_jwk_keys(aws_region: str, user_pool_id: str) -> dict:
    """
    Fetch JWK keys from Cognito User Pool

    Args:
        aws_region: AWS region (e.g., 'eu-central-1')
        user_pool_id: Cognito User Pool ID (e.g., 'eu-central-1_abc123')

    Returns:
        Dict containing JWK keys

    Raises:
        Exception if fetch fails
    """
    jwk_url = f"https://cognito-idp.{aws_region}.amazonaws.com/{user_pool_id}/.well-known/jwks.json"

    print(f"Fetching JWK keys from Cognito User Pool...")
    print(f"Region: {aws_region}")
    print(f"User Pool ID: {user_pool_id}")
    print(f"URL: {jwk_url}")
    print()

    try:
        with urllib.request.urlopen(jwk_url) as response:
            jwk_data = json.loads(response.read().decode('utf-8'))

        # Validate response
        if 'keys' not in jwk_data:
            raise ValueError("Invalid JWK response: 'keys' field missing")

        if len(jwk_data['keys']) == 0:
            raise ValueError("No keys found in JWK response")

        return jwk_data

    except HTTPError as e:
        raise Exception(f"HTTP Error {e.code}: {e.reason}")
    except URLError as e:
        raise Exception(f"URL Error: {e.reason}")
    except json.JSONDecodeError as e:
        raise Exception(f"Invalid JSON response: {e}")


def main():
    """Main entry point"""

    # Check arguments
    if len(sys.argv) != 3:
        print("Error: Missing arguments\n", file=sys.stderr)
        print("Usage: python fetch_cognito_jwk_keys.py <aws-region> <user-pool-id>\n")
        print("Example:")
        print("  python fetch_cognito_jwk_keys.py eu-central-1 eu-central-1_abc123\n")
        sys.exit(1)

    aws_region = sys.argv[1]
    user_pool_id = sys.argv[2]

    try:
        # Fetch JWK keys
        jwk_data = fetch_jwk_keys(aws_region, user_pool_id)

        key_count = len(jwk_data['keys'])
        print(f"✅ Successfully fetched {key_count} JWK key(s)\n")

        # Compact JSON (for environment variable)
        jwk_json_compact = json.dumps(jwk_data, separators=(',', ':'))

        # Pretty JSON (for file)
        jwk_json_pretty = json.dumps(jwk_data, indent=2)

        # Output for Terraform
        print("=" * 60)
        print("COGNITO JWK KEYS (for Terraform)")
        print("=" * 60)
        print()
        print("Add this to your Terraform Lambda environment variables:")
        print()
        print("environment {")
        print("  variables = {")
        print('    COGNITO_JWK_KEYS = <<-EOT')
        print(jwk_json_compact)
        print('EOT')
        print("  }")
        print("}")
        print()

        # Output for .env file
        print("=" * 60)
        print("FOR LOCAL TESTING (.env file)")
        print("=" * 60)
        print()
        print("Add this to your .env file:")
        print()
        print(f"COGNITO_JWK_KEYS='{jwk_json_compact}'")
        print()

        # Save to file
        output_file = "cognito_jwk_keys.json"
        with open(output_file, 'w') as f:
            f.write(jwk_json_pretty)
        print(f"✅ JWK keys saved to: {output_file}\n")

        # Show key details
        print("=" * 60)
        print("KEY DETAILS")
        print("=" * 60)
        print()
        for key in jwk_data['keys']:
            print(f"Key ID: {key.get('kid')}")
            print(f"Algorithm: {key.get('alg')}")
            print(f"Key Type: {key.get('kty')}")
            print(f"Use: {key.get('use')}")
            print()

        print("✅ Done!")

    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
