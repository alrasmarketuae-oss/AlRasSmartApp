import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import AdminAlertStack from '../components/alerts/AdminAlertStack'
import { useAppPreferences } from './AppPreferencesProvider'
import { useAdminNotifications } from './AdminNotificationProvider'
import { useChat } from './ChatProvider'
import { useAlertSoundUnlock } from '../hooks/useAlertSoundUnlock'
import {
  playAlertSoundOnce,
  startAlertSoundLoop,
  stopAlertSoundLoop,
} from '../lib/alertSound'
import type { AdminRealtimeAlert } from '../types/adminRealtime'

export type AdminAlertItem = {
  id: string
  type: 'chat' | 'order' | 'offer' | 'newUser' | 'profileEdit' | 'newAd' | 'newRequest' | 'adEdit' | 'newShippingAd'
  title: string
  body: string
  href?: string
  /** Optional router state (e.g. keep Reqs & Offers nav active on ad detail). */
  hrefState?: { from?: string }
  actionLabel: string
  dismissLabel: string
}

type AdminAlertContextValue = {
  dismissAlert: (id: string) => void
}

const AdminAlertContext = createContext<AdminAlertContextValue | null>(null)

function formatAlertQuantity(alert: AdminRealtimeAlert): string {
  const qty = (alert.quantity ?? '').trim()
  const unit = (alert.unitName ?? '').trim()
  if (!qty && !unit) return '—'
  if (!unit) return qty || '—'
  if (!qty) return unit
  return `${qty} ${unit}`
}

function formatAlertDetailsSuffix(
  alert: AdminRealtimeAlert,
  t: (key: string, vars?: Record<string, string | number>) => string,
): string {
  const details = (alert.details ?? '').trim()
  if (!details) return ''
  return t('alerts.orderAlertDetails', { details })
}

