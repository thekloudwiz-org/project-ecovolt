/**
 * Swaps Slice
 * Manages swap state
 */

import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Swap } from '../../types/swap';

interface SwapsState {
  current: Swap | null;
  history: Swap[];
  loading: boolean;
  error: string | null;
  historyPage: number;
  historyTotal: number;
}

const initialState: SwapsState = {
  current: null,
  history: [],
  loading: false,
  error: null,
  historyPage: 1,
  historyTotal: 0,
};

const swapsSlice = createSlice({
  name: 'swaps',
  initialState,
  reducers: {
    initiateSwapStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    initiateSwapSuccess: (state, action: PayloadAction<Swap>) => {
      state.current = action.payload;
      state.loading = false;
      state.error = null;
    },
    initiateSwapFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    completeSwapStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    completeSwapSuccess: (state, action: PayloadAction<Swap>) => {
      state.current = action.payload;
      state.loading = false;
      state.error = null;
    },
    completeSwapFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    clearCurrentSwap: (state) => {
      state.current = null;
    },
    fetchHistoryStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    fetchHistorySuccess: (
      state,
      action: PayloadAction<{ swaps: Swap[]; total: number; page: number }>
    ) => {
      state.history = action.payload.swaps;
      state.historyTotal = action.payload.total;
      state.historyPage = action.payload.page;
      state.loading = false;
      state.error = null;
    },
    fetchHistoryFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    clearError: (state) => {
      state.error = null;
    },
  },
});

export const {
  initiateSwapStart,
  initiateSwapSuccess,
  initiateSwapFailure,
  completeSwapStart,
  completeSwapSuccess,
  completeSwapFailure,
  clearCurrentSwap,
  fetchHistoryStart,
  fetchHistorySuccess,
  fetchHistoryFailure,
  clearError,
} = swapsSlice.actions;

export default swapsSlice.reducer;
