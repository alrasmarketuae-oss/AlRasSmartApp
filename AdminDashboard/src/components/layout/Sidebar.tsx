import { NavLink, useLocation } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useAdminNotifications } from '../../context/AdminNotificationProvider'
import { useLogout } from '../../hooks/useLogout'
import { getAuthUser } from '../../lib/authStorage'
import { hasPermission, isSuperAdmin, PERMISSIONS, type PermissionKey } from '../../lib/permissions'
import { PROJECT_IMAGES } from '../../constants/projectImages'
import { isSidebarNavActive } from '../../utils/navActive'
import NavBadge from './NavBadge'
import type { AdminNavCounts } from '../../types/adminRealtime'
import {
  IconAds,
  IconCategories,
  IconBanner,
  IconChat,
  IconClose,
  IconGrid,
  IconOrders,
  IconSettings,
  IconShipping,
  IconUsers,
  IconBell,
  IconActivity,
  IconLogout,
} from '../icons'

type CountKey = keyof AdminNavCounts
type BadgeTone = 'red' | 'green' | 'blue' | 'yellow' | 'amber' | 'sky' | 'slate'
type NavAccent = 'ads' | 'orders'

type NavItem = {
  to: string
  labelKey: string
  icon: typeof IconGrid
  countKey?: CountKey
  countKeys?: CountKey[]
  badgeTone?: BadgeTone
  accent?: NavAccent
  permission?: PermissionKey
  anyOf?: PermissionKey[]
  superAdminOnly?: boolean
}

const navItems: NavItem[] = [
  { to: '/', labelKey: 'nav.dashboard', icon: IconGrid, permission: PERMISSIONS.dashboardView },
  { to: '/users', labelKey: 'nav.users', icon: IconUsers, countKey: 'users', badgeTone: 'amber', permission: PERMISSIONS.usersView },
  {
    to: '/ads',
    labelKey: 'nav.ads',
    icon: IconAds,
    countKeys: ['ads', 'requestAds'],
    badgeTone: 'blue',
    accent: 'ads',
    anyOf: [PERMISSIONS.productsView, PERMISSIONS.ordersReqsOffers],
  },
  {
    to: '/orders/all',
    labelKey: 'nav.orders',
    icon: IconOrders,
    countKeys: ['retailOrders', 'bookingOrders', 'offersOrders', 'categoriesOrders', 'offers'],
    badgeTone: 'green',
    accent: 'orders',
    anyOf: [PERMISSIONS.ordersView, PERMISSIONS.ordersReqsOffers],
  },
  { to: '/categories', labelKey: 'nav.categories', icon: IconCategories, permission: PERMISSIONS.categoriesManage },
  { to: '/banners', labelKey: 'nav.banners', icon: IconBanner, permission: PERMISSIONS.bannersManage },
  { to: '/shipping', labelKey: 'nav.shipping', icon: IconShipping, countKey: 'shipping', badgeTone: 'sky', permission: PERMISSIONS.shippingView },
  { to: '/chat', labelKey: 'nav.chat', icon: IconChat, countKey: 'chat', badgeTone: 'red', permission: PERMISSIONS.chatAccess },
  { to: '/ai-conversations', labelKey: 'nav.aiConversations', icon: IconChat, permission: PERMISSIONS.chatAccess },
  {
    to: '/tech-support',
    labelKey: 'nav.techSupport',
    icon: IconBell,
    countKey: 'supportCallbacks',
    badgeTone: 'red',
    permission: PERMISSIONS.chatAccess,
  },
  {
    to: '/user-feedback',
    labelKey: 'nav.userFeedback',
    icon: IconBell,
    countKey: 'userFeedback',
    badgeTone: 'amber',
    permission: PERMISSIONS.chatAccess,
  },
  { to: '/notifications', labelKey: 'nav.notifications', icon: IconBell, permission: PERMISSIONS.notificationsView },
  { to: '/missed-searches', labelKey: 'nav.missedSearches', icon: IconAds, permission: PERMISSIONS.searchAccess },
  { to: '/audit-logs', labelKey: 'nav.auditLogs', icon: IconOrders, permission: PERMISSIONS.auditView },
  { to: '/monitoring', labelKey: 'nav.monitoring', icon: IconActivity, permission: PERMISSIONS.monitoringView },
  { to: '/employees', labelKey: 'nav.employees', icon: IconUsers, superAdminOnly: true },
  { to: '/settings', labelKey: 'nav.settings', icon: IconSettings, permission: PERMISSIONS.settingsView },
  { to: '/users?profileEdits=1', labelKey: 'nav.profileEdits', icon: IconUsers, countKey: 'profileEdits', badgeTone: 'amber', permission: PERMISSIONS.usersProfileEdits },
  { to: '/ads?adEdits=1', labelKey: 'nav.adEdits', icon: IconAds, countKey: 'adEdits', badgeTone: 'blue', permission: PERMISSIONS.productsAdEdits },
]

function canSeeItem(item: NavItem, roleName: string | undefined): boolean {
  if (item.superAdminOnly) return isSuperAdmin(roleName)
  if (item.anyOf?.length) return item.anyOf.some((key) => hasPermission(key))
  if (!item.permission) return true
  return hasPermission(item.permission)
}

function sumCounts(counts: AdminNavCounts, keys: CountKey[]): number {
  return keys.reduce((total, key) => total + (counts[key] ?? 0), 0)
}

type SidebarProps = {
  open: boolean
  onClose: () => void
}

