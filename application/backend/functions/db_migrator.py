"""
Database Migration Lambda Function
Runs SQL migrations against RDS PostgreSQL using runtime-installed psycopg2
"""

import json
import os
import boto3
import subprocess
import sys
from typing import Dict, Any, List

# Initialize AWS clients
s3 = boto3.client('s3')

# Install psycopg2-binary at runtime
def install_psycopg2():
    """Install psycopg2-binary at runtime"""
    subprocess.check_call([
        sys.executable, "-m", "pip", "install", 
        "psycopg2-binary==2.9.9", 
        "-t", "/tmp/", 
        "--no-cache-dir"
    ])
    sys.path.insert(0, '/tmp/')

# Try to import psycopg2, install if not available
try:
    import psycopg2
except ImportError:
    print("psycopg2 not found, installing...")
    install_psycopg2()
    import psycopg2


def get_db_connection():
    """
    Create database connection using credentials from environment variables.
    Credentials are injected by Terraform at deploy time - no AWS API calls needed.
    """
    db_host = os.environ.get('DB_HOST')
    db_name = os.environ.get('DB_NAME')
    db_user = os.environ.get('DB_USER')
    db_pass = os.environ.get('DB_PASS')
    
    if not all([db_host, db_name, db_user, db_pass]):
        raise ValueError("Database credentials not found in environment variables")
    
    return psycopg2.connect(
        host=db_host,
        port=5432,
        dbname=db_name,
        user=db_user,
        password=db_pass,
        connect_timeout=10
    )


def create_migrations_table(conn):
    """Create schema_migrations tracking table if it doesn't exist"""
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                migration_id VARCHAR(50) PRIMARY KEY,
                applied_at TIMESTAMP DEFAULT NOW()
            );
        """)
    conn.commit()


def get_applied_migrations(conn) -> List[str]:
    """Get list of already applied migrations"""
    with conn.cursor() as cur:
        cur.execute("SELECT migration_id FROM schema_migrations ORDER BY applied_at;")
        return [row[0] for row in cur.fetchall()]


def get_migration_files_from_s3(bucket: str, prefix: str) -> List[Dict[str, str]]:
    """Get list of migration files from S3"""
    response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
    
    if 'Contents' not in response:
        return []
    
    migrations = []
    for obj in response['Contents']:
        key = obj['Key']
        if key.endswith('.sql'):
            migration_name = key.split('/')[-1].replace('.sql', '')
            migrations.append({
                'name': migration_name,
                'key': key
            })
    
    # Sort by name to ensure order
    migrations.sort(key=lambda x: x['name'])
    return migrations


def apply_migration(conn, migration_name: str, sql_content: str) -> bool:
    """Apply a single migration"""
    try:
        with conn.cursor() as cur:
            # Execute the migration SQL
            cur.execute(sql_content)
            
            # Record the migration
            cur.execute(
                "INSERT INTO schema_migrations (migration_id) VALUES (%s);",
                (migration_name,)
            )
        
        conn.commit()
        return True
    except Exception as e:
        conn.rollback()
        raise Exception(f"Failed to apply migration {migration_name}: {str(e)}")


def handler(event, context):
    """
    Lambda handler for database migrations
    
    Event format:
    {
        "s3_bucket": "deployment-bucket",
        "s3_prefix": "migrations/",
        "dry_run": false
    }
    """
    
    print("🗄️  Starting database migration process...")
    
    # Get parameters from event
    s3_bucket = event.get('s3_bucket', os.environ.get('MIGRATION_BUCKET'))
    s3_prefix = event.get('s3_prefix', os.environ.get('MIGRATION_PREFIX', 'migrations/'))
    dry_run = event.get('dry_run', False)
    
    if not s3_bucket:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'S3 bucket not specified'})
        }
    
    try:
        # Connect to database
        print(f"📊 Connecting to database...")
        conn = get_db_connection()
        print("✅ Database connection successful")
        
        # Create migrations tracking table
        print("📋 Setting up migrations tracking table...")
        create_migrations_table(conn)
        
        # Get applied migrations
        applied_migrations = get_applied_migrations(conn)
        print(f"📝 Found {len(applied_migrations)} already applied migration(s)")
        
        # Get migration files from S3
        print(f"📦 Fetching migration files from s3://{s3_bucket}/{s3_prefix}")
        migration_files = get_migration_files_from_s3(s3_bucket, s3_prefix)
        print(f"📁 Found {len(migration_files)} migration file(s)")
        
        # Apply pending migrations
        applied_count = 0
        skipped_count = 0
        
        for migration in migration_files:
            migration_name = migration['name']
            
            if migration_name in applied_migrations:
                print(f"⏭️  Skipping {migration_name} (already applied)")
                skipped_count += 1
                continue
            
            if dry_run:
                print(f"🔍 [DRY RUN] Would apply {migration_name}")
                continue
            
            print(f"📝 Applying {migration_name}...")
            
            # Download migration file from S3
            response = s3.get_object(Bucket=s3_bucket, Key=migration['key'])
            sql_content = response['Body'].read().decode('utf-8')
            
            # Apply migration
            apply_migration(conn, migration_name, sql_content)
            print(f"✅ {migration_name} applied successfully")
            applied_count += 1
        
        # Close connection
        conn.close()
        
        # Summary
        summary = {
            'total_migrations': len(migration_files),
            'applied': applied_count,
            'skipped': skipped_count,
            'dry_run': dry_run
        }
        
        print("")
        print("=========================================")
        print("📊 Migration Summary")
        print("=========================================")
        print(f"✅ Applied: {applied_count} migration(s)")
        print(f"⏭️  Skipped: {skipped_count} migration(s)")
        print(f"📦 Total: {len(migration_files)} migration(s)")
        
        if dry_run:
            print("🔍 DRY RUN - No changes were made")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Migrations completed successfully',
                'summary': summary
            })
        }
        
    except Exception as e:
        error_msg = f"Migration failed: {str(e)}"
        print(f"❌ {error_msg}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg
            })
        }
