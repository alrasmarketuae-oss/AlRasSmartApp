import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { AdminOrderStats } from '../../types/adminOrder'

type OrdersStatsCardsProps = {
  stats: AdminOrderStats | undefined
  isLoading?: boolean
}

function StatTile({
  title,
  value,
  changePercent,
  changeSuffix,
  tone,
}: {
  title: string
  value: string
  changePercent?: number
  changeSuffix?: string
  tone: 'blue' | 'amber' | 'sky' | 'green'
}) {
  const toneClass = {
    blue: 'border-[#dbeafe] bg-[#eff6ff] text-[#2563eb]',
    amber: 'border-[#fef3c7] bg-[#fffbeb] text-[#d97706]',
    sky: 'border-[#e0f2fe] bg-[#f0f9ff] text-[#0284c7]',
    green: 'border-[#dcfce7] bg-[#f0fdf4] text-[#16a34a]',
  }[tone]

  return (
    <div className={`rounded-2xl border px-5 py-4 shadow-sm ${toneClass}`}>
      <p className="text-sm font-semibold opacity-90">{title}</p>
      <p className="mt-2 text-3xl font-bold tracking-tight">{value}</p>
      {changePercent != null ? (
        <p className="mt-2 text-xs font-semibold text-emerald-600">
          {changePercent >= 0 ? '+' : ''}
          {changePercent.toFixed(1)}% {changeSuffix}
        </p>
      ) : null}
    </div>
  )
}

export default function OrdersStatsCards({ stats, isLoading }: OrdersStatsCardsProps) {
  const { t, locale } = useAppPreferences()
  const numberLocale = locale === 'ar' ? 'ar-AE' : 'en-US'

  if (isLoading && !stats) {
    return (
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {Array.from({ length: 4 }).map((_, index) => (
          <div key={index} className="admin-surface-muted h-[108px] animate-pulse rounded-2xl" />
        ))}
      </div>
    )
  }

  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <StatTile
        title={t('orders.stats.totalOrders')}
        value={(stats?.totalOrders ?? 0).toLocaleString(numberLocale)}
        changePercent={stats?.totalOrdersChangePercent}
        changeSuffix={t('orders.stats.vsLastMonth')}
        tone="blue"
      />
      <StatTile
        title={t('orders.stats.ordered')}
        value={(stats?.orderedCount ?? 0).toLocaleString(numberLocale)}
        tone="amber"
      />
      <StatTile
        title={t('orders.stats.shipping')}
        value={(stats?.shippingCount ?? 0).toLocaleString(numberLocale)}
        tone="sky"
      />
      <StatTile
        title={t('orders.stats.delivered')}
        value={(stats?.deliveredCount ?? 0).toLocaleString(numberLocale)}
        tone="green"
      />
    </div>
  )
}
