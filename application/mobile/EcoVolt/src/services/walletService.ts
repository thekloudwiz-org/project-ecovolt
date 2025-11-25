/**
 * Wallet Service
 * Handles all wallet-related API calls
 */

import { get, post } from 'aws-amplify/api';
import {
  WalletBalance,
  TopUpParams,
  TopUpResponse,
  TransactionHistoryParams,
  TransactionHistoryResponse,
} from '../types/wallet';

const API_NAME = 'EcoVoltAPI';

/**
 * Get wallet balance
 * Requirements: 6.1
 */
export const getWalletBalance = async (): Promise<WalletBalance> => {
  try {
    const response = await get({
      apiName: API_NAME,
      path: '/wallet',
    }).response;

    const data = await response.body.json();
    return (data as any).wallet;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to fetch wallet balance');
  }
};

/**
 * Initiate wallet top-up
 * Requirements: 6.1, 6.2, 6.3
 */
export const initiateTopUp = async ({
  amount,
  paymentMethod,
  phoneNumber,
}: TopUpParams): Promise<TopUpResponse> => {
  try {
    const response = await post({
      apiName: API_NAME,
      path: '/wallet/topup',
      options: {
        body: {
          amount,
          payment_method: paymentMethod,
          phone_number: phoneNumber,
        },
      },
    }).response;

    const data = await response.body.json();
    return data as TopUpResponse;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to initiate top-up');
  }
};

/**
 * Get transaction history
 * Requirements: 6.2
 */
export const getTransactionHistory = async ({
  page = 1,
  pageSize = 20,
  type,
}: TransactionHistoryParams = {}): Promise<TransactionHistoryResponse> => {
  try {
    const queryParams: any = {
      page: page.toString(),
      page_size: pageSize.toString(),
    };

    if (type) {
      queryParams.type = type;
    }

    const response = await get({
      apiName: API_NAME,
      path: '/wallet/transactions',
      options: {
        queryParams,
      },
    }).response;

    const data = await response.body.json();
    return data as TransactionHistoryResponse;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to fetch transaction history');
  }
};
