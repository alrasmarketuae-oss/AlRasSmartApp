type MonitoringLineChartProps = {
  title: string
  points: Array<{ t: string; v: number }>
  color: string
  formatValue: (value: number) => string
  emptyLabel: string
}

export default function MonitoringLineChart({
  title,
  points,
  color,
  formatValue,
  emptyLabel,
}: MonitoringLineChartProps) {
  const width = 640
  const height = 220
  const padding = { top: 16, right: 16, bottom: 28, left: 56 }
  const chartW = width - padding.left - padding.right
  const chartH = height - padding.top - padding.bottom
  const values = points.map((p) => p.v)
  const max = Math.max(...values, 0.0001)
  const min = 0
  const range = Math.max(max - min, 0.0001)

  const polyline = points
    .map((point, index) => {
      const x =
        padding.left + (index / Math.max(points.length - 1, 1)) * chartW
      const y = padding.top + chartH - ((point.v - min) / range) * chartH
      return `${x},${y}`
    })
    .join(' ')

  const yTicks = [0, 0.5, 1]

  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-5 shadow-sm dark:border-slate-700">
      <h2 className="admin-text mb-3 text-sm font-bold">{title}</h2>
      {points.length < 2 ? (
        <p className="admin-text-muted py-10 text-center text-sm">{emptyLabel}</p>
      ) : (
        <svg
          viewBox={`0 0 ${width} ${height}`}
          className="w-full"
          role="img"
          aria-label={title}
          preserveAspectRatio="xMidYMid meet"
        >
          {yTicks.map((tick) => {
            const y = padding.top + chartH * (1 - tick)
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
                  x={padding.left - 8}
                  y={y + 4}
                  fill="#94A3B8"
                  fontSize="11"
                  textAnchor="end"
                >
                  {formatValue(max * tick)}
                </text>
              </g>
            )
          })}
          <polyline
            fill="none"
            stroke={color}
            strokeWidth="2.4"
            strokeLinecap="round"
            strokeLinejoin="round"
            points={polyline}
          />
        </svg>
      )}
    </div>
  )
}
