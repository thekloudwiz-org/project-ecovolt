/**
 * API Service
 * Handles all API calls to the backend
 */

import { get, post, put, del } from 'aws-amplify/api'
import type {
  DashboardMetrics,
  Station,
  StationFormData,
  Bike,
  BikeFormData,
  User,
  UserDetails,
  TimeSeriesAnalytics,
  StationAnalytics,
  RevenueAnalytics,
  BatteryAnalytics,
} from '../types'

const API_NAME = 'EcoVoltAPI'

// Dashboard
export const getDashboardMetrics = async (): Promise<DashboardMetrics> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/dashboard',
  }).response
  const data = await response.body.json()
  return data as unknown as DashboardMetrics
}

// Stations
export const getStations = async (page = 1, pageSize = 20) => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/stations',
    options: {
      queryParams: { page: page.toString(), page_size: pageSize.toString() },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as { stations: Station[]; pagination: any }
}

export const createStation = async (data: StationFormData): Promise<Station> => {
  const response = await post({
    apiName: API_NAME,
    path: '/admin/stations',
    options: { body: data as any },
  }).response
  const result = await response.body.json()
  return (result as any).station as Station
}

export const updateStation = async (id: string, data: Partial<StationFormData>): Promise<Station> => {
  const response = await put({
    apiName: API_NAME,
    path: `/admin/stations/${id}`,
    options: { body: data as any },
  }).response
  const result = await response.body.json()
  return (result as any).station as Station
}

export const deleteStation = async (id: string): Promise<void> => {
  await del({
    apiName: API_NAME,
    path: `/admin/stations/${id}`,
  }).response
}

// Bikes
export const getBikes = async (page = 1, pageSize = 20) => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/bikes',
    options: {
      queryParams: { page: page.toString(), page_size: pageSize.toString() },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as { bikes: Bike[]; pagination: any }
}

export const createBike = async (data: BikeFormData): Promise<Bike> => {
  const response = await post({
    apiName: API_NAME,
    path: '/admin/bikes',
    options: { body: data as any },
  }).response
  const result = await response.body.json()
  return (result as any).bike as Bike
}

export const updateBike = async (id: string, data: Partial<BikeFormData>): Promise<Bike> => {
  const response = await put({
    apiName: API_NAME,
    path: `/admin/bikes/${id}`,
    options: { body: data as any },
  }).response
  const result = await response.body.json()
  return (result as any).bike as Bike
}

export const assignBike = async (id: string, userId: string): Promise<Bike> => {
  const response = await put({
    apiName: API_NAME,
    path: `/admin/bikes/${id}/assign`,
    options: { body: { user_id: userId } as any },
  }).response
  const result = await response.body.json()
  return (result as any).bike as Bike
}

// Users
export const getUsers = async (page = 1, pageSize = 20) => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/users',
    options: {
      queryParams: { page: page.toString(), page_size: pageSize.toString() },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as { users: User[]; pagination: any }
}

export const getUser = async (id: string): Promise<UserDetails> => {
  const response = await get({
    apiName: API_NAME,
    path: `/admin/users/${id}`,
  }).response
  const data = await response.body.json()
  return data as unknown as UserDetails
}

export const adjustWalletBalance = async (
  userId: string,
  adjustment: number,
  reason: string
): Promise<void> => {
  await put({
    apiName: API_NAME,
    path: `/admin/users/${userId}/wallet`,
    options: { body: { adjustment, reason } as any },
  }).response
}

// Analytics
export const getAnalytics = async (startDate: string, endDate: string): Promise<TimeSeriesAnalytics> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics',
    options: {
      queryParams: { start_date: startDate, end_date: endDate },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as TimeSeriesAnalytics
}

export const getStationAnalytics = async (startDate: string, endDate: string): Promise<StationAnalytics> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics/stations',
    options: {
      queryParams: { start_date: startDate, end_date: endDate },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as StationAnalytics
}

export const getRevenueAnalytics = async (startDate: string, endDate: string): Promise<RevenueAnalytics> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics/revenue',
    options: {
      queryParams: { start_date: startDate, end_date: endDate },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as RevenueAnalytics
}

export const getBatteryAnalytics = async (): Promise<BatteryAnalytics> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics/batteries',
  }).response
  const data = await response.body.json()
  return data as unknown as BatteryAnalytics
}
