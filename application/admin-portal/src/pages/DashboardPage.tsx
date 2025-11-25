import { useQuery } from '@tanstack/react-query'
import { getDashboardMetrics } from '../services/api'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import './DashboardPage.css'

export default function DashboardPage() {
  const { data: metrics, isLoading } = useQuery({
    queryKey: ['dashboard'],
    queryFn: getDashboardMetrics,
  })

  if (isLoading) {
    return <div className="loading">Loading dashboard...</div>
  }

  return (
    <div className="dashboard-page">
      <h1 className="page-title">Dashboard</h1>

      {/* KPI Cards */}
      <div className="kpi-grid">
        <div className="kpi-card">
          <div className="kpi-icon" style={{ backgroundColor: '#e3f2fd' }}></div>
          <div className="kpi-content">
            <p className="kpi-label">Swaps Today</p>
            <p className="kpi-value">{metrics?.totalSwapsToday || 0}</p>
          </div>
        </div>

        <div className="kpi-card">
          <div className="kpi-icon" style={{ backgroundColor: '#e8f5e9' }}></div>
          <div className="kpi-content">
            <p className="kpi-label">Revenue Today</p>
            <p className="kpi-value">GHS {metrics?.totalRevenueToday.toFixed(2) || '0.00'}</p>
          </div>
        </div>

        <div className="kpi-card">
          <div className="kpi-icon" style={{ backgroundColor: '#fff3e0' }}></div>
          <div className="kpi-content">
            <p className="kpi-label">Active Riders</p>
            <p className="kpi-value">{metrics?.activeRiders || 0}</p>
          </div>
        </div>

        <div className="kpi-card">
          <div className="kpi-icon" style={{ backgroundColor: '#fce4ec' }}></div>
          <div className="kpi-content">
            <p className="kpi-label">Total Stations</p>
            <p className="kpi-value">{metrics?.totalStations || 0}</p>
          </div>
        </div>
      </div>

      {/* Swap Trend Chart */}
      <div className="chart-card">
        <h2 className="chart-title">7-Day Swap Trend</h2>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={metrics?.swapTrend || []}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Line type="monotone" dataKey="count" stroke="#2ecc71" strokeWidth={2} />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Top Stations */}
      <div className="table-card">
        <h2 className="table-title">Top 5 Stations by Volume</h2>
        <table className="data-table">
          <thead>
            <tr>
              <th>Station Name</th>
              <th>Swap Count</th>
              <th>Revenue</th>
            </tr>
          </thead>
          <tbody>
            {metrics?.topStations.map((station) => (
              <tr key={station.id}>
                <td>{station.name}</td>
                <td>{station.swapCount}</td>
                <td>GHS {station.revenue.toFixed(2)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
