import { useMemo, useState } from 'react'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import {
  useGetSupportCallbacksQuery,
  useUpdateSupportCallbackStatusMutation,
} from '../store'
import { queryViewState } from '../store/queryView'
import { getRtkErrorMessage } from '../utils/rtkError'
import { formatRelativeFromSeconds } from '../utils/timeAgo'

function formatUtcStamp(value: string): string {
  if (!value) return '—'
  const normalized = /Z$/i.test(value) || /[+-]\d{2}:\d{2}$/.test(value) ? value : `${value}Z`
  const date = new Date(normalized)
  if (Number.isNaN(date.getTime())) return value
  return date.toISOString().replace('T', ' ').replace(/\.\d{3}Z$/, ' UTC')
}

export default function TechSupportCallbacksPage() {
  const { t, locale } = useAppPreferences()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [status, setStatus] = useState('Pending')

  const pageSize = 20
  const queryParams = useMemo(
    () => ({
      page,
      pageSize,
      search: appliedSearch || undefined,
      status: status || undefined,
    }),
    [page, pageSize, appliedSearch, status],
  )

  const { data, error, isLoading, isFetching, refetch } =
    useGetSupportCallbacksQuery(queryParams)
  const [updateStatus, updateState] = useUpdateSupportCallbackStatusMutation()
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({ isLoading, isFetching })

  const totalPages = Math.max(1, data?.totalPages ?? 1)
  const items = data?.items ?? []

  async function markAs(id: string, next: 'Contacted' | 'Closed') {
    try {
      await updateStatus({ id, status: next }).unwrap()
    } catch {
      // error toast handled by RTK UI if needed
    }
  }

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold">{t('techSupport.title')}</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {t('techSupport.subtitle')}
          </p>
        </div>
        <button
          type="button"
          className="rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
          onClick={() => refetch()}
        >
          {t('techSupport.refresh')}
        </button>
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
          placeholder={t('techSupport.searchPlaceholder')}
        />
        <select
          className="admin-input"
          value={status}
          onChange={(e) => {
            setPage(1)
            setStatus(e.target.value)
          }}
        >
          <option value="Pending">{t('techSupport.statusPending')}</option>
          <option value="Contacted">{t('techSupport.statusContacted')}</option>
          <option value="Closed">{t('techSupport.statusClosed')}</option>
          <option value="all">{t('techSupport.statusAll')}</option>
        </select>
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
        <p className="text-sm text-red-600">
          {getRtkErrorMessage(error, t('techSupport.loadError'))}
        </p>
      ) : items.length === 0 ? (
        <p className="text-sm text-slate-500">{t('techSupport.empty')}</p>
      ) : (
        <div className={`admin-card overflow-hidden rounded-2xl ${showBackgroundUpdate ? 'opacity-70' : ''}`}>
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500 dark:border-slate-700 dark:bg-slate-900/40">
                <tr>
                  <th className="px-4 py-3">{t('techSupport.when')}</th>
                  <th className="px-4 py-3">{t('techSupport.customer')}</th>
                  <th className="px-4 py-3">{t('techSupport.contact')}</th>
                  <th className="px-4 py-3">{t('techSupport.question')}</th>
                  <th className="px-4 py-3">{t('techSupport.status')}</th>
                  <th className="px-4 py-3">{t('techSupport.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item) => (
                  <tr key={item.id} className="border-b border-slate-100 dark:border-slate-800">
                    <td className="px-4 py-3 align-top whitespace-nowrap">
                      <div className="font-medium admin-text">
                        {formatRelativeFromSeconds(item.ageSeconds, locale)}
                      </div>
                      <div className="text-xs text-slate-500">{formatUtcStamp(item.createdAtUtc)}</div>
                    </td>
                    <td className="px-4 py-3 align-top">
                      <div className="font-semibold admin-text">{item.fullName || '—'}</div>
                      {item.userId ? (
                        <div className="text-xs text-slate-500">{item.userId}</div>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 align-top">
                      <div className="admin-text">{item.phone}</div>
                      <div className="text-xs text-slate-500">{item.email}</div>
                    </td>
                    <td className="px-4 py-3 align-top max-w-xs">
                      <div className="admin-text whitespace-pre-wrap break-words">
                        {item.question || '—'}
                      </div>
                    </td>
                    <td className="px-4 py-3 align-top">
                      <span className="rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold dark:bg-slate-800">
                        {item.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 align-top">
                      <div className="flex flex-wrap gap-2">
                        {item.status === 'Pending' ? (
                          <button
                            type="button"
                            disabled={updateState.isLoading}
                            className="rounded-lg bg-emerald-600 px-2.5 py-1.5 text-xs font-semibold text-white"
                            onClick={() => void markAs(item.id, 'Contacted')}
                          >
                            {t('techSupport.markContacted')}
                          </button>
                        ) : null}
                        {item.status !== 'Closed' ? (
                          <button
                            type="button"
                            disabled={updateState.isLoading}
                            className="rounded-lg bg-slate-700 px-2.5 py-1.5 text-xs font-semibold text-white"
                            onClick={() => void markAs(item.id, 'Closed')}
                          >
                            {t('techSupport.markClosed')}
                          </button>
                        ) : null}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="flex items-center justify-between gap-3 border-t border-slate-100 px-4 py-3 dark:border-slate-800">
            <p className="text-xs text-slate-500">
              {t('techSupport.total')}: {data?.totalCount ?? 0}
            </p>
            <div className="flex gap-2">
              <button
                type="button"
                className="rounded-lg border px-3 py-1 text-xs disabled:opacity-40"
                disabled={page <= 1}
                onClick={() => setPage((p) => Math.max(1, p - 1))}
              >
                {t('previous')}
              </button>
              <span className="text-xs text-slate-500">
                {page} / {totalPages}
              </span>
              <button
                type="button"
                className="rounded-lg border px-3 py-1 text-xs disabled:opacity-40"
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
