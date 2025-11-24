"""
User Profile API Endpoints
Handles user profile operations
"""

import json
import os
from typing import Dict, Any
from utils.db import get_db_connection, Queries
from utils.validators import validate_phone_number


def get_profile(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /profile
    Get user profile
    
    Requirements: 15.1, 15.4
    """
    try:
        # Get authenticated user
        user = event.get('user')
        if not user:
            return {
                'statusCode': 401,
                'body': json.dumps({
                    'error': 'Unauthorized',
                    'details': 'Authentication required'
                })
            }
        
        user_id = user.get('user_id') or user.get('sub')
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(Queries.GET_USER_BY_ID, (user_id,))
            profile = cursor.fetchone()
        
        if not profile:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Profile not found',
                    'details': 'User profile not found in database'
                })
            }
        
        # Requirement 15.4: Return user information including email, name, phone, wallet balance, total swaps
        return {
            'statusCode': 200,
            'body': json.dumps({
                'profile': {
                    'user_id': profile['user_id'],
                    'email': profile['email'],
                    'name': profile['name'],
                    'phone': profile['phone'],
                    'wallet_balance': float(profile['wallet_balance']),
                    'subscription': profile['subscription'],
                    'total_swaps': profile.get('total_swaps', 0),
                    'created_at': profile['created_at'].isoformat() if profile.get('created_at') else None,
                    'updated_at': profile['updated_at'].isoformat() if profile.get('updated_at') else None
                }
            })
        }
        
    except Exception as e:
        print(f"Error getting profile: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def update_profile(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    PUT /profile
    Update user profile with validation
    
    Requirements: 15.1, 15.2, 15.3, 15.4, 15.5
    """
    try:
        # Get authenticated user
        user = event.get('user')
        if not user:
            return {
                'statusCode': 401,
                'body': json.dumps({
                    'error': 'Unauthorized',
                    'details': 'Authentication required'
                })
            }
        
        user_id = user.get('user_id') or user.get('sub')
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Requirement 15.5: Prevent modification of immutable fields (email, user_id)
        # We simply ignore these fields if they're in the request
        name = body.get('name', '').strip()
        phone = body.get('phone', '').strip()
        
        # Requirement 15.1: Validate input format
        if not name:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid input',
                    'details': 'Name is required'
                })
            }
        
        if len(name) < 2:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid input',
                    'details': 'Name must be at least 2 characters'
                })
            }
        
        # Requirement 15.2: Validate phone number format (Ghanaian format)
        if phone and not validate_phone_number(phone):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid phone number',
                    'details': 'Phone number must be in format +233XXXXXXXXX'
                })
            }
        
        # Requirement 15.3: Update user record and set updated_at timestamp
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(Queries.UPDATE_USER_PROFILE, (name, phone, user_id))
            updated = cursor.fetchone()
        
        if not updated:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Profile not found',
                    'details': 'User profile not found'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Profile updated successfully',
                'profile': {
                    'user_id': updated['user_id'],
                    'email': updated['email'],
                    'name': updated['name'],
                    'phone': updated['phone'],
                    'wallet_balance': float(updated['wallet_balance']),
                    'subscription': updated['subscription'],
                    'total_swaps': updated.get('total_swaps', 0),
                    'updated_at': updated['updated_at'].isoformat() if updated.get('updated_at') else None
                }
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
        print(f"Error updating profile: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def get_wallet(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /wallet
    Get wallet balance and transaction history
    
    Requirements: 6.1, 6.2
    """
    try:
        # Get authenticated user
        user = event.get('user')
        if not user:
            return {
                'statusCode': 401,
                'body': json.dumps({
                    'error': 'Unauthorized',
                    'details': 'Authentication required'
                })
            }
        
        user_id = user.get('user_id') or user.get('sub')
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Get user wallet balance
            cursor.execute(Queries.GET_USER_BY_ID, (user_id,))
            user_data = cursor.fetchone()
            
            if not user_data:
                return {
                    'statusCode': 404,
                    'body': json.dumps({
                        'error': 'User not found'
                    })
                }
            
            # Get recent transactions (last 50)
            cursor.execute(
                """SELECT * FROM wallet_transactions 
                   WHERE user_id = %s ORDER BY created_at DESC LIMIT 50""",
                (user_id,)
            )
            transactions = cursor.fetchall()
        
        # Format transactions
        transaction_list = []
        for txn in transactions:
            transaction_list.append({
                'transaction_id': txn['transaction_id'],
                'type': txn['type'],
                'amount': float(txn['amount']),
                'balance_after': float(txn['balance_after']),
                'reference': txn['reference'],
                'created_at': txn['created_at'].isoformat() if txn.get('created_at') else None
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'wallet_balance': float(user_data['wallet_balance']),
                'currency': 'GHS',
                'transactions': transaction_list,
                'transaction_count': len(transaction_list)
            })
        }
        
    except Exception as e:
        print(f"Error getting wallet: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def topup_wallet(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    POST /wallet/topup
    Initiate wallet top-up
    
    Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6
    """
    try:
        # Get authenticated user
        user = event.get('user')
        if not user:
            return {
                'statusCode': 401,
                'body': json.dumps({
                    'error': 'Unauthorized',
                    'details': 'Authentication required'
                })
            }
        
        user_id = user.get('user_id') or user.get('sub')
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Requirement 6.1: Validate amount is greater than zero
        try:
            amount = float(body.get('amount', 0))
        except (ValueError, TypeError):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid amount',
                    'details': 'Amount must be a valid number'
                })
            }
        
        if amount <= 0:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid amount',
                    'details': 'Amount must be greater than zero'
                })
            }
        
        # Requirement 6.6: Validate amount is between 10 and 1000 GHS
        from utils.validators import validate_wallet_topup
        valid, error = validate_wallet_topup(amount)
        if not valid:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid amount',
                    'details': error
                })
            }
        
        payment_method = body.get('payment_method', 'mobile_money')
        provider = body.get('provider')  # MTN, Telecel, AirtelTigo
        phone_number = body.get('phone_number')
        
        # Validate payment method
        if payment_method == 'mobile_money':
            if not provider:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'Missing provider',
                        'details': 'Provider is required for mobile money payments'
                    })
                }
            
            valid_providers = ['MTN', 'Telecel', 'AirtelTigo']
            if provider not in valid_providers:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'Invalid provider',
                        'details': f'Provider must be one of: {", ".join(valid_providers)}'
                    })
                }
            
            if not phone_number:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'Missing phone number',
                        'details': 'Phone number is required for mobile money payments'
                    })
                }
        
        # Requirement 6.2: Integrate with Mobile Money API (stub for now)
        # TODO: Implement actual Mobile Money integration when credentials are available
        import uuid
        payment_id = f"PAY-{uuid.uuid4()}"
        
        # Simulate payment processing
        # In production, this would call the Mobile Money API
        payment_success = True  # Stub: assume payment succeeds
        
        if payment_success:
            # Requirement 6.3: Add amount to wallet balance
            # Requirement 6.4: Create wallet transaction record
            with get_db_connection() as conn:
                cursor = conn.cursor()
                
                # Update wallet balance
                cursor.execute(
                    Queries.UPDATE_WALLET_BALANCE,
                    (amount, user_id)
                )
                new_balance_result = cursor.fetchone()
                new_balance = float(new_balance_result['wallet_balance'])
                
                # Requirement 6.4: Create transaction record with type "topup"
                transaction_id = f"TXN-{uuid.uuid4()}"
                cursor.execute(
                    Queries.CREATE_WALLET_TRANSACTION,
                    (transaction_id, user_id, 'topup', amount, new_balance, payment_id)
                )
            
            # Requirement 12.2: Send wallet top-up notification
            from utils.notifications import notify_wallet_topup
            notify_wallet_topup(user_id, amount, new_balance)
            
            # Requirement 12.3: Check for low balance and notify
            from utils.notifications import check_and_notify_low_balance
            check_and_notify_low_balance(user_id, new_balance)
            
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Wallet topped up successfully',
                    'payment_id': payment_id,
                    'transaction_id': transaction_id,
                    'amount': amount,
                    'new_balance': new_balance,
                    'currency': 'GHS'
                })
            }
        else:
            # Requirement 6.5: Return error without modifying balance
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Payment failed',
                    'details': 'Mobile Money payment could not be processed',
                    'payment_id': payment_id
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
        print(f"Error topping up wallet: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def get_wallet_transactions(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /wallet/transactions?page={page}&page_size={page_size}
    Get transaction history with pagination
    
    Requirements: 6.2
    """
    try:
        # Get authenticated user
        user = event.get('user')
        if not user:
            return {
                'statusCode': 401,
                'body': json.dumps({
                    'error': 'Unauthorized',
                    'details': 'Authentication required'
                })
            }
        
        user_id = user.get('user_id') or user.get('sub')
        
        # Get pagination parameters
        params = event.get('queryStringParameters') or {}
        page = int(params.get('page', 1))
        page_size = int(params.get('page_size', 20))
        
        # Validate pagination
        from utils.validators import validate_pagination
        valid, error, page, page_size = validate_pagination(page, page_size)
        if not valid:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid pagination parameters',
                    'details': error
                })
            }
        
        # Calculate offset
        offset = (page - 1) * page_size
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Get transactions with pagination
            cursor.execute(
                Queries.GET_WALLET_TRANSACTIONS,
                (user_id, page_size, offset)
            )
            transactions = cursor.fetchall()
            
            # Get total count
            cursor.execute(
                "SELECT COUNT(*) as total FROM wallet_transactions WHERE user_id = %s",
                (user_id,)
            )
            total_result = cursor.fetchone()
            total_count = total_result['total'] if total_result else 0
        
        # Calculate pagination metadata
        total_pages = (total_count + page_size - 1) // page_size if total_count > 0 else 0
        has_next = page < total_pages
        has_prev = page > 1
        
        # Format transactions
        transaction_list = []
        for txn in transactions:
            transaction_list.append({
                'transaction_id': txn['transaction_id'],
                'type': txn['type'],
                'amount': float(txn['amount']),
                'balance_after': float(txn['balance_after']),
                'reference': txn['reference'],
                'created_at': txn['created_at'].isoformat() if txn.get('created_at') else None
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'transactions': transaction_list,
                'pagination': {
                    'page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': total_pages,
                    'has_next': has_next,
                    'has_prev': has_prev
                }
            })
        }
        
    except Exception as e:
        print(f"Error getting wallet transactions: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }



