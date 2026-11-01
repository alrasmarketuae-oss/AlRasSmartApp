import { useQuery } from '@tanstack/react-query'
import { useAuth } from '../auth/AuthProvider'
import { fetchUnreadNotificationsCount } from './notificationsApi'

export const unreadNotificationsKey = (userId?: string) => ['notifications-unread', userId ?? '']

/** Header bell badge: there is no end-user notifications hub, so poll like the app refreshes on focus. */
export function useUnreadNotifications() {
  const { isAuthenticated, session } = useAuth()
  const { data } = useQuery({
    queryKey: unreadNotificationsKey(session?.id),
    queryFn: fetchUnreadNotificationsCount,
    enabled: isAuthenticated,
    refetchInterval: 60_000,
    refetchOnWindowFocus: true,
  })
  return data ?? 0
}
