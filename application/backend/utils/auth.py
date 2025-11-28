"""
Authentication Utilities - FIXED FOR PRIVATE VPC (No NAT)
Handles JWT token verification WITHOUT making outbound HTTPS calls

CHANGES FROM ORIGINAL:
1. Removed PyJWKClient (makes HTTPS calls to fetch keys)
2. Added local JWK key caching mechanism
3. JWT verification works offline using cached keys
4. Auth endpoints (register/login/confirm/refresh) MUST run in separate Lambda outside VPC

Requirements: Works in Private VPC with NO NAT Gateway
"""

import os
import json
import base64
from typing import Optional, Dict, Any
import jwt
from jwt.algorithms import RSAAlgorithm
from functools import wraps
from datetime import datetime, timedelta

# Cognito configuration
COGNITO_REGION = os.getenv('AWS_REGION', 'eu-central-1')
USER_POOL_ID = os.getenv('COGNITO_USER_POOL_ID')
APP_CLIENT_ID = os.getenv('COGNITO_APP_CLIENT_ID')
ADMIN_CLIENT_ID = os.getenv('COGNITO_ADMIN_CLIENT_ID', APP_CLIENT_ID)

# Global JWK key cache (persists across Lambda warm starts)
_jwk_cache = {}
_jwk_cache_timestamp = None
_jwk_cache_ttl = 3600  # Cache keys for 1 hour


def get_jwk_keys_from_env() -> Dict:
    """
    Get JWK keys from environment variable (injected by Terraform)

    This is the SAFE way to get JWK keys in a private VPC Lambda.
    Keys are fetched once during deployment and injected as env vars.

    Terraform should fetch keys and inject as COGNITO_JWK_KEYS env var:

    export COGNITO_JWK_KEYS='{"keys": [{"kid": "...", "kty": "RSA", ...}]}'

    Returns:
        Dict with JWK keys
    """
    jwk_keys_json = os.getenv('COGNITO_JWK_KEYS')

    if not jwk_keys_json:
        print("WARNING: COGNITO_JWK_KEYS not found in environment. JWT verification will fail.")
        print("Please configure Terraform to inject JWK keys as environment variable.")
        return {"keys": []}

    try:
        return json.loads(jwk_keys_json)
    except json.JSONDecodeError as e:
        print(f"ERROR: Failed to parse COGNITO_JWK_KEYS: {str(e)}")
        return {"keys": []}


def get_signing_key_from_cache(token: str) -> Optional[str]:
    """
    Get signing key for JWT token from cached JWK keys

    This replaces PyJWKClient.get_signing_key_from_jwt() which makes HTTPS calls.

    Args:
        token: JWT token string

    Returns:
        RSA public key in PEM format, or None if not found
    """
    global _jwk_cache, _jwk_cache_timestamp

    # Parse token header to get key ID (kid)
    try:
        unverified_header = jwt.get_unverified_header(token)
        kid = unverified_header.get('kid')

        if not kid:
            print("ERROR: Token header missing 'kid' field")
            return None

    except Exception as e:
        print(f"ERROR: Failed to parse token header: {str(e)}")
        return None

    # Check if we need to refresh cache
    now = datetime.now()
    if _jwk_cache_timestamp is None or (now - _jwk_cache_timestamp).seconds > _jwk_cache_ttl:
        print("Refreshing JWK key cache from environment...")
        jwk_data = get_jwk_keys_from_env()

        # Build cache: kid -> public_key
        _jwk_cache = {}
        for key_data in jwk_data.get('keys', []):
            key_kid = key_data.get('kid')
            if key_kid:
                # Convert JWK to PEM using PyJWT's RSAAlgorithm
                try:
                    public_key = RSAAlgorithm.from_jwk(json.dumps(key_data))
                    _jwk_cache[key_kid] = public_key
                except Exception as e:
                    print(f"WARNING: Failed to parse JWK for kid={key_kid}: {str(e)}")

        _jwk_cache_timestamp = now
        print(f"JWK cache refreshed. {len(_jwk_cache)} keys loaded.")

    # Get key from cache
    signing_key = _jwk_cache.get(kid)

    if not signing_key:
        print(f"ERROR: Signing key not found in cache for kid={kid}")
        print(f"Available kids: {list(_jwk_cache.keys())}")
        return None

    return signing_key


