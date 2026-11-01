import { useQuery } from '@tanstack/react-query'
import { useAuth } from '../auth/AuthProvider'
import { api } from '../lib/api'

export async function fetchUnreadChatCount(): Promise<number> {
  const data = await api.get<unknown>('/Chat/unread-count')
  if (typeof data === 'number') return data
  if (data && typeof data === 'object') {
    const record = data as Record<string, unknown>
    const value = record.totalUnread ?? record.TotalUnread
    return Number(value) || 0
  }
  return 0
}

export function useUnreadChatCount() {
  const { isAuthenticated, session } = useAuth()
  const { data } = useQuery({
    queryKey: ['chat-unread', session?.id],
    queryFn: fetchUnreadChatCount,
    enabled: isAuthenticated,
    refetchInterval: 30_000,
  })
  return data ?? 0
}
