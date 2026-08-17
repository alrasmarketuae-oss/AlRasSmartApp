import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { AdminOrder } from '../../types/adminOrder'
import { formatUtcDateTime } from '../../utils/formatTimeAgo'

type OrderCancellationDetailsProps = {
  order: AdminOrder
}

function roleLabel(
  role: string | null | undefined,
  t: (key: string) => string,
): string | null {
  if (!role) return null
  const normalized = role.trim().toLowerCase()
  if (normalized === 'admin') return t('orders.cancelledByAdmin')
  if (normalized === 'buyer') return t('orders.cancelledByBuyer')
  if (normalized === 'supplier') return t('orders.cancelledBySupplier')
  return role
}

export default function OrderCancellationDetails({ order }: OrderCancellationDetailsProps) {
  const { t, locale } = useAppPreferences()

  if (order.statusId !== 6) {
    return null
  }

  const reason =
    locale === 'ar'
      ? order.cancellationReasonNameAr?.trim() || order.cancellationReasonNameEn?.trim()
      : order.cancellationReasonNameEn?.trim() || order.cancellationReasonNameAr?.trim()
  const cancelledByRole = roleLabel(order.cancelledByRole, t)
  const cancelledByName = order.cancelledByName?.trim()
  const cancelledBy =
    cancelledByName && cancelledByRole
      ? `${cancelledByName} (${cancelledByRole})`
      : cancelledByName || cancelledByRole || '—'

  return (
    <section className="admin-card rounded-2xl border border-red-200/80 bg-red-50/40 px-5 py-4 text-start shadow-sm dark:border-red-900/50 dark:bg-red-950/20">
      <h3 className="text-sm font-bold text-red-800 dark:text-red-300">
        {t('orders.cancellationDetails')}
      </h3>
      <dl className="mt-3 space-y-2 text-sm">
        <div className="flex flex-wrap justify-between gap-2">
          <dt className="font-semibold text-slate-600 dark:text-slate-300">{t('orders.cancelReason')}</dt>
          <dd className="admin-text font-bold">{reason || '—'}</dd>
        </div>
        {order.cancellationNote?.trim() ? (
          <div className="flex flex-wrap justify-between gap-2">
            <dt className="font-semibold text-slate-600 dark:text-slate-300">{t('orders.cancelNote')}</dt>
            <dd className="admin-text max-w-[70%] text-end">{order.cancellationNote}</dd>
          </div>
        ) : null}
        <div className="flex flex-wrap justify-between gap-2">
          <dt className="font-semibold text-slate-600 dark:text-slate-300">{t('orders.cancelledAt')}</dt>
          <dd className="admin-text font-bold">
            {order.cancelledAt ? formatUtcDateTime(order.cancelledAt, locale) : '—'}
          </dd>
        </div>
        <div className="flex flex-wrap justify-between gap-2">
          <dt className="font-semibold text-slate-600 dark:text-slate-300">{t('orders.cancelledBy')}</dt>
          <dd className="admin-text font-bold">{cancelledBy}</dd>
        </div>
      </dl>
    </section>
  )
}
