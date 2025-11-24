"""
Authentication Utilities
Handles JWT token verification and user authorization
"""

import os
import json
import boto3
from typing import Optional, Dict
import jwt
from jwt import PyJWKClient
from functools import wraps

# Cognito configuration
COGNITO_REGION = os.getenv('AWS_REGION', 'eu-central-1')
USER_POOL_ID = os.getenv('COGNITO_USER_POOL_ID')
APP_CLIENT_ID = os.getenv('COGNITO_APP_CLIENT_ID')

# JWK client for token verification
jwks_url = f'https://cognito-idp.{COGNITO_REGION}.amazonaws.com/{USER_POOL_ID}/.well-known/jwks.json'
jwks_client = PyJWKClient(jwks_url)


def verify_token(token: str) -> Optional[Dict]:
    """
    Verify JWT token from Cognito
    
    Args:
        token: JWT token string
        
    Returns:
        User claims if valid, None otherwise
    """
    try:
        # Get signing key
        signing_key = jwks_client.get_signing_key_from_jwt(token)
        
        # Decode and verify token
        claims = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=APP_CLIENT_ID,
            options={"verify_exp": True}
        )
        
        # Extract user information
        user = {
            'user_id': claims.get('sub'),
            'email': claims.get('email'),
            'username': claims.get('cognito:username'),
            'groups': claims.get('cognito:groups', []),
            'is_admin': 'Admins' in claims.get('cognito:groups', [])
        }
        
        return user
        
    except jwt.ExpiredSignatureError:
        print("Token has expired")
        return None
    except jwt.InvalidTokenError as e:
        print(f"Invalid token: {str(e)}")
        return None
    except Exception as e:
        print(f"Error verifying token: {str(e)}")
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


def create_cognito_user(email: str, password: str, name: str, phone: str) -> Optional[str]:
    """
    Create a new user in Cognito
    
    Args:
        email: User email
        password: User password
        name: User full name
        phone: User phone number
        
    Returns:
        User ID (sub) if successful, None otherwise
    """
    try:
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
    
    Args:
        email: User email
        confirmation_code: Verification code
        
    Returns:
        True if successful, False otherwise
    """
    try:
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
    
    Args:
        email: User email
        password: User password
        
    Returns:
        Auth tokens if successful, None otherwise
    """
    try:
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
    
    Args:
        refresh_token: Refresh token
        
    Returns:
        New tokens if successful, None otherwise
    """
    try:
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
