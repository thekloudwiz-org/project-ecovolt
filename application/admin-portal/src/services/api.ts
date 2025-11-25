/**
 * API Service
 * Handles all API calls to the backend
 */

import { get, post, put, del } from 'aws-amplify/api'
import type { DashboardMetrics, Station, Bike, User, Analytics, PaginatedResponse } from '../types'

const API_NAME = 'EcoVoltAPI'

// Dashboard
export const getDashboardMetrics = async (): Promise<DashboardMetrics> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/dashboard',
  }).response
  return (await response.body.json()) as any
}

// Stations
export const getStations = async (page = 1, pageSize = 20): Promise<PaginatedResponse<Station>> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/stations',
    options: {
      queryParams: { page: page.toString(), page_size: pageSize.toString() },
    },
  }).response
  return (await response.body.json()) as any
}

export const createStation = async (data: Partial<Station>): Promise<Station> => {
  const response = await post({
    apiName: API_NAME,
    path: '/admin/stations',
    options: { body: data },
  }).response
  return ((await response.body.json()) as any).station
}

export const updateStation = async (id: string, data: Partial<Station>): Promise<Station> => {
  const response = await put({
    apiName: API_NAME,
    path: `/admin/stations/${id}`,
    options: { body: data },
  }).response
  return ((await response.body.json()) as any).station
}

export const deleteStation = async (id: string): Promise<void> => {
  await del({
    apiName: API_NAME,
    path: `/admin/stations/${id}`,
  }).response
}

// Bikes
export const getBikes = async (page = 1, pageSize = 20): Promise<PaginatedResponse<Bike>> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/bikes',
    options: {
      queryParams: { page: page.toString(), page_size: pageSize.toString() },
    },
  }).response
  return (await response.body.json()) as any
}

export const createBike = async (data: Partial<Bike>): Promise<Bike> => {
  const response = await post({
    apiName: API_NAME,
    path: '/admin/bikes',
    options: { body: data },
  }).response
  return ((await response.body.json()) as any).bike
}

export const updateBike = async (id: string, data: Partial<Bike>): Promise<Bike> => {
  const response = await put({
    apiName: API_NAME,
    path: `/admin/bikes/${id}`,
    options: { body: data },
  }).response
  return ((await response.body.json()) as any).bike
}

export const assignBike = async (id: string, userId: string): Promise<Bike> => {
  const response = await put({
    apiName: API_NAME,
    path: `/admin/bikes/${id}/assign`,
    options: { body: { user_id: userId } },
  }).response
  return ((await response.body.json()) as any).bike
}

// Users
export const getUsers = async (page = 1, pageSize = 20): Promise<PaginatedResponse<User>> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/users',
    options: {
      queryParams: { page: page.toString(), page_size: pageSize.toString() },
    },
  }).response
  return (await response.body.json()) as any
}

export const getUser = async (id: string): Promise<User> => {
  const response = await get({
    apiName: API_NAME,
    path: `/admin/users/${id}`,
  }).response
  return ((await response.body.json()) as any).user
}

export const adjustWalletBalance = async (
  userId: string,
  amount: number,
  reason: string
): Promise<void> => {
  await put({
    apiName: API_NAME,
    path: `/admin/users/${userId}/wallet`,
    options: { body: { amount, reason } },
  }).response
}

// Analytics
export const getAnalytics = async (startDate: string, endDate: string): Promise<Analytics> => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics',
    options: {
      queryParams: { start_date: startDate, end_date: endDate },
    },
  }).response
  return (await response.body.json()) as any
}

export const getStationAnalytics = async (startDate: string, endDate: string) => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics/stations',
    options: {
      queryParams: { start_date: startDate, end_date: endDate },
    },
  }).response
  return (await response.body.json()) as any
}

export const getRevenueAnalytics = async (startDate: string, endDate: string) => {
  const response = await get({
    apiName: API_NAME,
    path: '/admin/analytics/revenue',
    options: {
      queryParams: { start_date: startDate, end_date: endDate },
    },
  }).response
  return (await response.body.json()) as any
}