function navLinkClass(active: boolean, accent?: NavAccent) {
  const sizeClass = 'gap-3 rounded-xl px-4 py-3 text-[15px] sm:py-3.5'

  if (accent === 'ads') {
    return {
      linkClass: active
        ? 'keep-white bg-indigo-600 text-white shadow-md shadow-indigo-600/25'
        : 'text-indigo-800 hover:bg-indigo-50 dark:text-indigo-200 dark:hover:bg-indigo-950/40',
      iconClass: active ? 'keep-white text-white' : 'text-indigo-600 dark:text-indigo-400',
      sizeClass,
    }
  }

  if (accent === 'orders') {
    return {
      linkClass: active
        ? 'keep-white bg-emerald-600 text-white shadow-md shadow-emerald-600/25'
        : 'text-emerald-800 hover:bg-emerald-50 dark:text-emerald-200 dark:hover:bg-emerald-950/40',
      iconClass: active ? 'keep-white text-white' : 'text-emerald-600 dark:text-emerald-400',
      sizeClass,
    }
  }

  return {
    linkClass: active
      ? 'keep-white bg-[#1d4ed8] text-white shadow-md shadow-blue-600/20'
      : 'admin-text hover:bg-slate-50 dark:hover:bg-slate-800',
    iconClass: active ? 'keep-white text-white' : 'admin-text-muted',
    sizeClass,
  }
}

export default function Sidebar({ open, onClose }: SidebarProps) {
  const { t, dir } = useAppPreferences()
  const location = useLocation()
  const { navCounts } = useAdminNotifications()
  const logout = useLogout()
  const authUser = getAuthUser()

  const visibleItems = navItems
    .filter((item) => canSeeItem(item, authUser?.roleName))
    .map((item) => {
      const next = { ...item }
      if (next.to === '/ads' && !hasPermission(PERMISSIONS.productsView)) {
        next.to = '/reqs-offers'
      }
      if (next.to === '/orders/all' && !hasPermission(PERMISSIONS.ordersView)) {
        next.to = '/reqs-offers?nav=orders'
      }
      return next
    })

  const slideOff =
    dir === 'rtl'
      ? 'translate-x-full lg:translate-x-0'
      : '-translate-x-full lg:translate-x-0'

  function renderNavItem(item: NavItem) {
    const active = isSidebarNavActive(
      item.to,
      location.pathname,
      location.search,
      location.state,
    )
    const { linkClass, iconClass, sizeClass } = navLinkClass(active, item.accent)
    const Icon = item.icon
    return (
      <NavLink
        key={item.to}
        to={item.to}
        end={item.to === '/'}
        onClick={onClose}
        aria-current={active ? 'page' : undefined}
        className={() =>
          `flex w-full items-center font-semibold transition-colors ${sizeClass} ${linkClass}`
        }
      >
        <Icon className={`h-[22px] w-[22px] shrink-0 ${iconClass}`} />
        <span className="flex min-w-0 flex-1 items-center gap-1.5 text-start">
          {item.countKeys?.length || item.countKey ? (
            <NavBadge
              count={
                item.countKeys?.length
                  ? sumCounts(navCounts, item.countKeys)
                  : navCounts[item.countKey!]
              }
              active={active}
              tone={item.badgeTone}
            />
          ) : null}
          <span className="min-w-0 leading-snug">
            {item.labelKey.startsWith('nav.') ? t(item.labelKey) : item.labelKey}
          </span>
        </span>
      </NavLink>
    )
  }

  return (
    <aside
      className={`admin-sidebar fixed inset-y-0 start-0 z-40 flex h-svh max-h-svh w-[min(280px,85vw)] shrink-0 flex-col overflow-hidden transition-transform duration-300 ease-in-out lg:static lg:z-auto lg:h-full lg:w-[280px] ${
        open ? 'translate-x-0' : slideOff
      }`}
    >
      <div className="admin-border flex shrink-0 items-center gap-3 border-b px-4 py-5 sm:px-6">
        <img
          src={PROJECT_IMAGES.logo}
          alt={t('appName')}
          className="h-11 w-11 shrink-0 object-contain sm:h-12 sm:w-12"
        />
        <span className="brand-gradient-text flex-1 text-lg font-extrabold tracking-tight sm:text-xl">
          {t('appName')}
        </span>
        <button
          type="button"
          onClick={onClose}
          className="admin-text-muted flex h-10 w-10 shrink-0 items-center justify-center rounded-xl transition hover:bg-slate-100 lg:hidden dark:hover:bg-slate-800"
          aria-label={t('closeMenu')}
        >
          <IconClose className="h-5 w-5" />
        </button>
      </div>

      <nav className="flex min-h-0 flex-1 flex-col gap-1.5 overflow-y-auto px-3 py-4 sm:px-4 sm:py-5">
        {visibleItems.map((item) => renderNavItem(item))}
      </nav>

      <div className="admin-border shrink-0 border-t px-3 py-4 sm:px-4">
        <button
          type="button"
          onClick={() => {
            onClose()
            logout()
          }}
          className="admin-text flex w-full items-center gap-3 rounded-xl px-4 py-3 text-[15px] font-semibold transition-colors hover:bg-red-50 hover:text-red-600 dark:hover:bg-red-950/40 dark:hover:text-red-400"
        >
          <IconLogout className="h-[22px] w-[22px] shrink-0 text-red-500" />
          <span className="flex-1 text-start leading-none">{t('nav.logout')}</span>
        </button>
      </div>
    </aside>
  )
}
