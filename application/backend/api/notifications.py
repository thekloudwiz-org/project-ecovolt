"""
Notifications API Endpoints
Handles notification retrieval and management
"""

import json
import os
from typing import Dict, Any
from utils.db import DynamoDBHelper


def get_notifications(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    GET /notifications
    Get unread notifications sorted by timestamp
    
    Requirements: 12.5
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
        
        # Get notifications from DynamoDB
        notifications_table = os.getenv('DYNAMODB_NOTIFICATIONS_TABLE', 'ecovolt-dev-notifications')
        
        # Query notifications for user
        notifications = DynamoDBHelper.query(
            table_name=notifications_table,
            key_condition='user_id = :user_id',
            expression_values={':user_id': user_id}
        )
        
        # Requirement 12.5: Filter unread and sort by timestamp descending
        unread_notifications = [
            n for n in notifications 
            if not n.get('read', False)
        ]
        
        # Sort by created_at descending
        unread_notifications.sort(
            key=lambda x: x.get('created_at', ''),
            reverse=True
        )
        
        # Format notifications
        notification_list = []
        for notif in unread_notifications:
            notification_list.append({
                'notification_id': notif['notification_id'],
                'type': notif['type'],
                'title': notif['title'],
                'message': notif['message'],
                'data': notif.get('data', {}),
                'read': notif.get('read', False),
                'created_at': notif['created_at']
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'notifications': notification_list,
                'count': len(notification_list)
            })
        }
        
    except Exception as e:
        print(f"Error getting notifications: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }


def mark_notification_read(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    PUT /notifications/{id}/read
    Mark notification as read
    
    Requirements: 12.5
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
        
        # Get notification ID from path
        notification_id = event.get('pathParameters', {}).get('id')
        if not notification_id:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'Missing notification ID'
                })
            }
        
        # Update notification in DynamoDB
        notifications_table = os.getenv('DYNAMODB_NOTIFICATIONS_TABLE', 'ecovolt-dev-notifications')
        
        # First, verify the notification belongs to the user
        notification = DynamoDBHelper.get_item(
            table_name=notifications_table,
            key={'user_id': user_id, 'notification_id': notification_id}
        )
        
        if not notification:
            return {
                'statusCode': 404,
                'body': json.dumps({
                    'error': 'Notification not found'
                })
            }
        
        # Mark as read
        success = DynamoDBHelper.update_item(
            table_name=notifications_table,
            key={'user_id': user_id, 'notification_id': notification_id},
            update_expression='SET #read = :read',
            expression_values={':read': True},
            expression_names={'#read': 'read'}
        )
        
        if not success:
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'error': 'Failed to update notification'
                })
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Notification marked as read',
                'notification_id': notification_id
            })
        }
        
    except Exception as e:
        print(f"Error marking notification as read: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e) if os.getenv('ENVIRONMENT') == 'dev' else 'An error occurred'
            })
        }
