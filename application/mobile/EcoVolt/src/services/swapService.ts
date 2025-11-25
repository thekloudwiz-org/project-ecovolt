/**
 * Swap Service
 * Handles all swap-related API calls
 */

import { get, post, put } from 'aws-amplify/api';
import {
  InitiateSwapParams,
  InitiateSwapResponse,
  CompleteSwapParams,
  CompleteSwapResponse,
  SwapHistoryParams,
  SwapHistoryResponse,
  Swap,
} from '../types/swap';

const API_NAME = 'EcoVoltAPI';

/**
 * Initiate a battery swap
 * Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
 */
export const initiateSwap = async ({
  bikeId,
  stationId,
}: InitiateSwapParams): Promise<InitiateSwapResponse> => {
  try {
    const response = await post({
      apiName: API_NAME,
      path: '/swaps',
      options: {
        body: {
          bike_id: bikeId,
          station_id: stationId,
        },
      },
    }).response;

    const data = await response.body.json();
    return data as InitiateSwapResponse;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to initiate swap');
  }
};

/**
 * Complete a battery swap
 * Requirements: 4.1, 4.2, 4.3
 */
export const completeSwap = async ({
  swapId,
}: CompleteSwapParams): Promise<CompleteSwapResponse> => {
  try {
    const response = await put({
      apiName: API_NAME,
      path: `/swaps/${swapId}/complete`,
    }).response;

    const data = await response.body.json();
    return data as CompleteSwapResponse;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to complete swap');
  }
};

/**
 * Get swap status by ID
 */
export const getSwapStatus = async (swapId: string): Promise<Swap> => {
  try {
    const response = await get({
      apiName: API_NAME,
      path: `/swaps/${swapId}`,
    }).response;

    const data = await response.body.json();
    return (data as any).swap;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to fetch swap status');
  }
};

/**
 * Get swap history
 * Requirements: 5.1, 5.2, 5.3, 5.4
 */
export const getSwapHistory = async ({
  page = 1,
  pageSize = 20,
}: SwapHistoryParams = {}): Promise<SwapHistoryResponse> => {
  try {
    const response = await get({
      apiName: API_NAME,
      path: '/swaps/history',
      options: {
        queryParams: {
          page: page.toString(),
          page_size: pageSize.toString(),
        },
      },
    }).response;

    const data = await response.body.json();
    return data as SwapHistoryResponse;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to fetch swap history');
  }
};