def verify_token(token: str) -> Optional[Dict]:
    """
    Verify JWT token from Cognito (OFFLINE - No HTTPS calls)

    This version works in private VPC without NAT Gateway.
    JWK keys are cached from environment variables.

    Args:
        token: JWT token string

    Returns:
        User claims if valid, None otherwise
    """
    try:
        # Get signing key from cache (NO HTTPS calls)
        signing_key = get_signing_key_from_cache(token)

        if not signing_key:
            print("ERROR: Could not get signing key for token")
            return None

        # Try both client IDs (mobile app and admin portal)
        claims = None
        for client_id in [APP_CLIENT_ID, ADMIN_CLIENT_ID]:
            try:
                claims = jwt.decode(
                    token,
                    signing_key,
                    algorithms=["RS256"],
                    audience=client_id,
                    options={"verify_exp": True}
                )
                break
            except jwt.InvalidAudienceError:
                continue
            except jwt.ExpiredSignatureError:
                print("Token has expired")
                return None
            except jwt.InvalidTokenError as e:
                print(f"Invalid token: {str(e)}")
                return None

        if not claims:
            print("Invalid token: Audience doesn't match any configured client ID")
            return None

        # Debug: log all claims
        print(json.dumps({'event': 'jwt_claims', 'claims': list(claims.keys())}))

        # Extract user information
        groups = claims.get('cognito:groups', [])
        user = {
            'user_id': claims.get('sub'),
            'email': claims.get('email'),
            'username': claims.get('cognito:username'),
            'groups': groups,
            'is_admin': 'admin' in groups or 'admins' in groups
        }

        return user

    except Exception as e:
        print(f"Error verifying token: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


def require_auth(func):
    """
    Decorator to require authentication for endpoint

    Usage:
        @require_auth
        def my_endpoint(event, context):
            user = event['user']
            ...
    """
    @wraps(func)
    def wrapper(event, context):
        # Check if user is already authenticated
        if 'user' not in event:
            return {
                'statusCode': 401,
                'body': json.dumps({'error': 'Authentication required'})
            }
        return func(event, context)
    return wrapper


def require_admin(func):
    """
    Decorator to require admin role

    Usage:
        @require_admin
        def admin_endpoint(event, context):
            ...
    """
    @wraps(func)
    def wrapper(event, context):
        # Check if user is authenticated
        if 'user' not in event:
            return {
                'statusCode': 401,
                'body': json.dumps({'error': 'Authentication required'})
            }

        # Check if user is admin
        if not event['user'].get('is_admin', False):
            return {
                'statusCode': 403,
                'body': json.dumps({'error': 'Admin access required'})
            }

        return func(event, context)
    return wrapper


def get_user_from_event(event: Dict) -> Optional[Dict]:
    """
    Extract user information from event

    Args:
        event: Lambda event

    Returns:
        User dict or None
    """
    return event.get('user')


# ============================================================================
# COGNITO CLIENT FUNCTIONS - ONLY FOR AUTH LAMBDA (OUTSIDE VPC)
# ============================================================================
#
# WARNING: The functions below make HTTPS calls to AWS Cognito.
# They WILL FAIL in a Lambda function inside a private VPC with no NAT.
#
# These functions should ONLY be used by the auth_handler Lambda which
# must be deployed OUTSIDE the VPC (or in a public subnet with NAT).
# ============================================================================

def create_cognito_user(email: str, password: str, name: str, phone: str) -> Optional[str]:
    """
    Create a new user in Cognito

    ⚠️  WARNING: Makes HTTPS calls to Cognito API
    ⚠️  ONLY use in auth_handler Lambda (deployed outside VPC)

    Args:
        email: User email
        password: User password
        name: User full name
        phone: User phone number

    Returns:
        User ID (sub) if successful, None otherwise
    """
    try:
        import boto3
        cognito = boto3.client('cognito-idp', region_name=COGNITO_REGION)

        response = cognito.sign_up(
            ClientId=APP_CLIENT_ID,
            Username=email,
            Password=password,
            UserAttributes=[
                {'Name': 'email', 'Value': email},
                {'Name': 'name', 'Value': name},
                {'Name': 'phone_number', 'Value': phone}
            ]
        )

        return response['UserSub']

    except Exception as e:
        print(f"Error creating Cognito user: {str(e)}")
        return None


def confirm_user(email: str, confirmation_code: str) -> bool:
    """
    Confirm user email with verification code

    ⚠️  WARNING: Makes HTTPS calls to Cognito API
    ⚠️  ONLY use in auth_handler Lambda (deployed outside VPC)

    Args:
        email: User email
        confirmation_code: Verification code

    Returns:
        True if successful, False otherwise
    """
    try:
        import boto3
        cognito = boto3.client('cognito-idp', region_name=COGNITO_REGION)

        cognito.confirm_sign_up(
            ClientId=APP_CLIENT_ID,
            Username=email,
            ConfirmationCode=confirmation_code
        )

        return True

    except Exception as e:
        print(f"Error confirming user: {str(e)}")
        return False


def initiate_auth(email: str, password: str) -> Optional[Dict]:
    """
    Authenticate user and get tokens

    ⚠️  WARNING: Makes HTTPS calls to Cognito API
    ⚠️  ONLY use in auth_handler Lambda (deployed outside VPC)

    Args:
        email: User email
        password: User password

    Returns:
        Auth tokens if successful, None otherwise
    """
    try:
        import boto3
        cognito = boto3.client('cognito-idp', region_name=COGNITO_REGION)

        response = cognito.initiate_auth(
            ClientId=APP_CLIENT_ID,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': email,
                'PASSWORD': password
            }
        )

        return {
            'access_token': response['AuthenticationResult']['AccessToken'],
            'id_token': response['AuthenticationResult']['IdToken'],
            'refresh_token': response['AuthenticationResult']['RefreshToken'],
            'expires_in': response['AuthenticationResult']['ExpiresIn']
        }

    except Exception as e:
        print(f"Error authenticating user: {str(e)}")
        return None


