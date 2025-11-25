/**
 * Bike Service
 * Handles all bike-related API calls
 */

import { get } from 'aws-amplify/api';
import { BikeDetailsResponse } from '../types/bike';

const API_NAME = 'EcoVoltAPI';

/**
 * Get bike details with telemetry
 * Requirements: 7.1, 7.2, 7.3, 7.4
 */
export const getBikeDetails = async (bikeId: string): Promise<BikeDetailsResponse> => {
  try {
    const response = await get({
      apiName: API_NAME,
      path: `/bikes/${bikeId}`,
    }).response;

    const data = await response.body.json();
    return data as BikeDetailsResponse;
  } catch (error: any) {
    throw new Error(error.message || 'Failed to fetch bike details');
  }
};
