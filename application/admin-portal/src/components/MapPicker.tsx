import { useState, useEffect } from 'react'
import { MapContainer, TileLayer, Marker, useMapEvents, useMap } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

// Fix for default marker icon in React-Leaflet
import markerIcon from 'leaflet/dist/images/marker-icon.png'
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png'
import markerShadow from 'leaflet/dist/images/marker-shadow.png'

delete (L.Icon.Default.prototype as any)._getIconUrl
L.Icon.Default.mergeOptions({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
})

interface MapPickerProps {
  latitude?: number
  longitude?: number
  onLocationSelect: (lat: number, lng: number) => void
}

function LocationMarker({ position, onLocationSelect }: { position: L.LatLng | null; onLocationSelect: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      onLocationSelect(e.latlng.lat, e.latlng.lng)
    },
  })

  return position === null ? null : <Marker position={position} />
}

function MapController({ center }: { center: [number, number] }) {
  const map = useMap()

  useEffect(() => {
    map.setView(center, 13)
  }, [center, map])

  return null
}

export default function MapPicker({ latitude, longitude, onLocationSelect }: MapPickerProps) {
  const defaultCenter: [number, number] = [5.6037, -0.1870] // Accra, Ghana
  const initialPosition: [number, number] = latitude && longitude ? [latitude, longitude] : defaultCenter
  const [center, setCenter] = useState<[number, number]>(initialPosition)
  const [position, setPosition] = useState<L.LatLng | null>(
    latitude && longitude ? L.latLng(latitude, longitude) : null
  )
  const [gettingLocation, setGettingLocation] = useState(false)

  useEffect(() => {
    // Set initial position if provided
    if (latitude && longitude) {
      setPosition(L.latLng(latitude, longitude))
    }
  }, [latitude, longitude])

  const handleLocationSelect = (lat: number, lng: number) => {
    setPosition(L.latLng(lat, lng))
    onLocationSelect(lat, lng)
  }

  const handleUseMyLocation = () => {
    if (!navigator.geolocation) {
      alert('Geolocation is not supported by your browser')
      return
    }

    setGettingLocation(true)
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const lat = position.coords.latitude
        const lng = position.coords.longitude
        setCenter([lat, lng])
        handleLocationSelect(lat, lng)
        setGettingLocation(false)
      },
      (error) => {
        console.error('Error getting location:', error)
        alert(`Unable to get your location: ${error.message}`)
        setGettingLocation(false)
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    )
  }

  return (
    <div style={{ marginBottom: '20px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '10px' }}>
        <p style={{ margin: 0, color: '#666', fontSize: '14px' }}>
          Click on the map to select coordinates
        </p>
        <button
          type="button"
          onClick={handleUseMyLocation}
          disabled={gettingLocation}
          style={{
            padding: '8px 16px',
            backgroundColor: gettingLocation ? '#ccc' : '#2563eb',
            color: 'white',
            border: 'none',
            borderRadius: '6px',
            cursor: gettingLocation ? 'not-allowed' : 'pointer',
            fontSize: '14px',
            fontWeight: '500'
          }}
        >
          {gettingLocation ? '📍 Getting location...' : '📍 Use My Location'}
        </button>
      </div>
      <div style={{ height: '400px', width: '100%', borderRadius: '8px', overflow: 'hidden' }}>
        <MapContainer
          center={center}
          zoom={13}
          style={{ height: '100%', width: '100%' }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <MapController center={center} />
          <LocationMarker position={position} onLocationSelect={handleLocationSelect} />
        </MapContainer>
      </div>
    </div>
  )
}
