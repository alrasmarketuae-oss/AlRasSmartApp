import type { ReactNode } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'

export type ReqsOffersStats = {
  totalRequests: number
  newRequests: number
  awaitingApproval: number
  received: number
  sentOffers: number
  totalValueLabel: string
}

type ReqsOffersStatsCardsProps = {
  stats: ReqsOffersStats
  isLoading?: boolean
}

function StatCard({
  title,
  value,
  hint,
  icon,
  iconClass,
}: {
  title: string
  value: string
  hint?: string
  icon: ReactNode
  iconClass: string
}) {
  return (
    <div className="admin-card flex items-center gap-3 rounded-2xl px-4 py-3.5 shadow-sm">
      <div className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${iconClass}`}>
        {icon}
      </div>
      <div className="min-w-0 text-start">
        <p className="admin-text-subtle text-[11px] font-semibold">{title}</p>
        <p className="admin-text mt-0.5 truncate text-lg font-bold tracking-tight">{value}</p>
        {hint ? <p className="admin-text-muted mt-0.5 text-[10px]">{hint}</p> : null}
      </div>
    </div>
  )
}

export default function ReqsOffersStatsCards({ stats, isLoading }: ReqsOffersStatsCardsProps) {
  const { t, locale } = useAppPreferences()
  const numberLocale = locale === 'ar' ? 'ar-AE' : 'en-US'

  if (isLoading) {
    return (
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="admin-surface-muted h-[76px] animate-pulse rounded-2xl" />
        ))}
      </div>
    )
  }

  const fmt = (n: number) => n.toLocaleString(numberLocale)

  return (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
      <StatCard
        title={t('reqsOffers.stats.totalRequests')}
        value={`${fmt(stats.totalRequests)} ${t('reqsOffers.stats.requestUnit')}`}
        iconClass="bg-[#eff6ff] text-[#2563eb]"
        icon={
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 10.5V6a3.75 3.75 0 1 0-7.5 0v4.5m11.356-1.993 1.263 12c.07.665-.45 1.243-1.119 1.243H4.25a1.125 1.125 0 0 1-1.12-1.243l1.264-12A1.125 1.125 0 0 1 5.513 7.5h12.974c.576 0 1.059.435 1.119 1.007ZM8.625 10.5a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm7.5 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" />
          </svg>
        }
      />
      <StatCard
        title={t('reqsOffers.stats.newRequests')}
        value={`${fmt(stats.newRequests)} ${t('reqsOffers.stats.requestUnit')}`}
        iconClass="bg-[#fff7ed] text-[#ea580c]"
        icon={
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0H21M3.375 14.25h17.25m0 0V9.375c0-.621-.504-1.125-1.125-1.125H4.5A1.125 1.125 0 0 0 3.375 9.375v4.875Z" />
          </svg>
        }
      />
      <StatCard
        title={t('reqsOffers.stats.awaitingApproval')}
        value={`${fmt(stats.awaitingApproval)} ${t('reqsOffers.stats.requestUnit')}`}
        iconClass="bg-[#e0f2fe] text-[#0284c7]"
        icon={
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
          </svg>
        }
      />
      <StatCard
        title={t('reqsOffers.stats.received')}
        value={`${fmt(stats.received)} ${t('reqsOffers.stats.requestUnit')}`}
        iconClass="bg-[#ecfdf5] text-[#059669]"
        icon={
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
          </svg>
        }
      />
      <StatCard
        title={t('reqsOffers.stats.sentOffers')}
        value={`${fmt(stats.sentOffers)} ${t('reqsOffers.stats.offerUnit')}`}
        iconClass="bg-[#f5f3ff] text-[#7c3aed]"
        icon={
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9.568 3H5.25A2.25 2.25 0 0 0 3 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 0 0 5.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 0 0 9.568 3Z" />
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 6h.008v.008H6V6Z" />
          </svg>
        }
      />
      <StatCard
        title={t('reqsOffers.stats.totalValue')}
        value={stats.totalValueLabel}
        iconClass="bg-[#ecfdf5] text-[#16a34a]"
        icon={
          <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v12m-3-2.818.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
          </svg>
        }
      />
    </div>
  )
}
