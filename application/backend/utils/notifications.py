"""
Notifications Utility Module
Handles push notifications and notification storage
"""

import os
import json
import uuid
import boto3
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
from utils.db import DynamoDBHelper

# AWS clients
sns_client = boto3.client('sns')


class NotificationTemplates:
    """Notification message templates"""
    
    @staticmethod
    def swap_complete(swap_id: str, station_name: str, cost: float) -> Dict[str, str]:
        """
        Swap completion notification template
        
        Requirements: 4.6, 12.1
        """
        return {
            'title': 'Battery Swap Complete',
            'message': f'Your battery swap at {station_name} is complete. Cost: {cost} GHS',
            'type': 'swap_complete',
            'data': {
                'swap_id': swap_id,
                'station_name': station_name,
                'cost': cost
            }
        }
    
    @staticmethod
    def wallet_topup(amount: float, new_balance: float) -> Dict[str, str]:
        """
        Wallet top-up notification template
        
        Requirements: 12.2
        """
        return {
            'title': 'Wallet Topped Up',
            'message': f'Your wallet has been topped up with {amount} GHS. New balance: {new_balance} GHS',
            'type': 'wallet_topup',
            'data': {
                'amount': amount,
                'new_balance': new_balance
            }
        }
    
    @staticmethod
    def low_balance(current_balance: float) -> Dict[str, str]:
        """
        Low balance notification template
        
        Requirements: 12.3
        """
        return {
            'title': 'Low Wallet Balance',
            'message': f'Your wallet balance is low ({current_balance} GHS). Please top up to continue using EcoVolt.',
            'type': 'low_balance',
            'data': {
                'current_balance': current_balance
            }
        }
    
    @staticmethod
    def low_battery_alert(bike_id: str, battery_level: int) -> Dict[str, str]:
        """
        Low battery alert notification template
        
        Requirements: 13.5
        """
        return {
            'title': 'Low Battery Alert',
            'message': f'Your bike battery is low ({battery_level}%). Please swap your battery soon.',
            'type': 'low_battery_alert',
            'data': {
                'bike_id': bike_id,
                'battery_level': battery_level
            }
        }
    
    @staticmethod
    def general_alert(title: str, message: str) -> Dict[str, str]:
        """General alert notification template"""
        return {
            'title': title,
            'message': message,
            'type': 'alert',
            'data': {}
        }


def send_push_notification(user_id: str, notification: Dict[str, Any]) -> bool:
    """
    Send push notification via SNS
    
    Requirements: 12.1, 12.2
    
    Args:
        user_id: User ID to send notification to
        notification: Notification data with title, message, type, data
        
    Returns:
        True if successful, False otherwise
    """
    try:
        # Get user's device tokens from DynamoDB (would be stored during app registration)
        # For now, we'll use a placeholder
        
        # In production, you would:
        # 1. Query user's device tokens from a devices table
        # 2. Send to SNS topic or directly to device endpoints
        # 3. Handle different platforms (iOS, Android)
        
        # Placeholder SNS publish
        topic_arn = os.getenv('SNS_NOTIFICATIONS_TOPIC_ARN')
        
        if not topic_arn:
            print(f"Warning: SNS_NOTIFICATIONS_TOPIC_ARN not set. Notification not sent.")
            return False
        
        message = {
            'default': notification['message'],
            'GCM': json.dumps({
                'notification': {
                    'title': notification['title'],
                    'body': notification['message']
                },
                'data': notification.get('data', {})
            }),
            'APNS': json.dumps({
                'aps': {
                    'alert': {
                        'title': notification['title'],
                        'body': notification['message']
                    },
                    'sound': 'default'
                },
                'data': notification.get('data', {})
            })
        }
        
        response = sns_client.publish(
            TopicArn=topic_arn,
            Message=json.dumps(message),
            MessageStructure='json',
            MessageAttributes={
                'user_id': {
                    'DataType': 'String',
                    'StringValue': user_id
                },
                'notification_type': {
                    'DataType': 'String',
                    'StringValue': notification['type']
                }
            }
        )
        
        print(f"Push notification sent to user {user_id}: {response['MessageId']}")
        return True
        
    except Exception as e:
        print(f"Error sending push notification: {str(e)}")
        return False


def store_notification(user_id: str, notification: Dict[str, Any]) -> Optional[str]:
    """
    Store notification in DynamoDB with TTL
    
    Requirements: 12.4, 12.5
    
    Args:
        user_id: User ID
        notification: Notification data
        
    Returns:
        Notification ID if successful, None otherwise
    """
    try:
        notifications_table = os.getenv('DYNAMODB_NOTIFICATIONS_TABLE', 'ecovolt-dev-notifications')
        
        notification_id = f"NOTIF-{uuid.uuid4()}"
        timestamp = datetime.now()
        
        # Requirement 12.4: TTL of 30 days
        ttl = int((timestamp + timedelta(days=30)).timestamp())
        
        item = {
            'user_id': user_id,
            'notification_id': notification_id,
            'type': notification['type'],
            'title': notification['title'],
            'message': notification['message'],
            'data': notification.get('data', {}),
            'read': False,
            'created_at': timestamp.isoformat(),
            'ttl': ttl
        }
        
        success = DynamoDBHelper.put_item(
            table_name=notifications_table,
            item=item
        )
        
        if success:
            print(f"Notification stored: {notification_id}")
            return notification_id
        else:
            print(f"Failed to store notification")
            return None
            
    except Exception as e:
        print(f"Error storing notification: {str(e)}")
        return None


def send_and_store_notification(user_id: str, notification: Dict[str, Any]) -> Optional[str]:
    """
    Send push notification and store in DynamoDB
    
    Requirements: 12.1, 12.2, 12.4
    
    Args:
        user_id: User ID
        notification: Notification data
        
    Returns:
        Notification ID if stored successfully, None otherwise
    """
    # Send push notification (best effort)
    send_push_notification(user_id, notification)
    
    # Store notification (always store even if push fails)
    return store_notification(user_id, notification)


def notify_swap_complete(user_id: str, swap_id: str, station_name: str, cost: float) -> Optional[str]:
    """
    Send swap completion notification
    
    Requirements: 4.6, 12.1
    """
    notification = NotificationTemplates.swap_complete(swap_id, station_name, cost)
    return send_and_store_notification(user_id, notification)


def notify_wallet_topup(user_id: str, amount: float, new_balance: float) -> Optional[str]:
    """
    Send wallet top-up notification
    
    Requirements: 12.2
    """
    notification = NotificationTemplates.wallet_topup(amount, new_balance)
    return send_and_store_notification(user_id, notification)


def notify_low_balance(user_id: str, current_balance: float) -> Optional[str]:
    """
    Send low balance notification
    
    Requirements: 12.3
    """
    notification = NotificationTemplates.low_balance(current_balance)
    return send_and_store_notification(user_id, notification)


def notify_low_battery(user_id: str, bike_id: str, battery_level: int) -> Optional[str]:
    """
    Send low battery alert notification
    
    Requirements: 13.5
    """
    notification = NotificationTemplates.low_battery_alert(bike_id, battery_level)
    return send_and_store_notification(user_id, notification)


def check_and_notify_low_balance(user_id: str, balance: float, threshold: float = 10.0) -> bool:
    """
    Check balance and send notification if below threshold
    
    Requirements: 12.3
    
    Args:
        user_id: User ID
        balance: Current wallet balance
        threshold: Balance threshold (default 10 GHS)
        
    Returns:
        True if notification was sent, False otherwise
    """
    if balance < threshold:
        notification_id = notify_low_balance(user_id, balance)
        return notification_id is not None
    return False
