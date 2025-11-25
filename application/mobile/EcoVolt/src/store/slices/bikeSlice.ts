/**
 * Bike Slice
 * Manages bike state
 */

import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Bike, BikeTelemetry } from '../../types/bike';

interface BikeState {
  details: Bike | null;
  telemetry: BikeTelemetry | null;
  loading: boolean;
  error: string | null;
}

const initialState: BikeState = {
  details: null,
  telemetry: null,
  loading: false,
  error: null,
};

const bikeSlice = createSlice({
  name: 'bike',
  initialState,
  reducers: {
    fetchBikeStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    fetchBikeSuccess: (
      state,
      action: PayloadAction<{ bike: Bike; telemetry: BikeTelemetry | null }>
    ) => {
      state.details = action.payload.bike;
      state.telemetry = action.payload.telemetry;
      state.loading = false;
      state.error = null;
    },
    fetchBikeFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    clearBike: (state) => {
      state.details = null;
      state.telemetry = null;
    },
    clearError: (state) => {
      state.error = null;
    },
  },
});

export const {
  fetchBikeStart,
  fetchBikeSuccess,
  fetchBikeFailure,
  clearBike,
  clearError,
} = bikeSlice.actions;

export default bikeSlice.reducer;
