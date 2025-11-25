"""
AWS Secrets Manager RDS PostgreSQL Password Rotation Lambda
This Lambda function rotates RDS PostgreSQL database passwords automatically.
"""

import json
import boto3
import os
import psycopg2
from botocore.exceptions import ClientError

# Initialize AWS clients
secrets_client = boto3.client('secretsmanager')
rds_client = boto3.client('rds')


def lambda_handler(event, context):
    """
    Main handler for secret rotation
    
    Args:
        event: Lambda event containing SecretId, Token, and Step
        context: Lambda context
    """
    arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    # Make sure the version is staged correctly
    metadata = secrets_client.describe_secret(SecretId=arn)
    if not metadata['RotationEnabled']:
        raise ValueError(f"Secret {arn} is not enabled for rotation")
    
    versions = metadata['VersionIdsToStages']
    if token not in versions:
        raise ValueError(f"Secret version {token} has no stage for rotation of secret {arn}.")
    
    if "AWSCURRENT" in versions[token]:
        print(f"Secret version {token} already set as AWSCURRENT for secret {arn}.")
        return
    elif "AWSPENDING" not in versions[token]:
        raise ValueError(f"Secret version {token} not set as AWSPENDING for rotation of secret {arn}.")
    
    # Call the appropriate step function
    if step == "createSecret":
        create_secret(secrets_client, arn, token)
    elif step == "setSecret":
        set_secret(secrets_client, arn, token)
    elif step == "testSecret":
        test_secret(secrets_client, arn, token)
    elif step == "finishSecret":
        finish_secret(secrets_client, arn, token)
    else:
        raise ValueError("Invalid step parameter")


def create_secret(service_client, arn, token):
    """
    Generate a new secret
    
    This method first checks for the existence of a secret for the passed in token. If one does not exist, it will generate a
    new secret and put it with the passed in token.
    """
    # Make sure the current secret exists
    current_dict = get_secret_dict(service_client, arn, "AWSCURRENT")
    
    # Now try to get the secret version, if that fails, put a new secret
    try:
        get_secret_dict(service_client, arn, "AWSPENDING", token)
        print(f"createSecret: Successfully retrieved secret for {arn}.")
    except service_client.exceptions.ResourceNotFoundException:
        # Generate a random password
        passwd = service_client.get_random_password(
            ExcludeCharacters='/@"\'\\'
        )
        current_dict['password'] = passwd['RandomPassword']
        
        # Put the secret
        service_client.put_secret_value(
            SecretId=arn,
            ClientRequestToken=token,
            SecretString=json.dumps(current_dict),
            VersionStages=['AWSPENDING']
        )
        print(f"createSecret: Successfully put secret for ARN {arn} and version {token}.")


def set_secret(service_client, arn, token):
    """
    Set the secret in the database
    
    This method should set the AWSPENDING secret in the service that the secret belongs to.
    """
    # Get both current and pending secrets
    current_dict = get_secret_dict(service_client, arn, "AWSCURRENT")
    pending_dict = get_secret_dict(service_client, arn, "AWSPENDING", token)
    
    # Connect to the database with the current credentials
    conn = get_connection(current_dict)
    
    try:
        with conn.cursor() as cur:
            # Update the password
            cur.execute(f"ALTER USER {pending_dict['username']} WITH PASSWORD %s", (pending_dict['password'],))
            conn.commit()
            print(f"setSecret: Successfully set password for user {pending_dict['username']} in database.")
    finally:
        conn.close()


def test_secret(service_client, arn, token):
    """
    Test the secret
    
    This method should validate that the AWSPENDING secret works in the service that the secret belongs to.
    """
    # Get the pending secret
    pending_dict = get_secret_dict(service_client, arn, "AWSPENDING", token)
    
    # Try to connect with the pending secret
    conn = get_connection(pending_dict)
    
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
            print(f"testSecret: Successfully signed into database with AWSPENDING secret.")
    finally:
        conn.close()


def finish_secret(service_client, arn, token):
    """
    Finish the secret rotation
    
    This method finalizes the rotation process by marking the secret version passed in as the AWSCURRENT secret.
    """
    # First describe the secret to get the current version
    metadata = service_client.describe_secret(SecretId=arn)
    current_version = None
    for version in metadata["VersionIdsToStages"]:
        if "AWSCURRENT" in metadata["VersionIdsToStages"][version]:
            if version == token:
                # The correct version is already marked as current, return
                print(f"finishSecret: Version {version} already marked as AWSCURRENT for {arn}")
                return
            current_version = version
            break
    
    # Finalize by staging the secret version current
    service_client.update_secret_version_stage(
        SecretId=arn,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version
    )
    print(f"finishSecret: Successfully set AWSCURRENT stage to version {token} for secret {arn}.")


def get_connection(secret_dict):
    """
    Get a connection to PostgreSQL database
    
    Args:
        secret_dict: Dictionary containing connection parameters
        
    Returns:
        psycopg2 connection object
    """
    return psycopg2.connect(
        host=secret_dict['host'],
        port=secret_dict['port'],
        database=secret_dict['dbname'],
        user=secret_dict['username'],
        password=secret_dict['password'],
        connect_timeout=5
    )


def get_secret_dict(service_client, arn, stage, token=None):
    """
    Get the secret dictionary from Secrets Manager
    
    Args:
        service_client: boto3 secrets manager client
        arn: ARN of the secret
        stage: Stage of the secret to retrieve
        token: (Optional) ClientRequestToken associated with the secret version
        
    Returns:
        Dictionary containing the secret
    """
    required_fields = ['host', 'port', 'dbname', 'username', 'password']
    
    # Only do VersionId validation against the stage if a token is passed in
    if token:
        secret = service_client.get_secret_value(SecretId=arn, VersionId=token, VersionStage=stage)
    else:
        secret = service_client.get_secret_value(SecretId=arn, VersionStage=stage)
    
    plaintext = secret['SecretString']
    secret_dict = json.loads(plaintext)
    
    # Validate required fields
    for field in required_fields:
        if field not in secret_dict:
            raise KeyError(f"{field} key is missing from secret JSON")
    
    return secret_dict
