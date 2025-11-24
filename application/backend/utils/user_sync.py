"""
User Synchronization Utilities
Handles automatic user record creation from Cognito to database
"""

import json
from typing import Dict, Optional
from utils.db import get_db_connection, Queries


def ensure_user_exists(user_claims: Dict) -> Optional[Dict]:
    """
    Ensure user record exists in database, create if not
    
    This implements lazy user creation - users are created in the database
    on their first authenticated API call rather than during registration.
    
    Args:
        user_claims: JWT token claims containing user information
        
    Returns:
        User record dict if successful, None otherwise
        
    Requirements: 1.1, 1.2 (lazy user creation pattern)
    """
    try:
        user_id = user_claims.get('sub') or user_claims.get('user_id')
        email = user_claims.get('email')
        name = user_claims.get('name', '')
        phone = user_claims.get('phone_number', '')
        
        if not user_id or not email:
            print(f"Missing required user claims: user_id={user_id}, email={email}")
            return None
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Check if user exists
            cursor.execute(Queries.GET_USER_BY_ID, (user_id,))
            user = cursor.fetchone()
            
            if user:
                # User exists, return it
                print(json.dumps({
                    'event': 'user_exists',
                    'user_id': user_id
                }))
                return user
            
            # User doesn't exist, create it
            print(json.dumps({
                'event': 'creating_user_record',
                'user_id': user_id,
                'email': email
            }))
            
            cursor.execute(
                Queries.CREATE_USER,
                (user_id, email, name, phone, 0.0, 'basic')
            )
            
            # Fetch the newly created user
            cursor.execute(Queries.GET_USER_BY_ID, (user_id,))
            new_user = cursor.fetchone()
            
            print(json.dumps({
                'event': 'user_record_created',
                'user_id': user_id
            }))
            
            return new_user
            
    except Exception as e:
        print(json.dumps({
            'event': 'user_sync_error',
            'error': str(e),
            'error_type': type(e).__name__
        }))
        return None
