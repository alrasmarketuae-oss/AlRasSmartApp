import { getAuthUser } from './authStorage'

export const PERMISSIONS = {
  dashboardView: 'dashboard.view',
  usersView: 'users.view',
  usersManage: 'users.manage',
  usersProfileEdits: 'users.profile_edits',
  productsView: 'products.view',
  productsManage: 'products.manage',
  productsAdEdits: 'products.ad_edits',
  ordersView: 'orders.view',
  ordersManage: 'orders.manage',
  ordersReqsOffers: 'orders.reqs_offers',
  categoriesManage: 'categories.manage',
  bannersManage: 'banners.manage',
  shippingView: 'shipping.view',
  shippingManage: 'shipping.manage',
  chatAccess: 'chat.access',
  notificationsView: 'notifications.view',
  notificationsSend: 'notifications.send',
  settingsView: 'settings.view',
  settingsManage: 'settings.manage',
  searchAccess: 'search.access',
  auditView: 'audit.view',
  monitoringView: 'monitoring.view',
} as const

export type PermissionKey = (typeof PERMISSIONS)[keyof typeof PERMISSIONS]

export function isSuperAdmin(roleName: string | undefined | null): boolean {
  return roleName?.trim().toLowerCase() === 'admin'
}

export function isEmployee(roleName: string | undefined | null): boolean {
  return roleName?.trim().toLowerCase() === 'employee'
}

export function canAccessDashboard(roleName: string, permissions: string[] = []): boolean {
  if (isSuperAdmin(roleName)) return true
  if (isEmployee(roleName)) return permissions.length > 0
  return false
}

export function getStoredPermissions(): string[] {
  const user = getAuthUser()
  return user?.permissions ?? []
}

export function hasPermission(permission: PermissionKey): boolean {
  const user = getAuthUser()
  if (!user) return false
  if (isSuperAdmin(user.roleName)) return true
  return (user.permissions ?? []).includes(permission)
}

export function getDefaultRoute(): string {
  const checks: Array<{ permission: PermissionKey; path: string }> = [
    { permission: PERMISSIONS.dashboardView, path: '/' },
    { permission: PERMISSIONS.chatAccess, path: '/chat' },
    { permission: PERMISSIONS.ordersView, path: '/orders/all' },
    { permission: PERMISSIONS.ordersReqsOffers, path: '/reqs-offers' },
    { permission: PERMISSIONS.productsView, path: '/ads' },
    { permission: PERMISSIONS.productsView, path: '/image-search' },
    { permission: PERMISSIONS.productsAdEdits, path: '/ads?adEdits=1' },
    { permission: PERMISSIONS.usersView, path: '/users' },
    { permission: PERMISSIONS.usersProfileEdits, path: '/users?profileEdits=1' },
    { permission: PERMISSIONS.auditView, path: '/audit-logs' },
    { permission: PERMISSIONS.monitoringView, path: '/monitoring' },
    { permission: PERMISSIONS.searchAccess, path: '/missed-searches' },
    { permission: PERMISSIONS.notificationsView, path: '/notifications' },
    { permission: PERMISSIONS.settingsView, path: '/settings' },
  ]

  for (const item of checks) {
    if (hasPermission(item.permission)) return item.path
  }

  return '/login'
}
