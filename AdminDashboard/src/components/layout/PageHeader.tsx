import type { ReactNode } from 'react'

type PageHeaderProps = {
  eyebrow: string
  title: string
  description?: string
  icon: (props: { className?: string }) => ReactNode
}

export default function PageHeader({
  eyebrow,
  title,
  description,
  icon: Icon,
}: PageHeaderProps) {
  return (
    <header className="admin-card relative overflow-hidden px-5 py-6 sm:px-8 sm:py-8">
      <div
        className="pointer-events-none absolute inset-y-0 start-0 w-1.5 bg-gradient-to-b from-[#3B7FC7] to-[#619D51]"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none absolute -end-16 -top-16 h-40 w-40 rounded-full bg-[#3B7FC7]/8 blur-2xl dark:bg-[#3B7FC7]/15"
        aria-hidden="true"
      />
      <div className="relative flex items-center gap-4 sm:gap-5">
        <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-[#3B7FC7]/15 to-[#619D51]/20 text-[#3B7FC7] ring-1 ring-[#3B7FC7]/15 sm:h-16 sm:w-16">
          <Icon className="h-7 w-7 sm:h-8 sm:w-8" />
        </span>
        <div className="min-w-0 text-start">
          <p className="text-[11px] font-bold uppercase tracking-[0.2em] text-[#3B7FC7]">
            {eyebrow}
          </p>
          <h1 className="admin-text mt-1 text-3xl font-extrabold tracking-tight sm:text-4xl">
            {title}
          </h1>
          {description ? (
            <p className="admin-text-muted mt-1.5 max-w-2xl text-sm leading-relaxed">
              {description}
            </p>
          ) : null}
        </div>
      </div>
    </header>
  )
}
