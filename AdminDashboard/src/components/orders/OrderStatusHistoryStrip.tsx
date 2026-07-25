import type { AdminOrderStatusHistory } from '../../types/adminOrder'
import { useAppPreferences } from '../../context/AppPreferencesProvider'

type OrderStatusHistoryStripProps = {
  entries: AdminOrderStatusHistory[]
  locale: 'ar' | 'en'
}

function formatStripDate(value: string, locale: 'ar' | 'en') {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-US', {
    day: '2-digit',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export default function OrderStatusHistoryStrip({
  entries,
  locale,
}: OrderStatusHistoryStripProps) {
  const { t } = useAppPreferences()
  if (entries.length === 0) return null

  const isRtl = locale === 'ar'
  const lastIndex = entries.length - 1

  return (
    <section className="print:hidden">
      <div className="mb-2.5 flex items-center gap-2">
        <span className="flex h-6 w-6 items-center justify-center rounded-lg bg-[#EFF6FF] text-[#2563eb]">
          <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"
            />
          </svg>
        </span>
        <p className="admin-text text-xs font-bold">{t('orders.statusHistoryTitle')}</p>
      </div>

      <div className="overflow-x-auto pb-1">
        <ol
          className={`flex min-w-max items-start ${isRtl ? 'flex-row-reverse' : ''}`}
          aria-label={t('orders.statusHistoryTitle')}
        >
          {entries.map((entry, index) => {
            const label =
              locale === 'ar'
                ? entry.statusNameAr.trim() || entry.statusNameEn
                : entry.statusNameEn.trim() || entry.statusNameAr
            const isLatest = index === lastIndex
            const isPast = index < lastIndex

            return (
              <li
                key={entry.id || `${entry.createdAtUtc}-${index}`}
                className="relative flex w-[10rem] shrink-0 flex-col items-center px-1.5"
              >
                {index < lastIndex ? (
                  <span
                    className={`absolute top-[13px] h-[3px] w-[calc(100%-2rem)] rounded-full bg-[#93C5FD] ${
                      isRtl ? 'right-[calc(50%+1rem)]' : 'left-[calc(50%+1rem)]'
                    }`}
                    aria-hidden
                  />
                ) : null}

                <span
                  className={`relative z-[1] flex h-7 w-7 items-center justify-center rounded-full text-[11px] font-bold shadow-sm ring-4 ring-white dark:ring-slate-900 ${
                    isLatest
                      ? 'bg-[#2563eb] text-white'
                      : isPast
                        ? 'bg-emerald-500 text-white'
                        : 'bg-slate-200 text-slate-600 dark:bg-slate-700 dark:text-slate-200'
                  }`}
                >
                  {isPast ? (
                    <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={3}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                    </svg>
                  ) : isLatest ? (
                    <span className="h-2 w-2 rounded-full bg-white" />
                  ) : (
                    index + 1
                  )}
                </span>

                <p
                  className={`mt-2.5 max-w-[9rem] text-center text-[11px] leading-snug ${
                    isLatest
                      ? 'font-bold text-[#1d4ed8] dark:text-sky-300'
                      : 'font-semibold text-slate-700 dark:text-slate-200'
                  }`}
                >
                  {label}
                </p>
                <p className="mt-1 text-center text-[10px] leading-tight text-slate-500 dark:text-slate-400">
                  {formatStripDate(entry.createdAtUtc, locale)}
                </p>
              </li>
            )
          })}
        </ol>
      </div>
    </section>
  )
}
