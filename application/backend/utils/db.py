"""
Database Utilities
Handles connections to RDS PostgreSQL and DynamoDB
"""

import os
import json
import boto3
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Dict, List, Optional, Any
from contextlib import contextmanager
from .retry import retry_on_db_error, retry_on_dynamodb_error

# AWS clients
dynamodb = boto3.resource('dynamodb')


@contextmanager
def get_db_connection():
    """
    Context manager for PostgreSQL database connection
    
    Credentials are injected via environment variables at deploy time by Terraform.
    No runtime AWS API calls needed - works entirely within VPC.
    
    Usage:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM stations")
    """
    # Read credentials directly from environment (injected by Terraform)
    db_host = os.getenv('DB_HOST')
    db_name = os.getenv('DB_NAME', 'ecovolt')
    db_user = os.getenv('DB_USER')
    db_pass = os.getenv('DB_PASS')
    
    if not all([db_host, db_user, db_pass]):
        raise ValueError("Database credentials not found in environment variables")
    
    conn = psycopg2.connect(
        host=db_host,
        database=db_name,
        user=db_user,
        password=db_pass,
        cursor_factory=RealDictCursor
    )
    
    try:
        yield conn
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()


@retry_on_db_error(max_attempts=3)
def execute_query(query: str, params: tuple = None, fetch_one: bool = False, 
                 fetch_all: bool = True) -> Optional[Any]:
    """
    Execute a database query with retry logic
    
    Requirements: 14.4
    
    Args:
        query: SQL query string
        params: Query parameters tuple
        fetch_one: Return single row
        fetch_all: Return all rows (default)
        
    Returns:
        Query results or None
    """
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(query, params)
        
        if fetch_one:
            return cursor.fetchone()
        elif fetch_all:
            return cursor.fetchall()
        else:
            return cursor.rowcount


@retry_on_db_error(max_attempts=3)
def execute_transaction(queries: List[tuple]) -> bool:
    """
    Execute multiple queries in a transaction with retry logic
    
    Requirements: 14.4
    
    Args:
        queries: List of (query, params) tuples
        
    Returns:
        True if successful, raises exception otherwise
    """
    with get_db_connection() as conn:
        cursor = conn.cursor()
        for query, params in queries:
            cursor.execute(query, params)
        return True


class DynamoDBHelper:
    """Helper class for DynamoDB operations with retry logic"""
    
    @staticmethod
    def get_table(table_name: str):
        """Get DynamoDB table"""
        return dynamodb.Table(table_name)
    
    @staticmethod
    @retry_on_dynamodb_error(max_attempts=3)
    def put_item(table_name: str, item: Dict) -> bool:
        """Put item in DynamoDB table with retry logic"""
        try:
            table = DynamoDBHelper.get_table(table_name)
            table.put_item(Item=item)
            return True
        except Exception as e:
            print(f"Error putting item in {table_name}: {str(e)}")
            raise
    
    @staticmethod
    @retry_on_dynamodb_error(max_attempts=3)
    def get_item(table_name: str, key: Dict) -> Optional[Dict]:
        """Get item from DynamoDB table with retry logic"""
        try:
            table = DynamoDBHelper.get_table(table_name)
            response = table.get_item(Key=key)
            return response.get('Item')
        except Exception as e:
            print(f"Error getting item from {table_name}: {str(e)}")
            raise
    
    @staticmethod
    @retry_on_dynamodb_error(max_attempts=3)
    def query(table_name: str, key_condition: str, expression_values: Dict) -> List[Dict]:
        """Query DynamoDB table with retry logic"""
        try:
            table = DynamoDBHelper.get_table(table_name)
            response = table.query(
                KeyConditionExpression=key_condition,
                ExpressionAttributeValues=expression_values
            )
            return response.get('Items', [])
        except Exception as e:
            print(f"Error querying {table_name}: {str(e)}")
            raise
    
    @staticmethod
    @retry_on_dynamodb_error(max_attempts=3)
    def scan(table_name: str, filter_expression: Optional[str] = None, 
             expression_values: Optional[Dict] = None) -> List[Dict]:
        """Scan DynamoDB table with retry logic"""
        try:
            table = DynamoDBHelper.get_table(table_name)
            
            if filter_expression and expression_values:
                response = table.scan(
                    FilterExpression=filter_expression,
                    ExpressionAttributeValues=expression_values
                )
            else:
                response = table.scan()
            
            return response.get('Items', [])
        except Exception as e:
            print(f"Error scanning {table_name}: {str(e)}")
            raise
    
    @staticmethod
    @retry_on_dynamodb_error(max_attempts=3)
    def update_item(table_name: str, key: Dict, update_expression: str,
                   expression_values: Dict, expression_names: Dict = None) -> bool:
        """Update item in DynamoDB table with retry logic"""
        try:
            table = DynamoDBHelper.get_table(table_name)
            kwargs = {
                'Key': key,
                'UpdateExpression': update_expression,
                'ExpressionAttributeValues': expression_values
            }
            if expression_names:
                kwargs['ExpressionAttributeNames'] = expression_names
            table.update_item(**kwargs)
            return True
        except Exception as e:
            print(f"Error updating item in {table_name}: {str(e)}")
            raise
    
    @staticmethod
    @retry_on_dynamodb_error(max_attempts=3)
    def delete_item(table_name: str, key: Dict) -> bool:
        """Delete item from DynamoDB table with retry logic"""
        try:
            table = DynamoDBHelper.get_table(table_name)
            table.delete_item(Key=key)
            return True
        except Exception as e:
            print(f"Error deleting item from {table_name}: {str(e)}")
            raise


