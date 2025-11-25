/**
 * Wallet Slice
 * Manages wallet state
 */

import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { WalletTransaction } from '../../types/wallet';

interface WalletState {
  balance: number;
  currency: string;
  transactions: WalletTransaction[];
  loading: boolean;
  error: string | null;
  transactionPage: number;
  transactionTotal: number;
}

const initialState: WalletState = {
  balance: 0,
  currency: 'GHS',
  transactions: [],
  loading: false,
  error: null,
  transactionPage: 1,
  transactionTotal: 0,
};

const walletSlice = createSlice({
  name: 'wallet',
  initialState,
  reducers: {
    fetchBalanceStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    fetchBalanceSuccess: (
      state,
      action: PayloadAction<{ balance: number; currency: string }>
    ) => {
      state.balance = action.payload.balance;
      state.currency = action.payload.currency;
      state.loading = false;
      state.error = null;
    },
    fetchBalanceFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    topUpStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    topUpSuccess: (state, action: PayloadAction<WalletTransaction>) => {
      state.transactions.unshift(action.payload);
      state.loading = false;
      state.error = null;
    },
    topUpFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    fetchTransactionsStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    fetchTransactionsSuccess: (
      state,
      action: PayloadAction<{
        transactions: WalletTransaction[];
        total: number;
        page: number;
      }>
    ) => {
      state.transactions = action.payload.transactions;
      state.transactionTotal = action.payload.total;
      state.transactionPage = action.payload.page;
      state.loading = false;
      state.error = null;
    },
    fetchTransactionsFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    clearError: (state) => {
      state.error = null;
    },
  },
});

export const {
  fetchBalanceStart,
  fetchBalanceSuccess,
  fetchBalanceFailure,
  topUpStart,
  topUpSuccess,
  topUpFailure,
  fetchTransactionsStart,
  fetchTransactionsSuccess,
  fetchTransactionsFailure,
  clearError,
} = walletSlice.actions;

export default walletSlice.reducer;
