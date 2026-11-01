import { useQuery } from '@tanstack/react-query'
import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { useI18n } from '../i18n/I18nProvider'
import { fetchAppVersion } from '../products/productsApi'
import { Modal } from './Modal'

type GateValue = {
  /** Returns true when signed in; otherwise shows the login-required dialog. */
  ensureLoggedIn: () => boolean
  /** Explains that a feature lives in the mobile app, with store links. */
  showAppOnly: () => void
}

const GateContext = createContext<GateValue | null>(null)

const FALLBACK_STORES = {
  androidStoreUrl: 'https://play.google.com/store/apps/details?id=com.mergespice.alrasmarket',
  iosStoreUrl: 'https://apps.apple.com/gb/app/al-ras-smart/id6795899781',
}

export function StoreButtons() {
  const { t } = useI18n()
  const { data } = useQuery({ queryKey: ['app-version'], queryFn: fetchAppVersion, staleTime: 3_600_000 })
  const android = data?.androidStoreUrl || FALLBACK_STORES.androidStoreUrl
  const ios = data?.iosStoreUrl || FALLBACK_STORES.iosStoreUrl
  const cls =
    'flex flex-1 items-center justify-center gap-2 rounded-xl bg-[#0B0717] px-4 py-3 text-sm font-semibold text-white hover:opacity-90'
  return (
    <div className="flex gap-3">
      <a href={ios} target="_blank" rel="noopener noreferrer" className={cls}>
        <img src="/assets/icons/apple_ic.svg" alt="" className="size-5 invert" />
        {t('downloadOnAppStore')}
      </a>
      <a href={android} target="_blank" rel="noopener noreferrer" className={cls}>
        <svg viewBox="0 0 24 24" className="size-5" aria-hidden="true">
          <path fill="#34A853" d="M3.6 2.2 13.4 12l-9.8 9.8c-.4-.2-.6-.7-.6-1.2V3.4c0-.5.2-1 .6-1.2z" />
          <path fill="#FBBC04" d="m17 8.4-3.6 3.6L17 15.6l4-2.3c.9-.5.9-1.9 0-2.4z" />
          <path fill="#EA4335" d="M13.4 12 3.6 21.8c.3.2.8.2 1.2 0L17 15.6z" />
          <path fill="#4285F4" d="M4.8 2.2c-.4-.2-.9-.2-1.2 0L13.4 12 17 8.4z" />
        </svg>
        {t('getItOnGooglePlay')}
      </a>
    </div>
  )
}

export function GateProvider({ children }: { children: ReactNode }) {
  const { t } = useI18n()
  const { isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const [dialog, setDialog] = useState<'login' | 'app' | null>(null)
  const close = useCallback(() => setDialog(null), [])

  const value = useMemo<GateValue>(
    () => ({
      ensureLoggedIn: () => {
        if (isAuthenticated) return true
        setDialog('login')
        return false
      },
      showAppOnly: () => setDialog('app'),
    }),
    [isAuthenticated],
  )

  return (
    <GateContext.Provider value={value}>
      {children}
      <Modal open={dialog === 'login'} onClose={close} title={t('loginRequiredTitle')}>
        <p className="mb-5 text-sm text-auth-body">{t('loginRequiredMessage')}</p>
        <div className="flex gap-3">
          <button type="button" onClick={close} className="flex-1 rounded-xl border border-auth-border py-3 text-sm font-semibold text-auth-label">
            {t('cancel')}
          </button>
          <button
            type="button"
            onClick={() => {
              close()
              navigate('/login')
            }}
            className="flex-1 rounded-xl bg-gradient-to-r from-brand-dark to-brand-light py-3 text-sm font-bold text-white"
          >
            {t('login')}
          </button>
        </div>
      </Modal>
      <Modal open={dialog === 'app'} onClose={close} title={t('useAppTitle')}>
        <div className="mb-4 flex justify-center">
          <img src="/assets/logo/logo.png" alt="" className="h-16 w-auto" />
        </div>
        <p className="mb-5 text-center text-sm text-auth-body">{t('useAppMessage')}</p>
        <StoreButtons />
      </Modal>
    </GateContext.Provider>
  )
}

export function useGate() {
  const value = useContext(GateContext)
  if (!value) throw new Error('useGate must be used inside GateProvider')
  return value
}
