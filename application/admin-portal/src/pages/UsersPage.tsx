import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getUsers, getUser, adjustWalletBalance, createUser } from '../services/api'
import type { User } from '../types'
import MessageModal from '../components/MessageModal'
import './UsersPage.css'

export default function UsersPage() {
  const queryClient = useQueryClient()
  const [page, setPage] = useState(1)
  const [searchTerm, setSearchTerm] = useState('')
  const [showDetailsModal, setShowDetailsModal] = useState(false)
  const [showWalletModal, setShowWalletModal] = useState(false)
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null)
  const [messageModal, setMessageModal] = useState<{ type: 'success' | 'error'; message: string } | null>(null)

  // Fetch users
  const { data, isLoading, error } = useQuery({
    queryKey: ['users', page],
    queryFn: () => getUsers(page, 20),
  })

  // Fetch user details
  const {
    data: userDetails,
    isLoading: detailsLoading,
    error: detailsError,
  } = useQuery({
    queryKey: ['user', selectedUserId],
    queryFn: () => getUser(selectedUserId!),
    enabled: !!selectedUserId && showDetailsModal,
  })

  // Create user mutation
  const createMutation = useMutation({
    mutationFn: createUser,
    onSuccess: (data: { user: User; temporary_password: string }) => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      setShowCreateModal(false)
      setMessageModal({
        type: 'success',
        message: `User created successfully!\n\nEmail: ${data.user.email}\n\nTemporary Password: ${data.temporary_password}\n\nUser must change password on first login.`
      })
    },
    onError: (error: Error) => {
      setMessageModal({
        type: 'error',
        message: error.message || 'Failed to create user. Please try again.'
      })
    },
  })

  // Wallet adjustment mutation
  const walletMutation = useMutation({
    mutationFn: ({
      userId,
      adjustment,
      reason,
    }: {
      userId: string
      adjustment: number
      reason: string
    }) => adjustWalletBalance(userId, adjustment, reason),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      queryClient.invalidateQueries({ queryKey: ['user', selectedUserId] })
      setShowWalletModal(false)
      setMessageModal({
        type: 'success',
        message: 'Wallet balance adjusted successfully!'
      })
    },
    onError: (error: Error) => {
      setMessageModal({
        type: 'error',
        message: error.message || 'Failed to adjust wallet balance.'
      })
    },
  })

  const handleWalletAdjustment = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    const adjustment = parseFloat(formData.get('adjustment') as string)
    const reason = formData.get('reason') as string

    if (selectedUserId && !isNaN(adjustment)) {
      walletMutation.mutate({ userId: selectedUserId, adjustment, reason })
    }
  }

  const openDetailsModal = (userId: string) => {
    setSelectedUserId(userId)
    setShowDetailsModal(true)
  }

  const openWalletModal = (userId: string) => {
    setSelectedUserId(userId)
    setShowWalletModal(true)
  }

  const handleCreateUser = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    
    createMutation.mutate({
      email: formData.get('email') as string,
      name: formData.get('name') as string,
      phone: formData.get('phone') as string,
      subscription: formData.get('subscription') as string,
    })
  }

  const closeDetailsModal = () => {
    setShowDetailsModal(false)
    setSelectedUserId(null)
  }

  const closeWalletModal = () => {
    setShowWalletModal(false)
  }

  // Filter users by search term
  const filteredUsers = data?.users?.filter(
    (user: User) =>
      user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.user_id.toLowerCase().includes(searchTerm.toLowerCase())
  )

  if (isLoading) {
    return <div className="loading">Loading users...</div>
  }

  if (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    return <div className="error">Error loading users: {errorMessage || 'Unknown error occurred'}</div>
  }

  return (
    <div className="users-page">
      <div className="page-header">
        <h1 className="page-title">User Management</h1>
        <button className="btn-primary" onClick={() => setShowCreateModal(true)}>
          + Add User
        </button>
      </div>

      {/* Search */}
      <div className="search-bar">
        <input
          type="text"
          placeholder="Search by email, name, or user ID..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="search-input"
        />
      </div>

      {/* Users Table */}
      <div className="table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>User ID</th>
              <th>Name</th>
              <th>Email</th>
              <th>Phone</th>
              <th>Wallet Balance</th>
              <th>Total Swaps</th>
              <th>Subscription</th>
              <th>Joined</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers?.map((user: User) => (
              <tr key={user.user_id}>
                <td className="user-id">{user.user_id}</td>
                <td>{user.name}</td>
                <td>{user.email}</td>
                <td>{user.phone}</td>
                <td className="wallet-balance">GHS {user.wallet_balance.toFixed(2)}</td>
                <td>{user.total_swaps}</td>
                <td>
                  <span className={`subscription-badge subscription-${user.subscription}`}>
                    {user.subscription}
                  </span>
                </td>
                <td>{new Date(user.created_at).toLocaleDateString()}</td>
                <td>
                  <div className="action-buttons">
                    <button
                      className="btn-icon"
                      onClick={() => openDetailsModal(user.user_id)}
                    >
                      Details
                    </button>
                    <button
                      className="btn-icon"
                      onClick={() => openWalletModal(user.user_id)}
                    >
                      Adjust Wallet
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {data?.pagination && (
        <div className="pagination">
          <button
            onClick={() => setPage(page - 1)}
            disabled={!data.pagination.has_prev}
            className="btn-secondary"
          >
            Previous
          </button>
          <span className="page-info">
            Page {data.pagination.page} of {data.pagination.total_pages} (
            {data.pagination.total_count} total users)
          </span>
          <button
            onClick={() => setPage(page + 1)}
            disabled={!data.pagination.has_next}
            className="btn-secondary"
          >
            Next
          </button>
        </div>
      )}

      {/* User Details Modal */}
      {showDetailsModal && (
        <div className="modal-overlay" onClick={closeDetailsModal}>
          <div className="modal-content modal-large" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>User Details</h2>
              <button className="modal-close" onClick={closeDetailsModal}>
                ×
              </button>
            </div>
            <div className="modal-body">
              {detailsLoading && <div className="loading">Loading user details...</div>}
              {detailsError && (
                <div className="error">
                  Error loading details: {(detailsError as Error).message}
                </div>
              )}
              {userDetails && (
                <div className="user-details">
                  {/* Basic Info */}
                  <div className="details-section">
                    <h3>Basic Information</h3>
                    <div className="details-grid">
                      <div className="detail-item">
                        <label>User ID:</label>
                        <span>{userDetails.user_id || 'N/A'}</span>
                      </div>
                      <div className="detail-item">
                        <label>Name:</label>
                        <span>{userDetails.name || 'N/A'}</span>
                      </div>
                      <div className="detail-item">
                        <label>Email:</label>
                        <span>{userDetails.email || 'N/A'}</span>
                      </div>
                      <div className="detail-item">
                        <label>Phone:</label>
                        <span>{userDetails.phone || 'N/A'}</span>
                      </div>
                      <div className="detail-item">
                        <label>Subscription:</label>
                        <span className={`subscription-badge subscription-${userDetails.subscription || 'free'}`}>
                          {userDetails.subscription || 'Free'}
                        </span>
                      </div>
                      <div className="detail-item">
                        <label>Joined:</label>
                        <span>{userDetails.created_at ? new Date(userDetails.created_at).toLocaleDateString() : 'N/A'}</span>
                      </div>
                    </div>
                  </div>

                  {/* Statistics */}
                  <div className="details-section">
                    <h3>Statistics</h3>
                    <div className="stats-grid">
                      <div className="stat-card">
                        <div className="stat-value">{userDetails.statistics.total_swaps}</div>
                        <div className="stat-label">Total Swaps</div>
                      </div>
                      <div className="stat-card">
                        <div className="stat-value">
                          GHS {(userDetails.statistics?.total_spent || 0).toFixed(2)}
                        </div>
                        <div className="stat-label">Total Spent</div>
                      </div>
                      <div className="stat-card">
                        <div className="stat-value">
                          GHS {(userDetails.wallet_balance || 0).toFixed(2)}
                        </div>
                        <div className="stat-label">Wallet Balance</div>
                      </div>
                      <div className="stat-card">
                        <div className="stat-value">{userDetails.statistics.bikes_count}</div>
                        <div className="stat-label">Bikes Owned</div>
                      </div>
                    </div>
                  </div>

                  {/* Bikes */}
                  {userDetails.bikes && userDetails.bikes.length > 0 && (
                    <div className="details-section">
                      <h3>Bikes</h3>
                      <div className="bikes-list">
                        {userDetails.bikes.map((bike: { bike_id: string; model: string; status: string }) => (
                          <div key={bike.bike_id} className="bike-item">
                            <div className="bike-id">{bike.bike_id}</div>
                            <div className="bike-model">{bike.model}</div>
                            <span className={`status-badge status-${bike.status}`}>
                              {bike.status}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Wallet Adjustment Modal */}
      {showWalletModal && (
        <div className="modal-overlay" onClick={closeWalletModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Adjust Wallet Balance</h2>
              <button className="modal-close" onClick={closeWalletModal}>
                ×
              </button>
            </div>
            <form onSubmit={handleWalletAdjustment}>
              <div className="form-group">
                <label htmlFor="adjustment">Adjustment Amount (GHS) *</label>
                <input
                  type="number"
                  id="adjustment"
                  name="adjustment"
                  step="0.01"
                  required
                  placeholder="Enter amount (positive to add, negative to deduct)"
                />
                <small>
                  Use positive values to add funds, negative values to deduct funds
                </small>
              </div>
              <div className="form-group">
                <label htmlFor="reason">Reason *</label>
                <textarea
                  id="reason"
                  name="reason"
                  rows={3}
                  required
                  placeholder="Enter reason for adjustment"
                />
              </div>
              <div className="modal-actions">
                <button type="button" onClick={closeWalletModal} className="btn-secondary">
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  disabled={walletMutation.isPending}
                >
                  {walletMutation.isPending ? 'Adjusting...' : 'Adjust Balance'}
                </button>
              </div>
              {walletMutation.error && (
                <div className="error-message">
                  Error: {walletMutation.error.message}
                </div>
              )}
            </form>
          </div>
        </div>
      )}

      {/* Create User Modal */}
      {showCreateModal && (
        <div className="modal-overlay" onClick={() => setShowCreateModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Add New User</h2>
              <button className="modal-close" onClick={() => setShowCreateModal(false)}>
                ×
              </button>
            </div>
            <form onSubmit={handleCreateUser}>
              <div className="form-group">
                <label htmlFor="name">Full Name *</label>
                <input
                  type="text"
                  id="name"
                  name="name"
                  required
                  placeholder="e.g., John Doe"
                />
              </div>
              <div className="form-group">
                <label htmlFor="email">Email *</label>
                <input
                  type="email"
                  id="email"
                  name="email"
                  required
                  placeholder="e.g., john.doe@example.com"
                />
              </div>
              <div className="form-group">
                <label htmlFor="phone">Phone Number *</label>
                <input
                  type="tel"
                  id="phone"
                  name="phone"
                  required
                  placeholder="+233XXXXXXXXX"
                  pattern="\+233[0-9]{9}"
                />
                <small>Format: +233XXXXXXXXX (Ghana)</small>
              </div>
              <div className="form-group">
                <label htmlFor="subscription">Subscription Tier *</label>
                <select id="subscription" name="subscription" required defaultValue="basic">
                  <option value="basic">Basic</option>
                  <option value="premium">Premium</option>
                </select>
                <small>Initial wallet balance will be GHS 0.00</small>
              </div>
              <div style={{ 
                padding: '12px', 
                backgroundColor: '#fff3cd', 
                borderRadius: '6px', 
                marginBottom: '16px',
                fontSize: '14px',
                color: '#856404',
                border: '1px solid #ffeaa7'
              }}>
                ℹ️ <strong>Note:</strong> A temporary password will be generated and shown after creation. The user must change it on first login.
                <br /><br />
                The user will appear in this list after they complete their first login.
              </div>
              <div className="modal-actions">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="btn-secondary"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  disabled={createMutation.isPending}
                >
                  {createMutation.isPending ? 'Creating...' : 'Create User'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Message Modal */}
      {messageModal && (
        <MessageModal
          type={messageModal.type}
          message={messageModal.message}
          onClose={() => setMessageModal(null)}
        />
      )}
    </div>
  )
}
