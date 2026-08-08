import { useMemo, useState } from 'react'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGetMissedProductSearchesQuery } from '../store'
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

export default function MissedProductSearchesPage() {
  const { t, locale } = useAppPreferences()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')

  const pageSize = 20
  const queryParams = useMemo(
    () => ({
      page,
      pageSize,
      search: appliedSearch || undefined,
    }),
    [page, pageSize, appliedSearch],
  )

  const { data, error, isLoading, isFetching } = useGetMissedProductSearchesQuery(queryParams)
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({ isLoading, isFetching })

  const totalPages = Math.max(1, data?.totalPages ?? 1)
  const items = data?.items ?? []

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold">{t('missedSearches.title')}</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {t('missedSearches.subtitle')}
          </p>
        </div>
        {data?.serverUtcNow ? (
          <p className="text-xs text-slate-500">
            {t('missedSearches.serverUtc')}: {formatUtcStamp(data.serverUtcNow)}
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
          placeholder={t('missedSearches.searchPlaceholder')}
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
        <p className="text-sm text-red-600">
          {getRtkErrorMessage(error, t('missedSearches.loadError'))}
        </p>
      ) : items.length === 0 ? (
        <p className="text-sm text-slate-500">{t('missedSearches.empty')}</p>
      ) : (
        <div className={`admin-card overflow-hidden rounded-2xl ${showBackgroundUpdate ? 'opacity-70' : ''}`}>
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500 dark:border-slate-700 dark:bg-slate-900/40">
                <tr>
                  <th className="px-4 py-3">{t('missedSearches.when')}</th>
                  <th className="px-4 py-3">{t('missedSearches.query')}</th>
                  <th className="px-4 py-3">{t('missedSearches.customer')}</th>
                  <th className="px-4 py-3">{t('missedSearches.contact')}</th>
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
                      <div className="font-semibold admin-text">{item.queryText}</div>
                      {item.notes ? (
                        <div className="mt-1 text-xs text-slate-500">{item.notes}</div>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 align-top">
                      <div className="font-medium admin-text">
                        {item.userDisplayName || t('missedSearches.guest')}
                      </div>
                      {item.userId ? (
                        <div className="text-xs text-slate-500">{item.userId}</div>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 align-top">
                      {item.userEmail ? <div>{item.userEmail}</div> : null}
                      {item.userPhone ? (
                        <div className="text-xs text-slate-500">{item.userPhone}</div>
                      ) : null}
                      {!item.userEmail && !item.userPhone ? (
                        <span className="text-slate-400">—</span>
                      ) : null}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex items-center justify-between gap-3 border-t border-slate-200 px-4 py-3 dark:border-slate-700">
            <p className="text-xs text-slate-500">
              {t('missedSearches.total')}: {data?.totalCount ?? 0}
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
