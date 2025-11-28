"""
Authentication API Endpoints
Handles user registration, login, confirmation, and token refresh
"""

import json
import os
from typing import Dict, Any
from utils.auth import create_cognito_user, confirm_user, initiate_auth, refresh_token as refresh_auth_token
from utils.db import get_db_connection, Queries
from utils.validators import validate_email, validate_password, validate_phone_number
import uuid


def register(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    POST /auth/register
    Register a new user with Cognito and create user record in database
    
    Requirements: 1.1, 1.2
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        email = body.get('email', '').strip()
        password = body.get('password', '')
        name = body.get('name', '').strip()
        phone = body.get('phone', '').strip()
        
        # Validate required fields
        if not all([email, password, name, phone]):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required fields',
                    'details': 'email, password, name, and phone are required'
                })
            }
        
        # Validate email format
        if not validate_email(email):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid email format'
                })
            }
        
        # Validate password requirements (min 8 chars, uppercase, lowercase, numbers)
        password_valid, password_error = validate_password(password)
        if not password_valid:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid password',
                    'details': password_error
                })
            }
        
        # Validate phone number (Ghanaian format)
        if not validate_phone_number(phone):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid phone number',
                    'details': 'Phone number must be in format +233XXXXXXXXX'
                })
            }
        
        # Create user in Cognito
        user_id = create_cognito_user(email, password, name, phone)
        if not user_id:
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'error': 'Failed to create user account',
                    'details': 'Could not register with authentication service'
                })
            }
        
        # Note: User database record will be created automatically on first authenticated API call
        # This allows the auth Lambda to stay outside VPC for better performance and cost optimization
        
        return {
            'statusCode': 201,
            'body': json.dumps({
                'message': 'User registered successfully. Please check your email for verification code.',
                'user_id': user_id,
                'email': email
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    except Exception as e:
        print(f"Error in register endpoint: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def login(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    POST /auth/login
    Authenticate user and return JWT tokens
    
    Requirements: 1.3
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        email = body.get('email', '').strip()
        password = body.get('password', '')
        
        # Validate required fields
        if not email or not password:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required fields',
                    'details': 'email and password are required'
                })
            }
        
        # Authenticate with Cognito
        auth_result = initiate_auth(email, password)
        if not auth_result:
            return {
                'statusCode': 401,
                'body': json.dumps({
                    'error': 'Authentication failed',
                    'details': 'Invalid email or password'
                })
            }
        
        # Get user details from database
        try:
            with get_db_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(Queries.GET_USER_BY_EMAIL, (email,))
                user = cursor.fetchone()
                
                if not user:
                    return {
                        'statusCode': 404,
                        'body': json.dumps({
                            'error': 'User not found',
                            'details': 'User record not found in database'
                        })
                    }
        except Exception as db_error:
            print(f"Database error fetching user: {str(db_error)}")
            # Still return tokens even if DB fetch fails
            user = None
        
        response_data = {
            'message': 'Login successful',
            'access_token': auth_result['access_token'],
            'id_token': auth_result['id_token'],
            'refresh_token': auth_result['refresh_token'],
            'expires_in': auth_result['expires_in']
        }
        
        if user:
            response_data['user'] = {
                'user_id': user['user_id'],
                'email': user['email'],
                'name': user['name'],
                'phone': user['phone'],
                'wallet_balance': float(user['wallet_balance'])
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps(response_data)
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    except Exception as e:
        print(f"Error in login endpoint: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def confirm(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    POST /auth/confirm
    Confirm user email with verification code
    
    Requirements: 1.2
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        email = body.get('email', '').strip()
        confirmation_code = body.get('confirmation_code', '').strip()
        
        # Validate required fields
        if not email or not confirmation_code:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required fields',
                    'details': 'email and confirmation_code are required'
                })
            }
        
        # Confirm user with Cognito
        success = confirm_user(email, confirmation_code)
        if not success:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Confirmation failed',
                    'details': 'Invalid or expired confirmation code'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Email confirmed successfully. You can now log in.'
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    except Exception as e:
        print(f"Error in confirm endpoint: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def refresh(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    POST /auth/refresh
    Refresh access token using refresh token
    
    Requirements: 1.3
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        refresh_token_value = body.get('refresh_token', '').strip()
        
        # Validate required fields
        if not refresh_token_value:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required fields',
                    'details': 'refresh_token is required'
                })
            }
        
        # Refresh token with Cognito
        auth_result = refresh_auth_token(refresh_token_value)
        if not auth_result:
            return {
                'statusCode': 401,
                'body': json.dumps({
                    'error': 'Token refresh failed',
                    'details': 'Invalid or expired refresh token'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Token refreshed successfully',
                'access_token': auth_result['access_token'],
                'id_token': auth_result['id_token'],
                'expires_in': auth_result['expires_in']
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    except Exception as e:
        print(f"Error in refresh endpoint: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def admin_create_user_endpoint(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    POST /auth/admin/create-user
    Admin creates a new user with temporary password
    
    Requirements: 8.1
    """
    try:
        from utils.auth import admin_create_user
        from utils.validators import validate_email, validate_phone_number
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        email = body.get('email', '').strip()
        name = body.get('name', '').strip()
        phone = body.get('phone', '').strip()
        subscription = body.get('subscription', 'basic').lower()
        
        # Validate required fields
        if not all([email, name, phone]):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required fields',
                    'details': 'email, name, and phone are required'
                })
            }
        
        # Validate email format
        if not validate_email(email):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid email format'
                })
            }
        
        # Validate phone number
        if not validate_phone_number(phone):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid phone number',
                    'details': 'Phone number must be in format +233XXXXXXXXX'
                })
            }
        
        # Validate subscription
        if subscription not in ['basic', 'premium']:
            subscription = 'basic'
        
        # Create user in Cognito
        result = admin_create_user(email, name, phone, subscription)
        if not result:
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'error': 'Failed to create user',
                    'details': 'Could not create user in authentication service'
                })
            }
        
        # Create user record in database
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Check if user already exists
            cursor.execute(Queries.GET_USER_BY_EMAIL, (email,))
            existing = cursor.fetchone()
            
            if existing:
                return {
                    'statusCode': 409,
                    'body': json.dumps({
                        'error': 'User already exists',
                        'details': f'A user with email {email} already exists'
                    })
                }
            
            # Insert new user
            cursor.execute(
                """
                INSERT INTO users (user_id, email, name, phone, subscription, wallet_balance, total_swaps, created_at)
                VALUES (%s, %s, %s, %s, %s, 0, 0, NOW())
                RETURNING *
                """,
                (result['user_id'], email, name, phone, subscription)
            )
            user = cursor.fetchone()
        
        return {
            'statusCode': 201,
            'body': json.dumps({
                'message': 'User created successfully',
                'user': {
                    'user_id': user['user_id'],
                    'email': user['email'],
                    'name': user['name'],
                    'phone': user['phone'],
                    'subscription': user['subscription'],
                    'wallet_balance': float(user['wallet_balance']),
                    'created_at': user['created_at'].isoformat() if user.get('created_at') else None
                },
                'temporary_password': result['temporary_password'],
                'note': 'User must change password on first login'
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }
    except Exception as e:
        print(f"Error in admin create user: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }
