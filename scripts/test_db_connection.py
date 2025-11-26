#!/usr/bin/env python3
"""
Test script to verify database connection using environment variables
Simulates how Lambda will connect to RDS
"""

import os
import sys

# Simulate Lambda environment
os.environ['DB_HOST'] = 'localhost'  # Replace with actual RDS endpoint for testing
os.environ['DB_NAME'] = 'ecovolt'
os.environ['DB_USER'] = 'ecovolt_admin'
os.environ['DB_PASS'] = 'test_password'  # Replace with actual password for testing

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'application', 'backend'))

try:
    from utils.db import get_db_connection
    
    print("🔍 Testing database connection...")
    print(f"   Host: {os.environ['DB_HOST']}")
    print(f"   Database: {os.environ['DB_NAME']}")
    print(f"   User: {os.environ['DB_USER']}")
    print()
    
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"✅ Connection successful!")
        print(f"   PostgreSQL version: {version['version']}")
        
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("   Make sure psycopg2 is installed: pip install psycopg2-binary")
    sys.exit(1)
    
except ValueError as e:
    print(f"❌ Configuration error: {e}")
    print("   Set DB_HOST, DB_NAME, DB_USER, DB_PASS environment variables")
    sys.exit(1)
    
except Exception as e:
    print(f"❌ Connection failed: {e}")
    sys.exit(1)
