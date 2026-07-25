import type { ReactNode } from 'react'

type DetailSectionCardProps = {
  title: string
  accent?: 'blue' | 'amber' | 'green' | 'slate'
  children: ReactNode
  headerExtra?: ReactNode
}

const accentClasses: Record<NonNullable<DetailSectionCardProps['accent']>, string> = {
  blue: 'border-[#3B7FC7]',
  amber: 'border-[#e8a838]',
  green: 'border-[#619D51]',
  slate: 'border-slate-400',
}

export function DetailSectionCard({
  title,
  accent = 'blue',
  children,
  headerExtra,
}: DetailSectionCardProps) {
  return (
    <section className="admin-card overflow-hidden rounded-2xl border shadow-sm">
      <div
        className={`admin-border admin-text flex items-center justify-between gap-3 border-s-4 ${accentClasses[accent]} bg-slate-50/80 px-4 py-3 dark:bg-slate-900/50`}
      >
        <h4 className="text-sm font-bold">{title}</h4>
        {headerExtra}
      </div>
      <div className="p-4 sm:p-5">{children}</div>
    </section>
  )
}

export function DetailField({
  label,
  value,
  className = '',
}: {
  label: string
  value: ReactNode
  className?: string
}) {
  return (
    <div className={`text-start ${className}`}>
      <p className="admin-text-subtle text-xs font-medium">{label}</p>
      <p className="admin-text mt-1 text-sm font-semibold">{value}</p>
    </div>
  )
}

export function DetailStatGrid({ children }: { children: ReactNode }) {
  return <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">{children}</div>
}

export function DetailStatTile({
  label,
  value,
  hint,
}: {
  label: string
  value: ReactNode
  hint?: string
}) {
  return (
    <div
      className={`admin-surface-muted rounded-xl px-3 py-3 text-start ${hint ? 'cursor-help' : ''}`}
      title={hint}
    >
      <p className="admin-text-subtle flex items-center gap-1 text-xs font-medium">
        <span>{label}</span>
        {hint ? (
          <span className="admin-text-subtle inline-flex h-4 w-4 shrink-0 items-center justify-center rounded-full border border-current text-[10px] leading-none opacity-70">
            ?
          </span>
        ) : null}
      </p>
      <p className="admin-text mt-1 text-sm font-bold">{value}</p>
    </div>
  )
}
