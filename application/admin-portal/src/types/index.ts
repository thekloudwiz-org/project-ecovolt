/**
 * Type Definitions for Admin Portal
 */

export interface DashboardMetrics {
  totalSwapsToday: number
  totalRevenueToday: number
  activeRiders: number
  totalStations: number
  swapTrend: Array<{
    date: string
    count: number
  }>
  topStations: Array<{
    id: string
    name: string
    swapCount: number
    revenue: number
  }>
}

export interface Station {
  id: string
  name: string
  address: string
  city: string
  latitude: number
  longitude: number
  capacity: number
  availableBatteries: number
  swapCost: number
  status: 'active' | 'inactive' | 'maintenance'
  operatingHours: string
  createdAt: string
  updatedAt: string
}

export interface Bike {
  id: string
  userId: string | null
  model: string
  batteryId: string
  batteryLevel: number
  status: 'active' | 'inactive' | 'maintenance'
  latitude: number
  longitude: number
  odometer: number
  lastSwapAt: string | null
  createdAt: string
  updatedAt: string
}

export interface User {
  id: string
  email: string
  name: string
  phone: string
  walletBalance: number
  totalSwaps: number
  createdAt: string
  lastActiveAt: string
}

export interface Analytics {
  dateRange: {
    start: string
    end: string
  }
  swapVolume: Array<{
    date: string
    count: number
  }>
  revenue: Array<{
    date: string
    amount: number
  }>
  activeUsers: Array<{
    date: string
    count: number
  }>
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}
