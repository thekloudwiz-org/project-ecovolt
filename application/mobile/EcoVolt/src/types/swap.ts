/**
 * Swap Type Definitions
 */

export interface Swap {
  id: string;
  userId: string;
  bikeId: string;
  stationId: string;
  stationName?: string;
  oldBatteryId: string;
  newBatteryId: string;
  cost: number;
  status: 'initiated' | 'completed' | 'failed' | 'cancelled';
  initiatedAt: string;
  completedAt?: string;
  duration?: number; // in minutes
  createdAt: string;
  updatedAt: string;
}

export interface InitiateSwapParams {
  bikeId: string;
  stationId: string;
}

export interface InitiateSwapResponse {
  swap: Swap;
  reservedBatteryId: string;
  message: string;
}

export interface CompleteSwapParams {
  swapId: string;
}

export interface CompleteSwapResponse {
  swap: Swap;
  message: string;
}

export interface SwapHistoryParams {
  page?: number;
  pageSize?: number;
}

export interface SwapHistoryResponse {
  swaps: Swap[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}
