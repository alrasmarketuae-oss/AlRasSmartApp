type NavBadgeTone = 'red' | 'green' | 'blue' | 'yellow' | 'amber' | 'sky' | 'slate'

type NavBadgeProps = {
  count: number
  active?: boolean
  tone?: NavBadgeTone
}

const toneClass: Record<NavBadgeTone, string> = {
  red: 'bg-red-300 text-red-900',
  green: 'bg-green-300 text-green-900',
  blue: 'bg-blue-300 text-blue-900',
  yellow: 'bg-yellow-300 text-yellow-900',
  amber: 'bg-amber-300 text-amber-900',
  sky: 'bg-sky-300 text-sky-900',
  slate: 'bg-slate-200 text-slate-700 dark:bg-slate-700 dark:text-slate-100',
}

export default function NavBadge({ count, active = false, tone = 'red' }: NavBadgeProps) {
  if (count <= 0) return null

  const label = count > 99 ? '99+' : String(count)

  return (
    <span
      className={`inline-flex min-h-5 min-w-5 shrink-0 items-center justify-center rounded-full px-1.5 text-[11px] font-bold leading-none shadow-sm ${
        active ? 'keep-white bg-white/25 text-white' : toneClass[tone]
      }`}
      aria-label={label}
    >
      {label}
    </span>
  )
}
