import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { MonthlyProfitPoint } from '../../types/dashboard'

type ProfitsChartProps = {
  data: MonthlyProfitPoint[]
}

export default function ProfitsChart({ data }: ProfitsChartProps) {
  const { t, locale, isDark } = useAppPreferences()
  const numberLocale = locale === 'ar' ? 'ar-AE' : 'en-US'

  const gridColor = isDark ? '#334155' : '#f1f5f9'
  const labelColor = isDark ? '#94a3b8' : '#94a3b8'
  const monthColor = isDark ? '#94a3b8' : '#64748b'
  const dotFill = isDark ? '#1e293b' : '#ffffff'

  const max = Math.max(...data.map((d) => d.value), 1)
  const width = 900
  const height = 260
  const padding = { top: 24, right: 20, bottom: 40, left: 48 }
  const chartW = width - padding.left - padding.right
  const chartH = height - padding.top - padding.bottom

  const points = data.map((d, i) => {
    const x = padding.left + (i / Math.max(data.length - 1, 1)) * chartW
    const y = padding.top + chartH - (d.value / max) * chartH
    return { x, y, ...d }
  })

  const linePath = points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${p.x} ${p.y}`).join(' ')
  const areaPath = `${linePath} L ${points[points.length - 1]?.x ?? padding.left} ${padding.top + chartH} L ${points[0]?.x ?? padding.left} ${padding.top + chartH} Z`

  const yTicks = [0, 0.25, 0.5, 0.75, 1]

  return (
    <div className="admin-card p-6">
      <h2 className="admin-text mb-5 text-right text-lg font-bold">
        {t('dashboard.monthlyProfits')}
      </h2>
      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="w-full"
        role="img"
        aria-label={t('dashboard.monthlyProfits')}
        preserveAspectRatio="xMidYMid meet"
      >
        <defs>
          <linearGradient id="profitGradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#3b82f6" stopOpacity={isDark ? 0.35 : 0.4} />
            <stop offset="100%" stopColor="#3b82f6" stopOpacity={isDark ? 0.02 : 0.03} />
          </linearGradient>
        </defs>

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
                stroke={gridColor}
              />
              <text
                x={padding.left - 8}
                y={y + 4}
                fill={labelColor}
                fontSize="11"
                textAnchor="end"
              >
                {label}
              </text>
            </g>
          )
        })}

        <path d={areaPath} fill="url(#profitGradient)" />
        <path
          d={linePath}
          fill="none"
          stroke="#2563eb"
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {points.map((p) => (
          <g key={`${p.month}-${p.monthAr}`}>
            <circle cx={p.x} cy={p.y} r="5" fill={dotFill} stroke="#2563eb" strokeWidth="2.5" />
            <text
              x={p.x}
              y={height - 12}
              textAnchor="middle"
              fill={monthColor}
              fontSize="11"
              fontFamily="Cairo, sans-serif"
            >
              {locale === 'ar' ? p.monthAr : p.month}
            </text>
          </g>
        ))}
      </svg>
    </div>
  )
}
