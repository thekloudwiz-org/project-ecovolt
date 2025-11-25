/**
 * Wallet Type Definitions
 */

export interface WalletTransaction {
  id: string;
  userId: string;
  type: 'topup' | 'swap' | 'refund' | 'adjustment';
  amount: number;
  balanceBefore: number;
  balanceAfter: number;
  description: string;
  status: 'pending' | 'completed' | 'failed';
  paymentMethod?: string;
  referenceId?: string;
  createdAt: string;
}

export interface WalletBalance {
  balance: number;
  currency: string;
  lastUpdated: string;
}

export interface TopUpParams {
  amount: number;
  paymentMethod: 'mtn_momo' | 'vodafone_cash' | 'airteltigo_money';
  phoneNumber: string;
}

export interface TopUpResponse {
  transaction: WalletTransaction;
  paymentUrl?: string;
  message: string;
}

export interface TransactionHistoryParams {
  page?: number;
  pageSize?: number;
  type?: string;
}

export interface TransactionHistoryResponse {
  transactions: WalletTransaction[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}
