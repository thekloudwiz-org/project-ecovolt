/**
 * Notification Service
 * Handles all notification-related API calls
 */

import { get, put } from 'aws-amplify/api';
import { NotificationsResponse } from '../types/notification';

const API_NAME = 'EcoVoltAPI';

/**
 * Get unread notifications
 * Requirements: 12.5
 */
export const getNotifications = async (): Promise<NotificationsResponse> => {
  try {
    const response = await get({
      apiName: API_NAME,
      path: '/notifications',
    }).response;

    const data = await response.body.json();
    return data as NotificationsResponse;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to fetch notifications');
  }
};

/**
 * Mark notification as read
 * Requirements: 12.5
 */
export const markNotificationAsRead = async (notificationId: string): Promise<void> => {
  try {
    await put({
      apiName: API_NAME,
      path: `/notifications/${notificationId}/read`,
    }).response;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to mark notification as read');
  }
};
