interface MessageModalProps {
  type: 'success' | 'error'
  message: string
  onClose: () => void
}

export default function MessageModal({ type, message, onClose }: MessageModalProps) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()} style={{ maxWidth: '500px' }}>
        <div style={{ textAlign: 'center', padding: '20px' }}>
          <div style={{ fontSize: '48px', marginBottom: '16px' }}>
            {type === 'success' ? '✅' : '❌'}
          </div>
          <h2 style={{
            marginBottom: '12px',
            color: type === 'success' ? '#4caf50' : '#f44336',
            fontSize: '24px'
          }}>
            {type === 'success' ? 'Success!' : 'Error'}
          </h2>
          <p style={{
            fontSize: '16px',
            color: '#666',
            lineHeight: '1.5',
            marginBottom: '24px',
            whiteSpace: 'pre-line',
            textAlign: 'center'
          }}>
            {message}
          </p>
          <button
            className="btn-primary"
            onClick={onClose}
            style={{ minWidth: '120px' }}
          >
            OK
          </button>
        </div>
      </div>
    </div>
  )
}
