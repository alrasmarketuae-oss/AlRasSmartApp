import { NavLink, useLocation } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useAdminNotifications } from '../../context/AdminNotificationProvider'
import { useLogout } from '../../hooks/useLogout'
import { getAuthUser } from '../../lib/authStorage'
import { hasPermission, isSuperAdmin, PERMISSIONS, type PermissionKey } from '../../lib/permissions'
import { PROJECT_IMAGES } from '../../constants/projectImages'
import { isSidebarNavActive } from '../../utils/navActive'
import NavBadge from './NavBadge'
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
  IconLogout,
} from '../icons'

type NavTone =
  | 'ads'
  | 'retail'
  | 'booking'
  | 'offers'
  | 'categoriesOrders'
  | 'request'

/**
 * Sidebar channel colors match pending-row blink peaks:
 * - Offers → green (row-attention-offer)
 * - Requests → red (row-attention-request)
 * - Other ads (Retail / Booking / Categories / Ads) → blue (row-attention-ad)
 * - Order queues without a dedicated ad wink → yellow (row-attention-order)
 */
const navToneClasses: Record<
  NavTone,
  { idle: string; active: string; iconIdle: string; pulse: string }
> = {
  ads: {
    idle: 'bg-blue-100 text-blue-900 hover:bg-blue-200/90 dark:bg-blue-950/55 dark:text-blue-100 dark:hover:bg-blue-900/70',
    active: 'keep-white bg-blue-600 text-white shadow-md shadow-blue-600/25',
    iconIdle: 'text-blue-700 dark:text-blue-300',
    pulse: 'nav-attention-ad',
  },
  retail: {
    idle: 'bg-blue-100 text-blue-900 hover:bg-blue-200/90 dark:bg-blue-950/55 dark:text-blue-100 dark:hover:bg-blue-900/70',
    active: 'keep-white bg-blue-600 text-white shadow-md shadow-blue-600/25',
    iconIdle: 'text-blue-700 dark:text-blue-300',
    pulse: 'nav-attention-ad',
  },
  booking: {
    idle: 'bg-blue-100 text-blue-900 hover:bg-blue-200/90 dark:bg-blue-950/55 dark:text-blue-100 dark:hover:bg-blue-900/70',
    active: 'keep-white bg-blue-600 text-white shadow-md shadow-blue-600/25',
    iconIdle: 'text-blue-700 dark:text-blue-300',
    pulse: 'nav-attention-ad',
  },
  offers: {
    idle: 'bg-green-100 text-green-900 hover:bg-green-200/90 dark:bg-green-950/55 dark:text-green-100 dark:hover:bg-green-900/70',
    active: 'keep-white bg-green-600 text-white shadow-md shadow-green-600/25',
    iconIdle: 'text-green-700 dark:text-green-300',
    pulse: 'nav-attention-offer',
  },
  categoriesOrders: {
    idle: 'bg-blue-100 text-blue-900 hover:bg-blue-200/90 dark:bg-blue-950/55 dark:text-blue-100 dark:hover:bg-blue-900/70',
    active: 'keep-white bg-blue-600 text-white shadow-md shadow-blue-600/25',
    iconIdle: 'text-blue-700 dark:text-blue-300',
    pulse: 'nav-attention-ad',
  },
  request: {
    idle: 'bg-red-100 text-red-900 hover:bg-red-200/90 dark:bg-red-950/55 dark:text-red-100 dark:hover:bg-red-900/70',
    active: 'keep-white bg-red-600 text-white shadow-md shadow-red-600/25',
    iconIdle: 'text-red-700 dark:text-red-300',
    pulse: 'nav-attention-request',
  },
}

