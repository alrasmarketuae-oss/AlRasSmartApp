export type NotificationAudience =
  | 'All'
  | 'Suppliers'
  | 'Clients'
  | 'Shipping'
  | 'SingleUser'

export type AdminPushNotificationItem = {
  id: string
  title: string
  body: string
  audience: string
  targetUserId?: string | null
  targetUserName?: string | null
  createdAt: string
  sentCount: number
  failedCount: number
  type?: string | null
}

export type AdminNotificationsResponse = {
  page: number
  pageSize: number
  total: number
  items: AdminPushNotificationItem[]
}

export type SendAdminNotificationPayload = {
  audience: NotificationAudience
  title: string
  body: string
  titleAr?: string
  bodyAr?: string
  type?: string
  targetUserId?: string
}

export type AdminNotificationsFilters = {
  page?: number
  pageSize?: number
  audience?: NotificationAudience | ''
}
