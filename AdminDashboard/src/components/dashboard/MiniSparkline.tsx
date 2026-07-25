type MiniSparklineProps = {
  values: number[]
  color: string
  className?: string
}

export default function MiniSparkline({
  values,
  color,
  className = '',
}: MiniSparklineProps) {
  const series = values.length > 0 ? values : [0, 0, 0, 0]
  const max = Math.max(...series, 1)
  const min = Math.min(...series, 0)
  const range = Math.max(max - min, 1)
  const width = 88
  const height = 36
  const pad = 2

  const points = series.map((value, index) => {
    const x = pad + (index / Math.max(series.length - 1, 1)) * (width - pad * 2)
    const y = height - pad - ((value - min) / range) * (height - pad * 2)
    return `${x},${y}`
  })

  return (
    <svg
      viewBox={`0 0 ${width} ${height}`}
      className={`h-9 w-[5.5rem] shrink-0 ${className}`}
      aria-hidden
    >
      <polyline
        fill="none"
        stroke={color}
        strokeWidth="2.2"
        strokeLinecap="round"
        strokeLinejoin="round"
        points={points.join(' ')}
      />
    </svg>
  )
}