# SQL Queries
class Queries:
    """Common SQL queries"""
    
    # Stations
    GET_ALL_STATIONS = """
        SELECT * FROM stations WHERE status = 'active' ORDER BY name
    """
    
    GET_STATION_BY_ID = """
        SELECT * FROM stations WHERE station_id = %s
    """
    
    GET_NEARBY_STATIONS = """
        SELECT *, 
               (6371 * acos(cos(radians(%s)) * cos(radians(latitude)) * 
               cos(radians(longitude) - radians(%s)) + sin(radians(%s)) * 
               sin(radians(latitude)))) AS distance
        FROM stations
        WHERE status = 'active'
        HAVING distance < %s
        ORDER BY distance
        LIMIT %s
    """
    
    CREATE_STATION = """
        INSERT INTO stations (station_id, name, latitude, longitude, address, 
                            city, status, total_capacity, operating_hours, 
                            amenities, pricing, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
        RETURNING *
    """
    
    UPDATE_STATION = """
        UPDATE stations 
        SET name = %s, address = %s, status = %s, operating_hours = %s,
            amenities = %s, pricing = %s, updated_at = NOW()
        WHERE station_id = %s
        RETURNING *
    """
    
    # Users
    GET_USER_BY_ID = """
        SELECT * FROM users WHERE user_id = %s
    """
    
    GET_USER_BY_EMAIL = """
        SELECT * FROM users WHERE email = %s
    """
    
    CREATE_USER = """
        INSERT INTO users (user_id, email, name, phone, wallet_balance, 
                          subscription, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, NOW())
        RETURNING *
    """
    
    UPDATE_USER_PROFILE = """
        UPDATE users 
        SET name = %s, phone = %s, updated_at = NOW()
        WHERE user_id = %s
        RETURNING *
    """
    
    UPDATE_WALLET_BALANCE = """
        UPDATE users 
        SET wallet_balance = wallet_balance + %s, updated_at = NOW()
        WHERE user_id = %s
        RETURNING wallet_balance
    """
    
    # Swaps
    CREATE_SWAP = """
        INSERT INTO swaps (swap_id, user_id, bike_id, station_id, 
                          old_battery_id, new_battery_id, cost, status, 
                          created_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW())
        RETURNING *
    """
    
    UPDATE_SWAP_STATUS = """
        UPDATE swaps 
        SET status = %s, completed_at = NOW(), duration_seconds = %s
        WHERE swap_id = %s
        RETURNING *
    """
    
    GET_USER_SWAP_HISTORY = """
        SELECT s.*, st.name as station_name, st.address as station_address
        FROM swaps s
        JOIN stations st ON s.station_id = st.station_id
        WHERE s.user_id = %s
        ORDER BY s.created_at DESC
        LIMIT %s OFFSET %s
    """
    
    # Bikes
    GET_BIKE_BY_ID = """
        SELECT * FROM bikes WHERE bike_id = %s
    """
    
    UPDATE_BIKE_BATTERY = """
        UPDATE bikes 
        SET battery_id = %s, battery_level = %s, last_swap = NOW(), 
            updated_at = NOW()
        WHERE bike_id = %s
        RETURNING *
    """
    
    # Wallet Transactions
    CREATE_WALLET_TRANSACTION = """
        INSERT INTO wallet_transactions (transaction_id, user_id, type, amount, 
                                        balance_after, reference, created_at)
        VALUES (%s, %s, %s, %s, %s, %s, NOW())
        RETURNING *
    """
    
    GET_WALLET_TRANSACTIONS = """
        SELECT * FROM wallet_transactions 
        WHERE user_id = %s 
        ORDER BY created_at DESC
        LIMIT %s OFFSET %s
    """
