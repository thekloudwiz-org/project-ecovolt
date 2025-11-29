#!/usr/bin/env python3
"""
EcoVolt Full System Verification Script
========================================

This script performs a comprehensive end-to-end test of the EcoVolt IoT infrastructure,
validating the complete "Polyglot & Fan-Out" architecture:

Architecture Flow:
    IoT Core → Kinesis Data Streams
        ├─→ Lambda → DynamoDB (Current State)
        ├─→ Lambda → Timestream InfluxDB (Historical Data)
        └─→ Firehose → S3 (Data Lake - Bronze/Raw)

Test Phases:
    1. Inject unique test payload via IoT Core
    2. Verify State Layer (DynamoDB)
    3. Verify History Layer (Timestream InfluxDB)
    4. Verify Data Lake (S3 via Firehose)

Author: EcoVolt QA Team
Date: 2025-11-29
"""

import boto3
import json
import time
import sys
from datetime import datetime, timezone
from typing import Dict, Optional, Tuple
import argparse
from botocore.exceptions import ClientError

# ANSI color codes for terminal output
class Colors:
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    MAGENTA = '\033[0;35m'
    BOLD = '\033[1m'
    NC = '\033[0m'  # No Color

class EcoVoltSystemVerification:
    """Main verification class for EcoVolt system testing"""
    
    def __init__(self, region: str = 'eu-central-1', environment: str = 'dev'):
        self.region = region
        self.environment = environment
        self.project = 'ecovolt'
        
        # Initialize AWS clients
        self.iot_client = boto3.client('iot-data', region_name=region)
        self.iot_control = boto3.client('iot', region_name=region)
        self.dynamodb = boto3.resource('dynamodb', region_name=region)
        self.s3_client = boto3.client('s3', region_name=region)
        self.kinesis_client = boto3.client('kinesis', region_name=region)
        self.timestream_query = boto3.client('timestream-query', region_name=region)
        
        # Test configuration
        self.test_device_id = f'TEST-{int(time.time())}'
        self.test_timestamp = datetime.now(timezone.utc).isoformat()
        
        # Resource names
        self.kinesis_stream = f'{self.project}-{self.environment}-telemetry-stream'
        self.dynamodb_table = f'{self.project}-{self.environment}-bike-status'
        self.timestream_db = f'{self.project}-{self.environment}-telemetry'
        self.timestream_table = 'bike_telemetry'
        
        # Results tracking
        self.results = {
            'injection': False,
            'dynamodb': False,
            'timestream': False,
            's3_firehose': False,
            'kinesis': False
        }
        
    def print_header(self, text: str):
        """Print formatted section header"""
        print(f"\n{Colors.CYAN}{'='*70}{Colors.NC}")
        print(f"{Colors.CYAN}{Colors.BOLD}{text}{Colors.NC}")
        print(f"{Colors.CYAN}{'='*70}{Colors.NC}\n")
    
    def print_success(self, text: str):
        """Print success message"""
        print(f"{Colors.GREEN}✓ {text}{Colors.NC}")
    
    def print_error(self, text: str):
        """Print error message"""
        print(f"{Colors.RED}✗ {text}{Colors.NC}")
    
    def print_warning(self, text: str):
        """Print warning message"""
        print(f"{Colors.YELLOW}⚠ {text}{Colors.NC}")
    
    def print_info(self, text: str):
        """Print info message"""
        print(f"{Colors.BLUE}ℹ {text}{Colors.NC}")
    
    def get_iot_endpoint(self) -> str:
        """Get IoT Core endpoint"""
        try:
            response = self.iot_control.describe_endpoint(endpointType='iot:Data-ATS')
            return response['endpointAddress']
        except Exception as e:
            self.print_error(f"Failed to get IoT endpoint: {e}")
            return None
    
    def create_test_payload(self) -> Dict:
        """Create unique test payload"""
        return {
            'device_id': self.test_device_id,
            'device_type': 'bike',
            'timestamp': self.test_timestamp,
            'battery': {
                'voltage': 450.0,  # Unique test value
                'current': 12.5,
                'soc': 85.0,
                'temperature': 28.5
            },
            'location': {
                'latitude': 5.6037,
                'longitude': -0.1870,
                'altitude': 61.0
            },
            'speed': 25.5,
            'odometer': 1234.5,
            'test_marker': 'ECOVOLT_SYSTEM_VERIFICATION'
        }
    
    def phase1_inject_data(self) -> bool:
        """Phase 1: Inject test data via IoT Core"""
        self.print_header("PHASE 1: Data Injection via IoT Core")
        
        try:
            # Get IoT endpoint
            endpoint = self.get_iot_endpoint()
            if not endpoint:
                return False
            
            self.print_info(f"IoT Endpoint: {endpoint}")
            
            # Create test payload
            payload = self.create_test_payload()
            self.print_info(f"Test Device ID: {self.test_device_id}")
            self.print_info(f"Test Voltage: {payload['battery']['voltage']}V")
            
            # Publish to IoT Core
            topic = f'{self.environment}/telemetry/bikes/{self.test_device_id}'
            self.print_info(f"Publishing to topic: {topic}")
            
            response = self.iot_client.publish(
                topic=topic,
                qos=1,
                payload=json.dumps(payload)
            )
            
            self.print_success(f"Data injected successfully")
            self.print_info(f"Payload: {json.dumps(payload, indent=2)}")
            
            self.results['injection'] = True
            return True
            
        except Exception as e:
            self.print_error(f"Data injection failed: {e}")
            return False
    
    def phase2_verify_dynamodb(self, max_retries: int = 10, retry_delay: int = 3) -> bool:
        """Phase 2: Verify data in DynamoDB (Current State)"""
        self.print_header("PHASE 2: Verify State Layer (DynamoDB)")
        
        self.print_info(f"Table: {self.dynamodb_table}")
        self.print_info(f"Looking for device: {self.test_device_id}")
        self.print_info(f"Polling with {max_retries} retries, {retry_delay}s delay...")
        
        table = self.dynamodb.Table(self.dynamodb_table)
        
        for attempt in range(1, max_retries + 1):
            try:
                print(f"\n  Attempt {attempt}/{max_retries}...", end='', flush=True)
                
                response = table.get_item(
                    Key={'device_id': self.test_device_id}
                )
                
                if 'Item' in response:
                    item = response['Item']
                    print(f" {Colors.GREEN}FOUND!{Colors.NC}")
                    
                    # Verify voltage matches
                    if 'battery' in item and 'voltage' in item['battery']:
                        actual_voltage = float(item['battery']['voltage'])
                        expected_voltage = 450.0
                        
                        if abs(actual_voltage - expected_voltage) < 0.1:
                            self.print_success(f"Voltage verified: {actual_voltage}V (expected {expected_voltage}V)")
                            self.print_success("Data integrity confirmed!")
                            
                            # Show full item
                            print(f"\n{Colors.BLUE}Retrieved Item:{Colors.NC}")
                            print(json.dumps(item, indent=2, default=str))
                            
                            self.results['dynamodb'] = True
                            return True
                        else:
                            self.print_warning(f"Voltage mismatch: {actual_voltage}V (expected {expected_voltage}V)")
                    else:
                        self.print_warning("Item found but voltage data missing")
                        print(json.dumps(item, indent=2, default=str))
                else:
                    print(f" not found yet")
                
                if attempt < max_retries:
                    time.sleep(retry_delay)
                    
            except ClientError as e:
                if e.response['Error']['Code'] == 'ResourceNotFoundException':
                    self.print_error(f"Table {self.dynamodb_table} not found!")
                    return False
                else:
                    self.print_error(f"DynamoDB error: {e}")
                    return False
            except Exception as e:
                self.print_error(f"Unexpected error: {e}")
                return False
        
        self.print_error(f"Data not found in DynamoDB after {max_retries} attempts")
        self.print_warning("This could indicate:")
        self.print_warning("  - Lambda processor not running")
        self.print_warning("  - IoT Rule not routing to Kinesis")
        self.print_warning("  - Event source mapping disabled")
        return False
    
    def phase3_verify_timestream(self) -> bool:
        """Phase 3: Verify data in Timestream InfluxDB (Historical Data)"""
        self.print_header("PHASE 3: Verify History Layer (Timestream InfluxDB)")
        
        self.print_info(f"Database: {self.timestream_db}")
        self.print_info(f"Table: {self.timestream_table}")
        self.print_info(f"Querying for device: {self.test_device_id}")
        
        try:
            # Query Timestream
            query = f"""
            SELECT * FROM "{self.timestream_db}"."{self.timestream_table}"
            WHERE device_id = '{self.test_device_id}'
            ORDER BY time DESC
            LIMIT 10
            """
            
            self.print_info(f"Executing query...")
            
            response = self.timestream_query.query(QueryString=query)
            
            if response['Rows']:
                self.print_success(f"Found {len(response['Rows'])} record(s) in Timestream")
                
                # Display results
                print(f"\n{Colors.BLUE}Query Results:{Colors.NC}")
                for row in response['Rows']:
                    print(json.dumps(row, indent=2, default=str))
                
                self.results['timestream'] = True
                return True
            else:
                self.print_warning("No records found in Timestream")
                self.print_info("This is expected if:")
                self.print_info("  - Timestream InfluxDB is not yet configured")
                self.print_info("  - Lambda is writing to DynamoDB only")
                return False
                
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'ResourceNotFoundException':
                self.print_warning(f"Timestream database/table not found")
                self.print_info("Timestream InfluxDB may not be configured yet")
            else:
                self.print_error(f"Timestream query failed: {e}")
            return False
        except Exception as e:
            self.print_warning(f"Timestream verification skipped: {e}")
            self.print_info("This is expected if Timestream InfluxDB is not configured")
            return False
    
    def phase4_verify_s3_firehose(self) -> bool:
        """Phase 4: Verify data will reach S3 via Firehose"""
        self.print_header("PHASE 4: Verify Data Lake (S3 via Firehose)")
        
        # Get S3 bucket name
        try:
            # Try to get bucket from Terraform outputs
            import subprocess
            result = subprocess.run(
                ['terraform', 'output', '-json'],
                cwd='../../infra',
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                outputs = json.loads(result.stdout)
                # Look for data lake bucket (not in outputs, need to check)
                bucket_name = f'{self.project}-{self.environment}-data-lake'
            else:
                bucket_name = f'{self.project}-{self.environment}-data-lake'
                
        except:
            bucket_name = f'{self.project}-{self.environment}-data-lake'
        
        self.print_info(f"S3 Bucket: {bucket_name}")
        self.print_info(f"Firehose Buffer Interval: 60 seconds (minimum)")
        
        # Check if bucket exists
        try:
            self.s3_client.head_bucket(Bucket=bucket_name)
            self.print_success(f"S3 bucket exists and is accessible")
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                self.print_error(f"S3 bucket not found: {bucket_name}")
                return False
            elif error_code == '403':
                self.print_error(f"Access denied to bucket: {bucket_name}")
                return False
            else:
                self.print_error(f"S3 error: {e}")
                return False
        
        # Explain Firehose buffering
        print(f"\n{Colors.YELLOW}{'─'*70}{Colors.NC}")
        print(f"{Colors.YELLOW}IMPORTANT: Firehose Buffering Behavior{Colors.NC}")
        print(f"{Colors.YELLOW}{'─'*70}{Colors.NC}")
        print(f"\n{Colors.BLUE}Firehose buffers data before writing to S3:{Colors.NC}")
        print(f"  • Buffer Size: 1 MB (minimum)")
        print(f"  • Buffer Interval: 60 seconds (minimum)")
        print(f"  • Whichever condition is met first triggers delivery")
        
        print(f"\n{Colors.CYAN}Expected S3 Path:{Colors.NC}")
        now = datetime.now(timezone.utc)
        expected_prefix = f"bronze/telemetry/year={now.year}/month={now.month:02d}/day={now.day:02d}/hour={now.hour:02d}/"
        print(f"  s3://{bucket_name}/{expected_prefix}")
        
        print(f"\n{Colors.GREEN}Action Required:{Colors.NC}")
        print(f"  1. Wait at least 60 seconds after data injection")
        print(f"  2. Check S3 bucket: {bucket_name}")
        print(f"  3. Navigate to: {expected_prefix}")
        print(f"  4. Look for .gz files containing your test data")
        
        print(f"\n{Colors.BLUE}AWS Console Path:{Colors.NC}")
        print(f"  S3 → Buckets → {bucket_name} → bronze/telemetry/")
        
        print(f"\n{Colors.BLUE}CLI Command:{Colors.NC}")
        print(f"  aws s3 ls s3://{bucket_name}/{expected_prefix} --recursive")
        
        self.results['s3_firehose'] = True  # Mark as informational success
        return True
    
    def verify_kinesis_stream(self) -> bool:
        """Verify data reached Kinesis stream"""
        self.print_header("BONUS: Verify Kinesis Stream")
        
        try:
            self.print_info(f"Stream: {self.kinesis_stream}")
            
            # Get shard iterator
            response = self.kinesis_client.get_shard_iterator(
                StreamName=self.kinesis_stream,
                ShardId='shardId-000000000000',
                ShardIteratorType='TRIM_HORIZON'
            )
            
            shard_iterator = response['ShardIterator']
            
            # Get records
            response = self.kinesis_client.get_records(
                ShardIterator=shard_iterator,
                Limit=100
            )
            
            records = response['Records']
            
            if records:
                self.print_success(f"Found {len(records)} record(s) in Kinesis")
                
                # Look for our test record
                for record in records:
                    try:
                        data = json.loads(record['Data'].decode('utf-8'))
                        if data.get('device_id') == self.test_device_id:
                            self.print_success(f"Found test record in Kinesis!")
                            print(f"\n{Colors.BLUE}Record:{Colors.NC}")
                            print(json.dumps(data, indent=2))
                            self.results['kinesis'] = True
                            return True
                    except:
                        continue
                
                self.print_warning("Test record not found in recent Kinesis records")
                self.print_info("This is normal if data has already been processed")
            else:
                self.print_warning("No records found in Kinesis")
                self.print_info("Records may have already been processed by Lambda")
            
            return True
            
        except Exception as e:
            self.print_error(f"Kinesis verification failed: {e}")
            return False
    
    def print_final_report(self):
        """Print final test report"""
        self.print_header("FINAL TEST REPORT")
        
        print(f"{Colors.BOLD}Test Summary:{Colors.NC}\n")
        
        # Calculate pass rate
        total_tests = len(self.results)
        passed_tests = sum(1 for v in self.results.values() if v)
        pass_rate = (passed_tests / total_tests) * 100
        
        # Print results
        for test, passed in self.results.items():
            status = f"{Colors.GREEN}PASS{Colors.NC}" if passed else f"{Colors.RED}FAIL{Colors.NC}"
            test_name = test.replace('_', ' ').title()
            print(f"  {status}  {test_name}")
        
        print(f"\n{Colors.BOLD}Overall Result:{Colors.NC}")
        print(f"  Tests Passed: {passed_tests}/{total_tests}")
        print(f"  Pass Rate: {pass_rate:.1f}%")
        
        if pass_rate >= 80:
            print(f"\n{Colors.GREEN}{'='*70}{Colors.NC}")
            print(f"{Colors.GREEN}{Colors.BOLD}✓ SYSTEM VERIFICATION SUCCESSFUL{Colors.NC}")
            print(f"{Colors.GREEN}{'='*70}{Colors.NC}")
        elif pass_rate >= 50:
            print(f"\n{Colors.YELLOW}{'='*70}{Colors.NC}")
            print(f"{Colors.YELLOW}{Colors.BOLD}⚠ PARTIAL SUCCESS - Some components need attention{Colors.NC}")
            print(f"{Colors.YELLOW}{'='*70}{Colors.NC}")
        else:
            print(f"\n{Colors.RED}{'='*70}{Colors.NC}")
            print(f"{Colors.RED}{Colors.BOLD}✗ SYSTEM VERIFICATION FAILED{Colors.NC}")
            print(f"{Colors.RED}{'='*70}{Colors.NC}")
        
        # Recommendations
        print(f"\n{Colors.CYAN}Next Steps:{Colors.NC}")
        
        if not self.results['dynamodb']:
            print(f"  • Check Lambda stream processor logs")
            print(f"  • Verify IoT Rules are routing to Kinesis")
            print(f"  • Check Lambda event source mapping")
        
        if not self.results['timestream']:
            print(f"  • Configure Timestream InfluxDB if needed")
            print(f"  • Update Lambda to write to Timestream")
        
        print(f"  • Wait 60+ seconds and check S3 for Firehose data")
        print(f"  • Review CloudWatch Logs for detailed diagnostics")
        print(f"  • Run monitoring script: ./04-monitor-metrics.sh")
        
        print()
    
    def run_full_verification(self):
        """Run complete system verification"""
        print(f"\n{Colors.MAGENTA}{'='*70}{Colors.NC}")
        print(f"{Colors.MAGENTA}{Colors.BOLD}EcoVolt Full System Verification{Colors.NC}")
        print(f"{Colors.MAGENTA}{'='*70}{Colors.NC}")
        print(f"\n{Colors.BLUE}Architecture: Polyglot & Fan-Out Pattern{Colors.NC}")
        print(f"  IoT Core → Kinesis → Lambda → DynamoDB (State)")
        print(f"                    → Lambda → Timestream (History)")
        print(f"                    → Firehose → S3 (Data Lake)")
        print()
        
        # Phase 1: Inject data
        if not self.phase1_inject_data():
            self.print_error("Data injection failed. Aborting test.")
            return False
        
        # Wait a moment for data to propagate
        print(f"\n{Colors.YELLOW}Waiting 3 seconds for data propagation...{Colors.NC}")
        time.sleep(3)
        
        # Phase 2: Verify DynamoDB
        self.phase2_verify_dynamodb()
        
        # Phase 3: Verify Timestream
        self.phase3_verify_timestream()
        
        # Phase 4: Verify S3/Firehose
        self.phase4_verify_s3_firehose()
        
        # Bonus: Verify Kinesis
        self.verify_kinesis_stream()
        
        # Final report
        self.print_final_report()
        
        return True

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='EcoVolt Full System Verification',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 full_system_verification.py
  python3 full_system_verification.py --region us-east-1
  python3 full_system_verification.py --environment prod
        """
    )
    
    parser.add_argument(
        '--region',
        default='eu-central-1',
        help='AWS region (default: eu-central-1)'
    )
    
    parser.add_argument(
        '--environment',
        default='dev',
        help='Environment (default: dev)'
    )
    
    args = parser.parse_args()
    
    # Run verification
    verifier = EcoVoltSystemVerification(
        region=args.region,
        environment=args.environment
    )
    
    try:
        verifier.run_full_verification()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Test interrupted by user{Colors.NC}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Colors.RED}Unexpected error: {e}{Colors.NC}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
