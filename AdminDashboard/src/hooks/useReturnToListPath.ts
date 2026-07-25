import { useLocation } from 'react-router-dom'
import { resolveReturnToListPath } from '../utils/listPageParams'

export function useReturnToListPath(fallbackPath: string): string {
  const location = useLocation()
  return resolveReturnToListPath(fallbackPath, location.state)
}
