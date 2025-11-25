/**
 * Notification Type Definitions
 */

export interface Notification {
  id: string;
  userId: string;
  type: 'swap_complete' | 'wallet_topup' | 'low_balance' | 'alert' | 'info';
  title: string;
  message: string;
  data?: any;
  read: boolean;
  createdAt: string;
}

export interface NotificationsResponse {
  notifications: Notification[];
  unreadCount: number;
}
