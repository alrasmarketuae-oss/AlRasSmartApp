import { useMemo, useState } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { MonthlyProfitPoint } from '../../types/dashboard'

type MonthlySalesChartProps = {
  data: MonthlyProfitPoint[]
}

export default function MonthlySalesChart({ data }: MonthlySalesChartProps) {
  const { t, locale } = useAppPreferences()
  const [range, setRange] = useState<'year' | '6m' | '3m'>('year')
  const numberLocale = locale === 'ar' ? 'ar-AE' : 'en-US'

  const points = useMemo(() => {
    if (range === '3m') return data.slice(-3)
    if (range === '6m') return data.slice(-6)
    return data
  }, [data, range])

  const max = Math.max(...points.map((d) => d.value), 1)
  const width = 760
  const height = 280
  const padding = { top: 28, right: 16, bottom: 42, left: 56 }
  const chartW = width - padding.left - padding.right
  const chartH = height - padding.top - padding.bottom
  const barGap = 10
  const barWidth = Math.max(
    18,
    (chartW - barGap * (points.length - 1)) / Math.max(points.length, 1),
  )

  const yTicks = [0, 0.25, 0.5, 0.75, 1]

  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-5 shadow-sm sm:p-6 dark:border-slate-700">
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h2 className="admin-text text-lg font-bold">
          {t('dashboard.monthlySalesOverview')}
        </h2>
        <select
          value={range}
          onChange={(e) => setRange(e.target.value as typeof range)}
          className="admin-input h-9 rounded-lg px-3 text-sm font-medium"
        >
          <option value="year">{t('dashboard.thisYear')}</option>
          <option value="6m">{t('dashboard.last6Months')}</option>
          <option value="3m">{t('dashboard.last3Months')}</option>
        </select>
      </div>

      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="w-full"
        role="img"
        aria-label={t('dashboard.monthlySalesOverview')}
        preserveAspectRatio="xMidYMid meet"
      >
        {yTicks.map((tick) => {
          const y = padding.top + chartH * (1 - tick)
          const label = Math.round(max * tick).toLocaleString(numberLocale)
          return (
            <g key={tick}>
              <line
                x1={padding.left}
                x2={width - padding.right}
                y1={y}
                y2={y}
                stroke="#E2E8F0"
                strokeDasharray={tick === 0 ? undefined : '4 4'}
              />
              <text
                x={padding.left - 10}
                y={y + 4}
                fill="#94A3B8"
                fontSize="11"
                textAnchor="end"
              >
                {label}
              </text>
            </g>
          )
        })}

        {points.map((point, index) => {
          const x = padding.left + index * (barWidth + barGap)
          const barH = (point.value / max) * chartH
          const y = padding.top + chartH - barH
          const showValue = point.value > 0
          return (
            <g key={`${point.month}-${index}`}>
              <rect
                x={x}
                y={y}
                width={barWidth}
                height={Math.max(barH, 2)}
                rx={8}
                fill="#3B7FC7"
                opacity={point.value > 0 ? 1 : 0.25}
              />
              {showValue ? (
                <text
                  x={x + barWidth / 2}
                  y={y - 8}
                  textAnchor="middle"
                  fill="#3B7FC7"
                  fontSize="10"
                  fontWeight="700"
                >
                  {Math.round(point.value).toLocaleString(numberLocale)}
                </text>
              ) : null}
              <text
                x={x + barWidth / 2}
                y={height - 14}
                textAnchor="middle"
                fill="#64748B"
                fontSize="11"
              >
                {locale === 'ar' ? point.monthAr : point.month}
              </text>
            </g>
          )
        })}
      </svg>
    </div>
  )
}
