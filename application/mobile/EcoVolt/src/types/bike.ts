/**
 * Bike Type Definitions
 */

export interface Bike {
  id: string;
  userId: string;
  model: string;
  batteryId: string;
  batteryLevel: number;
  latitude: number;
  longitude: number;
  odometer: number;
  status: 'active' | 'inactive' | 'maintenance';
  lastSwapAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface BikeTelemetry {
  bikeId: string;
  batteryLevel: number;
  latitude: number;
  longitude: number;
  speed: number;
  odometer: number;
  temperature: number;
  timestamp: string;
  isStale: boolean; // True if data is older than 5 minutes
}

export interface BikeDetailsResponse {
  bike: Bike;
  telemetry: BikeTelemetry | null;
}
