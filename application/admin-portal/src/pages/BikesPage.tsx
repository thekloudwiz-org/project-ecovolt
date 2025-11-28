import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getBikes, createBike, updateBike, assignBike, unassignBike, getUsers } from '../services/api'
import type { Bike, BikeFormData } from '../types'
import MessageModal from '../components/MessageModal'
import './BikesPage.css'

export default function BikesPage() {
  const queryClient = useQueryClient()
  const [page, setPage] = useState(1)
  const [showModal, setShowModal] = useState(false)
  const [showAssignModal, setShowAssignModal] = useState(false)
  const [editingBike, setEditingBike] = useState<Bike | null>(null)
  const [selectedBike, setSelectedBike] = useState<Bike | null>(null)
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [assignmentFilter, setAssignmentFilter] = useState<string>('all')
  const [messageModal, setMessageModal] = useState<{ type: 'success' | 'error'; message: string } | null>(null)

  // Fetch bikes
  const { data, isLoading, error } = useQuery({
    queryKey: ['bikes', page],
    queryFn: () => getBikes(page, 20),
  })

  // Fetch users for assignment dropdown
  const { data: usersData } = useQuery({
    queryKey: ['users'],
    queryFn: () => getUsers(1, 1000), // Fetch all users
  })

  // Create bike mutation
  const createMutation = useMutation({
    mutationFn: createBike,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bikes'] })
      setShowModal(false)
      setEditingBike(null)
    },
  })

  // Update bike mutation
  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<BikeFormData> }) =>
      updateBike(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bikes'] })
      setShowModal(false)
      setEditingBike(null)
    },
  })

  // Assign bike mutation
  const assignMutation = useMutation({
    mutationFn: ({ bikeId, userId }: { bikeId: string; userId: string }) =>
      assignBike(bikeId, userId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bikes'] })
      queryClient.invalidateQueries({ queryKey: ['users'] })
      setShowAssignModal(false)
      setSelectedBike(null)
      setMessageModal({
        type: 'success',
        message: 'Bike has been successfully assigned to the user!'
      })
    },
    onError: (error: any) => {
      setShowAssignModal(false)
      setSelectedBike(null)
      // Check if it's a "bike already assigned" error
      const errorMessage = error.message || 'Failed to assign bike. Please try again.'
      setMessageModal({
        type: 'error',
        message: errorMessage
      })
    },
  })

  // Unassign bike mutation
  const unassignMutation = useMutation({
    mutationFn: (bikeId: string) => unassignBike(bikeId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['bikes'] })
      setMessageModal({
        type: 'success',
        message: 'Bike has been successfully unassigned!'
      })
    },
    onError: (error: Error) => {
      setMessageModal({
        type: 'error',
        message: error.message || 'Failed to unassign bike. Please try again.'
      })
    },
  })

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    const data: any = {
      bike_id: formData.get('bike_id') as string,
      model: formData.get('model') as string,
      battery_id: formData.get('battery_id') as string || undefined,
    }

    // Include status when editing
    if (editingBike) {
      data.status = formData.get('status') as string
      updateMutation.mutate({ id: editingBike.bike_id, data })
    } else {
      createMutation.mutate(data)
    }
  }

  const handleAssign = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    const userId = formData.get('user_id') as string

    if (selectedBike && userId) {
      assignMutation.mutate({ bikeId: selectedBike.bike_id, userId })
    }
  }

  const openEditModal = (bike: Bike) => {
    setEditingBike(bike)
    setShowModal(true)
  }

  const openAssignModal = (bike: Bike) => {
    setSelectedBike(bike)
    setShowAssignModal(true)
  }

  const handleUnassign = (bike: Bike) => {
    if (confirm(`Are you sure you want to unassign ${bike.bike_id}?`)) {
      unassignMutation.mutate(bike.bike_id)
    }
  }

  const closeModal = () => {
    setShowModal(false)
    setEditingBike(null)
  }

  const closeAssignModal = () => {
    setShowAssignModal(false)
    setSelectedBike(null)
  }

  // Filter bikes
  const filteredBikes = data?.bikes?.filter((bike) => {
    const statusMatch = statusFilter === 'all' || bike.status === statusFilter
    const assignmentMatch =
      assignmentFilter === 'all' ||
      (assignmentFilter === 'assigned' && bike.user_id) ||
      (assignmentFilter === 'unassigned' && !bike.user_id)
    return statusMatch && assignmentMatch
  })

  if (isLoading) {
    return <div className="loading">Loading bikes...</div>
  }

  if (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    return <div className="error">Error loading bikes: {errorMessage || 'Unknown error occurred'}</div>
  }

  return (
    <div className="bikes-page">
      <div className="page-header">
        <h1 className="page-title">Bike Fleet Management</h1>
        <button className="btn-primary" onClick={() => setShowModal(true)}>
          Register New Bike
        </button>
      </div>

      {/* Filters */}
      <div className="filters">
        <div className="filter-group">
          <label>Status:</label>
          <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)}>
            <option value="all">All</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
            <option value="maintenance">Maintenance</option>
          </select>
        </div>
        <div className="filter-group">
          <label>Assignment:</label>
          <select
            value={assignmentFilter}
            onChange={(e) => setAssignmentFilter(e.target.value)}
          >
            <option value="all">All</option>
            <option value="assigned">Assigned</option>
            <option value="unassigned">Unassigned</option>
          </select>
        </div>
      </div>

      {/* Bikes Table */}
      <div className="table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>Bike ID</th>
              <th>Model</th>
              <th>Status</th>
              <th>Battery Level</th>
              <th>Assigned To</th>
              <th>Odometer (km)</th>
              <th>Last Swap</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredBikes?.map((bike) => (
              <tr key={bike.bike_id}>
                <td>{bike.bike_id}</td>
                <td>{bike.model}</td>
                <td>
                  <span className={`status-badge status-${bike.status}`}>
                    {bike.status}
                  </span>
                </td>
                <td>
                  {bike.battery_level !== null ? (
                    <div className="battery-indicator">
                      <div
                        className="battery-bar"
                        style={{
                          width: `${bike.battery_level}%`,
                          backgroundColor:
                            bike.battery_level > 50
                              ? '#4caf50'
                              : bike.battery_level > 20
                              ? '#ff9800'
                              : '#f44336',
                        }}
                      />
                      <span>{bike.battery_level}%</span>
                    </div>
                  ) : (
                    'N/A'
                  )}
                </td>
                <td>{bike.user_id || 'Unassigned'}</td>
                <td>{bike.odometer?.toFixed(1) || '0.0'}</td>
                <td>
                  {bike.last_swap
                    ? new Date(bike.last_swap).toLocaleDateString()
                    : 'Never'}
                </td>
                <td>
                  <div className="action-buttons">
                    <button className="btn-icon" onClick={() => openEditModal(bike)}>
                      Edit
                    </button>
                    {bike.status === 'active' && !bike.user_id && (
                      <button className="btn-icon" onClick={() => openAssignModal(bike)}>
                        Assign
                      </button>
                    )}
                    {bike.status === 'active' && bike.user_id && (
                      <button className="btn-icon" onClick={() => handleUnassign(bike)}>
                        Unassign
                      </button>
                    )}
                    {bike.status !== 'active' && (
                      <button
                        className="btn-icon"
                        disabled
                        style={{ opacity: 0.5, cursor: 'not-allowed' }}
                        title={`Cannot assign ${bike.status} bike`}
                      >
                        {bike.user_id ? 'Unassign' : 'Assign'}
                      </button>
                    )}
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
            {data.pagination.total_count} total bikes)
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

      {/* Create/Edit Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={closeModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>{editingBike ? 'Edit Bike' : 'Register New Bike'}</h2>
              <button className="modal-close" onClick={closeModal}>
                ×
              </button>
            </div>
            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label htmlFor="bike_id">Bike ID *</label>
                <input
                  type="text"
                  id="bike_id"
                  name="bike_id"
                  defaultValue={editingBike?.bike_id}
                  required
                  disabled={!!editingBike}
                  placeholder="e.g., BIKE-001"
                />
              </div>
              <div className="form-group">
                <label htmlFor="model">Model *</label>
                <input
                  type="text"
                  id="model"
                  name="model"
                  defaultValue={editingBike?.model}
                  required
                  placeholder="e.g., EcoVolt Pro 2024"
                />
              </div>
              <div className="form-group">
                <label htmlFor="battery_id">Battery ID</label>
                <input
                  type="text"
                  id="battery_id"
                  name="battery_id"
                  defaultValue={editingBike?.battery_id || ''}
                  placeholder="e.g., BAT-001"
                />
              </div>
              {editingBike && (
                <div className="form-group">
                  <label htmlFor="status">Status</label>
                  <select id="status" name="status" defaultValue={editingBike.status}>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="maintenance">Maintenance</option>
                  </select>
                </div>
              )}
              <div className="modal-actions">
                <button type="button" onClick={closeModal} className="btn-secondary">
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  disabled={createMutation.isPending || updateMutation.isPending}
                >
                  {createMutation.isPending || updateMutation.isPending
                    ? 'Saving...'
                    : editingBike
                    ? 'Update Bike'
                    : 'Register Bike'}
                </button>
              </div>
              {(createMutation.error || updateMutation.error) && (
                <div className="error-message">
                  Error: {(createMutation.error || updateMutation.error)?.message}
                </div>
              )}
            </form>
          </div>
        </div>
      )}

      {/* Assign Modal */}
      {showAssignModal && selectedBike && (
        <div className="modal-overlay" onClick={closeAssignModal}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Assign Bike: {selectedBike.bike_id}</h2>
              <button className="modal-close" onClick={closeAssignModal}>
                ×
              </button>
            </div>
            <form onSubmit={handleAssign}>
              <div className="form-group">
                <label htmlFor="user_id">Select User *</label>
                <select
                  id="user_id"
                  name="user_id"
                  required
                  style={{ width: '100%', padding: '8px', fontSize: '14px' }}
                >
                  <option value="">-- Select a user --</option>
                  {usersData?.users?.map((user) => (
                    <option key={user.user_id} value={user.user_id}>
                      {user.email} - {user.name || 'No name'}
                    </option>
                  ))}
                </select>
                <small style={{ color: '#666', marginTop: '8px', display: 'block' }}>
                  Users can own multiple bikes. Each bike can only be assigned to one user.
                </small>
              </div>
              <div className="modal-actions">
                <button
                  type="button"
                  onClick={closeAssignModal}
                  className="btn-secondary"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  disabled={assignMutation.isPending}
                >
                  {assignMutation.isPending ? 'Assigning...' : 'Assign Bike'}
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
