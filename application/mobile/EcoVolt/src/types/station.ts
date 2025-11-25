/**
 * Station Type Definitions
 */

export interface Station {
  id: string;
  name: string;
  address: string;
  city: string;
  latitude: number;
  longitude: number;
  distance?: number; // Distance from user in km
  availableBatteries: number;
  totalCapacity: number;
  operatingHours: string;
  swapCost: number;
  status: 'active' | 'inactive' | 'maintenance';
  createdAt: string;
  updatedAt: string;
}

export interface NearbyStationsParams {
  latitude: number;
  longitude: number;
  radius?: number; // in km, default 10
}

export interface StationDetailsResponse {
  station: Station;
  realtimeBatteryCount: number;
  recentSwaps: number;
}
