import { useMemo, useState } from 'react'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGetAdminAuditLogsQuery } from '../store'
import { queryViewState } from '../store/queryView'
import { getRtkErrorMessage } from '../utils/rtkError'

function formatUtcStamp(value: string): string {
  if (!value) return '—'
  const normalized = /Z$/i.test(value) || /[+-]\d{2}:\d{2}$/.test(value) ? value : `${value}Z`
  const date = new Date(normalized)
  if (Number.isNaN(date.getTime())) return value
  return date.toISOString().replace('T', ' ').replace(/\.\d{3}Z$/, ' UTC')
}

function formatAge(seconds: number, locale: string): string {
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)
  if (locale === 'ar') {
    if (seconds < 60) return 'الآن'
    if (minutes < 60) return `منذ ${minutes} دقيقة`
    if (hours < 24) return `منذ ${hours} ساعة`
    return `منذ ${days} يوم`
  }
  if (seconds < 60) return 'Just now'
  if (minutes < 60) return `${minutes} min ago`
  if (hours < 24) return `${hours} hr ago`
  return `${days} day${days === 1 ? '' : 's'} ago`
}

function tryPrettyDetails(raw: string | null): string {
  if (!raw) return ''
  try {
    return JSON.stringify(JSON.parse(raw), null, 2)
  } catch {
    return raw
  }
}

export default function AuditLogsPage() {
  const { t, locale } = useAppPreferences()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [action, setAction] = useState('')
  const [entityType, setEntityType] = useState('')
  const [expandedId, setExpandedId] = useState<string | null>(null)

  const pageSize = 20
  const queryParams = useMemo(
    () => ({
      page,
      pageSize,
      search: appliedSearch || undefined,
      action: action || undefined,
      entityType: entityType || undefined,
    }),
    [page, pageSize, appliedSearch, action, entityType],
  )

  const { data, error, isLoading, isFetching } = useGetAdminAuditLogsQuery(queryParams)
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({ isLoading, isFetching })

  const totalPages = Math.max(1, data?.totalPages ?? 1)
  const items = data?.items ?? []

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold">{t('audit.title')}</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{t('audit.subtitle')}</p>
        </div>
        {data?.serverUtcNow ? (
          <p className="text-xs text-slate-500">
            {t('audit.serverUtc')}: {formatUtcStamp(data.serverUtcNow)}
          </p>
        ) : null}
      </header>

      <div className="admin-card flex flex-wrap gap-3 rounded-2xl p-4">
        <input
          className="admin-input min-w-[200px] flex-1"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              setPage(1)
              setAppliedSearch(search.trim())
            }
          }}
          placeholder={t('audit.searchPlaceholder')}
        />
        <select
          className="admin-input"
          value={entityType}
          onChange={(e) => {
            setPage(1)
            setEntityType(e.target.value)
          }}
        >
          <option value="">{t('audit.allEntities')}</option>
          <option value="Company">Company</option>
          <option value="Product">Product</option>
          <option value="Category">Category</option>
          <option value="Settings">Settings</option>
          <option value="Employee">Employee</option>
          <option value="Order">Order</option>
          <option value="Shipping">Shipping</option>
          <option value="Banner">Banner</option>
        </select>
        <input
          className="admin-input min-w-[180px]"
          value={action}
          onChange={(e) => setAction(e.target.value)}
          onBlur={() => setPage(1)}
          placeholder={t('audit.actionFilter')}
        />
        <button
          type="button"
          className="rounded-xl bg-[#3B7FC7] px-4 py-2 text-sm font-semibold text-white"
          onClick={() => {
            setPage(1)
            setAppliedSearch(search.trim())
          }}
        >
          {t('filter')}
        </button>
      </div>

      {showInitialLoader ? (
        <p className="text-sm text-slate-500">{t('loading')}</p>
      ) : error ? (
        <p className="text-sm text-red-600">{getRtkErrorMessage(error, t('audit.loadError'))}</p>
      ) : items.length === 0 ? (
        <p className="text-sm text-slate-500">{t('audit.empty')}</p>
      ) : (
        <div className={`admin-card overflow-hidden rounded-2xl ${showBackgroundUpdate ? 'opacity-70' : ''}`}>
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500 dark:border-slate-700 dark:bg-slate-900/40">
                <tr>
                  <th className="px-4 py-3">{t('audit.when')}</th>
                  <th className="px-4 py-3">{t('audit.employee')}</th>
                  <th className="px-4 py-3">{t('audit.action')}</th>
                  <th className="px-4 py-3">{t('audit.entity')}</th>
                  <th className="px-4 py-3">{t('audit.summary')}</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item) => {
                  const open = expandedId === item.id
                  return (
                    <tr key={item.id} className="border-b border-slate-100 dark:border-slate-800">
                      <td className="px-4 py-3 align-top whitespace-nowrap">
                        <div className="font-medium admin-text">{formatUtcStamp(item.createdAtUtc)}</div>
                        <div className="text-xs text-slate-500">
                          {formatAge(item.ageSeconds, locale)}
                        </div>
                      </td>
                      <td className="px-4 py-3 align-top">
                        <div className="font-medium admin-text">{item.actorName}</div>
                        <div className="text-xs text-slate-500">{item.actorUserId}</div>
                      </td>
                      <td className="px-4 py-3 align-top">
                        <code className="rounded bg-slate-100 px-1.5 py-0.5 text-xs dark:bg-slate-800">
                          {item.action}
                        </code>
                      </td>
                      <td className="px-4 py-3 align-top">
                        <div>{item.entityType}</div>
                        {item.entityId ? (
                          <div className="text-xs text-slate-500">{item.entityId}</div>
                        ) : null}
                      </td>
                      <td className="px-4 py-3 align-top">
                        <button
                          type="button"
                          className="text-left"
                          onClick={() => setExpandedId(open ? null : item.id)}
                        >
                          <div className="admin-text font-medium">{item.summary}</div>
                          {item.detailsJson ? (
                            <div className="mt-1 text-xs text-[#3B7FC7]">
                              {open ? t('audit.hideDetails') : t('audit.showDetails')}
                            </div>
                          ) : null}
                        </button>
                        {open && item.detailsJson ? (
                          <pre className="mt-2 max-h-56 overflow-auto rounded-xl bg-slate-950/90 p-3 text-xs text-slate-100">
                            {tryPrettyDetails(item.detailsJson)}
                          </pre>
                        ) : null}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          <div className="flex items-center justify-between gap-3 border-t border-slate-200 px-4 py-3 dark:border-slate-700">
            <p className="text-xs text-slate-500">
              {t('audit.total')}: {data?.totalCount ?? 0}
            </p>
            <div className="flex items-center gap-2">
              <button
                type="button"
                className="rounded-lg border px-3 py-1.5 text-sm disabled:opacity-40"
                disabled={page <= 1}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
              >
                {t('previous')}
              </button>
              <span className="text-sm">
                {page} / {totalPages}
              </span>
              <button
                type="button"
                className="rounded-lg border px-3 py-1.5 text-sm disabled:opacity-40"
                disabled={page >= totalPages}
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              >
                {t('next')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
