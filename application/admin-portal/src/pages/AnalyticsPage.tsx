import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  getAnalytics,
  getStationAnalytics,
  getRevenueAnalytics,
  getBatteryAnalytics,
} from '../services/api'
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts'
import './AnalyticsPage.css'

export default function AnalyticsPage() {
  // Default to last 30 days
  const today = new Date()
  const thirtyDaysAgo = new Date(today)
  thirtyDaysAgo.setDate(today.getDate() - 30)

  const [startDate, setStartDate] = useState(thirtyDaysAgo.toISOString().split('T')[0])
  const [endDate, setEndDate] = useState(today.toISOString().split('T')[0])
  const [activeTab, setActiveTab] = useState<'overview' | 'stations' | 'revenue' | 'batteries'>(
    'overview'
  )

  // Fetch analytics data
  const { data: timeSeriesData, isLoading: timeSeriesLoading } = useQuery({
    queryKey: ['analytics', startDate, endDate],
    queryFn: () => getAnalytics(startDate, endDate),
  })

  const { data: stationData, isLoading: stationLoading } = useQuery({
    queryKey: ['station-analytics', startDate, endDate],
    queryFn: () => getStationAnalytics(startDate, endDate),
    enabled: activeTab === 'stations',
  })

  const { data: revenueData, isLoading: revenueLoading } = useQuery({
    queryKey: ['revenue-analytics', startDate, endDate],
    queryFn: () => getRevenueAnalytics(startDate, endDate),
    enabled: activeTab === 'revenue',
  })

  const { data: batteryData, isLoading: batteryLoading } = useQuery({
    queryKey: ['battery-analytics'],
    queryFn: getBatteryAnalytics,
    enabled: activeTab === 'batteries',
  })

  const handleDateChange = () => {
    // Dates are already bound to state, queries will refetch automatically
  }

  const exportToCSV = () => {
    let csvContent = ''
    let filename = ''

    if (activeTab === 'overview' && timeSeriesData) {
      csvContent = 'Date,Swap Volume,Revenue,Avg Duration (s),New Users\n'
      timeSeriesData.daily_analytics.forEach((day) => {
        const userDay = timeSeriesData.user_analytics.find((u) => u.date === day.date)
        csvContent += `${day.date},${day.swap_volume},${day.revenue},${day.avg_duration_seconds},${userDay?.new_users || 0}\n`
      })
      filename = `analytics_overview_${startDate}_${endDate}.csv`
    } else if (activeTab === 'stations' && stationData) {
      csvContent = 'Station ID,Name,City,Swap Count,Revenue\n'
      stationData.station_analytics.forEach((station) => {
        csvContent += `${station.station_id},${station.name},${station.city},${station.swap_count},${station.revenue}\n`
      })
      filename = `station_analytics_${startDate}_${endDate}.csv`
    } else if (activeTab === 'revenue' && revenueData) {
      csvContent = 'Date,Revenue\n'
      revenueData.daily_revenue.forEach((day) => {
        csvContent += `${day.date},${day.revenue}\n`
      })
      filename = `revenue_analytics_${startDate}_${endDate}.csv`
    }

    if (csvContent) {
      const blob = new Blob([csvContent], { type: 'text/csv' })
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      a.click()
      window.URL.revokeObjectURL(url)
    }
  }

  const COLORS = ['#2ecc71', '#3498db', '#f39c12', '#e74c3c', '#9b59b6']

  return (
    <div className="analytics-page">
      <div className="page-header">
        <h1 className="page-title">Analytics & Reports</h1>
        <button className="btn-primary" onClick={exportToCSV}>
          Export to CSV
        </button>
      </div>

      {/* Date Range Picker */}
      <div className="date-range-picker">
        <div className="date-input-group">
          <label>Start Date:</label>
          <input
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            max={endDate}
          />
        </div>
        <div className="date-input-group">
          <label>End Date:</label>
          <input
            type="date"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
            min={startDate}
            max={today.toISOString().split('T')[0]}
          />
        </div>
        <button className="btn-secondary" onClick={handleDateChange}>
          Apply
        </button>
      </div>

      {/* Tabs */}
      <div className="tabs">
        <button
          className={`tab ${activeTab === 'overview' ? 'active' : ''}`}
          onClick={() => setActiveTab('overview')}
        >
          Overview
        </button>
        <button
          className={`tab ${activeTab === 'stations' ? 'active' : ''}`}
          onClick={() => setActiveTab('stations')}
        >
          Stations
        </button>
        <button
          className={`tab ${activeTab === 'revenue' ? 'active' : ''}`}
          onClick={() => setActiveTab('revenue')}
        >
          Revenue
        </button>
        <button
          className={`tab ${activeTab === 'batteries' ? 'active' : ''}`}
          onClick={() => setActiveTab('batteries')}
        >
          Batteries
        </button>
      </div>

      {/* Overview Tab */}
      {activeTab === 'overview' && (
        <div className="tab-content">
          {timeSeriesLoading ? (
            <div className="loading">Loading analytics...</div>
          ) : timeSeriesData ? (
            <>
              {/* Swap Volume Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Swap Volume Over Time</h2>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={timeSeriesData.daily_analytics}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line
                      type="monotone"
                      dataKey="swap_volume"
                      stroke="#2ecc71"
                      strokeWidth={2}
                      name="Swaps"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>

              {/* Revenue Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Revenue Over Time</h2>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={timeSeriesData.daily_analytics}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line
                      type="monotone"
                      dataKey="revenue"
                      stroke="#3498db"
                      strokeWidth={2}
                      name="Revenue (GHS)"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>

              {/* New Users Chart */}
              <div className="chart-card">
                <h2 className="chart-title">New User Registrations</h2>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={timeSeriesData.user_analytics}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Bar dataKey="new_users" fill="#9b59b6" name="New Users" />
                  </BarChart>
                </ResponsiveContainer>
              </div>

              {/* Average Duration Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Average Swap Duration</h2>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={timeSeriesData.daily_analytics}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line
                      type="monotone"
                      dataKey="avg_duration_seconds"
                      stroke="#f39c12"
                      strokeWidth={2}
                      name="Avg Duration (seconds)"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </>
          ) : (
            <div className="error">No data available</div>
          )}
        </div>
      )}

      {/* Stations Tab */}
      {activeTab === 'stations' && (
        <div className="tab-content">
          {stationLoading ? (
            <div className="loading">Loading station analytics...</div>
          ) : stationData ? (
            <>
              {/* Station Performance Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Station Performance by Swap Count</h2>
                <ResponsiveContainer width="100%" height={400}>
                  <BarChart data={stationData.station_analytics.slice(0, 10)}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Bar dataKey="swap_count" fill="#2ecc71" name="Swap Count" />
                  </BarChart>
                </ResponsiveContainer>
              </div>

              {/* Station Revenue Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Station Revenue Comparison</h2>
                <ResponsiveContainer width="100%" height={400}>
                  <BarChart data={stationData.station_analytics.slice(0, 10)}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Bar dataKey="revenue" fill="#3498db" name="Revenue (GHS)" />
                  </BarChart>
                </ResponsiveContainer>
              </div>

              {/* Station Table */}
              <div className="table-card">
                <h2 className="table-title">All Stations Performance</h2>
                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Station Name</th>
                        <th>City</th>
                        <th>Swap Count</th>
                        <th>Revenue (GHS)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {stationData.station_analytics.map((station) => (
                        <tr key={station.station_id}>
                          <td>{station.name}</td>
                          <td>{station.city}</td>
                          <td>{station.swap_count}</td>
                          <td>{station.revenue.toFixed(2)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          ) : (
            <div className="error">No data available</div>
          )}
        </div>
      )}

      {/* Revenue Tab */}
      {activeTab === 'revenue' && (
        <div className="tab-content">
          {revenueLoading ? (
            <div className="loading">Loading revenue analytics...</div>
          ) : revenueData ? (
            <>
              {/* Total Revenue Summary */}
              <div className="summary-card">
                <h2>Total Revenue</h2>
                <div className="summary-value">GHS {revenueData.total_revenue.toFixed(2)}</div>
                <div className="summary-period">
                  {startDate} to {endDate}
                </div>
              </div>

              {/* Daily Revenue Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Daily Revenue</h2>
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={revenueData.daily_revenue}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="date" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line
                      type="monotone"
                      dataKey="revenue"
                      stroke="#2ecc71"
                      strokeWidth={2}
                      name="Revenue (GHS)"
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>

              {/* Revenue by Station Pie Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Revenue Distribution by Station</h2>
                <ResponsiveContainer width="100%" height={400}>
                  <PieChart>
                    <Pie
                      data={revenueData.revenue_by_station.slice(0, 5)}
                      dataKey="revenue"
                      nameKey="station_name"
                      cx="50%"
                      cy="50%"
                      outerRadius={120}
                      label
                    >
                      {revenueData.revenue_by_station.slice(0, 5).map((_entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>

              {/* Revenue by Station Table */}
              <div className="table-card">
                <h2 className="table-title">Revenue by Station</h2>
                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Station Name</th>
                        <th>Revenue (GHS)</th>
                        <th>Percentage</th>
                      </tr>
                    </thead>
                    <tbody>
                      {revenueData.revenue_by_station.map((station) => (
                        <tr key={station.station_name}>
                          <td>{station.station_name}</td>
                          <td>{station.revenue.toFixed(2)}</td>
                          <td>
                            {((station.revenue / revenueData.total_revenue) * 100).toFixed(1)}%
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          ) : (
            <div className="error">No data available</div>
          )}
        </div>
      )}

      {/* Batteries Tab */}
      {activeTab === 'batteries' && (
        <div className="tab-content">
          {batteryLoading ? (
            <div className="loading">Loading battery analytics...</div>
          ) : batteryData ? (
            <>
              {/* Battery Summary Cards */}
              <div className="summary-grid">
                <div className="summary-card">
                  <h3>Total Batteries</h3>
                  <div className="summary-value">{batteryData.total_batteries}</div>
                </div>
                <div className="summary-card">
                  <h3>Average Health</h3>
                  <div className="summary-value">{batteryData.average_health.toFixed(1)}%</div>
                </div>
                <div className="summary-card">
                  <h3>Average Cycles</h3>
                  <div className="summary-value">{batteryData.average_cycles.toFixed(0)}</div>
                </div>
              </div>

              {/* Health Distribution Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Battery Health Distribution</h2>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart
                    data={[
                      { range: 'Excellent (90-100%)', count: batteryData.health_distribution.excellent },
                      { range: 'Good (70-89%)', count: batteryData.health_distribution.good },
                      { range: 'Fair (50-69%)', count: batteryData.health_distribution.fair },
                      { range: 'Poor (<50%)', count: batteryData.health_distribution.poor },
                    ]}
                  >
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="range" />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="count" fill="#2ecc71" name="Battery Count" />
                  </BarChart>
                </ResponsiveContainer>
              </div>

              {/* Status Distribution Pie Chart */}
              <div className="chart-card">
                <h2 className="chart-title">Battery Status Distribution</h2>
                <ResponsiveContainer width="100%" height={400}>
                  <PieChart>
                    <Pie
                      data={Object.entries(batteryData.status_distribution).map(([key, value]) => ({
                        name: key,
                        value,
                      }))}
                      dataKey="value"
                      nameKey="name"
                      cx="50%"
                      cy="50%"
                      outerRadius={120}
                      label
                    >
                      {Object.keys(batteryData.status_distribution).map((_key, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </>
          ) : (
            <div className="error">No data available</div>
          )}
        </div>
      )}
    </div>
  )
}
