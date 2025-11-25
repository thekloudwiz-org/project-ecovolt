/**
 * Stations Slice
 * Manages station state
 */

import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Station } from '../../types/station';

interface StationsState {
  nearby: Station[];
  selected: Station | null;
  loading: boolean;
  error: string | null;
  userLocation: {
    latitude: number;
    longitude: number;
  } | null;
}

const initialState: StationsState = {
  nearby: [],
  selected: null,
  loading: false,
  error: null,
  userLocation: null,
};

const stationsSlice = createSlice({
  name: 'stations',
  initialState,
  reducers: {
    fetchStationsStart: (state) => {
      state.loading = true;
      state.error = null;
    },
    fetchStationsSuccess: (state, action: PayloadAction<Station[]>) => {
      state.nearby = action.payload;
      state.loading = false;
      state.error = null;
    },
    fetchStationsFailure: (state, action: PayloadAction<string>) => {
      state.loading = false;
      state.error = action.payload;
    },
    selectStation: (state, action: PayloadAction<Station>) => {
      state.selected = action.payload;
    },
    clearSelectedStation: (state) => {
      state.selected = null;
    },
    setUserLocation: (
      state,
      action: PayloadAction<{ latitude: number; longitude: number }>
    ) => {
      state.userLocation = action.payload;
    },
    clearError: (state) => {
      state.error = null;
    },
  },
});

export const {
  fetchStationsStart,
  fetchStationsSuccess,
  fetchStationsFailure,
  selectStation,
  clearSelectedStation,
  setUserLocation,
  clearError,
} = stationsSlice.actions;

export default stationsSlice.reducer;
