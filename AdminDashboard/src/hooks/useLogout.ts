import { useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { clearAuthSession } from '../lib/authStorage'

export function useLogout() {
  const navigate = useNavigate()

  return useCallback(() => {
    clearAuthSession()
    navigate('/login', { replace: true })
  }, [navigate])
}
