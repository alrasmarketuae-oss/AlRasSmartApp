import { useEffect, useMemo, useState } from 'react'
import OrdersFilterBar from '../components/orders/OrdersFilterBar'
import OrdersStatsCards from '../components/orders/OrdersStatsCards'
import OrdersTable from '../components/orders/OrdersTable'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGlobalSearchParam } from '../hooks/useGlobalSearchParam'
import { useListPageParam } from '../hooks/useListPageParam'
import {
  useGetAdminOrderStatsQuery,
  useGetAdminOrdersQuery,
} from '../store'
import { queryViewState } from '../store/queryView'
import type { AdminOrdersFilters } from '../types/adminOrder'
import type { OrderChannel } from '../utils/orderChannel'
import { getRtkErrorMessage } from '../utils/rtkError'

export type { OrderChannel }

type AppliedFilters = {
  search: string
  statusId: string
  createdOn: string
}

const defaultFilters: AppliedFilters = {
  search: '',
  statusId: '',
  createdOn: '',
}

const channelTitleKey: Record<OrderChannel, string> = {
  retail: 'nav.ordersRetail',
  booking: 'nav.ordersBooking',
  offers: 'nav.ordersOffersType',
  categories: 'nav.ordersCategories',
}

type OrdersPageProps = {
  channel: OrderChannel
}

export default function OrdersPage({ channel }: OrdersPageProps) {
  const { t } = useAppPreferences()
  const { page, setPage } = useListPageParam()
  const [search, setSearch] = useState('')
  const [statusId, setStatusId] = useState('')
  const [createdOn, setCreatedOn] = useState('')
  const [appliedFilters, setAppliedFilters] = useState<AppliedFilters>(defaultFilters)

  const { urlSearch, setUrlSearch } = useGlobalSearchParam()

  const [successMessage] = useState<string | null>(null)
  const [actionError] = useState<string | null>(null)

  const pageSize = 20

  const { data: stats, isLoading: statsLoading } = useGetAdminOrderStatsQuery()

  const queryParams = useMemo((): AdminOrdersFilters => {
    const date = appliedFilters.createdOn.trim()
    return {
      page,
      pageSize,
      orderChannel: channel,
      statusId: appliedFilters.statusId ? Number(appliedFilters.statusId) : undefined,
      search: appliedFilters.search.trim() || undefined,
      createdFrom: date || undefined,
      createdTo: date || undefined,
    }
  }, [page, pageSize, appliedFilters, channel])

  const {
    data: ordersData,
    error: ordersError,
    isLoading,
    isFetching,
  } = useGetAdminOrdersQuery(queryParams)
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading,
    isFetching,
  })

  function commitFilters(next: AppliedFilters) {
    setAppliedFilters(next)
    setPage(1)
  }

  function applyInstantFilter(patch: Partial<AppliedFilters>) {
    const next = {
      search,
      statusId,
      createdOn,
      ...patch,
    }
    if (patch.search !== undefined) {
      setSearch(patch.search)
    }
    if (patch.statusId !== undefined) {
      setStatusId(patch.statusId)
    }
    if (patch.createdOn !== undefined) {
      setCreatedOn(patch.createdOn)
    }
    commitFilters(next)
  }

  useEffect(() => {
    if (urlSearch === appliedFilters.search && urlSearch === search) return
    setSearch(urlSearch)
    commitFilters({
      search: urlSearch,
      statusId,
      createdOn,
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [urlSearch])

  useEffect(() => {
    const timer = window.setTimeout(() => {
      const trimmed = search.trim()
      if (trimmed === appliedFilters.search.trim()) return
      commitFilters({ search: trimmed, statusId, createdOn })
      setUrlSearch(trimmed)
    }, 400)
    return () => window.clearTimeout(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search])

  const orders = useMemo(() => {
    const items = ordersData?.items ?? []
    return [...items].sort((a, b) => {
      const aTime = Date.parse(a.createdAt) || 0
      const bTime = Date.parse(b.createdAt) || 0
      if (bTime !== aTime) return bTime - aTime
      return b.id - a.id
    })
  }, [ordersData?.items])
  const totalPages = ordersData?.totalPages ?? 1

  useEffect(() => {
    window.document.querySelector('main')?.scrollTo({ top: 0 })
  }, [page])

  return (
    <div className="space-y-5">
      <div>
        <h1 className="admin-text text-2xl font-bold tracking-tight">
          {t(channelTitleKey[channel])}
        </h1>
      </div>

      <OrdersStatsCards stats={stats} isLoading={statsLoading} />

      <div className="admin-card overflow-hidden">
        <OrdersFilterBar
          search={search}
          onSearchChange={setSearch}
          statusId={statusId}
          onStatusIdChange={(value) => applyInstantFilter({ statusId: value })}
          createdOn={createdOn}
          onCreatedOnChange={(value) => applyInstantFilter({ createdOn: value })}
          hideProductTypeFilter
        />

        {successMessage ? (
          <div className="admin-alert-success mx-4 mt-4 sm:mx-6">{successMessage}</div>
        ) : null}

        {ordersError || actionError ? (
          <div className="admin-alert-error mx-4 mt-4 sm:mx-6">
            {actionError ?? getRtkErrorMessage(ordersError, t('orders.loadError'))}
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

            <OrdersTable orders={orders} />

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
