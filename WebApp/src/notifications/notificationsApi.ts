import { api } from '../lib/api'

export const NOTIFICATIONS_PAGE_SIZE = 20

export type AppNotification = {
  id: string
  title: string
  body: string
  typeName: string
  routeName: string
  routeId: string
  referenceId: string
  isRead: boolean
  createdAt: string
}

export type NotificationsPage = { page: number; totalCount: number; unreadCount: number; items: AppNotification[] }

type Raw = Record<string, unknown>
const text = (value: unknown) => (value === null || value === undefined ? '' : String(value).trim())

function mapNotification(raw: Raw): AppNotification {
  return {
    id: text(raw.id),
    title: text(raw.title),
    body: text(raw.body),
    typeName: text(raw.typeName ?? raw.type),
    routeName: text(raw.routeName),
    routeId: text(raw.routeId),
    referenceId: text(raw.referenceId),
    isRead: raw.isRead === true,
    createdAt: text(raw.createdAt),
  }
}

export async function fetchNotifications(page: number, signal?: AbortSignal): Promise<NotificationsPage> {
  const data = await api.get<Raw>('/Notifications/mine', { query: { page, pageSize: NOTIFICATIONS_PAGE_SIZE }, signal })
  const items = Array.isArray(data?.items) ? (data.items as Raw[]).map(mapNotification) : []
  return { page: Number(data?.page) || page, totalCount: Number(data?.totalCount) || 0, unreadCount: Number(data?.unreadCount) || 0, items }
}

export async function fetchUnreadNotificationsCount(): Promise<number> {
  const data = await api.get<unknown>('/Notifications/unread-count')
  if (typeof data === 'number') return data
  return Number((data as Raw | null)?.unreadCount) || 0
}

export const markNotificationRead = (id: string) => api.post<unknown>(`/Notifications/${encodeURIComponent(id)}/read`, {})

export const markAllNotificationsRead = () => api.post<unknown>('/Notifications/read-all', {})

/** `routeName` when present, else the legacy `routeId` (AppNotificationModel.navigationRoute). */
export const navigationRoute = (n: AppNotification) => (n.routeName || n.routeId).toLowerCase()
