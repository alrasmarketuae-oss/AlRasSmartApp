import { useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { API_BASE_URL } from '../config/api.js'
import { clearAuthSession, getAuthToken } from '../lib/authStorage'

export function useLogout() {
  const navigate = useNavigate()

  return useCallback(() => {
    const token = getAuthToken()
    if (token) {
      void fetch(`${API_BASE_URL}/api/Auth/clear-fcm-token`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: '{}',
        keepalive: true,
      }).catch(() => undefined)
    }
    clearAuthSession()
    navigate('/login', { replace: true })
  }, [navigate])
}
