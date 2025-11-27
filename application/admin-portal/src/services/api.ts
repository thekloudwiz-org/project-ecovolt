/**
 * API Service
 * Handles all API calls to the backend
 */

import { get, post, put, del } from 'aws-amplify/api'
import { fetchAuthSession } from 'aws-amplify/auth'
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

// Helper to get auth headers
async function getAuthHeaders() {
  try {
    const session = await fetchAuthSession()
    // Use idToken for Cognito User Pool authorizer
    const token = session.tokens?.idToken?.toString()
    if (!token) {
      console.error('No auth token available. Session:', session)
      throw new Error('No authentication token available')
    }
    console.log('Auth token retrieved, length:', token.length)
    return {
      Authorization: `Bearer ${token}`,
    }
  } catch (error) {
    console.error('Error getting auth headers:', error)
    throw error
  }
}

// Dashboard
export const getDashboardMetrics = async (): Promise<DashboardMetrics> => {
  const headers = await getAuthHeaders()
  const response = await get({
    apiName: API_NAME,
    path: '/admin/dashboard',
    options: { headers },
  }).response
  const data = await response.body.json()
  return data as unknown as DashboardMetrics
}

// Stations
export const getStations = async (page = 1, pageSize = 20) => {
  const headers = await getAuthHeaders()
  const response = await get({
    apiName: API_NAME,
    path: '/admin/stations',
    options: {
      headers,
      queryParams: { page: page.toString(), page_size: pageSize.toString() },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as { stations: Station[]; pagination: any }
}

export const createStation = async (data: StationFormData): Promise<Station> => {
  const headers = await getAuthHeaders()
  try {
    const response = await post({
      apiName: API_NAME,
      path: '/admin/stations',
      options: { headers, body: data as any },
    }).response
    const result = await response.body.json()

    // Check if response contains an error
    if ((result as any).error) {
      throw new Error((result as any).details || (result as any).error)
    }

    return (result as any).station as Station
  } catch (error: any) {
    // Re-throw with better error message
    const errorMessage = error.response?.body
      ? JSON.parse(await error.response.body.text()).details || JSON.parse(await error.response.body.text()).error
      : error.message
    throw new Error(errorMessage || 'Failed to create station')
  }
}

export const updateStation = async (id: string, data: Partial<StationFormData>): Promise<Station> => {
  const headers = await getAuthHeaders()
  const response = await put({
    apiName: API_NAME,
    path: `/admin/stations/${id}`,
    options: { headers, body: data as any },
  }).response
  const result = await response.body.json()
  return (result as any).station as Station
}

export const deleteStation = async (id: string): Promise<void> => {
  const headers = await getAuthHeaders()
  await del({
    apiName: API_NAME,
    path: `/admin/stations/${id}`,
    options: { headers },
  }).response
}

// Bikes
export const getBikes = async (page = 1, pageSize = 20) => {
  try {
    const headers = await getAuthHeaders()
    const restOperation = get({
      apiName: API_NAME,
      path: '/admin/bikes',
      options: {
        headers,
        queryParams: { page: page.toString(), page_size: pageSize.toString() },
      },
    })
    const response = await restOperation.response
    const data = await response.body.json()
    return data as unknown as { bikes: Bike[]; pagination: any }
  } catch (error: any) {
    console.error('getBikes error:', error)
    throw new Error(error.message || error.response?.body || 'Failed to fetch bikes')
  }
}

export const createBike = async (data: BikeFormData): Promise<Bike> => {
  const headers = await getAuthHeaders()
  const response = await post({
    apiName: API_NAME,
    path: '/admin/bikes',
    options: { headers, body: data as any },
  }).response
  const result = await response.body.json()
  return (result as any).bike as Bike
}

export const updateBike = async (id: string, data: Partial<BikeFormData>): Promise<Bike> => {
  const headers = await getAuthHeaders()
  const response = await put({
    apiName: API_NAME,
    path: `/admin/bikes/${id}`,
    options: { headers, body: data as any },
  }).response
  const result = await response.body.json()
  return (result as any).bike as Bike
}

export const assignBike = async (id: string, userId: string): Promise<Bike> => {
  const headers = await getAuthHeaders()
  const response = await put({
    apiName: API_NAME,
    path: `/admin/bikes/${id}/assign`,
    options: { headers, body: { user_id: userId } as any },
  }).response
  const result = await response.body.json()
  return (result as any).bike as Bike
}

// Users
export const getUsers = async (page = 1, pageSize = 20) => {
  try {
    const headers = await getAuthHeaders()
    const response = await get({
      apiName: API_NAME,
      path: '/admin/users',
      options: {
        headers,
        queryParams: { page: page.toString(), page_size: pageSize.toString() },
      },
    }).response
    const data = await response.body.json()
    return data as unknown as { users: User[]; pagination: any }
  } catch (error: any) {
    console.error('getUsers error:', error)
    throw new Error(error.message || error.response?.body || 'Failed to fetch users')
  }
}

export const getUser = async (id: string): Promise<UserDetails> => {
  const headers = await getAuthHeaders()
  const response = await get({
    apiName: API_NAME,
    path: `/admin/users/${id}`,
    options: { headers },
  }).response
  const data = await response.body.json()
  return data as unknown as UserDetails
}

export const adjustWalletBalance = async (
  userId: string,
  adjustment: number,
  reason: string
): Promise<void> => {
  const headers = await getAuthHeaders()
  await put({
    apiName: API_NAME,
    path: `/admin/users/${userId}/wallet`,
    options: { headers, body: { adjustment, reason } as any },
  }).response
}

// Analytics
export const getAnalytics = async (startDate: string, endDate: string): Promise<TimeSeriesAnalytics> => {
  const headers = await getAuthHeaders()
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics',
    options: {
      headers,
      queryParams: { start_date: startDate, end_date: endDate },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as TimeSeriesAnalytics
}

export const getStationAnalytics = async (startDate: string, endDate: string): Promise<StationAnalytics> => {
  const headers = await getAuthHeaders()
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics/stations',
    options: {
      headers,
      queryParams: { start_date: startDate, end_date: endDate },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as StationAnalytics
}

export const getRevenueAnalytics = async (startDate: string, endDate: string): Promise<RevenueAnalytics> => {
  const headers = await getAuthHeaders()
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics/revenue',
    options: {
      headers,
      queryParams: { start_date: startDate, end_date: endDate },
    },
  }).response
  const data = await response.body.json()
  return data as unknown as RevenueAnalytics
}

export const getBatteryAnalytics = async (): Promise<BatteryAnalytics> => {
  const headers = await getAuthHeaders()
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics/batteries',
    options: { headers },
  }).response
  const data = await response.body.json()
  return data as unknown as BatteryAnalytics
}
