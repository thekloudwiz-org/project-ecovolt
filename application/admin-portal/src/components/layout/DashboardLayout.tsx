import { ReactNode } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'
import './DashboardLayout.css'

interface DashboardLayoutProps {
  children: ReactNode
}

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  const { user, logout } = useAuth()
  const location = useLocation()
  const navigate = useNavigate()

  const handleLogout = async () => {
    await logout()
    // Force a full page reload to ensure auth state is properly cleared
    window.location.href = '/login'
  }

  const navItems = [
    { path: '/dashboard', label: 'Dashboard', icon: '' },
    { path: '/stations', label: 'Stations', icon: '' },
    { path: '/bikes', label: 'Bikes', icon: '' },
    { path: '/users', label: 'Users', icon: '' },
    { path: '/analytics', label: 'Analytics', icon: '' },
  ]

  return (
    <div className="dashboard-layout">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <h1 className="sidebar-logo">EcoVolt</h1>
          <p className="sidebar-subtitle">Admin Portal</p>
        </div>

        <nav className="sidebar-nav">
          {navItems.map((item) => (
            <Link
              key={item.path}
              to={item.path}
              className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}
            >
              <span className="nav-icon">{item.icon}</span>
              <span className="nav-label">{item.label}</span>
            </Link>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="user-info">
            <div className="user-avatar">
              {user?.email.charAt(0).toUpperCase()}
            </div>
            <div className="user-details">
              <p className="user-email">{user?.email}</p>
              <p className="user-role">Administrator</p>
            </div>
          </div>
          <button onClick={handleLogout} className="logout-button">
            Logout
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="main-content">
        {children}
      </main>
    </div>
  )
}
