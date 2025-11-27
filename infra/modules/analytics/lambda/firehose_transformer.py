"""
Kinesis Firehose Data Transformation Lambda
Transforms telemetry data before writing to S3
"""

import base64
import json
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Transform records from Kinesis Firehose
    
    Args:
        event: Firehose event with records
        context: Lambda context
        
    Returns:
        Transformed records for Firehose
    """
    output_records = []
    
    for record in event['records']:
        try:
            # Decode the data
            payload = base64.b64decode(record['data']).decode('utf-8')
            data = json.loads(payload)
            
            # Transform the data
            transformed_data = transform_telemetry(data)
            
            # Encode the transformed data
            output_data = json.dumps(transformed_data) + '\n'
            output_bytes = output_data.encode('utf-8')
            encoded_data = base64.b64encode(output_bytes).decode('utf-8')
            
            # Mark as successful
            output_record = {
                'recordId': record['recordId'],
                'result': 'Ok',
                'data': encoded_data
            }
            
        except Exception as e:
            logger.error(f"Error transforming record: {str(e)}")
            logger.error(f"Record data: {record.get('data', 'N/A')}")
            
            # Mark as failed
            output_record = {
                'recordId': record['recordId'],
                'result': 'ProcessingFailed',
                'data': record['data']  # Return original data
            }
        
        output_records.append(output_record)
    
    logger.info(f"Processed {len(output_records)} records")
    
    return {
        'records': output_records
    }


def transform_telemetry(data):
    """
    Transform telemetry data
    
    Args:
        data: Raw telemetry data
        
    Returns:
        Transformed data
    """
    # Add processing timestamp
    data['processedAt'] = datetime.utcnow().isoformat()
    
    # Validate and clean data
    if 'bikeId' in data:
        data['bikeId'] = str(data['bikeId']).strip()
    
    if 'timestamp' in data:
        # Ensure timestamp is in ISO format
        try:
            if isinstance(data['timestamp'], (int, float)):
                data['timestamp'] = datetime.fromtimestamp(data['timestamp']).isoformat()
        except Exception as e:
            logger.warning(f"Could not convert timestamp: {e}")
    
    # Validate battery data
    if 'battery' in data:
        battery = data['battery']
        
        # Ensure values are within valid ranges
        if 'stateOfCharge' in battery:
            battery['stateOfCharge'] = max(0, min(100, float(battery['stateOfCharge'])))
        
        if 'temperature' in battery:
            # Flag extreme temperatures
            temp = float(battery['temperature'])
            if temp < -20 or temp > 60:
                data['alerts'] = data.get('alerts', [])
                data['alerts'].append({
                    'type': 'EXTREME_TEMPERATURE',
                    'value': temp,
                    'timestamp': datetime.utcnow().isoformat()
                })
    
    # Validate location data
    if 'location' in data:
        location = data['location']
        
        # Ensure coordinates are valid
        if 'latitude' in location:
            location['latitude'] = max(-90, min(90, float(location['latitude'])))
        
        if 'longitude' in location:
            location['longitude'] = max(-180, min(180, float(location['longitude'])))
    
    # Add data quality score
    data['dataQuality'] = calculate_data_quality(data)
    
    return data


def calculate_data_quality(data):
    """
    Calculate data quality score (0-100)
    
    Args:
        data: Telemetry data
        
    Returns:
        Quality score
    """
    score = 100
    required_fields = ['bikeId', 'timestamp', 'battery', 'location']
    
    # Deduct points for missing required fields
    for field in required_fields:
        if field not in data:
            score -= 25
    
    # Deduct points for invalid battery data
    if 'battery' in data:
        battery = data['battery']
        if 'stateOfCharge' not in battery:
            score -= 10
        if 'voltage' not in battery:
            score -= 5
        if 'temperature' not in battery:
            score -= 5
    
    # Deduct points for invalid location data
    if 'location' in data:
        location = data['location']
        if 'latitude' not in location or 'longitude' not in location:
            score -= 10
    
    return max(0, score)
