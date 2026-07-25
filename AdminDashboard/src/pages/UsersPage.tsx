import { useEffect, useMemo, useRef, useState } from 'react'
import { useLocation } from 'react-router-dom'
import UsersFilterBar from '../components/users/UsersFilterBar'
import UsersTable from '../components/users/UsersTable'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGlobalSearchParam } from '../hooks/useGlobalSearchParam'
import { useListPageParam } from '../hooks/useListPageParam'
import { useGetUsersQuery } from '../store'
import { queryViewState } from '../store/queryView'
import { getRtkErrorMessage } from '../utils/rtkError'

export default function UsersPage() {
  const { t } = useAppPreferences()
  const location = useLocation()
  const profileEditsOnly = new URLSearchParams(location.search).get('profileEdits') === '1'
  const { page, setPage } = useListPageParam()
  const [tableSearch, setTableSearch] = useState('')
  const [typeFilter, setTypeFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [joinDate, setJoinDate] = useState('')

  const [appliedFilters, setAppliedFilters] = useState({
    tableSearch: '',
    typeFilter: '',
    statusFilter: '',
    joinDate: '',
  })

  const { urlSearch, setUrlSearch } = useGlobalSearchParam()
  const syncingFromUrlRef = useRef(false)

  const pageSize = 20

  const queryParams = useMemo(() => {
    const statusParam =
      appliedFilters.statusFilter === 'complete'
        ? 'complete'
        : appliedFilters.statusFilter === 'incomplete'
          ? 'incomplete'
          : appliedFilters.statusFilter === 'suspended'
            ? 'suspended'
            : appliedFilters.statusFilter === 'pending'
              ? 'pending'
              : appliedFilters.statusFilter === 'rejected'
                ? 'rejected'
                : undefined

    return {
      page,
      pageSize,
      roleId: appliedFilters.typeFilter
        ? Number(appliedFilters.typeFilter)
        : undefined,
      search: appliedFilters.tableSearch.trim() || undefined,
      status: statusParam,
      joinedFrom: appliedFilters.joinDate || undefined,
      joinedTo: appliedFilters.joinDate || undefined,
    }
  }, [page, pageSize, appliedFilters])

  const { data, error, isLoading, isFetching } = useGetUsersQuery(queryParams)
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading,
    isFetching,
  })

  function applyFilters() {
    setAppliedFilters({
      tableSearch,
      typeFilter,
      statusFilter,
      joinDate,
    })
    setPage(1)
    setUrlSearch(tableSearch)
  }

  useEffect(() => {
    if (urlSearch === appliedFilters.tableSearch && urlSearch === tableSearch) return

    syncingFromUrlRef.current = true
    setTableSearch(urlSearch)
    setAppliedFilters((prev) => ({ ...prev, tableSearch: urlSearch }))
    setPage(1)
  }, [urlSearch])

  useEffect(() => {
    if (syncingFromUrlRef.current) {
      syncingFromUrlRef.current = false
      return
    }

    const timer = window.setTimeout(() => {
      const trimmed = tableSearch.trim()
      if (trimmed === appliedFilters.tableSearch.trim()) return

      setAppliedFilters((prev) => ({ ...prev, tableSearch: trimmed }))
      setPage(1)
      setUrlSearch(trimmed)
    }, 400)

    return () => window.clearTimeout(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps -- debounce search input only
  }, [tableSearch])

  function applyInstantFilter(patch: Partial<typeof appliedFilters>) {
    setAppliedFilters({
      tableSearch,
      typeFilter,
      statusFilter,
      joinDate,
      ...patch,
    })
    setPage(1)
  }

  const users = useMemo(() => {
    const items = data?.items ?? []
    if (!profileEditsOnly) return items
    return items.filter((user) => Boolean(user.hasPendingProfileChanges))
  }, [data?.items, profileEditsOnly])
  const totalPages = data?.totalPages ?? 1

  return (
    <div className="space-y-4">
      <div className="max-w-3xl">
        <h1 className="admin-text text-2xl font-bold">{t('users.title')}</h1>
        <p className="admin-text-muted mt-2 text-sm leading-relaxed">
          {t('users.description')}
        </p>
      </div>

    <div className="admin-card">
      <UsersFilterBar
        tableSearch={tableSearch}
        onTableSearchChange={setTableSearch}
        typeFilter={typeFilter}
        onTypeFilterChange={(value) => {
          setTypeFilter(value)
          applyInstantFilter({ typeFilter: value })
        }}
        statusFilter={statusFilter}
        onStatusFilterChange={(value) => {
          setStatusFilter(value)
          applyInstantFilter({ statusFilter: value })
        }}
        joinDate={joinDate}
        onJoinDateChange={(value) => {
          setJoinDate(value)
          applyInstantFilter({ joinDate: value })
        }}
        onApply={applyFilters}
      />

      {error ? (
        <div className="admin-alert-error mx-6 mb-4">
          {getRtkErrorMessage(error, t('users.loadError'))}
        </div>
      ) : null}

      {showInitialLoader ? (
        <div className="flex justify-center py-24">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
        </div>
      ) : (
        <>
          {showBackgroundUpdate ? (
            <p className="admin-text-subtle px-4 pb-2 text-center text-xs sm:px-6">
              {t('updating')}
            </p>
          ) : null}

          <UsersTable users={users} />

          {totalPages > 1 ? (
            <div
              dir="ltr"
              className="admin-border flex flex-wrap items-center justify-between gap-3 border-t px-4 py-4 sm:px-6"
            >
              <button
                type="button"
                disabled={page <= 1}
                onClick={() => setPage((p) => p - 1)}
                className="admin-btn-ghost"
              >
                {t('previous')}
              </button>
              <span className="admin-text-muted text-sm">
                {t('pageOf', { page, total: totalPages })}
              </span>
              <button
                type="button"
                disabled={page >= totalPages}
                onClick={() => setPage((p) => p + 1)}
                className="admin-btn-ghost"
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
