import type { ReactNode } from 'react'
import MiniSparkline from './MiniSparkline'

type OverviewStatCardProps = {
  title: string
  value: string
  changePercent: number
  accent: 'blue' | 'green' | 'orange' | 'purple'
  icon: ReactNode
  sparkline?: number[]
  changeLabel: string
}

const ACCENT = {
  blue: {
    iconBg: 'bg-[#E8F1FF]',
    iconColor: 'text-[#3B7FC7]',
    spark: '#3B7FC7',
  },
  green: {
    iconBg: 'bg-[#E9F9EF]',
    iconColor: 'text-[#22C55E]',
    spark: '#22C55E',
  },
  orange: {
    iconBg: 'bg-[#FFF1E8]',
    iconColor: 'text-[#F97316]',
    spark: '#F97316',
  },
  purple: {
    iconBg: 'bg-[#F3EAFF]',
    iconColor: 'text-[#8B5CF6]',
    spark: '#8B5CF6',
  },
} as const

export default function OverviewStatCard({
  title,
  value,
  changePercent,
  accent,
  icon,
  sparkline = [],
  changeLabel,
}: OverviewStatCardProps) {
  const theme = ACCENT[accent]
  const isPositive = changePercent >= 0

  return (
    <div className="admin-card rounded-2xl border border-slate-100 p-5 shadow-sm dark:border-slate-700">
      <div className="flex items-start justify-between gap-3">
        <div
          className={`flex h-11 w-11 items-center justify-center rounded-xl ${theme.iconBg} ${theme.iconColor}`}
        >
          {icon}
        </div>
        <MiniSparkline values={sparkline} color={theme.spark} />
      </div>
      <p className="admin-text-muted mt-4 text-sm font-medium">{title}</p>
      <p className="admin-text mt-1 text-3xl font-bold tracking-tight">{value}</p>
      <p
        className={`mt-2 text-sm font-semibold ${
          isPositive ? 'text-emerald-600' : 'text-red-500'
        }`}
      >
        {isPositive ? '+' : ''}
        {changePercent}% {changeLabel}
      </p>
    </div>
  )
}
