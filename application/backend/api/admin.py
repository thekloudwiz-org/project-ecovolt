"""
Admin API Endpoints
Handles administrative operations and analytics
"""

import json
import os
import uuid
from typing import Dict, Any
from datetime import datetime, timedelta
from utils.db import get_db_connection, DynamoDBHelper, Queries
from utils.validators import validate_station_data, validate_pagination, validate_date_range


def check_admin_role(user: Dict[str, Any]) -> bool:
    """
    Check if user has admin role
    
    Requirements: 8.1, 9.6
    """
    # Check if user has admin role in Cognito groups
    groups = user.get('groups', [])
    if isinstance(groups, str):
        groups = [groups]
    return 'admin' in groups or 'admins' in groups or user.get('is_admin', False)


def get_dashboard(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /admin/dashboard
    Dashboard statistics with admin role check
    
    Requirements: 8.1, 8.2, 8.3, 8.4
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
        
        # Requirement 8.1: Verify user has admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Requirement 8.2: Total swaps today
            cursor.execute(
                "SELECT COUNT(*) as count FROM swaps WHERE DATE(created_at) = CURRENT_DATE"
            )
            swaps_today = cursor.fetchone()['count']
            
            # Requirement 8.2: Total revenue today
            cursor.execute(
                "SELECT COALESCE(SUM(cost), 0) as revenue FROM swaps WHERE DATE(created_at) = CURRENT_DATE"
            )
            revenue_today = float(cursor.fetchone()['revenue'])
            
            # Requirement 8.2: Active riders count (users who have done at least one swap)
            cursor.execute(
                "SELECT COUNT(DISTINCT user_id) as count FROM swaps"
            )
            active_riders = cursor.fetchone()['count']
            
            # Requirement 8.2: Total stations count
            cursor.execute(
                "SELECT COUNT(*) as count FROM stations WHERE status = 'active'"
            )
            total_stations = cursor.fetchone()['count']
            
            # Requirement 8.3: Swap trend data for last 7 days
            cursor.execute(
                """
                SELECT DATE(created_at) as date, COUNT(*) as swaps
                FROM swaps
                WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
                GROUP BY DATE(created_at)
                ORDER BY date
                """
            )
            swap_trend = cursor.fetchall()
            
            # Requirement 8.4: Top 5 stations by swap volume
            cursor.execute(
                """
                SELECT s.station_id, s.name, COUNT(sw.swap_id) as swap_count
                FROM stations s
                LEFT JOIN swaps sw ON s.station_id = sw.station_id
                GROUP BY s.station_id, s.name
                ORDER BY swap_count DESC
                LIMIT 5
                """
            )
            top_stations = cursor.fetchall()
        
        # Format swap trend data
        trend_data = []
        for row in swap_trend:
            trend_data.append({
                'date': row['date'].isoformat() if row.get('date') else None,
                'swaps': row['swaps']
            })
        
        # Format top stations data
        top_stations_data = []
        for row in top_stations:
            top_stations_data.append({
                'station_id': row['station_id'],
                'name': row['name'],
                'swap_count': row['swap_count']
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'metrics': {
                    'swaps_today': swaps_today,
                    'revenue_today': revenue_today,
                    'active_riders': active_riders,
                    'total_stations': total_stations
                },
                'swap_trend_7days': trend_data,
                'top_stations': top_stations_data
            })
        }
        
    except Exception as e:
        print(f"Error getting dashboard: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def get_analytics(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /admin/analytics?start_date={date}&end_date={date}
    Time-series analytics with date range
    
    Requirements: 11.1, 11.2, 11.3, 11.4, 11.5
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get date range parameters
        params = event.get('queryStringParameters') or {}
        
        # Requirement 11.5: Default date range of last 30 days
        end_date = params.get('end_date', datetime.now().date().isoformat())
        start_date = params.get('start_date', (datetime.now().date() - timedelta(days=30)).isoformat())
        
        # Validate date range
        valid, error = validate_date_range(start_date, end_date)
        if not valid:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid date range',
                    'details': error
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Requirement 11.1: Swap volume, revenue, and average swap duration by day
            cursor.execute(
                """
                SELECT 
                    DATE(created_at) as date,
                    COUNT(*) as swap_volume,
                    COALESCE(SUM(cost), 0) as revenue,
                    COALESCE(AVG(duration_seconds), 0) as avg_duration
                FROM swaps
                WHERE DATE(created_at) BETWEEN %s AND %s
                GROUP BY DATE(created_at)
                ORDER BY date
                """,
                (start_date, end_date)
            )
            daily_analytics = cursor.fetchall()
            
            # Requirement 11.3: New user registrations by day
            cursor.execute(
                """
                SELECT 
                    DATE(created_at) as date,
                    COUNT(*) as new_users
                FROM users
                WHERE DATE(created_at) BETWEEN %s AND %s
                GROUP BY DATE(created_at)
                ORDER BY date
                """,
                (start_date, end_date)
            )
            user_analytics = cursor.fetchall()
        
        # Format analytics data
        analytics_data = []
        for row in daily_analytics:
            analytics_data.append({
                'date': row['date'].isoformat() if row.get('date') else None,
                'swap_volume': row['swap_volume'],
                'revenue': float(row['revenue']),
                'avg_duration_seconds': float(row['avg_duration'])
            })
        
        user_data = []
        for row in user_analytics:
            user_data.append({
                'date': row['date'].isoformat() if row.get('date') else None,
                'new_users': row['new_users']
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'date_range': {
                    'start_date': start_date,
                    'end_date': end_date
                },
                'daily_analytics': analytics_data,
                'user_analytics': user_data
            })
        }
        
    except Exception as e:
        print(f"Error getting analytics: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def get_station_analytics(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /admin/analytics/stations?start_date={date}&end_date={date}
    Per-station analytics
    
    Requirements: 11.2
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get date range parameters
        params = event.get('queryStringParameters') or {}
        end_date = params.get('end_date', datetime.now().date().isoformat())
        start_date = params.get('start_date', (datetime.now().date() - timedelta(days=30)).isoformat())
        
        # Validate date range
        valid, error = validate_date_range(start_date, end_date)
        if not valid:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid date range',
                    'details': error
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Requirement 11.2: Swap count and revenue per station
            cursor.execute(
                """
                SELECT 
                    s.station_id,
                    s.name,
                    s.city,
                    COUNT(sw.swap_id) as swap_count,
                    COALESCE(SUM(sw.cost), 0) as revenue
                FROM stations s
                LEFT JOIN swaps sw ON s.station_id = sw.station_id
                    AND DATE(sw.created_at) BETWEEN %s AND %s
                GROUP BY s.station_id, s.name, s.city
                ORDER BY swap_count DESC
                """,
                (start_date, end_date)
            )
            station_analytics = cursor.fetchall()
        
        # Format station analytics
        analytics_data = []
        for row in station_analytics:
            analytics_data.append({
                'station_id': row['station_id'],
                'name': row['name'],
                'city': row['city'],
                'swap_count': row['swap_count'],
                'revenue': float(row['revenue'])
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'date_range': {
                    'start_date': start_date,
                    'end_date': end_date
                },
                'station_analytics': analytics_data
            })
        }
        
    except Exception as e:
        print(f"Error getting station analytics: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def get_revenue_analytics(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /admin/analytics/revenue?start_date={date}&end_date={date}
    Revenue breakdown
    
    Requirements: 11.3
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get date range parameters
        params = event.get('queryStringParameters') or {}
        end_date = params.get('end_date', datetime.now().date().isoformat())
        start_date = params.get('start_date', (datetime.now().date() - timedelta(days=30)).isoformat())
        
        # Validate date range
        valid, error = validate_date_range(start_date, end_date)
        if not valid:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid date range',
                    'details': error
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Total revenue
            cursor.execute(
                """
                SELECT COALESCE(SUM(cost), 0) as total_revenue
                FROM swaps
                WHERE DATE(created_at) BETWEEN %s AND %s
                """,
                (start_date, end_date)
            )
            total_revenue = float(cursor.fetchone()['total_revenue'])
            
            # Revenue by station
            cursor.execute(
                """
                SELECT 
                    s.name as station_name,
                    COALESCE(SUM(sw.cost), 0) as revenue
                FROM stations s
                LEFT JOIN swaps sw ON s.station_id = sw.station_id
                    AND DATE(sw.created_at) BETWEEN %s AND %s
                GROUP BY s.name
                ORDER BY revenue DESC
                """,
                (start_date, end_date)
            )
            revenue_by_station = cursor.fetchall()
            
            # Revenue by day
            cursor.execute(
                """
                SELECT 
                    DATE(created_at) as date,
                    COALESCE(SUM(cost), 0) as revenue
                FROM swaps
                WHERE DATE(created_at) BETWEEN %s AND %s
                GROUP BY DATE(created_at)
                ORDER BY date
                """,
                (start_date, end_date)
            )
            revenue_by_day = cursor.fetchall()
        
        # Format data
        station_breakdown = []
        for row in revenue_by_station:
            station_breakdown.append({
                'station_name': row['station_name'],
                'revenue': float(row['revenue'])
            })
        
        daily_revenue = []
        for row in revenue_by_day:
            daily_revenue.append({
                'date': row['date'].isoformat() if row.get('date') else None,
                'revenue': float(row['revenue'])
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'date_range': {
                    'start_date': start_date,
                    'end_date': end_date
                },
                'total_revenue': total_revenue,
                'revenue_by_station': station_breakdown,
                'daily_revenue': daily_revenue
            })
        }
        
    except Exception as e:
        print(f"Error getting revenue analytics: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def get_battery_analytics(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /admin/analytics/batteries
    Battery health metrics
    
    Requirements: 11.4
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get battery data from DynamoDB
        batteries_table = os.getenv('DYNAMODB_BATTERIES_TABLE', 'ecovolt-dev-batteries')
        batteries = DynamoDBHelper.scan(table_name=batteries_table)
        
        # Calculate metrics
        total_batteries = len(batteries)
        avg_health = sum(b.get('health', 0) for b in batteries) / total_batteries if total_batteries > 0 else 0
        avg_cycles = sum(b.get('cycles', 0) for b in batteries) / total_batteries if total_batteries > 0 else 0
        
        # Battery status distribution
        status_distribution = {}
        for battery in batteries:
            status = battery.get('status', 'unknown')
            status_distribution[status] = status_distribution.get(status, 0) + 1
        
        # Health distribution
        health_ranges = {
            'excellent': 0,  # 90-100%
            'good': 0,       # 70-89%
            'fair': 0,       # 50-69%
            'poor': 0        # <50%
        }
        
        for battery in batteries:
            health = battery.get('health', 0)
            if health >= 90:
                health_ranges['excellent'] += 1
            elif health >= 70:
                health_ranges['good'] += 1
            elif health >= 50:
                health_ranges['fair'] += 1
            else:
                health_ranges['poor'] += 1
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'total_batteries': total_batteries,
                'average_health': round(avg_health, 2),
                'average_cycles': round(avg_cycles, 2),
                'status_distribution': status_distribution,
                'health_distribution': health_ranges
            })
        }
        
    except Exception as e:
        print(f"Error getting battery analytics: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }



def list_stations(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /admin/stations?page={page}&page_size={page_size}
    List all stations with pagination
    
    Requirements: 9.1, 9.6
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
        
        # Requirement 9.6: Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
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
            
            # Get stations with pagination
            cursor.execute(
                """
                SELECT * FROM stations 
                ORDER BY created_at DESC 
                LIMIT %s OFFSET %s
                """,
                (page_size, offset)
            )
            stations = cursor.fetchall()
            
            # Get total count
            cursor.execute("SELECT COUNT(*) as total FROM stations")
            total_count = cursor.fetchone()['total']
        
        # Calculate pagination metadata
        total_pages = (total_count + page_size - 1) // page_size if total_count > 0 else 0
        has_next = page < total_pages
        has_prev = page > 1
        
        # Format stations
        station_list = []
        for station in stations:
            station_list.append({
                'station_id': station['station_id'],
                'name': station['name'],
                'latitude': float(station['latitude']),
                'longitude': float(station['longitude']),
                'address': station['address'],
                'city': station['city'],
                'status': station['status'],
                'total_capacity': station['total_capacity'],
                'operating_hours': station.get('operating_hours'),
                'amenities': station.get('amenities'),
                'pricing': station.get('pricing'),
                'created_at': station['created_at'].isoformat() if station.get('created_at') else None,
                'updated_at': station['updated_at'].isoformat() if station.get('updated_at') else None
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'stations': station_list,
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
        print(f"Error listing stations: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def create_station(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    POST /admin/stations
    Create station with validation
    
    Requirements: 9.1, 9.2, 9.3, 9.6
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
        
        # Requirement 9.6: Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))

        # Log received data for debugging
        print(json.dumps({
            'event': 'create_station_request',
            'body_keys': list(body.keys()),
            'body': body
        }))

        # Requirement 9.1: Validate all required fields are present
        # Requirement 9.2: Validate latitude and longitude
        valid, error = validate_station_data(body)
        if not valid:
            print(json.dumps({
                'event': 'validation_failed',
                'error': error,
                'received_data': body
            }))
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid station data',
                    'details': error
                })
            }
        
        # Requirement 9.3: Generate unique station ID
        station_id = f"STN-{uuid.uuid4()}"
        
        # Parse JSON fields
        operating_hours = body.get('operating_hours', {})
        amenities = body.get('amenities', [])
        pricing = body.get('pricing', {})
        
        if isinstance(operating_hours, dict):
            operating_hours = json.dumps(operating_hours)
        if isinstance(amenities, list):
            amenities = json.dumps(amenities)
        if isinstance(pricing, dict):
            pricing = json.dumps(pricing)
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                Queries.CREATE_STATION,
                (station_id, body['name'], body['latitude'], body['longitude'],
                 body['address'], body['city'], 'active', body['total_capacity'],
                 operating_hours, amenities, pricing)
            )
            station = cursor.fetchone()
        
        return {
            'statusCode': 201,
            'body': json.dumps({
                'message': 'Station created successfully',
                'station': {
                    'station_id': station['station_id'],
                    'name': station['name'],
                    'latitude': float(station['latitude']),
                    'longitude': float(station['longitude']),
                    'address': station['address'],
                    'city': station['city'],
                    'status': station['status'],
                    'total_capacity': station['total_capacity'],
                    'created_at': station['created_at'].isoformat() if station.get('created_at') else None
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
        print(f"Error creating station: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def update_station(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    PUT /admin/stations/{id}
    Update station (partial updates)
    
    Requirements: 9.4, 9.6
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
        
        # Requirement 9.6: Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get station ID from path
        station_id = event.get('pathParameters', {}).get('id')
        if not station_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing station ID'
                })
            }
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Build dynamic update query based on provided fields
        update_fields = []
        update_values = []
        
        if 'name' in body:
            update_fields.append('name = %s')
            update_values.append(body['name'])
        
        if 'address' in body:
            update_fields.append('address = %s')
            update_values.append(body['address'])
        
        if 'status' in body:
            update_fields.append('status = %s')
            update_values.append(body['status'])
        
        if 'operating_hours' in body:
            update_fields.append('operating_hours = %s')
            update_values.append(json.dumps(body['operating_hours']) if isinstance(body['operating_hours'], dict) else body['operating_hours'])
        
        if 'amenities' in body:
            update_fields.append('amenities = %s')
            update_values.append(json.dumps(body['amenities']) if isinstance(body['amenities'], list) else body['amenities'])
        
        if 'pricing' in body:
            update_fields.append('pricing = %s')
            update_values.append(json.dumps(body['pricing']) if isinstance(body['pricing'], dict) else body['pricing'])
        
        if not update_fields:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'No fields to update'
                })
            }
        
        # Requirement 9.4: Update updated_at timestamp
        update_fields.append('updated_at = NOW()')
        update_values.append(station_id)
        
        # Build and execute query
        query = f"""
            UPDATE stations 
            SET {', '.join(update_fields)}
            WHERE station_id = %s
            RETURNING *
        """
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, update_values)
            station = cursor.fetchone()
        
        if not station:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Station not found'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Station updated successfully',
                'station': {
                    'station_id': station['station_id'],
                    'name': station['name'],
                    'address': station['address'],
                    'status': station['status'],
                    'updated_at': station['updated_at'].isoformat() if station.get('updated_at') else None
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
        print(f"Error updating station: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def delete_station(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    DELETE /admin/stations/{id}
    Soft delete station
    
    Requirements: 9.5, 9.6
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
        
        # Requirement 9.6: Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get station ID from path
        station_id = event.get('pathParameters', {}).get('id')
        if not station_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing station ID'
                })
            }
        
        # Requirement 9.5: Soft delete (set status to inactive)
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                UPDATE stations 
                SET status = 'inactive', updated_at = NOW()
                WHERE station_id = %s
                RETURNING *
                """,
                (station_id,)
            )
            station = cursor.fetchone()
        
        if not station:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Station not found'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Station deleted successfully (soft delete)',
                'station_id': station['station_id'],
                'status': station['status']
            })
        }
        
    except Exception as e:
        print(f"Error deleting station: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }



def list_bikes(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /admin/bikes?page={page}&page_size={page_size}
    List all bikes with pagination
    
    Requirements: 10.1, 10.5
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
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
            
            # Get bikes with pagination
            cursor.execute(
                """
                SELECT * FROM bikes 
                ORDER BY created_at DESC 
                LIMIT %s OFFSET %s
                """,
                (page_size, offset)
            )
            bikes = cursor.fetchall()
            
            # Get total count
            cursor.execute("SELECT COUNT(*) as total FROM bikes")
            total_count = cursor.fetchone()['total']
        
        # Calculate pagination metadata
        total_pages = (total_count + page_size - 1) // page_size if total_count > 0 else 0
        has_next = page < total_pages
        has_prev = page > 1
        
        # Requirement 10.6: Include telemetry data
        telemetry_table = os.getenv('DYNAMODB_TELEMETRY_TABLE')

        # Format bikes
        bike_list = []
        for bike in bikes:
            bike_data = {
                'bike_id': bike['bike_id'],
                'user_id': bike['user_id'],
                'battery_id': bike['battery_id'],
                'model': bike['model'],
                'status': bike['status'],
                'battery_level': bike.get('battery_level'),
                'odometer': float(bike['odometer']) if bike.get('odometer') else None,
                'last_swap': bike['last_swap'].isoformat() if bike.get('last_swap') else None,
                'created_at': bike['created_at'].isoformat() if bike.get('created_at') else None
            }

            # Get latest telemetry (gracefully handle missing table or data)
            try:
                # Query with bikeId key (matches DynamoDB table schema)
                telemetry_items = DynamoDBHelper.query(
                    table_name=telemetry_table,
                    key_condition='bikeId = :bikeId',
                    expression_values={':bikeId': bike['bike_id']}
                )

                if telemetry_items:
                    telemetry_items.sort(key=lambda x: x.get('lastUpdated', 0), reverse=True)
                    latest = telemetry_items[0]
                    bike_data['latest_telemetry'] = {
                        'battery_level': latest.get('batteryLevel'),
                        'location': latest.get('location'),
                        'timestamp': latest.get('lastUpdated')
                    }
            except Exception as telemetry_error:
                # Log but don't fail - telemetry is optional
                print(f"Could not fetch telemetry for bike {bike['bike_id']}: {str(telemetry_error)}")
                bike_data['latest_telemetry'] = None

            bike_list.append(bike_data)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'bikes': bike_list,
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
        print(f"Error listing bikes: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def register_bike(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    POST /admin/bikes
    Register new bike
    
    Requirements: 10.1, 10.2
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Validate required fields
        if not body.get('bike_id') or not body.get('model'):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing required fields',
                    'details': 'bike_id and model are required'
                })
            }
        
        bike_id = body['bike_id']
        model = body['model']
        battery_id = body.get('battery_id')
        
        # Requirement 10.2: Set initial state (status=active, battery_level=100)
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO bikes (bike_id, user_id, battery_id, model, status, 
                                  battery_level, odometer, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, NOW())
                RETURNING *
                """,
                (bike_id, None, battery_id, model, 'active', 100, 0.0)
            )
            bike = cursor.fetchone()
        
        return {
            'statusCode': 201,
            'body': json.dumps({
                'message': 'Bike registered successfully',
                'bike': {
                    'bike_id': bike['bike_id'],
                    'model': bike['model'],
                    'status': bike['status'],
                    'battery_level': bike['battery_level'],
                    'battery_id': bike['battery_id'],
                    'created_at': bike['created_at'].isoformat() if bike.get('created_at') else None
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
        print(f"Error registering bike: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def update_bike(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    PUT /admin/bikes/{id}
    Update bike details
    
    Requirements: 10.4
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get bike ID from path
        bike_id = event.get('pathParameters', {}).get('id')
        if not bike_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing bike ID'
                })
            }
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))

        # Build dynamic update query
        update_fields = []
        update_values = []

        if 'model' in body:
            update_fields.append('model = %s')
            update_values.append(body['model'])

        if 'status' in body:
            update_fields.append('status = %s')
            update_values.append(body['status'])

            # Auto-unassign bike if status changes from active to inactive/maintenance
            if body['status'] in ['inactive', 'maintenance']:
                update_fields.append('user_id = NULL')

        if 'battery_id' in body:
            update_fields.append('battery_id = %s')
            update_values.append(body['battery_id'])

        if not update_fields:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'No fields to update'
                })
            }

        update_fields.append('updated_at = NOW()')
        update_values.append(bike_id)

        query = f"""
            UPDATE bikes
            SET {', '.join(update_fields)}
            WHERE bike_id = %s
            RETURNING *
        """

        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, update_values)
            bike = cursor.fetchone()
        
        if not bike:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Bike not found'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Bike updated successfully',
                'bike': {
                    'bike_id': bike['bike_id'],
                    'model': bike['model'],
                    'status': bike['status'],
                    'battery_id': bike['battery_id'],
                    'updated_at': bike['updated_at'].isoformat() if bike.get('updated_at') else None
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
        print(f"Error updating bike: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def assign_bike(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    PUT /admin/bikes/{id}/assign
    Assign bike to user
    
    Requirements: 10.3
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get bike ID from path
        bike_id = event.get('pathParameters', {}).get('id')
        if not bike_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing bike ID'
                })
            }
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        user_id = body.get('user_id')
        
        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing user_id',
                    'details': 'user_id is required to assign bike'
                })
            }
        
        # Requirement 10.3: Update bike's user_id field
        with get_db_connection() as conn:
            cursor = conn.cursor()

            # Verify user exists
            cursor.execute(Queries.GET_USER_BY_ID, (user_id,))
            user_record = cursor.fetchone()

            if not user_record:
                return {
                    'statusCode': 404,
                    'body': json.dumps({
                        'error': 'User not found',
                        'details': f'User {user_id} does not exist'
                    })
                }

            # Check if user already has an active bike assigned
            cursor.execute(
                """
                SELECT bike_id, model
                FROM bikes
                WHERE user_id = %s AND status = 'active'
                """,
                (user_id,)
            )
            existing_bike = cursor.fetchone()

            if existing_bike:
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'User already has an active bike assigned',
                        'details': f'User {user_id} is already assigned bike {existing_bike["bike_id"]} ({existing_bike["model"]}). Please unassign or deactivate the existing bike first.'
                    })
                }

            # Verify bike is active and not already assigned
            cursor.execute(
                """
                SELECT bike_id, status, user_id
                FROM bikes
                WHERE bike_id = %s
                """,
                (bike_id,)
            )
            bike_check = cursor.fetchone()

            if not bike_check:
                return {
                    'statusCode': 404,
                    'body': json.dumps({
                        'error': 'Bike not found'
                    })
                }

            if bike_check['status'] != 'active':
                return {
                    'statusCode': 400,
                    'body': json.dumps({
                        'error': 'Cannot assign inactive bike',
                        'details': f'Bike status is "{bike_check["status"]}". Only active bikes can be assigned.'
                    })
                }

            # Assign bike to user
            cursor.execute(
                """
                UPDATE bikes
                SET user_id = %s, updated_at = NOW()
                WHERE bike_id = %s
                RETURNING *
                """,
                (user_id, bike_id)
            )
            bike = cursor.fetchone()
        
        if not bike:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Bike not found'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Bike assigned successfully',
                'bike': {
                    'bike_id': bike['bike_id'],
                    'user_id': bike['user_id'],
                    'model': bike['model'],
                    'status': bike['status']
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
        print(f"Error assigning bike: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def unassign_bike(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    PUT /admin/bikes/{id}/unassign
    Unassign bike from user

    Requirements: 10.3
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

        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }

        # Get bike ID from path
        bike_id = event.get('pathParameters', {}).get('id')
        if not bike_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing bike ID'
                })
            }

        # Unassign bike
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                """
                UPDATE bikes
                SET user_id = NULL, updated_at = NOW()
                WHERE bike_id = %s
                RETURNING *
                """,
                (bike_id,)
            )
            bike = cursor.fetchone()

        if not bike:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Bike not found'
                })
            }

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Bike unassigned successfully',
                'bike': {
                    'bike_id': bike['bike_id'],
                    'user_id': bike['user_id'],
                    'model': bike['model'],
                    'status': bike['status']
                }
            })
        }

    except Exception as e:
        print(f"Error unassigning bike: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def list_users(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /admin/users?page={page}&page_size={page_size}
    List users with pagination
    
    Requirements: 8.1
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
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
            
            # Get users with pagination
            cursor.execute(
                """
                SELECT * FROM users 
                ORDER BY created_at DESC 
                LIMIT %s OFFSET %s
                """,
                (page_size, offset)
            )
            users = cursor.fetchall()
            
            # Get total count
            cursor.execute("SELECT COUNT(*) as total FROM users")
            total_count = cursor.fetchone()['total']
        
        # Calculate pagination metadata
        total_pages = (total_count + page_size - 1) // page_size if total_count > 0 else 0
        has_next = page < total_pages
        has_prev = page > 1
        
        # Format users
        user_list = []
        for u in users:
            user_list.append({
                'user_id': u['user_id'],
                'email': u['email'],
                'name': u['name'],
                'phone': u['phone'],
                'wallet_balance': float(u['wallet_balance']),
                'subscription': u['subscription'],
                'total_swaps': u.get('total_swaps', 0),
                'created_at': u['created_at'].isoformat() if u.get('created_at') else None
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'users': user_list,
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
        print(f"Error listing users: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def get_user_details(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /admin/users/{id}
    Get user details
    
    Requirements: 8.1
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get user ID from path
        user_id = event.get('pathParameters', {}).get('id')
        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing user ID'
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Get user details
            cursor.execute(Queries.GET_USER_BY_ID, (user_id,))
            user_data = cursor.fetchone()
            
            if not user_data:
                return {
                    'statusCode': 404,
                    'body': json.dumps({
                        'error': 'User not found'
                    })
                }
            
            # Get user's swap history
            cursor.execute(
                """
                SELECT COUNT(*) as total_swaps, 
                       COALESCE(SUM(cost), 0) as total_spent
                FROM swaps 
                WHERE user_id = %s
                """,
                (user_id,)
            )
            swap_stats = cursor.fetchone()
            
            # Get user's bikes
            cursor.execute(
                "SELECT * FROM bikes WHERE user_id = %s",
                (user_id,)
            )
            bikes = cursor.fetchall()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'user': {
                    'user_id': user_data['user_id'],
                    'email': user_data['email'],
                    'name': user_data['name'],
                    'phone': user_data['phone'],
                    'wallet_balance': float(user_data['wallet_balance']),
                    'subscription': user_data['subscription'],
                    'total_swaps': user_data.get('total_swaps', 0),
                    'created_at': user_data['created_at'].isoformat() if user_data.get('created_at') else None
                },
                'statistics': {
                    'total_swaps': swap_stats['total_swaps'],
                    'total_spent': float(swap_stats['total_spent']),
                    'bikes_count': len(bikes)
                },
                'bikes': [{'bike_id': b['bike_id'], 'model': b['model'], 'status': b['status']} for b in bikes]
            })
        }
        
    except Exception as e:
        print(f"Error getting user details: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def adjust_user_wallet(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    PUT /admin/users/{id}/wallet
    Adjust wallet balance (admin override)
    
    Requirements: 8.1
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
        
        # Verify admin role
        if not check_admin_role(user):
            return {
                'statusCode': 403,
                'body': json.dumps({
                    'error': 'Forbidden',
                    'details': 'Admin access required'
                })
            }
        
        # Get user ID from path
        user_id = event.get('pathParameters', {}).get('id')
        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing user ID'
                })
            }
        
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        adjustment = body.get('adjustment')
        reason = body.get('reason', 'Admin adjustment')
        
        if adjustment is None:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing adjustment amount'
                })
            }
        
        try:
            adjustment = float(adjustment)
        except (ValueError, TypeError):
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Invalid adjustment amount',
                    'details': 'Adjustment must be a valid number'
                })
            }
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            
            # Update wallet balance
            cursor.execute(
                Queries.UPDATE_WALLET_BALANCE,
                (adjustment, user_id)
            )
            new_balance_result = cursor.fetchone()
            new_balance = float(new_balance_result['wallet_balance'])
            
            # Create transaction record
            transaction_id = f"TXN-{uuid.uuid4()}"
            admin_user_id = user.get('user_id') or user.get('sub')
            
            cursor.execute(
                Queries.CREATE_WALLET_TRANSACTION,
                (transaction_id, user_id, 'adjustment', adjustment, new_balance, 
                 f"Admin adjustment by {admin_user_id}: {reason}")
            )
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Wallet balance adjusted successfully',
                'user_id': user_id,
                'adjustment': adjustment,
                'new_balance': new_balance,
                'transaction_id': transaction_id
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
        print(f"Error adjusting wallet: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }
