/**
 * Type Definitions for Admin Portal
 * Matches backend API responses exactly
 */

// Dashboard Types
export interface DashboardMetrics {
  metrics: {
    swaps_today: number
    revenue_today: number
    active_riders: number
    total_stations: number
  }
  swap_trend_7days: Array<{
    date: string
    swaps: number
  }>
  top_stations: Array<{
    station_id: string
    name: string
    swap_count: number
  }>
}

// Station Types
export interface Station {
  station_id: string
  name: string
  address: string
  city: string
  latitude: number
  longitude: number
  total_capacity: number
  status: 'active' | 'inactive' | 'maintenance'
  operating_hours?: string
  amenities?: string
  pricing?: string
  created_at: string
  updated_at?: string
}

export interface StationFormData {
  name: string
  address: string
  city: string
  latitude: number
  longitude: number
  total_capacity: number
  operating_hours?: string
  amenities?: string[]
  pricing?: Record<string, any>
}

// Bike Types
export interface Bike {
  bike_id: string
  user_id: string | null
  model: string
  battery_id: string | null
  battery_level: number | null
  status: 'active' | 'inactive' | 'maintenance'
  odometer: number | null
  last_swap: string | null
  created_at: string
  updated_at?: string
  latest_telemetry?: {
    battery_level: number
    location: {
      latitude: number
      longitude: number
    }
    timestamp: string
  }
}

export interface BikeFormData {
  bike_id: string
  model: string
  battery_id?: string
}

// User Types
export interface User {
  user_id: string
  email: string
  name: string
  phone: string
  wallet_balance: number
  subscription: string
  total_swaps: number
  created_at: string
}

export interface UserDetails extends User {
  statistics: {
    total_swaps: number
    total_spent: number
    bikes_count: number
  }
  bikes: Array<{
    bike_id: string
    model: string
    status: string
  }>
}

// Analytics Types
export interface TimeSeriesAnalytics {
  date_range: {
    start_date: string
    end_date: string
  }
  daily_analytics: Array<{
    date: string
    swap_volume: number
    revenue: number
    avg_duration_seconds: number
  }>
  user_analytics: Array<{
    date: string
    new_users: number
  }>
}

export interface StationAnalytics {
  date_range: {
    start_date: string
    end_date: string
  }
  station_analytics: Array<{
    station_id: string
    name: string
    city: string
    swap_count: number
    revenue: number
  }>
}

export interface RevenueAnalytics {
  date_range: {
    start_date: string
    end_date: string
  }
  total_revenue: number
  revenue_by_station: Array<{
    station_name: string
    revenue: number
  }>
  daily_revenue: Array<{
    date: string
    revenue: number
  }>
}

export interface BatteryAnalytics {
  total_batteries: number
  average_health: number
  average_cycles: number
  status_distribution: Record<string, number>
  health_distribution: {
    excellent: number
    good: number
    fair: number
    poor: number
  }
}

// Pagination Types
export interface PaginationParams {
  page: number
  page_size: number
}

export interface PaginationMeta {
  page: number
  page_size: number
  total_count: number
  total_pages: number
  has_next: boolean
  has_prev: boolean
}

export interface PaginatedResponse<T> {
  [key: string]: T[] | PaginationMeta
  pagination: PaginationMeta
}
