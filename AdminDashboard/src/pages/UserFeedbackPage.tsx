import { useMemo, useState } from 'react'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import {
  useGetUserFeedbackQuery,
  useUpdateUserFeedbackStatusMutation,
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

export default function UserFeedbackPage() {
  const { t, locale } = useAppPreferences()
  const [page, setPage] = useState(1)
  const [search, setSearch] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [status, setStatus] = useState('Pending')
  const [type, setType] = useState('all')

  const pageSize = 20
  const queryParams = useMemo(
    () => ({
      page,
      pageSize,
      search: appliedSearch || undefined,
      status: status || undefined,
      type: type || undefined,
    }),
    [page, pageSize, appliedSearch, status, type],
  )

  const { data, error, isLoading, isFetching, refetch } =
    useGetUserFeedbackQuery(queryParams)
  const [updateStatus, updateState] = useUpdateUserFeedbackStatusMutation()
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({ isLoading, isFetching })

  const totalPages = Math.max(1, data?.totalPages ?? 1)
  const items = data?.items ?? []

  async function markAs(id: string, next: 'InReview' | 'Resolved' | 'Closed') {
    try {
      await updateStatus({ id, status: next }).unwrap()
    } catch {
      // handled by RTK
    }
  }

  function typeLabel(value: string): string {
    if (value === 'Complaint') return t('userFeedback.typeComplaint')
    if (value === 'Suggestion') return t('userFeedback.typeSuggestion')
    return value
  }

  return (
    <div className="space-y-6">
      <header className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold">{t('userFeedback.title')}</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {t('userFeedback.subtitle')}
          </p>
        </div>
        <button
          type="button"
          className="rounded-xl border border-slate-200 px-3 py-2 text-sm dark:border-slate-700"
          onClick={() => refetch()}
        >
          {t('userFeedback.refresh')}
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
          placeholder={t('userFeedback.searchPlaceholder')}
        />
        <select
          className="admin-input"
          value={type}
          onChange={(e) => {
            setPage(1)
            setType(e.target.value)
          }}
        >
          <option value="all">{t('userFeedback.typeAll')}</option>
          <option value="Complaint">{t('userFeedback.typeComplaint')}</option>
          <option value="Suggestion">{t('userFeedback.typeSuggestion')}</option>
        </select>
        <select
          className="admin-input"
          value={status}
          onChange={(e) => {
            setPage(1)
            setStatus(e.target.value)
          }}
        >
          <option value="Pending">{t('userFeedback.statusPending')}</option>
          <option value="InReview">{t('userFeedback.statusInReview')}</option>
          <option value="Resolved">{t('userFeedback.statusResolved')}</option>
          <option value="Closed">{t('userFeedback.statusClosed')}</option>
          <option value="all">{t('userFeedback.statusAll')}</option>
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
          {getRtkErrorMessage(error, t('userFeedback.loadError'))}
        </p>
      ) : items.length === 0 ? (
        <p className="text-sm text-slate-500">{t('userFeedback.empty')}</p>
      ) : (
        <div className={`admin-card overflow-hidden rounded-2xl ${showBackgroundUpdate ? 'opacity-70' : ''}`}>
          <div className="overflow-x-auto">
            <table className="min-w-full text-left text-sm">
              <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase text-slate-500 dark:border-slate-700 dark:bg-slate-900/40">
                <tr>
                  <th className="px-4 py-3">{t('userFeedback.when')}</th>
                  <th className="px-4 py-3">{t('userFeedback.type')}</th>
                  <th className="px-4 py-3">{t('userFeedback.user')}</th>
                  <th className="px-4 py-3">{t('userFeedback.subject')}</th>
                  <th className="px-4 py-3">{t('userFeedback.message')}</th>
                  <th className="px-4 py-3">{t('userFeedback.status')}</th>
                  <th className="px-4 py-3">{t('userFeedback.actions')}</th>
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
                      <span
                        className={`rounded-full px-2 py-1 text-xs font-semibold ${
                          item.type === 'Suggestion'
                            ? 'bg-sky-100 text-sky-800 dark:bg-sky-950 dark:text-sky-200'
                            : 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-200'
                        }`}
                      >
                        {typeLabel(item.type)}
                      </span>
                      {item.source ? (
                        <div className="mt-1 text-xs text-slate-500">{item.source}</div>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 align-top">
                      <div className="font-semibold admin-text">{item.fullName || '—'}</div>
                      {item.phone ? (
                        <div className="admin-text text-xs" dir="ltr">{item.phone}</div>
                      ) : null}
                      {item.email ? (
                        <div className="text-xs text-slate-500">{item.email}</div>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 align-top max-w-[180px]">
                      <div className="admin-text font-medium break-words">{item.subject}</div>
                      {item.orderReference ? (
                        <div className="mt-1 text-xs text-slate-500">
                          {t('userFeedback.orderRef')}: {item.orderReference}
                        </div>
                      ) : null}
                    </td>
                    <td className="px-4 py-3 align-top max-w-xs">
                      <div className="admin-text whitespace-pre-wrap break-words">
                        {item.message || '—'}
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
                            className="rounded-lg bg-blue-600 px-2.5 py-1.5 text-xs font-semibold text-white"
                            onClick={() => void markAs(item.id, 'InReview')}
                          >
                            {t('userFeedback.markInReview')}
                          </button>
                        ) : null}
                        {item.status !== 'Resolved' && item.status !== 'Closed' ? (
                          <button
                            type="button"
                            disabled={updateState.isLoading}
                            className="rounded-lg bg-emerald-600 px-2.5 py-1.5 text-xs font-semibold text-white"
                            onClick={() => void markAs(item.id, 'Resolved')}
                          >
                            {t('userFeedback.markResolved')}
                          </button>
                        ) : null}
                        {item.status !== 'Closed' ? (
                          <button
                            type="button"
                            disabled={updateState.isLoading}
                            className="rounded-lg bg-slate-700 px-2.5 py-1.5 text-xs font-semibold text-white"
                            onClick={() => void markAs(item.id, 'Closed')}
                          >
                            {t('userFeedback.markClosed')}
                          </button>
                        ) : null}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {totalPages > 1 ? (
        <div className="flex items-center justify-center gap-3">
          <button
            type="button"
            disabled={page <= 1}
            className="rounded-lg border px-3 py-1.5 text-sm disabled:opacity-50"
            onClick={() => setPage((p) => Math.max(1, p - 1))}
          >
            {t('pagination.prev')}
          </button>
          <span className="text-sm text-slate-500">
            {page} / {totalPages}
          </span>
          <button
            type="button"
            disabled={page >= totalPages}
            className="rounded-lg border px-3 py-1.5 text-sm disabled:opacity-50"
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
          >
            {t('pagination.next')}
          </button>
        </div>
      ) : null}
    </div>
  )
}
