import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { useI18n } from '../i18n/I18nProvider'
import type { StringKey } from '../i18n/strings'
import { resolveMediaUrl } from '../lib/media'
import { useUnreadNotifications } from '../notifications/useUnreadNotifications'
import { useGate } from '../ui/GateProvider'
import { Icon } from '../ui/Icon'
import { SearchBar } from './SearchBar'

export function useAccountSubtitle(): StringKey | null {
  const { isSupplier, isCompanyCustomer, isAdmin, isPersonalCustomer } = useAuth()
  if (isSupplier) return 'supplierAccount'
  if (isCompanyCustomer) return 'companyCustomerAccount'
  if (isAdmin) return 'adminAccount'
  if (isPersonalCustomer) return 'personalAccount'
  return null
}

export function Avatar({ size = 40 }: { size?: number }) {
  const { session, displayName } = useAuth()
  const [failed, setFailed] = useState(false)
  const src = resolveMediaUrl(session?.imgPath)
  useEffect(() => setFailed(false), [src])
  if (session?.token && src && !failed) {
    return <img src={src} alt="" onError={() => setFailed(true)} style={{ width: size, height: size }} className="shrink-0 rounded-full border border-line object-cover" />
  }
  const initial = (displayName || '').trim().charAt(0).toUpperCase()
  return (
    <span style={{ width: size, height: size }} className="grid shrink-0 place-items-center rounded-full border border-line bg-[#EAF1FA] text-brand">
      {initial ? <span className="text-base font-bold">{initial}</span> : <Icon name="person" size={size * 0.55} />}
    </span>
  )
}

function LanguageToggle() {
  const { t, toggleLang } = useI18n()
  return (
    <button
      type="button"
      onClick={toggleLang}
      className="flex items-center gap-1.5 rounded-full px-2 py-1.5 text-[13px] font-semibold text-title hover:bg-page"
      style={{ fontFamily: 'Cairo' }}
    >
      <img src="/assets/icons/globe.svg" alt="" className="size-[18px] opacity-80" />
      {t('language')}
    </button>
  )
}

function NotificationBell() {
  const { t } = useI18n()
  const { ensureLoggedIn } = useGate()
  const navigate = useNavigate()
  const unread = useUnreadNotifications()
  return (
    <button
      type="button"
      onClick={() => ensureLoggedIn() && navigate('/notifications')}
      className="relative grid size-10 place-items-center rounded-full text-title hover:bg-page"
      aria-label={t('notifications')}
    >
      {unread > 0 && (
        <span className="absolute end-1 top-1 min-w-4 rounded-full border-[1.2px] border-white bg-[#E53935] px-1 text-center text-[9px] font-bold leading-[14px] text-white">
          {unread > 99 ? '99+' : unread}
        </span>
      )}
      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M6 8a6 6 0 1 1 12 0c0 7 3 9 3 9H3s3-2 3-9" />
        <path d="M10.3 21a1.94 1.94 0 0 0 3.4 0" />
      </svg>
    </button>
  )
}

/** Mirrors the app's AppHeader on every screen size (always LTR, like the app). */
export function SiteHeader() {
  const { t } = useI18n()
  const { displayName } = useAuth()
  const subtitle = useAccountSubtitle()
  const navigate = useNavigate()

  return (
    <header className="sticky top-0 z-30 bg-white/95 shadow-[0_1px_0_rgba(0,0,0,0.04),0_4px_14px_rgba(15,40,80,0.05)] backdrop-blur">
      <div className="mx-auto w-full max-w-[1600px] px-4 pb-3 pt-3 sm:px-6 2xl:px-10">
        <div dir="ltr" className="flex items-center gap-2">
          <button type="button" onClick={() => navigate('/profile')} className="rounded-full">
            <Avatar />
          </button>
          <button type="button" onClick={() => navigate('/profile')} className="min-w-0 flex-1 text-left">
            <p className="truncate text-base font-bold leading-tight text-black first-letter:uppercase">{displayName || t('guestName')}</p>
            {subtitle && <p className="mt-0.5 truncate text-[11px] font-medium leading-tight text-[#64748B]">{t(subtitle)}</p>}
          </button>
          <div className="mx-4 hidden max-w-2xl flex-[2] lg:block">
            <SearchBar compact />
          </div>
          <LanguageToggle />
          <NotificationBell />
          <Link to="/" aria-label="Home">
            <img src="/assets/logo/logo.png" alt="Al Ras Smart" className="h-10 w-12 object-contain" />
          </Link>
        </div>
        <div className="mt-4 lg:hidden">
          <SearchBar />
        </div>
      </div>
    </header>
  )
}
