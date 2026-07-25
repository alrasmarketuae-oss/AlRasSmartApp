import { useEffect, useMemo, useState, type FormEvent } from 'react'
import NotificationsHistoryTable from '../components/notifications/NotificationsHistoryTable'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import {
  useGetAdminNotificationsQuery,
  useGetUsersQuery,
  useSendAdminNotificationMutation,
} from '../store'
import { queryViewState } from '../store/queryView'
import type { NotificationAudience } from '../types/adminNotification'
import { getRtkErrorMessage } from '../utils/rtkError'

const AUDIENCE_OPTIONS: NotificationAudience[] = [
  'All',
  'Suppliers',
  'Clients',
  'Shipping',
  'SingleUser',
]

export default function NotificationsPage() {
  const { t } = useAppPreferences()
  const [page, setPage] = useState(1)
  const [sendAudience, setSendAudience] = useState<NotificationAudience>('All')
  const [filterAudience, setFilterAudience] = useState<NotificationAudience | ''>('')
  const [targetUserId, setTargetUserId] = useState('')
  const [userSearch, setUserSearch] = useState('')
  const [appliedUserSearch, setAppliedUserSearch] = useState('')
  const [form, setForm] = useState({
    title: '',
    body: '',
    type: 'admin_broadcast',
  })
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const pageSize = 20

  const queryParams = useMemo(
    () => ({
      page,
      pageSize,
      audience: filterAudience || undefined,
    }),
    [page, pageSize, filterAudience],
  )

  const {
    data,
    error,
    isLoading,
    isFetching,
  } = useGetAdminNotificationsQuery(queryParams)
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading,
    isFetching,
  })

  const { data: usersData, isFetching: isSearchingUsers } = useGetUsersQuery(
    {
      page: 1,
      pageSize: 20,
      search: appliedUserSearch || undefined,
    },
    { skip: sendAudience !== 'SingleUser' },
  )

  const [sendNotification, { isLoading: isSending }] = useSendAdminNotificationMutation()

  const totalPages = Math.max(1, Math.ceil((data?.total ?? 0) / pageSize))
  const totalCount = data?.total ?? 0
  const userOptions = usersData?.items ?? []

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setAppliedUserSearch(userSearch.trim())
    }, 350)
    return () => window.clearTimeout(timer)
  }, [userSearch])

  useEffect(() => {
    if (sendAudience !== 'SingleUser') {
      setTargetUserId('')
      setUserSearch('')
      setAppliedUserSearch('')
    }
  }, [sendAudience])

  async function handleSend(event: FormEvent) {
    event.preventDefault()
    setSuccessMessage(null)
    setActionError(null)

    if (!form.title.trim() || !form.body.trim()) {
      setActionError(t('notificationsPage.required'))
      return
    }

    if (sendAudience === 'SingleUser' && !targetUserId) {
      setActionError(t('notificationsPage.targetUserRequired'))
      return
    }

    try {
      await sendNotification({
        audience: sendAudience,
        title: form.title.trim(),
        body: form.body.trim(),
        type: form.type.trim() || 'admin_broadcast',
        targetUserId: sendAudience === 'SingleUser' ? targetUserId : undefined,
      }).unwrap()

      setSuccessMessage(t('notificationsPage.sendSuccess'))
      setForm({ title: '', body: '', type: 'admin_broadcast' })
      setTargetUserId('')
      setUserSearch('')
      setAppliedUserSearch('')
      setPage(1)
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('notificationsPage.sendError')))
    }
  }

  function audienceLabel(value: string, targetUserName?: string | null) {
    if (value === 'Suppliers') return t('notificationsPage.audienceSuppliers')
    if (value === 'Clients') return t('notificationsPage.audienceClients')
    if (value === 'Shipping') return t('notificationsPage.audienceShipping')
    if (value === 'SingleUser') {
      return targetUserName
        ? t('notificationsPage.audienceSingleUserNamed').replace('{name}', targetUserName)
        : t('notificationsPage.audienceSingleUser')
    }
    return t('notificationsPage.audienceAll')
  }

  const selectedUser = userOptions.find((user) => user.id === targetUserId)

  return (
    <div className="space-y-6">
      <header>
        <h1 className="admin-page-title">{t('notificationsPage.title')}</h1>
        <p className="admin-text-subtle mt-1">{t('notificationsPage.subtitle')}</p>
      </header>

      <section className="admin-card space-y-4 p-6">
        <h2 className="text-lg font-semibold">{t('notificationsPage.sendTitle')}</h2>
        <p className="admin-text-subtle text-sm">{t('notificationsPage.autoTranslateHint')}</p>

        {successMessage ? (
          <p className="rounded-lg bg-emerald-600/10 px-4 py-2 text-sm text-emerald-700 dark:text-emerald-300">
            {successMessage}
          </p>
        ) : null}
        {actionError ? (
          <p className="rounded-lg bg-red-600/10 px-4 py-2 text-sm text-red-700 dark:text-red-300">
            {actionError}
          </p>
        ) : null}

        <form className="grid grid-cols-1 gap-4 lg:grid-cols-2" onSubmit={handleSend}>
          <label className="block">
            <span className="admin-text-subtle mb-1 block text-xs font-medium">
              {t('notificationsPage.audience')}
            </span>
            <select
              className="admin-input w-full"
              value={sendAudience}
              onChange={(event) => setSendAudience(event.target.value as NotificationAudience)}
              disabled={isSending}
            >
              {AUDIENCE_OPTIONS.map((option) => (
                <option key={option} value={option}>
                  {audienceLabel(option)}
                </option>
              ))}
            </select>
          </label>

          <label className="block">
            <span className="admin-text-subtle mb-1 block text-xs font-medium">
              {t('notificationsPage.type')}
            </span>
            <input
              type="text"
              className="admin-input w-full"
              value={form.type}
              onChange={(event) => setForm((prev) => ({ ...prev, type: event.target.value }))}
              placeholder="admin_broadcast"
              disabled={isSending}
            />
          </label>

          {sendAudience === 'SingleUser' ? (
            <div className="space-y-3 lg:col-span-2">
              <label className="block">
                <span className="admin-text-subtle mb-1 block text-xs font-medium">
                  {t('notificationsPage.searchUser')}
                </span>
                <input
                  type="search"
                  className="admin-input w-full"
                  value={userSearch}
                  onChange={(event) => setUserSearch(event.target.value)}
                  placeholder={t('notificationsPage.searchUserPlaceholder')}
                  disabled={isSending}
                />
              </label>

              <label className="block">
                <span className="admin-text-subtle mb-1 block text-xs font-medium">
                  {t('notificationsPage.selectUser')}
                </span>
                <select
                  className="admin-input w-full"
                  value={targetUserId}
                  onChange={(event) => setTargetUserId(event.target.value)}
                  disabled={isSending || isSearchingUsers}
                >
                  <option value="">{t('notificationsPage.chooseUser')}</option>
                  {userOptions.map((user) => (
                    <option key={user.id} value={user.id}>
                      {(user.companyName || user.fullName).trim()} — {user.email}
                    </option>
                  ))}
                </select>
              </label>

              {selectedUser ? (
                <p className="admin-text-subtle text-xs">
                  {t('notificationsPage.selectedUser')}: {selectedUser.companyName || selectedUser.fullName} ({selectedUser.email})
                </p>
              ) : null}
            </div>
          ) : null}

          <label className="block lg:col-span-2">
            <span className="admin-text-subtle mb-1 block text-xs font-medium">
              {t('notificationsPage.notificationTitle')}
            </span>
            <input
              type="text"
              className="admin-input w-full"
              value={form.title}
              onChange={(event) => setForm((prev) => ({ ...prev, title: event.target.value }))}
              disabled={isSending}
            />
          </label>

          <label className="block lg:col-span-2">
            <span className="admin-text-subtle mb-1 block text-xs font-medium">
              {t('notificationsPage.notificationBody')}
            </span>
            <textarea
              className="admin-input min-h-28 w-full resize-y"
              value={form.body}
              onChange={(event) => setForm((prev) => ({ ...prev, body: event.target.value }))}
              disabled={isSending}
            />
          </label>

          <div className="lg:col-span-2">
            <button type="submit" className="admin-btn-primary" disabled={isSending}>
              {isSending ? t('notificationsPage.sending') : t('notificationsPage.sendButton')}
            </button>
          </div>
        </form>
      </section>

      <div className="admin-card">
        <div className="admin-border flex flex-wrap items-center justify-between gap-3 border-b px-4 py-4 sm:px-6">
          <div>
            <h2 className="admin-text text-lg font-bold">{t('notificationsPage.historyTitle')}</h2>
            <p className="admin-text-muted mt-1 text-sm">
              {t('notificationsPage.resultsCount').replace('{count}', String(totalCount))}
            </p>
          </div>
          <label className="flex min-w-[200px] flex-col gap-1 text-sm sm:min-w-[240px]">
            <span className="admin-text-subtle text-xs font-medium">
              {t('notificationsPage.filterAudience')}
            </span>
            <select
              className="admin-input h-10 w-full"
              value={filterAudience}
              onChange={(event) => {
                setFilterAudience(event.target.value as NotificationAudience | '')
                setPage(1)
              }}
            >
              <option value="">{t('notificationsPage.audienceAllFilter')}</option>
              {AUDIENCE_OPTIONS.map((option) => (
                <option key={option} value={option}>
                  {audienceLabel(option)}
                </option>
              ))}
            </select>
          </label>
        </div>

        {error ? (
          <div className="admin-alert-error mx-4 mt-4 sm:mx-6">
            {getRtkErrorMessage(error, t('notificationsPage.loadError'))}
          </div>
        ) : null}

        {showInitialLoader ? (
          <div className="flex justify-center py-20">
            <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
          </div>
        ) : (
          <>
            {showBackgroundUpdate ? (
              <p className="admin-text-subtle px-4 pb-2 pt-3 text-center text-xs sm:px-6">
                {t('updating')}
              </p>
            ) : null}

            <NotificationsHistoryTable
              items={data?.items ?? []}
              audienceLabel={audienceLabel}
            />

            {totalPages > 1 ? (
              <div
                dir="ltr"
                className="admin-border flex flex-wrap items-center justify-between gap-3 border-t px-4 py-4 sm:px-6"
              >
                <button
                  type="button"
                  className="admin-btn-ghost"
                  disabled={page <= 1}
                  onClick={() => setPage((prev) => Math.max(1, prev - 1))}
                >
                  {t('previous')}
                </button>
                <span className="admin-text-muted text-sm">
                  {t('pageOf', { page, total: totalPages })}
                </span>
                <button
                  type="button"
                  className="admin-btn-ghost"
                  disabled={page >= totalPages}
                  onClick={() => setPage((prev) => Math.min(totalPages, prev + 1))}
                >
                  {t('next')}
                </button>
              </div>
            ) : null}
          </>
        )}
      </div>
    </div>
  )
}
