import { Link } from 'react-router-dom'
import NavBadge from './NavBadge'

export type ChannelTabItem = {
  id: string
  label: string
  to: string
  count?: number
}

type ChannelTabsProps = {
  items: ChannelTabItem[]
  activeId: string
  accent?: 'ads' | 'orders'
}

export default function ChannelTabs({
  items,
  activeId,
  accent = 'ads',
}: ChannelTabsProps) {
  const activeClass =
    accent === 'orders'
      ? 'keep-white bg-emerald-600 text-white shadow-sm shadow-emerald-600/20'
      : 'keep-white bg-indigo-600 text-white shadow-sm shadow-indigo-600/20'
  const idleClass =
    accent === 'orders'
      ? 'text-emerald-800 hover:bg-emerald-50 dark:text-emerald-200 dark:hover:bg-emerald-950/40'
      : 'text-indigo-800 hover:bg-indigo-50 dark:text-indigo-200 dark:hover:bg-indigo-950/40'
  const shellClass =
    accent === 'orders'
      ? 'bg-emerald-50/80 ring-1 ring-emerald-100 dark:bg-emerald-950/30 dark:ring-emerald-900/60'
      : 'bg-indigo-50/80 ring-1 ring-indigo-100 dark:bg-indigo-950/30 dark:ring-indigo-900/60'

  return (
    <div className={`overflow-x-auto rounded-2xl p-1.5 ${shellClass}`}>
      <div className="flex min-w-max items-center gap-1">
        {items.map((item) => {
          const active = item.id === activeId
          return (
            <Link
              key={item.id}
              to={item.to}
              aria-current={active ? 'page' : undefined}
              className={`inline-flex h-10 items-center gap-1.5 rounded-xl px-3.5 text-sm font-bold transition-colors sm:px-4 ${
                active ? activeClass : idleClass
              }`}
            >
              {item.count != null && item.count > 0 ? (
                <NavBadge
                  count={item.count}
                  active={active}
                  tone={accent === 'orders' ? 'green' : 'blue'}
                />
              ) : null}
              <span className="whitespace-nowrap">{item.label}</span>
            </Link>
          )
        })}
      </div>
    </div>
  )
}
