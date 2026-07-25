import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { AdminProductStats } from '../../types/adminProduct'

type AdsStatsCardsProps = {
  stats: AdminProductStats | undefined
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
  tone: 'blue' | 'rose' | 'green' | 'amber'
}) {
  const toneClass = {
    blue: 'border-[#dbeafe] bg-[#eff6ff] text-[#2563eb]',
    rose: 'border-[#ffe4e6] bg-[#fff1f2] text-[#e11d48]',
    green: 'border-[#dcfce7] bg-[#f0fdf4] text-[#16a34a]',
    amber: 'border-[#fef3c7] bg-[#fffbeb] text-[#d97706]',
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

export default function AdsStatsCards({ stats, isLoading }: AdsStatsCardsProps) {
  const { t, locale } = useAppPreferences()
  const numberLocale = locale === 'ar' ? 'ar-AE' : 'en-US'

  const total = stats?.totalAds ?? 0
  const offers = stats?.offersCount ?? 0
  const retail = stats?.retailCount ?? 0
  const booking = stats?.bookingCount ?? 0
  const change = stats?.totalAdsChangePercent

  if (isLoading && !stats) {
    return (
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {Array.from({ length: 4 }).map((_, index) => (
          <div
            key={index}
            className="admin-surface-muted h-[108px] animate-pulse rounded-2xl"
          />
        ))}
      </div>
    )
  }

  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <StatTile
        title={t('ads.stats.totalAds')}
        value={total.toLocaleString(numberLocale)}
        changePercent={change}
        changeSuffix={t('ads.stats.vsLastMonth')}
        tone="blue"
      />
      <StatTile
        title={t('ads.stats.offers')}
        value={offers.toLocaleString(numberLocale)}
        tone="rose"
      />
      <StatTile
        title={t('ads.stats.retail')}
        value={retail.toLocaleString(numberLocale)}
        tone="green"
      />
      <StatTile
        title={t('ads.stats.booking')}
        value={booking.toLocaleString(numberLocale)}
        tone="amber"
      />
    </div>
  )
}
