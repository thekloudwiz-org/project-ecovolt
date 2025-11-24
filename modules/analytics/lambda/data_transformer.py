"""
Lambda function for transforming raw telemetry data into structured formats.
This function reads raw JSON data from S3, transforms it to Parquet format,
and writes it back to S3 for efficient querying with Athena.
"""

import json
import os
import boto3
import pandas as pd
from io import BytesIO
from datetime import datetime

# Initialize S3 client
s3_client = boto3.client('s3')

# Environment variables
DATA_LAKE_BUCKET = os.environ['DATA_LAKE_BUCKET']


def handler(event, context):
    """
    Transform raw JSON data to structured Parquet format.
    
    Args:
        event: S3 event or manual invocation
        context: Lambda context
        
    Returns:
        dict: Transformation results
    """
    files_processed = 0
    files_failed = 0
    
    # Handle S3 event trigger
    if 'Records' in event:
        for record in event['Records']:
            try:
                bucket = record['s3']['bucket']['name']
                key = record['s3']['object']['key']
                
                # Only process raw data files
                if not key.startswith('raw/'):
                    continue
                
                transform_file(bucket, key)
                files_processed += 1
                
            except Exception as e:
                print(f"Error processing file {key}: {str(e)}")
                files_failed += 1
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'filesProcessed': files_processed,
            'filesFailed': files_failed
        })
    }


def transform_file(bucket, key):
    """
    Transform a single JSON file to Parquet format.
    
    Args:
        bucket: S3 bucket name
        key: S3 object key
    """
    # Download raw JSON file
    response = s3_client.get_object(Bucket=bucket, Key=key)
    raw_data = response['Body'].read().decode('utf-8')
    
    # Parse JSON lines
    records = []
    for line in raw_data.strip().split('\n'):
        if line:
            records.append(json.loads(line))
    
    if not records:
        print(f"No records found in {key}")
        return
    
    # Convert to DataFrame
    df = pd.DataFrame(records)
    
    # Determine data type and apply transformations
    if 'bikeId' in df.columns:
        df = transform_bike_data(df)
        output_prefix = 'processed/bike/'
    elif 'stationId' in df.columns and 'solar' in df.columns:
        df = transform_station_data(df)
        output_prefix = 'processed/station/'
    elif 'swapId' in df.columns:
        df = transform_swap_data(df)
        output_prefix = 'processed/swap/'
    else:
        print(f"Unknown data type in {key}")
        return
    
    # Write to Parquet
    parquet_buffer = BytesIO()
    df.to_parquet(parquet_buffer, engine='pyarrow', compression='snappy')
    parquet_buffer.seek(0)
    
    # Generate output key with partitioning
    now = datetime.now()
    output_key = f"{output_prefix}year={now.year}/month={now.month:02d}/day={now.day:02d}/{os.path.basename(key).replace('.json', '.parquet')}"
    
    # Upload to S3
    s3_client.put_object(
        Bucket=bucket,
        Key=output_key,
        Body=parquet_buffer.getvalue(),
        ContentType='application/octet-stream'
    )
    
    print(f"Transformed {key} to {output_key}")


def transform_bike_data(df):
    """Transform bike telemetry data."""
    # Flatten nested battery data
    if 'battery' in df.columns:
        battery_df = pd.json_normalize(df['battery'])
        battery_df.columns = ['battery_' + col for col in battery_df.columns]
        df = pd.concat([df.drop('battery', axis=1), battery_df], axis=1)
    
    # Flatten location data
    if 'location' in df.columns:
        location_df = pd.json_normalize(df['location'])
        location_df.columns = ['location_' + col for col in location_df.columns]
        df = pd.concat([df.drop('location', axis=1), location_df], axis=1)
    
    # Convert timestamp to datetime
    if 'timestamp' in df.columns:
        df['timestamp'] = pd.to_datetime(df['timestamp'])
    
    return df


def transform_station_data(df):
    """Transform station energy data."""
    # Flatten nested solar data
    if 'solar' in df.columns:
        solar_df = pd.json_normalize(df['solar'])
        solar_df.columns = ['solar_' + col for col in solar_df.columns]
        df = pd.concat([df.drop('solar', axis=1), solar_df], axis=1)
    
    # Flatten grid data
    if 'grid' in df.columns:
        grid_df = pd.json_normalize(df['grid'])
        grid_df.columns = ['grid_' + col for col in grid_df.columns]
        df = pd.concat([df.drop('grid', axis=1), grid_df], axis=1)
    
    # Convert timestamp to datetime
    if 'timestamp' in df.columns:
        df['timestamp'] = pd.to_datetime(df['timestamp'])
    
    return df


def transform_swap_data(df):
    """Transform swap event data."""
    # Convert timestamp to datetime
    if 'timestamp' in df.columns:
        df['timestamp'] = pd.to_datetime(df['timestamp'])
    
    return df
