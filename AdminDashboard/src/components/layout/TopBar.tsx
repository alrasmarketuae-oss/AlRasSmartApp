import { Link } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useAdminNotifications } from '../../context/AdminNotificationProvider'
import { useLogout } from '../../hooks/useLogout'
import { resolveAssetUrl } from '../../lib/assets'
import { getAuthUser } from '../../lib/authStorage'
import GlobalSearchBox from '../search/GlobalSearchBox'
import { IconBell, IconChat, IconLogout, IconMenu } from '../icons'
import PreferencesControls from './PreferencesControls'

type TopBarProps = {
  onMenuClick: () => void
}

export default function TopBar({ onMenuClick }: TopBarProps) {
  const { t } = useAppPreferences()
  const { navCounts, totalBadgeCount } = useAdminNotifications()
  const logout = useLogout()
  const user = getAuthUser()
  const initial = (user?.name ?? 'A')[0]

  return (
    <header
      dir="ltr"
      className="admin-header flex shrink-0 flex-wrap items-center gap-3 px-4 py-3 lg:gap-6 lg:px-8"
    >
      <button
        type="button"
        onClick={onMenuClick}
        className="admin-text flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-slate-200 bg-slate-50 transition hover:bg-slate-100 lg:hidden dark:border-slate-700 dark:bg-slate-800 dark:hover:bg-slate-700"
        aria-label={t('openMenu')}
      >
        <IconMenu className="h-5 w-5" />
      </button>

      <div className="flex shrink-0 items-center gap-3">
        {user?.imgPath ? (
          <img
            src={resolveAssetUrl(user.imgPath)}
            alt=""
            className="h-10 w-10 rounded-full object-cover sm:h-11 sm:w-11"
          />
        ) : (
          <div className="flex h-10 w-10 items-center justify-center rounded-full bg-slate-200 text-sm font-bold text-slate-600 sm:h-11 sm:w-11 dark:bg-slate-700 dark:text-slate-200">
            {initial}
          </div>
        )}
        <div className="hidden min-[480px]:block">
          <p className="admin-text text-sm font-bold leading-tight">
            {user?.name ?? t('generalManager')}
          </p>
          <p className="admin-text-muted text-xs">{t('generalManager')}</p>
        </div>
      </div>

      <GlobalSearchBox
        variant="topbar"
        className="order-last w-full min-w-0 sm:order-none sm:mx-auto sm:flex-1 sm:max-w-3xl"
        inputClassName="admin-input w-full rounded-full border-0 bg-[#f0f2f5] py-3 pl-12 pr-5 text-sm sm:py-3.5"
      />

      <div className="ms-auto flex shrink-0 items-center gap-2 sm:gap-3">
        <PreferencesControls />
        <Link
          to="/chat"
          className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-slate-200 bg-slate-50 text-[#2563eb] transition hover:bg-slate-100 sm:h-11 sm:w-11 dark:border-slate-700 dark:bg-slate-800 dark:hover:bg-slate-700"
          aria-label={t('nav.chat')}
        >
          <IconChat className="h-5 w-5" />
          {navCounts.chat > 0 ? (
            <span className="absolute -top-1 -end-1 inline-flex min-h-[18px] min-w-[18px] items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
              {navCounts.chat > 99 ? '99+' : navCounts.chat}
            </span>
          ) : null}
        </Link>
        <Link
          to={navCounts.profileEdits > 0 ? '/users?profileEdits=1' : '/orders/retail'}
          className="relative flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-slate-200 bg-slate-50 text-[#2563eb] transition hover:bg-slate-100 sm:h-11 sm:w-11 dark:border-slate-700 dark:bg-slate-800 dark:hover:bg-slate-700"
          aria-label={t('notifications')}
        >
          <IconBell className="h-5 w-5" />
          {navCounts.profileEdits > 0 ? (
            <span className="absolute -top-1 -end-1 inline-flex min-h-[18px] min-w-[18px] items-center justify-center rounded-full bg-amber-500 px-1 text-[10px] font-bold text-white">
              {navCounts.profileEdits > 99 ? '99+' : navCounts.profileEdits}
            </span>
          ) : totalBadgeCount > 0 ? (
            <span className="absolute -top-1 -end-1 inline-flex min-h-[18px] min-w-[18px] items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
              {totalBadgeCount > 99 ? '99+' : totalBadgeCount}
            </span>
          ) : null}
        </Link>
        <button
          type="button"
          onClick={logout}
          className="admin-text hidden h-10 shrink-0 items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 text-sm font-semibold transition hover:bg-red-50 hover:text-red-600 sm:inline-flex sm:h-11 dark:border-slate-700 dark:bg-slate-800 dark:hover:bg-red-950/40 dark:hover:text-red-400"
          aria-label={t('nav.logout')}
        >
          <IconLogout className="h-5 w-5 shrink-0 text-red-500" />
          <span className="hidden lg:inline">{t('nav.logout')}</span>
        </button>
      </div>
    </header>
  )
}