def refresh_token(refresh_token: str) -> Optional[Dict]:
    """
    Refresh access token using refresh token

    ⚠️  WARNING: Makes HTTPS calls to Cognito API
    ⚠️  ONLY use in auth_handler Lambda (deployed outside VPC)

    Args:
        refresh_token: Refresh token

    Returns:
        New tokens if successful, None otherwise
    """
    try:
        import boto3
        cognito = boto3.client('cognito-idp', region_name=COGNITO_REGION)

        response = cognito.initiate_auth(
            ClientId=APP_CLIENT_ID,
            AuthFlow='REFRESH_TOKEN_AUTH',
            AuthParameters={
                'REFRESH_TOKEN': refresh_token
            }
        )

        return {
            'access_token': response['AuthenticationResult']['AccessToken'],
            'id_token': response['AuthenticationResult']['IdToken'],
            'expires_in': response['AuthenticationResult']['ExpiresIn']
        }

    except Exception as e:
        print(f"Error refreshing token: {str(e)}")
        return None


def admin_create_user(email: str, name: str, phone: str, subscription: str = 'basic') -> Optional[Dict[str, Any]]:
    """
    Admin creates a new user in Cognito with temporary password
    
    ⚠️  WARNING: Makes HTTPS calls to Cognito API
    ⚠️  ONLY use in auth_handler Lambda (deployed outside VPC)
    
    Args:
        email: User email
        name: User full name
        phone: User phone number
        subscription: Initial subscription tier (basic/premium)
        
    Returns:
        Dict with user_id and temporary_password if successful, None otherwise
    """
    try:
        import boto3
        import secrets
        import string
        
        cognito = boto3.client('cognito-idp', region_name=COGNITO_REGION)
        
        # Generate secure temporary password (meets Cognito requirements)
        # Min 8 chars, uppercase, lowercase, number, special char
        password_chars = (
            secrets.choice(string.ascii_uppercase) +
            secrets.choice(string.ascii_lowercase) +
            secrets.choice(string.digits) +
            secrets.choice('!@#$%^&*') +
            ''.join(secrets.choice(string.ascii_letters + string.digits + '!@#$%^&*') for _ in range(8))
        )
        # Shuffle to randomize position of required characters
        temp_password = ''.join(secrets.SystemRandom().sample(password_chars, len(password_chars)))
        
        # Create user with admin privileges
        response = cognito.admin_create_user(
            UserPoolId=USER_POOL_ID,
            Username=email,
            UserAttributes=[
                {'Name': 'email', 'Value': email},
                {'Name': 'email_verified', 'Value': 'true'},  # Auto-verify
                {'Name': 'name', 'Value': name},
                {'Name': 'phone_number', 'Value': phone}
            ],
            TemporaryPassword=temp_password,
            MessageAction='SUPPRESS',  # Don't send Cognito email, we'll handle it
            DesiredDeliveryMediums=['EMAIL']
        )
        
        user_sub = None
        for attr in response['User']['Attributes']:
            if attr['Name'] == 'sub':
                user_sub = attr['Value']
                break
        
        return {
            'user_id': user_sub,
            'temporary_password': temp_password,
            'email': email
        }
        
    except Exception as e:
        print(f"Error creating user via admin: {str(e)}")
        import traceback
        traceback.print_exc()
        return None
