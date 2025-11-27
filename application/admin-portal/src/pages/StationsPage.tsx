import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getStations, createStation, updateStation, deleteStation } from '../services/api'
import type { Station } from '../types'
import './StationsPage.css'

export default function StationsPage() {
  const queryClient = useQueryClient()
  const [page, setPage] = useState(1)
  const [showModal, setShowModal] = useState(false)
  const [editingStation, setEditingStation] = useState<Station | null>(null)
  const [searchTerm, setSearchTerm] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['stations', page],
    queryFn: () => getStations(page, 20),
  })

  const createMutation = useMutation({
    mutationFn: createStation,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stations'] })
      setShowModal(false)
      setEditingStation(null)
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Station> }) => updateStation(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stations'] })
      setShowModal(false)
      setEditingStation(null)
    },
  })

  const deleteMutation = useMutation({
    mutationFn: deleteStation,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stations'] })
    },
  })

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)

    // Parse operating hours from "HH:MM-HH:MM" format to object
    const operatingHoursStr = formData.get('operatingHours') as string
    let operating_hours: { open: string; close: string } | string = operatingHoursStr

    if (operatingHoursStr && operatingHoursStr.includes('-')) {
      const [open, close] = operatingHoursStr.split('-').map(s => s.trim())
      operating_hours = { open, close }
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
      latitude: parseFloat(formData.get('latitude') as string),
      longitude: parseFloat(formData.get('longitude') as string),
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

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this station?')) {
      deleteMutation.mutate(id)
    }
  }

  const filteredStations = data?.stations.filter((station: Station) =>
    station.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    station.city.toLowerCase().includes(searchTerm.toLowerCase())
  ) || []

  return (
    <div className="stations-page">
      <div className="page-header">
        <h1 className="page-title">Station Management</h1>
        <button className="btn-primary" onClick={() => { setEditingStation(null); setShowModal(true) }}>
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
                        <span className={`status-badge status-${station.status}`}>
                          {station.status}
                        </span>
                      </td>
                      <td>
                        <button className="btn-icon" onClick={() => { setEditingStation(station); setShowModal(true) }}>
                          Edit
                        </button>
                        <button className="btn-icon" onClick={() => handleDelete(station.station_id)}>
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
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h2>{editingStation ? 'Edit Station' : 'Add Station'}</h2>
            <form onSubmit={handleSubmit}>
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
                  <label>Latitude</label>
                  <input name="latitude" type="number" step="0.000001" defaultValue={editingStation?.latitude} required />
                </div>
                <div className="form-group">
                  <label>Longitude</label>
                  <input name="longitude" type="number" step="0.000001" defaultValue={editingStation?.longitude} required />
                </div>
                <div className="form-group">
                  <label>Capacity</label>
                  <input name="capacity" type="number" defaultValue={editingStation?.total_capacity} required />
                </div>
                <div className="form-group">
                  <label>Operating Hours</label>
                  <input
                    name="operatingHours"
                    placeholder="e.g., 06:00 - 22:00 or 24/7"
                    defaultValue={
                      editingStation?.operating_hours
                        ? typeof editingStation.operating_hours === 'string'
                          ? editingStation.operating_hours
                          : `${editingStation.operating_hours.open} - ${editingStation.operating_hours.close}`
                        : '06:00 - 22:00'
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
                <button type="button" className="btn-secondary" onClick={() => setShowModal(false)}>
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
    </div>
  )
}
