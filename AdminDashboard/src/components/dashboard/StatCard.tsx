type StatCardProps = {
  title: string
  value: string
  changePercent: number
  iconSrc: string
  iconAlt?: string
}

export default function StatCard({
  title,
  value,
  changePercent,
  iconSrc,
  iconAlt = '',
}: StatCardProps) {
  const isPositive = changePercent >= 0

  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-5 shadow-sm dark:border-slate-300">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0 flex-1 text-right">
          <p className="admin-text-muted text-sm font-medium">{title}</p>
          <p className="admin-text mt-2 text-3xl font-bold tracking-tight">
            {value}
          </p>
          <p
            className={`mt-2 inline-flex items-center gap-1 text-sm font-semibold ${
              isPositive ? 'text-emerald-600' : 'text-red-500'
            }`}
          >
            <span aria-hidden>{isPositive ? '↗' : '↘'}</span>
            <span>
              {isPositive ? '+' : ''}
              {changePercent}%
            </span>
          </p>
        </div>
        <img
          src={iconSrc}
          alt={iconAlt}
          className="h-14 w-14 shrink-0 object-contain"
        />
      </div>
    </div>
  )
}
