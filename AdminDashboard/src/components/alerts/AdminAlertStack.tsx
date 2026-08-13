import { Link } from 'react-router-dom'
import { IconAds, IconChat, IconClose, IconOrders, IconShipping, IconUsers } from '../icons'
import type { AdminAlertItem } from '../../context/AdminAlertProvider'

type AdminAlertStackProps = {
  alerts: AdminAlertItem[]
  onDismiss: (id: string) => void
}

function AlertIcon({ type }: { type: AdminAlertItem['type'] }) {
  const cls = 'h-5 w-5'
  if (type === 'chat' || type === 'techSupportCallback') {
    return <IconChat className={cls} />
  }
  if (type === 'newUser' || type === 'profileEdit') {
    return <IconUsers className={cls} />
  }
  if (type === 'newAd' || type === 'adEdit' || type === 'newShippingAd' || type === 'newRequest') {
    return type === 'newShippingAd' ? (
      <IconShipping className={cls} />
    ) : (
      <IconAds className={cls} />
    )
  }
  return <IconOrders className={cls} />
}

/** Light pastel tones — not dark/saturated. */
function alertTone(type: AdminAlertItem['type']): string {
  if (type === 'chat' || type === 'techSupportCallback') {
    return 'bg-sky-200 text-sky-800'
  }
  if (type === 'newUser' || type === 'profileEdit') {
    return 'bg-violet-200 text-violet-800'
  }
  if (type === 'newRequest') {
    return 'bg-red-200 text-red-800'
  }
  if (type === 'newAd' || type === 'adEdit') {
    return 'bg-blue-200 text-blue-800'
  }
  if (type === 'newShippingAd') {
    return 'bg-cyan-200 text-cyan-800'
  }
  if (type === 'offer') {
    return 'bg-green-200 text-green-800'
  }
  // order
  return 'bg-yellow-200 text-yellow-900'
}

export default function AdminAlertStack({ alerts, onDismiss }: AdminAlertStackProps) {
  if (alerts.length === 0) return null

  return (
    <div className="pointer-events-none fixed bottom-4 start-4 z-[100] flex w-[min(100%,22rem)] flex-col gap-3 print:hidden">
      {alerts.map((alert) => (
        <div
          key={alert.id}
          className="admin-alert-toast pointer-events-auto flex items-start gap-3 rounded-2xl border border-slate-200/80 bg-white p-4 shadow-lg shadow-slate-200/60 animate-[alertSlideIn_0.35s_ease-out] dark:border-slate-700 dark:bg-slate-900 dark:shadow-none"
          role="alert"
        >
          <div
            className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${alertTone(alert.type)}`}
          >
            <AlertIcon type={alert.type} />
          </div>

          <div className="min-w-0 flex-1">
            <p className="text-sm font-bold text-slate-900 dark:text-white">{alert.title}</p>
            <p className="mt-0.5 whitespace-pre-line text-xs leading-relaxed text-slate-600 dark:text-slate-300">
              {alert.body}
            </p>
            {alert.href ? (
              <Link
                to={alert.href}
                state={alert.hrefState}
                className="mt-2 inline-flex text-xs font-semibold text-[#2563eb] hover:underline dark:text-[#7eb8ff]"
              >
                {alert.actionLabel}
              </Link>
            ) : null}
          </div>

          <button
            type="button"
            onClick={() => onDismiss(alert.id)}
            className="shrink-0 rounded-lg p-1 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-700 dark:hover:text-slate-200"
            aria-label={alert.dismissLabel}
          >
            <IconClose className="h-4 w-4" />
          </button>
        </div>
      ))}
    </div>
  )
}
