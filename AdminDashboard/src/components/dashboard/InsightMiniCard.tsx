import type { ReactNode } from 'react'

type InsightMiniCardProps = {
  title: string
  value: string
  icon: ReactNode
  iconClassName: string
}

export default function InsightMiniCard({
  title,
  value,
  icon,
  iconClassName,
}: InsightMiniCardProps) {
  return (
    <div className="admin-card flex items-center gap-3 rounded-2xl border border-slate-100 p-4 shadow-sm dark:border-slate-700">
      <div
        className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl ${iconClassName}`}
      >
        {icon}
      </div>
      <div className="min-w-0">
        <p className="admin-text-muted text-xs font-medium">{title}</p>
        <p className="admin-text mt-0.5 text-lg font-bold tracking-tight">{value}</p>
      </div>
    </div>
  )
}