function buildAlertFromRealtime(
  alert: AdminRealtimeAlert,
  t: (key: string, vars?: Record<string, string | number>) => string,
): AdminAlertItem | null {
  switch (alert.type) {
    case 'newUser':
      return {
        id: `user-${alert.referenceId ?? Date.now()}`,
        type: 'newUser',
        title: t('alerts.newUserTitle'),
        body: t('alerts.newUserBody', {
          name: alert.displayName ?? '—',
          email: alert.secondaryName ?? '',
        }),
        href: '/users',
        actionLabel: t('alerts.openUsers'),
        dismissLabel: t('alerts.dismiss'),
      }
    case 'profileEdit':
      return {
        id: `profile-edit-${alert.referenceId ?? 'x'}-${Date.now()}`,
        type: 'profileEdit',
        title: t('alerts.profileEditTitle'),
        body: t('alerts.profileEditBody', {
          name: alert.displayName ?? '—',
          email: alert.secondaryName ?? '',
        }),
        href: alert.referenceId ? `/users/${alert.referenceId}` : '/users?profileEdits=1',
        actionLabel: t('alerts.reviewProfileEdit'),
        dismissLabel: t('alerts.dismiss'),
      }
    case 'newAd': {
      const kind = (alert.secondaryName ?? '').trim().toLowerCase()
      const isRequest = kind === 'requests' || kind === 'request' || kind === '4'
      const isOfferAd = kind === 'offers' || kind === 'offer' || kind === '3'
      if (isRequest) {
        return {
          id: `request-${alert.referenceId ?? Date.now()}`,
          type: 'newRequest',
          title: t('alerts.newAdTitle'),
          body: t('alerts.newAdBody', {
            name: alert.displayName ?? '—',
          }),
          href: alert.referenceId ? `/ads/${alert.referenceId}` : '/reqs-offers?tab=requests',
          hrefState: { from: '/reqs-offers' },
          actionLabel: t('alerts.openAds'),
          dismissLabel: t('alerts.dismiss'),
        }
      }
      if (isOfferAd) {
        return {
          id: `offer-ad-${alert.referenceId ?? Date.now()}`,
          type: 'newAd',
          title: t('alerts.newAdTitle'),
          body: t('alerts.newAdBody', {
            name: alert.displayName ?? '—',
          }),
          href: alert.referenceId ? `/ads/${alert.referenceId}` : '/ads?productTypeId=3',
          hrefState: { from: '/ads' },
          actionLabel: t('alerts.openAds'),
          dismissLabel: t('alerts.dismiss'),
        }
      }
      return {
        id: `ad-${alert.referenceId ?? Date.now()}`,
        type: 'newAd',
        title: t('alerts.newAdTitle'),
        body: t('alerts.newAdBody', {
          name: alert.displayName ?? '—',
        }),
        href: alert.referenceId ? `/ads/${alert.referenceId}` : '/ads',
        actionLabel: t('alerts.openAds'),
        dismissLabel: t('alerts.dismiss'),
      }
    }
    case 'adEdit':
      return {
        id: `ad-edit-${alert.referenceId ?? Date.now()}`,
        type: 'adEdit',
        title: t('alerts.adEditTitle'),
        body: t('alerts.adEditBody', {
          name: alert.displayName ?? '—',
        }),
        href: alert.referenceId ? `/ads/${alert.referenceId}` : '/ads?adEdits=1',
        actionLabel: t('alerts.openAdEdits'),
        dismissLabel: t('alerts.dismiss'),
      }
    case 'newShippingAd': {
      const providerId = alert.secondaryName ?? ''
      return {
        id: `shipping-ad-${alert.referenceId ?? Date.now()}`,
        type: 'newShippingAd',
        title: t('alerts.newShippingAdTitle'),
        body: t('alerts.newShippingAdBody', {
          name: alert.displayName ?? '—',
        }),
        href: providerId ? `/shipping/${providerId}` : '/shipping',
        actionLabel: t('alerts.openShipping'),
        dismissLabel: t('alerts.dismiss'),
      }
    }
    case 'newOrder':
      return {
        id: `order-${alert.referenceId ?? Date.now()}`,
        type: 'order',
        title: t('alerts.newOrderTitle'),
        body: t('alerts.newOrderBody', {
          id: alert.referenceId ?? '—',
          customer: alert.displayName ?? '—',
          product: alert.secondaryName ?? '—',
          quantity: formatAlertQuantity(alert),
          details: formatAlertDetailsSuffix(alert, t),
        }),
        href: alert.referenceId ? `/orders/${alert.referenceId}` : '/orders/retail',
        actionLabel: t('alerts.openOrders'),
        dismissLabel: t('alerts.dismiss'),
      }
    case 'newOffer': {
      const productId = alert.tertiaryName?.trim()
      return {
        id: `offer-${alert.referenceId ?? Date.now()}`,
        type: 'offer',
        title: t('alerts.newOfferTitle'),
        body: t('alerts.newOfferBody', {
          id: alert.referenceId ?? '—',
          supplier: alert.displayName ?? '—',
          product: alert.secondaryName ?? '—',
          quantity: formatAlertQuantity(alert),
          details: formatAlertDetailsSuffix(alert, t),
        }),
        // Prefer the request ad itself; also keep ReqsOffers deep-link as fallback.
        href: productId
          ? `/ads/${productId}`
          : '/reqs-offers?tab=offers&offerReview=awaitingAdmin',
        hrefState: productId ? { from: '/reqs-offers' } : undefined,
        actionLabel: productId
          ? t('alerts.openRequestAd')
          : t('alerts.openReqsOffers'),
        dismissLabel: t('alerts.dismiss'),
      }
    }
    case 'chat':
      return {
        id: `chat-${alert.referenceId ?? Date.now()}`,
        type: 'chat',
        title: t('alerts.newMessageTitle'),
        body: t('alerts.newChatBody', {
          name: alert.displayName ?? '—',
        }),
        href: '/chat',
        actionLabel: t('alerts.openChat'),
        dismissLabel: t('alerts.dismiss'),
      }
    default:
      return null
  }
}

export function AdminAlertProvider({ children }: { children: ReactNode }) {
  const { t, alertSoundMuted } = useAppPreferences()
  const { totalUnread, subscribeReceiveMessage } = useChat()
  const { subscribeAdminAlert } = useAdminNotifications()
  const { needsUnlock, enableSoundManually, unlockLabel, unlockHint } = useAlertSoundUnlock()

  const [flashChat, setFlashChat] = useState(false)
  const [realtimeAlerts, setRealtimeAlerts] = useState<AdminAlertItem[]>([])
  const [dismissedIds, setDismissedIds] = useState<Set<string>>(() => new Set())
  const prevUnreadRef = useRef(0)

  useEffect(() => {
    return subscribeReceiveMessage(() => {
      setFlashChat(true)
      setDismissedIds((prev) => {
        if (!prev.has('chat-summary')) return prev
        const next = new Set(prev)
        next.delete('chat-summary')
        return next
      })
      void playAlertSoundOnce()
    })
  }, [subscribeReceiveMessage])

  useEffect(() => {
    return subscribeAdminAlert((alert) => {
      const item = buildAlertFromRealtime(alert, t)
      if (!item) return

      setRealtimeAlerts((prev) => {
        if (prev.some((existing) => existing.id === item.id)) {
          return prev
        }
        return [item, ...prev].slice(0, 8)
      })

      if (alert.type === 'chat') {
        setFlashChat(true)
      }

      void playAlertSoundOnce()
    })
  }, [subscribeAdminAlert, t])

  useEffect(() => {
    if (totalUnread > prevUnreadRef.current) {
      setFlashChat(true)
      void playAlertSoundOnce()
    } else if (totalUnread === 0) {
      setFlashChat(false)
    }
    prevUnreadRef.current = totalUnread
  }, [totalUnread])

  const dismissAlert = useCallback((id: string) => {
    setDismissedIds((prev) => new Set(prev).add(id))
    setRealtimeAlerts((prev) => prev.filter((item) => item.id !== id))
    if (id === 'chat-summary') {
      setFlashChat(false)
    }
  }, [])

  const alerts = useMemo((): AdminAlertItem[] => {
    const list: AdminAlertItem[] = []

    if (flashChat && totalUnread > 0 && !dismissedIds.has('chat-summary')) {
      list.push({
        id: 'chat-summary',
        type: 'chat',
        title: t('alerts.newMessageTitle'),
        body: t('alerts.newMessageBody', { count: totalUnread }),
        href: '/chat',
        actionLabel: t('alerts.openChat'),
        dismissLabel: t('alerts.dismiss'),
      })
    }

    for (const item of realtimeAlerts) {
      if (!dismissedIds.has(item.id)) {
        list.push(item)
      }
    }

    return list
  }, [flashChat, totalUnread, dismissedIds, realtimeAlerts, t])

  const shouldLoopSound =
    !needsUnlock &&
    !alertSoundMuted &&
    alerts.some((alert) => {
      if (alert.type === 'chat' && alert.id === 'chat-summary') {
        return flashChat && totalUnread > 0
      }
      return alert.type === 'order'
        || alert.type === 'offer'
        || alert.type === 'newAd'
        || alert.type === 'newRequest'
        || alert.type === 'chat'
        || alert.type === 'profileEdit'
    })

  useEffect(() => {
    if (shouldLoopSound) {
      startAlertSoundLoop()
    } else {
      stopAlertSoundLoop()
    }
    return () => stopAlertSoundLoop()
  }, [shouldLoopSound, alertSoundMuted])

  useEffect(() => {
    if (totalUnread === 0) {
      setDismissedIds((prev) => {
        if (!prev.has('chat-summary')) return prev
        const next = new Set(prev)
        next.delete('chat-summary')
        return next
      })
    }
  }, [totalUnread])

  const value = useMemo(() => ({ dismissAlert }), [dismissAlert])

  return (
    <AdminAlertContext.Provider value={value}>
      {children}

      {needsUnlock ? (
        <div className="pointer-events-none fixed top-20 start-1/2 z-[110] w-[min(100%,24rem)] -translate-x-1/2 px-4 print:hidden">
          <div className="pointer-events-auto flex flex-col gap-2 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 shadow-lg dark:border-amber-800/60 dark:bg-amber-950/90">
            <p className="text-sm font-bold text-amber-900 dark:text-amber-200">{unlockLabel}</p>
            <p className="text-xs text-amber-800 dark:text-amber-300/90">{unlockHint}</p>
            <button
              type="button"
              onClick={() => void enableSoundManually()}
              className="mt-1 rounded-xl bg-gradient-to-r from-[#3B7FC7] to-[#619d51] px-4 py-2 text-sm font-bold text-white shadow"
            >
              {t('alerts.enableSoundButton')}
            </button>
          </div>
        </div>
      ) : null}

      <AdminAlertStack alerts={alerts} onDismiss={dismissAlert} />
    </AdminAlertContext.Provider>
  )
}

export function useAdminAlerts() {
  const ctx = useContext(AdminAlertContext)
  if (!ctx) {
    throw new Error('useAdminAlerts must be used within AdminAlertProvider')
  }
  return ctx
}
