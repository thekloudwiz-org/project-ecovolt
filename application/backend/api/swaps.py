"""
Swaps API Endpoints
Handles battery swap operations
"""

import json
import os
import uuid
from typing import Dict, Any
from datetime import datetime
from utils.db import get_db_connection, DynamoDBHelper, Queries
from utils.validators import validate_swap_request, validate_pagination
from models.swap import Swap, SwapStatus


def initiate_swap(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    POST /swaps
    Initiate a battery swap with all validations
    
    Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
    """
    try:
        # Get authenticated user from event context
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
        bike_id = body.get('bike_id', '').strip()
        station_id = body.get('station_id', '').strip()
        
        # Validate request data
        valid, error = validate_swap_request(body)
        if not valid:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid request',
                    'details': error
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Requirement 3.1: Verify bike belongs to rider
            cursor.execute(Queries.GET_BIKE_BY_ID, (bike_id,))
            bike = cursor.fetchone()
            
            if not bike:
                return {
                    'statusCode': 404,
                    'body': json.dumps({
                        'error': 'Bike not found',
                        'details': f'Bike {bike_id} does not exist'
                    })
                }
            
            if bike['user_id'] != user_id:
                return {
                    'statusCode': 403,
                    'body': json.dumps({
                        'error': 'Forbidden',
                        'details': 'This bike does not belong to you'
                    })
                }
            
            # Requirement 3.2: Verify station has available charged battery
            cursor.execute(Queries.GET_STATION_BY_ID, (station_id,))
            station = cursor.fetchone()
            
            if not station:
                return {
                    'statusCode': 404,
                    'body': json.dumps({
                        'error': 'Station not found',
                        'details': f'Station {station_id} does not exist'
                    })
                }
            
            if station['status'] != 'active':
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'Station unavailable',
                        'details': 'This station is not currently active'
                    })
                }
            
            # Get available batteries from DynamoDB
            batteries_table = os.getenv('DYNAMODB_BATTERIES_TABLE', 'ecovolt-dev-batteries')
            available_batteries = DynamoDBHelper.query(
                table_name=batteries_table,
                key_condition='station_id = :station_id',
                expression_values={
                    ':station_id': station_id
                }
            )
            
            # Filter for available and charged batteries (>= 80%)
            charged_batteries = [
                b for b in available_batteries 
                if b.get('status') == 'available' and b.get('charge_level', 0) >= 80
            ]
            
            if not charged_batteries:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'No batteries available',
                        'details': 'This station has no charged batteries available'
                    })
                }
            
            # Get swap cost from station pricing
            pricing = station.get('pricing', {})
            if isinstance(pricing, str):
                pricing = json.loads(pricing)
            swap_cost = float(pricing.get('swap_fee', 5.0))
            
            # Requirement 3.3: Verify wallet balance covers swap cost
            cursor.execute(Queries.GET_USER_BY_ID, (user_id,))
            user_record = cursor.fetchone()
            
            if not user_record:
                return {
                    'statusCode': 404,
                    'body': json.dumps({
                        'error': 'User not found',
                        'details': 'User record not found'
                    })
                }
            
            wallet_balance = float(user_record['wallet_balance'])
            
            # Requirement 3.7: Reject if insufficient balance
            if wallet_balance < swap_cost:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'Insufficient balance',
                        'details': f'Wallet balance ({wallet_balance} GHS) is less than swap cost ({swap_cost} GHS)',
                        'wallet_balance': wallet_balance,
                        'swap_cost': swap_cost
                    })
                }
            
            # Requirement 3.6: Reserve a charged battery
            selected_battery = charged_batteries[0]
            new_battery_id = selected_battery['battery_id']
            old_battery_id = bike.get('battery_id')
            
            # Requirement 3.4: Create swap transaction with status "initiated"
            swap_id = f"SWAP-{uuid.uuid4()}"
            
            cursor.execute(
                Queries.CREATE_SWAP,
                (swap_id, user_id, bike_id, station_id, old_battery_id, 
                 new_battery_id, swap_cost, SwapStatus.INITIATED.value)
            )
            swap = cursor.fetchone()
            
            # Requirement 3.5: Deduct swap cost from wallet
            cursor.execute(
                Queries.UPDATE_WALLET_BALANCE,
                (-swap_cost, user_id)
            )
            new_balance_result = cursor.fetchone()
            new_balance = float(new_balance_result['wallet_balance'])
            
            # Create wallet transaction record
            transaction_id = f"TXN-{uuid.uuid4()}"
            cursor.execute(
                """
                INSERT INTO wallet_transactions 
                (transaction_id, user_id, type, amount, balance_after, reference, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, NOW())
                """,
                (transaction_id, user_id, 'swap', -swap_cost, new_balance, swap_id)
            )
            
            # Update battery status to reserved in DynamoDB
            DynamoDBHelper.update_item(
                table_name=batteries_table,
                key={'station_id': station_id, 'battery_id': new_battery_id},
                update_expression='SET #status = :status',
                expression_values={':status': 'reserved'},
                expression_names={'#status': 'status'}
            )
            
            # Requirement 12.3: Check for low balance and notify
            from utils.notifications import check_and_notify_low_balance
            check_and_notify_low_balance(user_id, new_balance)
        
        return {
            'statusCode': 201,
            'body': json.dumps({
                'message': 'Swap initiated successfully',
                'swap': {
                    'swap_id': swap['swap_id'],
                    'bike_id': swap['bike_id'],
                    'station_id': swap['station_id'],
                    'old_battery_id': swap['old_battery_id'],
                    'new_battery_id': swap['new_battery_id'],
                    'cost': float(swap['cost']),
                    'status': swap['status'],
                    'created_at': swap['created_at'].isoformat() if swap.get('created_at') else None
                },
                'wallet_balance': new_balance
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
        print(f"Error initiating swap: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def complete_swap(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    PUT /swaps/{id}/complete
    Complete a battery swap with state updates
    
    Requirements: 4.1, 4.2, 4.3, 4.4, 4.5
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
        
        # Get swap ID from path
        swap_id = event.get('pathParameters', {}).get('id')
        if not swap_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing swap ID'
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Get swap details
            cursor.execute(
                "SELECT * FROM swaps WHERE swap_id = %s",
                (swap_id,)
            )
            swap = cursor.fetchone()
            
            if not swap:
                return {
                    'statusCode': 404,
                    'body': json.dumps({
                        'error': 'Swap not found',
                        'details': f'Swap {swap_id} does not exist'
                    })
                }
            
            # Verify swap belongs to user
            if swap['user_id'] != user_id:
                return {
                    'statusCode': 403,
                    'body': json.dumps({
                        'error': 'Forbidden',
                        'details': 'This swap does not belong to you'
                    })
                }
            
            # Requirement 4.1: Verify swap status is "initiated"
            if swap['status'] != SwapStatus.INITIATED.value:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'Invalid swap status',
                        'details': f'Swap must be in "initiated" status to complete. Current status: {swap["status"]}'
                    })
                }
            
            # Calculate duration
            created_at = swap['created_at']
            completed_at = datetime.now()
            duration_seconds = int((completed_at - created_at).total_seconds())
            
            # Requirement 4.3: Update swap status to "completed" with completion timestamp
            cursor.execute(
                Queries.UPDATE_SWAP_STATUS,
                (SwapStatus.COMPLETED.value, duration_seconds, swap_id)
            )
            updated_swap = cursor.fetchone()
            
            # Requirement 4.2: Update bike's battery ID to new battery
            new_battery_id = swap['new_battery_id']
            bike_id = swap['bike_id']
            
            cursor.execute(
                Queries.UPDATE_BIKE_BATTERY,
                (new_battery_id, 100, bike_id)  # Assume new battery is 100%
            )
            
            # Requirement 4.4: Update old battery status to "charging" in DynamoDB
            batteries_table = os.getenv('DYNAMODB_BATTERIES_TABLE', 'ecovolt-dev-batteries')
            old_battery_id = swap['old_battery_id']
            station_id = swap['station_id']
            
            if old_battery_id:
                # Find the old battery's current location (might be with bike)
                # Update it to charging status at the station
                DynamoDBHelper.put_item(
                    table_name=batteries_table,
                    item={
                        'station_id': station_id,
                        'battery_id': old_battery_id,
                        'status': 'charging',
                        'charge_level': 0,  # Will be updated by IoT
                        'health': 100,
                        'cycles': 0,
                        'last_charged': datetime.now().isoformat()
                    }
                )
            
            # Requirement 4.5: Update new battery status to "in-use" in DynamoDB
            DynamoDBHelper.update_item(
                table_name=batteries_table,
                key={'station_id': station_id, 'battery_id': new_battery_id},
                update_expression='SET #status = :status, bike_id = :bike_id',
                expression_values={
                    ':status': 'in_use',
                    ':bike_id': bike_id
                },
                expression_names={'#status': 'status'}
            )
            
            # Increment user's total swaps count
            cursor.execute(
                "UPDATE users SET total_swaps = total_swaps + 1 WHERE user_id = %s",
                (user_id,)
            )
        
        # Requirement 4.6: Send push notification
        from utils.notifications import notify_swap_complete
        notify_swap_complete(user_id, swap_id, station['name'], float(swap['cost']))
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Swap completed successfully',
                'swap': {
                    'swap_id': updated_swap['swap_id'],
                    'bike_id': updated_swap['bike_id'],
                    'station_id': updated_swap['station_id'],
                    'old_battery_id': updated_swap['old_battery_id'],
                    'new_battery_id': updated_swap['new_battery_id'],
                    'cost': float(updated_swap['cost']),
                    'status': updated_swap['status'],
                    'created_at': updated_swap['created_at'].isoformat() if updated_swap.get('created_at') else None,
                    'completed_at': updated_swap['completed_at'].isoformat() if updated_swap.get('completed_at') else None,
                    'duration_seconds': updated_swap['duration_seconds']
                }
            })
        }
        
    except Exception as e:
        print(f"Error completing swap: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def get_swap_status(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /swaps/{id}
    Get swap status
    
    Requirements: 3.4, 4.3
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
        
        # Get swap ID from path
        swap_id = event.get('pathParameters', {}).get('id')
        if not swap_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing swap ID'
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Get swap with station details
            cursor.execute(
                """
                SELECT s.*, st.name as station_name, st.address as station_address
                FROM swaps s
                JOIN stations st ON s.station_id = st.station_id
                WHERE s.swap_id = %s
                """,
                (swap_id,)
            )
            swap = cursor.fetchone()
        
        if not swap:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Swap not found',
                    'details': f'Swap {swap_id} does not exist'
                })
            }
        
        # Verify swap belongs to user
        if swap['user_id'] != user_id:
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'This swap does not belong to you'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'swap': {
                    'swap_id': swap['swap_id'],
                    'bike_id': swap['bike_id'],
                    'station_id': swap['station_id'],
                    'station_name': swap['station_name'],
                    'station_address': swap['station_address'],
                    'old_battery_id': swap['old_battery_id'],
                    'new_battery_id': swap['new_battery_id'],
                    'cost': float(swap['cost']),
                    'status': swap['status'],
                    'created_at': swap['created_at'].isoformat() if swap.get('created_at') else None,
                    'completed_at': swap['completed_at'].isoformat() if swap.get('completed_at') else None,
                    'duration_seconds': swap['duration_seconds']
                }
            })
        }
        
    except Exception as e:
        print(f"Error getting swap status: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def get_swap_history(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /swaps/history?page={page}&page_size={page_size}
    Get user swap history with pagination
    
    Requirements: 5.1, 5.2, 5.3, 5.4
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
            
            # Requirement 5.1: Get all swaps for user sorted by timestamp descending
            # Requirement 5.2: Include swap_id, station_name, timestamp, cost, status
            cursor.execute(
                Queries.GET_USER_SWAP_HISTORY,
                (user_id, page_size, offset)
            )
            swaps = cursor.fetchall()
            
            # Get total count for pagination metadata
            cursor.execute(
                "SELECT COUNT(*) as total FROM swaps WHERE user_id = %s",
                (user_id,)
            )
            total_result = cursor.fetchone()
            total_count = total_result['total'] if total_result else 0
        
        # Calculate pagination metadata
        total_pages = (total_count + page_size - 1) // page_size if total_count > 0 else 0
        has_next = page < total_pages
        has_prev = page > 1
        
        # Requirement 5.5: Return empty list if no history
        swap_list = []
        for swap in swaps:
            swap_list.append({
                'swap_id': swap['swap_id'],
                'bike_id': swap['bike_id'],
                'station_id': swap['station_id'],
                'station_name': swap['station_name'],
                'station_address': swap['station_address'],
                'old_battery_id': swap['old_battery_id'],
                'new_battery_id': swap['new_battery_id'],
                'cost': float(swap['cost']),
                'status': swap['status'],
                'created_at': swap['created_at'].isoformat() if swap.get('created_at') else None,
                'completed_at': swap['completed_at'].isoformat() if swap.get('completed_at') else None,
                'duration_seconds': swap['duration_seconds']
            })
        
        # Requirement 5.4: Return page with total count and metadata
        return {
            'statusCode': 200,
            'body': json.dumps({
                'swaps': swap_list,
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
        print(f"Error getting swap history: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }
