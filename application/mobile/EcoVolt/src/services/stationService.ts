/**
 * Station Service
 * Handles all station-related API calls
 */

import { get } from 'aws-amplify/api';
import { Station, NearbyStationsParams, StationDetailsResponse } from '../types/station';

const API_NAME = 'EcoVoltAPI';

/**
 * Get nearby stations based on user location
 * Requirements: 2.1, 2.2, 2.4
 */
export const getNearbyStations = async ({
  latitude,
  longitude,
  radius = 10,
}: NearbyStationsParams): Promise<Station[]> => {
  try {
    const response = await get({
      apiName: API_NAME,
      path: '/stations/nearby',
      options: {
        queryParams: {
          latitude: latitude.toString(),
          longitude: longitude.toString(),
          radius: radius.toString(),
        },
      },
    }).response;

    const data = await response.body.json();
    return (data as any).stations || [];
  } catch (error: any) {
    throw new Error(error.message || 'Failed to fetch nearby stations');
  }
};

/**
 * Get station details by ID
 */
export const getStationDetails = async (stationId: string): Promise<StationDetailsResponse> => {
  try {
    const response = await get({
      apiName: API_NAME,
      path: `/stations/${stationId}`,
    }).response;

    const data = await response.body.json();
    return data as StationDetailsResponse;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to fetch station details');
  }
};

/**
 * Get all stations (for admin or full list)
 */
export const getAllStations = async (): Promise<Station[]> => {
  try {
    const response = await get({
      apiName: API_NAME,
      path: '/stations',
    }).response;

    const data = await response.body.json();
    return (data as any).stations || [];
  } catch (error: any) {
    throw new Error(error.message || 'Failed to fetch stations');
  }
};
