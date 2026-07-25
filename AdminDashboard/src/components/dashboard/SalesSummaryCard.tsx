import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { SalesSummary } from '../../types/dashboard'
import { formatDashboardAmount } from '../../utils/formatMoney'

type SalesSummaryCardProps = {
  summary: SalesSummary
}

export default function SalesSummaryCard({ summary }: SalesSummaryCardProps) {
  const { t, locale } = useAppPreferences()
  const total = Math.max(summary.totalSales, 1)
  const monthRatio = Math.min(summary.thisMonth / total, 1)
  const radius = 54
  const stroke = 14
  const circumference = 2 * Math.PI * radius
  const monthArc = circumference * monthRatio
  const restArc = circumference - monthArc

  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-5 shadow-sm dark:border-slate-700">
      <h2 className="admin-text mb-4 text-lg font-bold">
        {t('dashboard.salesSummary')}
      </h2>
      <div className="flex items-center gap-4">
        <svg viewBox="0 0 140 140" className="h-32 w-32 shrink-0" aria-hidden>
          <circle
            cx="70"
            cy="70"
            r={radius}
            fill="none"
            stroke="#EDE9FE"
            strokeWidth={stroke}
          />
          <circle
            cx="70"
            cy="70"
            r={radius}
            fill="none"
            stroke="#8B5CF6"
            strokeWidth={stroke}
            strokeLinecap="round"
            strokeDasharray={`${monthArc} ${restArc}`}
            transform="rotate(-90 70 70)"
          />
          <circle
            cx="70"
            cy="70"
            r={radius}
            fill="none"
            stroke="#3B7FC7"
            strokeWidth={stroke}
            strokeLinecap="round"
            strokeDasharray={`${Math.max(restArc * 0.55, 1)} ${circumference}`}
            strokeDashoffset={-monthArc}
            transform="rotate(-90 70 70)"
            opacity={0.9}
          />
        </svg>
        <ul className="min-w-0 flex-1 space-y-3 text-sm">
          <li className="flex items-start gap-2">
            <span className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full bg-[#3B7FC7]" />
            <div className="min-w-0">
              <p className="admin-text-muted">{t('dashboard.totalSales')}</p>
              <p className="admin-text font-bold">
                {formatDashboardAmount(
                  summary.totalSales,
                  locale,
                  summary.totalSalesFormatted,
                )}
              </p>
            </div>
          </li>
          <li className="flex items-start gap-2">
            <span className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full bg-[#8B5CF6]" />
            <div className="min-w-0">
              <p className="admin-text-muted">{t('dashboard.thisMonth')}</p>
              <p className="admin-text font-bold">
                {formatDashboardAmount(
                  summary.thisMonth,
                  locale,
                  summary.thisMonthFormatted,
                )}
              </p>
            </div>
          </li>
          <li className="flex items-start gap-2">
            <span className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full bg-emerald-500" />
            <div className="min-w-0">
              <p className="admin-text-muted">{t('dashboard.growth')}</p>
              <p
                className={`font-bold ${
                  summary.growthPercent >= 0 ? 'text-emerald-600' : 'text-red-500'
                }`}
              >
                {summary.growthPercent >= 0 ? '+' : ''}
                {summary.growthPercent}%
              </p>
            </div>
          </li>
        </ul>
      </div>
    </div>
  )
}