const navItems: Array<{
  to: string
  labelKey: string
  icon: typeof IconGrid
  countKey?:
    | 'users'
    | 'profileEdits'
    | 'ads'
    | 'adEdits'
    | 'retailOrders'
    | 'bookingOrders'
    | 'offersOrders'
    | 'categoriesOrders'
    | 'offers'
    | 'shipping'
    | 'chat'
  badgeTone?: 'red' | 'green' | 'blue' | 'yellow' | 'amber' | 'sky'
  navTone?: NavTone
  permission?: PermissionKey
  superAdminOnly?: boolean
}> = [
  { to: '/', labelKey: 'nav.dashboard', icon: IconGrid, permission: PERMISSIONS.dashboardView },
  { to: '/users', labelKey: 'nav.users', icon: IconUsers, countKey: 'users', badgeTone: 'amber', permission: PERMISSIONS.usersView },
  { to: '/ads', labelKey: 'nav.ads', icon: IconAds, countKey: 'ads', badgeTone: 'blue', navTone: 'ads', permission: PERMISSIONS.productsView },
  { to: '/orders/retail', labelKey: 'nav.ordersRetail', icon: IconOrders, countKey: 'retailOrders', badgeTone: 'blue', navTone: 'retail', permission: PERMISSIONS.ordersView },
  { to: '/orders/booking', labelKey: 'nav.ordersBooking', icon: IconOrders, countKey: 'bookingOrders', badgeTone: 'blue', navTone: 'booking', permission: PERMISSIONS.ordersView },
  { to: '/orders/offers', labelKey: 'nav.ordersOffersType', icon: IconOrders, countKey: 'offersOrders', badgeTone: 'green', navTone: 'offers', permission: PERMISSIONS.ordersView },
  { to: '/orders/categories', labelKey: 'nav.ordersCategories', icon: IconOrders, countKey: 'categoriesOrders', badgeTone: 'blue', navTone: 'categoriesOrders', permission: PERMISSIONS.ordersView },
  { to: '/reqs-offers', labelKey: 'nav.reqsOffers', icon: IconOrders, countKey: 'offers', badgeTone: 'red', navTone: 'request', permission: PERMISSIONS.ordersReqsOffers },
  { to: '/categories', labelKey: 'nav.categories', icon: IconCategories, permission: PERMISSIONS.categoriesManage },
  { to: '/banners', labelKey: 'nav.banners', icon: IconBanner, permission: PERMISSIONS.bannersManage },
  { to: '/shipping', labelKey: 'nav.shipping', icon: IconShipping, countKey: 'shipping', badgeTone: 'sky', permission: PERMISSIONS.shippingView },
  { to: '/chat', labelKey: 'nav.chat', icon: IconChat, countKey: 'chat', badgeTone: 'red', permission: PERMISSIONS.chatAccess },
  { to: '/notifications', labelKey: 'nav.notifications', icon: IconBell, permission: PERMISSIONS.notificationsView },
  { to: '/missed-searches', labelKey: 'nav.missedSearches', icon: IconAds, permission: PERMISSIONS.searchAccess },
  { to: '/audit-logs', labelKey: 'nav.auditLogs', icon: IconOrders, permission: PERMISSIONS.auditView },
  { to: '/employees', labelKey: 'nav.employees', icon: IconUsers, superAdminOnly: true },
  { to: '/settings', labelKey: 'nav.settings', icon: IconSettings, permission: PERMISSIONS.settingsView },
  // Keep company/ad edit queues at the very end of the sidebar.
  { to: '/users?profileEdits=1', labelKey: 'nav.profileEdits', icon: IconUsers, countKey: 'profileEdits', badgeTone: 'amber', permission: PERMISSIONS.usersProfileEdits },
  { to: '/ads?adEdits=1', labelKey: 'nav.adEdits', icon: IconAds, countKey: 'adEdits', badgeTone: 'blue', permission: PERMISSIONS.productsAdEdits },
]

type SidebarProps = {
  open: boolean
  onClose: () => void
}

export default function Sidebar({ open, onClose }: SidebarProps) {
  const { t, dir } = useAppPreferences()
  const location = useLocation()
  const { navCounts } = useAdminNotifications()
  const logout = useLogout()
  const authUser = getAuthUser()
  const visibleNavItems = navItems.filter((item) => {
    if (item.superAdminOnly) return isSuperAdmin(authUser?.roleName)
    if (!item.permission) return true
    return hasPermission(item.permission)
  })
  const slideOff =
    dir === 'rtl'
      ? 'translate-x-full lg:translate-x-0'
      : '-translate-x-full lg:translate-x-0'

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
        {visibleNavItems.map(({ to, labelKey, icon: Icon, countKey, badgeTone, navTone }) => {
          const active = isSidebarNavActive(
            to,
            location.pathname,
            location.search,
            location.state,
          )
          const tone = navTone ? navToneClasses[navTone] : null
          const pendingCount = countKey ? navCounts[countKey] : 0
          const shouldPulse = Boolean(tone && !active && pendingCount > 0)
          const linkClass = active
            ? tone?.active ??
              'keep-white bg-[#1d4ed8] text-white shadow-md shadow-blue-600/20'
            : shouldPulse
              ? `${tone?.pulse ?? ''} ${tone?.idle ?? ''}`.trim()
              : tone?.idle ?? 'admin-text hover:bg-slate-50 dark:hover:bg-slate-800'
          const iconClass = active
            ? 'keep-white text-white'
            : tone?.iconIdle ?? 'admin-text-muted'
          return (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              onClick={onClose}
              aria-current={active ? 'page' : undefined}
              className={() =>
                `flex w-full items-center gap-3 rounded-xl px-4 py-3 text-[15px] font-semibold transition-colors sm:py-3.5 ${linkClass}`
              }
            >
              <Icon className={`h-[22px] w-[22px] shrink-0 ${iconClass}`} />
              <span className="flex-1 text-start leading-none">{t(labelKey)}</span>
              {countKey ? (
                <NavBadge count={navCounts[countKey]} active={active} tone={badgeTone} />
              ) : null}
            </NavLink>
          )
        })}
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
