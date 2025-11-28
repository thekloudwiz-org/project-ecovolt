import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getStations, createStation, updateStation, deleteStation } from '../services/api'
import type { Station } from '../types'
import MapPicker from '../components/MapPicker'
import MessageModal from '../components/MessageModal'
import './StationsPage.css'

export default function StationsPage() {
  const queryClient = useQueryClient()
  const [page, setPage] = useState(1)
  const [showModal, setShowModal] = useState(false)
  const [editingStation, setEditingStation] = useState<Station | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedLat, setSelectedLat] = useState<number | undefined>()
  const [selectedLng, setSelectedLng] = useState<number | undefined>()
  const [messageModal, setMessageModal] = useState<{ type: 'success' | 'error'; message: string } | null>(null)

  const { data, isLoading } = useQuery({
    queryKey: ['stations', page],
    queryFn: () => getStations(page, 20),
  })

  const createMutation = useMutation({
    mutationFn: createStation,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stations'] })
      handleModalClose()
      setMessageModal({
        type: 'success',
        message: 'Station created successfully!'
      })
    },
    onError: (error: Error) => {
      handleModalClose()
      setMessageModal({
        type: 'error',
        message: `Failed to create station: ${error.message}`
      })
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Station> }) => updateStation(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stations'] })
      handleModalClose()
      setMessageModal({
        type: 'success',
        message: 'Station updated successfully!'
      })
    },
    onError: (error: Error) => {
      handleModalClose()
      setMessageModal({
        type: 'error',
        message: `Failed to update station: ${error.message}`
      })
    },
  })

  const deleteMutation = useMutation({
    mutationFn: deleteStation,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stations'] })
      setMessageModal({
        type: 'success',
        message: 'Station deleted successfully!'
      })
    },
    onError: (error: Error) => {
      setMessageModal({
        type: 'error',
        message: `Failed to delete station: ${error.message}`
      })
    },
  })

  const toggleStatusMutation = useMutation({
    mutationFn: ({ id, currentStatus }: { id: string; currentStatus: string }) => {
      const newStatus = currentStatus === 'active' ? 'inactive' : 'active'
      return updateStation(id, { status: newStatus })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stations'] })
    },
    onError: (error: Error) => {
      setMessageModal({
        type: 'error',
        message: `Failed to update station status: ${error.message}`
      })
    },
  })

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)

    // Use selected coordinates from map
    if (!selectedLat || !selectedLng) {
      alert('Please select a location on the map')
      return
    }

    // Parse operating hours from separate time inputs
    const openTime = formData.get('openTime') as string
    const closeTime = formData.get('closeTime') as string
    const operating_hours = {
      open: openTime,
      close: closeTime
    }

    // Parse pricing
    const currency = formData.get('currency') as string || 'GHS'
    const swapFee = parseFloat(formData.get('swapFee') as string) || 5.0
    const pricing = {
      currency,
      swap_fee: swapFee
    }

    const data = {
      name: formData.get('name') as string,
      address: formData.get('address') as string,
      city: formData.get('city') as string,
      latitude: selectedLat,
      longitude: selectedLng,
      total_capacity: parseInt(formData.get('capacity') as string),
      operating_hours,
      pricing,
      status: formData.get('status') as 'active' | 'inactive' | 'maintenance',
    }

    if (editingStation) {
      updateMutation.mutate({ id: editingStation.station_id, data })
    } else {
      createMutation.mutate(data)
    }
  }

  const handleModalOpen = (station: Station | null) => {
    setEditingStation(station)
    setSelectedLat(station?.latitude)
    setSelectedLng(station?.longitude)
    setShowModal(true)
  }

  const handleModalClose = () => {
    setShowModal(false)
    setEditingStation(null)
    setSelectedLat(undefined)
    setSelectedLng(undefined)
  }

  const handleDelete = (id: string, name: string) => {
    if (confirm(`Are you sure you want to permanently delete "${name}"? This action cannot be undone.`)) {
      deleteMutation.mutate(id)
    }
  }

  const handleToggleStatus = (id: string, currentStatus: string) => {
    toggleStatusMutation.mutate({ id, currentStatus })
  }

  const filteredStations = data?.stations.filter((station: Station) =>
    station.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    station.city.toLowerCase().includes(searchTerm.toLowerCase())
  ) || []

  return (
    <div className="stations-page">
      <div className="page-header">
        <h1 className="page-title">Station Management</h1>
        <button className="btn-primary" onClick={() => handleModalOpen(null)}>
          + Add Station
        </button>
      </div>

      <div className="search-bar">
        <input
          type="text"
          placeholder="Search stations..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="search-input"
        />
      </div>

      {isLoading ? (
        <div className="loading">Loading stations...</div>
      ) : (
        <>
          <div className="table-card">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>City</th>
                  <th>Capacity</th>
                  <th>Address</th>
                  <th>Operating Hours</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredStations.map((station: Station) => {
                  // Format operating hours for display
                  const formatOperatingHours = (hours: any) => {
                    if (!hours) return '24/7'
                    if (typeof hours === 'string') return hours
                    if (typeof hours === 'object' && hours.open && hours.close) {
                      return `${hours.open} - ${hours.close}`
                    }
                    return '24/7'
                  }

                  return (
                    <tr key={station.station_id}>
                      <td>{station.name}</td>
                      <td>{station.city}</td>
                      <td>{station.total_capacity}</td>
                      <td>{station.address}</td>
                      <td>{formatOperatingHours(station.operating_hours)}</td>
                      <td>
                        <button
                          onClick={() => handleToggleStatus(station.station_id, station.status)}
                          disabled={toggleStatusMutation.isPending}
                          style={{
                            padding: '6px 16px',
                            border: 'none',
                            borderRadius: '20px',
                            cursor: toggleStatusMutation.isPending ? 'not-allowed' : 'pointer',
                            fontSize: '12px',
                            fontWeight: '500',
                            transition: 'all 0.2s',
                            backgroundColor: station.status === 'active' ? '#4caf50' : '#9e9e9e',
                            color: 'white'
                          }}
                          onMouseEnter={(e) => {
                            if (!toggleStatusMutation.isPending) {
                              e.currentTarget.style.opacity = '0.8'
                            }
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.opacity = '1'
                          }}
                        >
                          {station.status === 'active' ? '✓ Active' : '○ Inactive'}
                        </button>
                      </td>
                      <td>
                        <button className="btn-icon" onClick={() => handleModalOpen(station)}>
                          Edit
                        </button>
                        <button 
                          className="btn-icon" 
                          onClick={() => handleDelete(station.station_id, station.name)}
                          style={{ 
                            color: '#f44336',
                            borderColor: '#f44336'
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.backgroundColor = '#ffebee'
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.backgroundColor = 'white'
                          }}
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          <div className="pagination">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1}>
              Previous
            </button>
            <span>Page {page} of {data?.pagination?.total_pages || 1}</span>
            <button onClick={() => setPage(p => p + 1)} disabled={page >= (data?.pagination?.total_pages || 1)}>
              Next
            </button>
          </div>
        </>
      )}

      {showModal && (
        <div className="modal-overlay" onClick={handleModalClose}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h2>{editingStation ? 'Edit Station' : 'Add Station'}</h2>
            <form onSubmit={handleSubmit}>
              <MapPicker
                latitude={selectedLat}
                longitude={selectedLng}
                onLocationSelect={(lat, lng) => {
                  setSelectedLat(lat)
                  setSelectedLng(lng)
                }}
              />
              {selectedLat && selectedLng && (
                <p style={{ marginBottom: '20px', color: '#333', fontSize: '14px' }}>
                  📍 Selected: {selectedLat.toFixed(6)}, {selectedLng.toFixed(6)}
                </p>
              )}
              <div className="form-grid">
                <div className="form-group">
                  <label>Name</label>
                  <input name="name" defaultValue={editingStation?.name} required />
                </div>
                <div className="form-group">
                  <label>City</label>
                  <input name="city" defaultValue={editingStation?.city} required />
                </div>
                <div className="form-group">
                  <label>Address</label>
                  <input name="address" defaultValue={editingStation?.address} required />
                </div>
                <div className="form-group">
                  <label>Capacity</label>
                  <input name="capacity" type="number" defaultValue={editingStation?.total_capacity} required />
                </div>
                <div className="form-group">
                  <label>Opening Time</label>
                  <input
                    name="openTime"
                    type="time"
                    defaultValue={
                      editingStation?.operating_hours
                        ? typeof editingStation.operating_hours === 'string'
                          ? '06:00'
                          : editingStation.operating_hours.open
                        : '06:00'
                    }
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Closing Time</label>
                  <input
                    name="closeTime"
                    type="time"
                    defaultValue={
                      editingStation?.operating_hours
                        ? typeof editingStation.operating_hours === 'string'
                          ? '22:00'
                          : editingStation.operating_hours.close
                        : '22:00'
                    }
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Status</label>
                  <select name="status" defaultValue={editingStation?.status || 'active'}>
                    <option value="active">Active</option>
                    <option value="inactive">Inactive</option>
                    <option value="maintenance">Maintenance</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Currency</label>
                  <input
                    name="currency"
                    defaultValue={
                      editingStation?.pricing
                        ? typeof editingStation.pricing === 'string'
                          ? 'GHS'
                          : editingStation.pricing.currency
                        : 'GHS'
                    }
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Swap Fee</label>
                  <input
                    name="swapFee"
                    type="number"
                    step="0.01"
                    defaultValue={
                      editingStation?.pricing
                        ? typeof editingStation.pricing === 'string'
                          ? '5.0'
                          : editingStation.pricing.swap_fee
                        : '5.0'
                    }
                    required
                  />
                </div>
              </div>
              <div className="modal-actions">
                <button type="button" className="btn-secondary" onClick={handleModalClose}>
                  Cancel
                </button>
                <button type="submit" className="btn-primary">
                  {editingStation ? 'Update' : 'Create'}
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
