import { useState } from 'react'
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
  IconChevronDown,
  IconClose,
  IconGrid,
  IconOrders,
  IconSettings,
  IconShipping,
  IconUsers,
  IconBell,
  IconWallet,
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
  badgeTone?: BadgeTone
  permission?: PermissionKey
  anyOf?: PermissionKey[]
  superAdminOnly?: boolean
}

type NavGroup = {
  id: 'ads' | 'orders'
  labelKey: string
  icon: typeof IconGrid
  accent: NavAccent
  badgeTone: BadgeTone
  countKeys: CountKey[]
  anyOf: PermissionKey[]
  children: NavItem[]
}

type NavEntry =
  | { kind: 'item'; item: NavItem }
  | { kind: 'group'; group: NavGroup }

const navEntries: NavEntry[] = [
  { kind: 'item', item: { to: '/', labelKey: 'nav.dashboard', icon: IconGrid, permission: PERMISSIONS.dashboardView } },
  { kind: 'item', item: { to: '/users', labelKey: 'nav.users', icon: IconUsers, countKey: 'users', badgeTone: 'amber', permission: PERMISSIONS.usersView } },
  {
    kind: 'group',
    group: {
      id: 'ads',
      labelKey: 'nav.ads',
      icon: IconAds,
      accent: 'ads',
      badgeTone: 'blue',
      countKeys: ['ads', 'requestAds'],
      anyOf: [PERMISSIONS.productsView, PERMISSIONS.ordersReqsOffers],
      children: [
        { to: '/ads', labelKey: 'nav.adAll', icon: IconAds, permission: PERMISSIONS.productsView },
        { to: '/ads?productTypeId=1', labelKey: 'nav.adRetail', icon: IconAds, permission: PERMISSIONS.productsView },
        { to: '/ads?productTypeId=2', labelKey: 'nav.adBooking', icon: IconAds, permission: PERMISSIONS.productsView },
        { to: '/ads?productTypeId=3', labelKey: 'nav.adOffers', icon: IconAds, permission: PERMISSIONS.productsView },
        { to: '/ads?channel=categories', labelKey: 'nav.adCategories', icon: IconAds, permission: PERMISSIONS.productsView },
        { to: '/reqs-offers', labelKey: 'nav.adRequest', icon: IconAds, countKey: 'requestAds', badgeTone: 'blue', permission: PERMISSIONS.ordersReqsOffers },
      ],
    },
  },
  {
    kind: 'group',
    group: {
      id: 'orders',
      labelKey: 'nav.orders',
      icon: IconOrders,
      accent: 'orders',
      badgeTone: 'green',
      countKeys: ['retailOrders', 'bookingOrders', 'offersOrders', 'categoriesOrders', 'offers'],
      anyOf: [PERMISSIONS.ordersView, PERMISSIONS.ordersReqsOffers],
      children: [
        { to: '/orders/all', labelKey: 'nav.orderAll', icon: IconOrders, permission: PERMISSIONS.ordersView },
        { to: '/orders/retail', labelKey: 'nav.orderRetail', icon: IconOrders, countKey: 'retailOrders', badgeTone: 'green', permission: PERMISSIONS.ordersView },
        { to: '/orders/booking', labelKey: 'nav.orderBooking', icon: IconOrders, countKey: 'bookingOrders', badgeTone: 'green', permission: PERMISSIONS.ordersView },
        { to: '/orders/offers', labelKey: 'nav.orderOffers', icon: IconOrders, countKey: 'offersOrders', badgeTone: 'green', permission: PERMISSIONS.ordersView },
        { to: '/orders/categories', labelKey: 'nav.orderCategories', icon: IconOrders, countKey: 'categoriesOrders', badgeTone: 'green', permission: PERMISSIONS.ordersView },
        { to: '/reqs-offers?nav=orders', labelKey: 'nav.orderRequest', icon: IconOrders, countKey: 'offers', badgeTone: 'green', permission: PERMISSIONS.ordersReqsOffers },
      ],
    },
  },
  { kind: 'item', item: { to: '/categories', labelKey: 'nav.categories', icon: IconCategories, permission: PERMISSIONS.categoriesManage } },
  { kind: 'item', item: { to: '/banners', labelKey: 'nav.banners', icon: IconBanner, permission: PERMISSIONS.bannersManage } },
  { kind: 'item', item: { to: '/shipping', labelKey: 'nav.shipping', icon: IconShipping, countKey: 'shipping', badgeTone: 'sky', permission: PERMISSIONS.shippingView } },
  { kind: 'item', item: { to: '/chat', labelKey: 'nav.chat', icon: IconChat, countKey: 'chat', badgeTone: 'red', permission: PERMISSIONS.chatAccess } },
  { kind: 'item', item: { to: '/notifications', labelKey: 'nav.notifications', icon: IconBell, permission: PERMISSIONS.notificationsView } },
  { kind: 'item', item: { to: '/finance', labelKey: 'Finance', icon: IconWallet, permission: PERMISSIONS.financeView } },
  { kind: 'item', item: { to: '/missed-searches', labelKey: 'nav.missedSearches', icon: IconAds, permission: PERMISSIONS.searchAccess } },
  { kind: 'item', item: { to: '/audit-logs', labelKey: 'nav.auditLogs', icon: IconOrders, permission: PERMISSIONS.auditView } },
  { kind: 'item', item: { to: '/employees', labelKey: 'nav.employees', icon: IconUsers, superAdminOnly: true } },
  { kind: 'item', item: { to: '/settings', labelKey: 'nav.settings', icon: IconSettings, permission: PERMISSIONS.settingsView } },
  { kind: 'item', item: { to: '/users?profileEdits=1', labelKey: 'nav.profileEdits', icon: IconUsers, countKey: 'profileEdits', badgeTone: 'amber', permission: PERMISSIONS.usersProfileEdits } },
  { kind: 'item', item: { to: '/ads?adEdits=1', labelKey: 'nav.adEdits', icon: IconAds, countKey: 'adEdits', badgeTone: 'blue', permission: PERMISSIONS.productsAdEdits } },
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

function navLinkClass(active: boolean, nested = false, accent?: NavAccent) {
  const sizeClass = nested
    ? 'gap-2 rounded-lg px-3 py-2 text-[13px] sm:py-2.5'
    : 'gap-3 rounded-xl px-4 py-3 text-[15px] sm:py-3.5'

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
  const [openGroups, setOpenGroups] = useState<Record<string, boolean>>({})

  const visibleEntries = navEntries
    .map((entry) => {
      if (entry.kind === 'item') {
        return canSeeItem(entry.item, authUser?.roleName) ? entry : null
      }
      const children = entry.group.children.filter((child) =>
        canSeeItem(child, authUser?.roleName),
      )
      if (children.length === 0) return null
      if (!entry.group.anyOf.some((key) => hasPermission(key))) return null
      return { kind: 'group' as const, group: { ...entry.group, children } }
    })
    .filter((entry): entry is NavEntry => entry != null)

  const slideOff =
    dir === 'rtl'
      ? 'translate-x-full lg:translate-x-0'
      : '-translate-x-full lg:translate-x-0'

  function renderNavItem(item: NavItem, nested = false, accent?: NavAccent) {
    const active = isSidebarNavActive(
      item.to,
      location.pathname,
      location.search,
      location.state,
    )
    const { linkClass, iconClass, sizeClass } = navLinkClass(active, nested, accent)
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
        <Icon className={`${nested ? 'h-4 w-4' : 'h-[22px] w-[22px]'} shrink-0 ${iconClass}`} />
        <span className="flex min-w-0 flex-1 items-center gap-1.5 text-start">
          {item.countKey ? (
            <NavBadge
              count={navCounts[item.countKey]}
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
        {visibleEntries.map((entry) => {
          if (entry.kind === 'item') {
            return renderNavItem(entry.item)
          }

          const { group } = entry
          const childActive = group.children.some((child) =>
            isSidebarNavActive(
              child.to,
              location.pathname,
              location.search,
              location.state,
            ),
          )
          // Orders stays collapsed until the user opens it. Ads still auto-opens
          // when one of its children is the current page.
          const expanded =
            group.id === 'orders'
              ? openGroups[group.id] === true
              : childActive || openGroups[group.id] === true
          const pendingCount = sumCounts(navCounts, group.countKeys)
          const { linkClass, iconClass, sizeClass } = navLinkClass(childActive, false, group.accent)
          const Icon = group.icon
          const groupShell =
            group.accent === 'ads'
              ? 'bg-indigo-50/70 dark:bg-indigo-950/25'
              : 'bg-emerald-50/70 dark:bg-emerald-950/25'
          const nestedBorder =
            group.accent === 'ads'
              ? 'border-indigo-200 dark:border-indigo-800'
              : 'border-emerald-200 dark:border-emerald-800'

          return (
            <div key={group.id} className={`flex flex-col gap-1 rounded-2xl p-1.5 ${groupShell}`}>
              <button
                type="button"
                onClick={() => {
                  if (group.id !== 'orders' && childActive) return
                  setOpenGroups((current) => ({
                    ...current,
                    [group.id]: current[group.id] !== true,
                  }))
                }}
                aria-expanded={expanded}
                className={`flex w-full items-center font-semibold transition-colors ${sizeClass} ${linkClass}`}
              >
                <Icon className={`h-[22px] w-[22px] shrink-0 ${iconClass}`} />
                <span className="flex min-w-0 flex-1 items-center gap-1.5 text-start">
                  <NavBadge
                    count={pendingCount}
                    active={childActive}
                    tone={group.badgeTone}
                  />
                  <span className="min-w-0 leading-none">{t(group.labelKey)}</span>
                </span>
                <IconChevronDown
                  className={`h-4 w-4 shrink-0 transition-transform ${iconClass} ${
                    expanded ? 'rotate-180' : ''
                  }`}
                />
              </button>
              {expanded ? (
                <div className={`ms-3 flex flex-col gap-1 border-s ps-2 ${nestedBorder}`}>
                  {group.children.map((child) =>
                    renderNavItem(child, true, group.accent),
                  )}
                </div>
              ) : null}
            </div>
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
