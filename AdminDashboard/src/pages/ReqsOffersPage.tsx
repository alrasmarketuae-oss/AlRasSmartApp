import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import AdsTable from '../components/ads/AdsTable'
import OrdersTable from '../components/orders/OrdersTable'
import PageHeader from '../components/layout/PageHeader'
import { IconAds, IconOrders } from '../components/icons'
import ReqsOffersStatsCards from '../components/reqsOffers/ReqsOffersStatsCards'
import ReqsOffersToolbar from '../components/reqsOffers/ReqsOffersToolbar'
import { PRODUCT_TYPE_REQUESTS } from '../constants/productTypes'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGlobalSearchParam } from '../hooks/useGlobalSearchParam'
import {
  useApproveProductMutation,
  useGetAdminOrdersQuery,
  useGetAdminProductsQuery,
  useRejectProductMutation,
} from '../store'
import { queryViewState } from '../store/queryView'
import type { AdminOrdersFilters } from '../types/adminOrder'
import { getRtkErrorMessage } from '../utils/rtkError'

type TabKey = 'requests' | 'offers'
type RequestFilter = 'all' | 'hasNewOffers'
type OfferReviewFilter = 'all' | 'awaitingAdmin' | 'awaitingSeller' | 'sellerApproved'

const PAGE_SIZE_OPTIONS = [10, 20, 50] as const

function parseTab(value: string | null): TabKey {
  return value === 'offers' ? 'offers' : 'requests'
}

function parseRequestFilter(value: string | null): RequestFilter {
  return value === 'hasNewOffers' || value === '1' || value === 'true'
    ? 'hasNewOffers'
    : 'all'
}

function parseOfferReview(value: string | null): OfferReviewFilter {
  if (
    value === 'awaitingAdmin' ||
    value === 'awaitingSeller' ||
    value === 'sellerApproved'
  ) {
    return value
  }
  return 'all'
}

function parsePageSize(value: string | null): number {
  const n = Number(value)
  return PAGE_SIZE_OPTIONS.includes(n as (typeof PAGE_SIZE_OPTIONS)[number]) ? n : 10
}

export default function ReqsOffersPage() {
  const { t, locale } = useAppPreferences()
  const { urlSearch, setUrlSearch } = useGlobalSearchParam()
  const [searchParams, setSearchParams] = useSearchParams()

  const [activeTab, setActiveTab] = useState<TabKey>(() =>
    parseTab(searchParams.get('tab')),
  )
  const [requestFilter, setRequestFilter] = useState<RequestFilter>(() =>
    parseRequestFilter(
      searchParams.get('hasPendingOffers') ?? searchParams.get('requestFilter'),
    ),
  )
  const [offerReview, setOfferReview] = useState<OfferReviewFilter>(() =>
    parseOfferReview(searchParams.get('offerReview')),
  )
  const [createdOn, setCreatedOn] = useState(() => searchParams.get('createdOn') ?? '')
  const [localSearch, setLocalSearch] = useState(urlSearch)
  const [requestPage, setRequestPage] = useState(1)
  const [offerPage, setOfferPage] = useState(1)
  const [pageSize, setPageSize] = useState(() => parsePageSize(searchParams.get('pageSize')))

  const [approvingId, setApprovingId] = useState<string | null>(null)
  const [rejectingId, setRejectingId] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  useEffect(() => {
    setLocalSearch(urlSearch)
  }, [urlSearch])

  useEffect(() => {
    const next = new URLSearchParams(searchParams)
    next.set('tab', activeTab)
    next.set('pageSize', String(pageSize))
    if (createdOn.trim()) next.set('createdOn', createdOn.trim())
    else next.delete('createdOn')

    if (activeTab === 'requests') {
      if (requestFilter === 'hasNewOffers') {
        next.set('hasPendingOffers', '1')
      } else {
        next.delete('hasPendingOffers')
      }
      next.delete('offerReview')
    } else {
      next.delete('hasPendingOffers')
      if (offerReview !== 'all') {
        next.set('offerReview', offerReview)
      } else {
        next.delete('offerReview')
      }
    }
    setSearchParams(next, { replace: true })
    // eslint-disable-next-line react-hooks/exhaustive-deps -- sync URL from local filter state only
  }, [activeTab, requestFilter, offerReview, createdOn, pageSize])

  const dateFilter = createdOn.trim() || undefined

  const requestQuery = useMemo(
    () => ({
      page: requestPage,
      pageSize,
      productTypeId: PRODUCT_TYPE_REQUESTS,
      approval: 'all' as const,
      search: urlSearch.trim() || undefined,
      hasPendingOffers: requestFilter === 'hasNewOffers' ? true : undefined,
      createdFrom: dateFilter,
      createdTo: dateFilter,
      lang: locale,
    }),
    [requestPage, pageSize, urlSearch, requestFilter, dateFilter, locale],
  )

  const offerQuery = useMemo((): AdminOrdersFilters => {
    const base: AdminOrdersFilters = {
      page: offerPage,
      pageSize,
      productTypeId: PRODUCT_TYPE_REQUESTS,
      search: urlSearch.trim() || undefined,
      createdFrom: dateFilter,
      createdTo: dateFilter,
    }
    if (offerReview !== 'all') {
      base.offerReview = offerReview
    }
    return base
  }, [offerPage, pageSize, urlSearch, offerReview, dateFilter])

  const {
    data: requestsData,
    error: requestsError,
    isLoading: requestsLoading,
    isFetching: requestsFetching,
  } = useGetAdminProductsQuery(requestQuery, { skip: activeTab !== 'requests' })

  const {
    data: offersData,
    error: offersError,
    isLoading: offersLoading,
    isFetching: offersFetching,
  } = useGetAdminOrdersQuery(offerQuery, { skip: activeTab !== 'offers' })

  const statsBase = { page: 1, pageSize: 1, productTypeId: PRODUCT_TYPE_REQUESTS, lang: locale }
  const { data: totalRequestsData, isLoading: totalRequestsLoading } =
    useGetAdminProductsQuery({ ...statsBase, approval: 'all' })
  const { data: newRequestsData, isLoading: newRequestsLoading } =
    useGetAdminProductsQuery({ ...statsBase, hasPendingOffers: true })
  const { data: awaitingAdsData, isLoading: awaitingAdsLoading } =
    useGetAdminProductsQuery({ ...statsBase, approval: 'pending' })
  const { data: sentOffersData, isLoading: sentOffersLoading } =
    useGetAdminOrdersQuery({ ...statsBase })
  const { data: receivedData, isLoading: receivedLoading } = useGetAdminOrdersQuery({
    ...statsBase,
    statusId: 5,
  })
  const { data: valueSampleData, isLoading: valueLoading } = useGetAdminOrdersQuery({
    page: 1,
    pageSize: 100,
    productTypeId: PRODUCT_TYPE_REQUESTS,
  })

  const statsLoading =
    totalRequestsLoading ||
    newRequestsLoading ||
    awaitingAdsLoading ||
    sentOffersLoading ||
    receivedLoading ||
    valueLoading

  const totalValueLabel = useMemo(() => {
    const items = valueSampleData?.items ?? []
    const sum = items.reduce((acc, order) => {
      const n = Number(order.customerTotalPrice || order.totalPrice || 0)
      return acc + (Number.isFinite(n) ? n : 0)
    }, 0)
    const currency = items[0]?.currency?.trim().toUpperCase() || 'AED'
    const numberLocale = locale === 'ar' ? 'ar-AE' : 'en-US'
    return `${sum.toLocaleString(numberLocale, {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    })} ${currency}`
  }, [valueSampleData, locale])

  const stats = {
    totalRequests: totalRequestsData?.totalCount ?? 0,
    newRequests: newRequestsData?.totalCount ?? 0,
    awaitingApproval: awaitingAdsData?.totalCount ?? 0,
    received: receivedData?.totalCount ?? 0,
    sentOffers: sentOffersData?.totalCount ?? 0,
    totalValueLabel,
  }

  const requestView = queryViewState({
    isLoading: requestsLoading,
    isFetching: requestsFetching,
  })
  const offerView = queryViewState({
    isLoading: offersLoading,
    isFetching: offersFetching,
  })

  const [approveProduct] = useApproveProductMutation()
  const [rejectProduct] = useRejectProductMutation()

  async function handleApprove(productId: string) {
    setApprovingId(productId)
    setActionError(null)
    setSuccessMessage(null)
    try {
      await approveProduct({ productId }).unwrap()
      setSuccessMessage(t('ads.approveSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.approveError')))
    } finally {
      setApprovingId(null)
    }
  }

  async function handleReject(productId: string) {
    if (!window.confirm(t('ads.rejectConfirm'))) return
    setRejectingId(productId)
    setActionError(null)
    setSuccessMessage(null)
    try {
      await rejectProduct({ productId }).unwrap()
      setSuccessMessage(t('ads.rejectSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.rejectError')))
    } finally {
      setRejectingId(null)
    }
  }

  function selectTab(tab: TabKey) {
    setActiveTab(tab)
    if (tab === 'requests') setRequestPage(1)
    else setOfferPage(1)
  }

  function applySearch() {
    setUrlSearch(localSearch.trim())
    setRequestPage(1)
    setOfferPage(1)
  }

  function handleRequestFilterChange(value: RequestFilter) {
    setRequestFilter(value)
    setRequestPage(1)
  }

  function handleOfferReviewChange(value: OfferReviewFilter) {
    setOfferReview(value)
    setOfferPage(1)
  }

  function handleCreatedOnChange(value: string) {
    setCreatedOn(value)
    setRequestPage(1)
    setOfferPage(1)
  }

  function handlePageSizeChange(value: number) {
    setPageSize(value)
    setRequestPage(1)
    setOfferPage(1)
  }

  const requests = requestsData?.items ?? []
  const offers = offersData?.items ?? []
  const requestTotalPages = requestsData?.totalPages ?? 1
  const offerTotalPages = offersData?.totalPages ?? 1
  const requestTotalCount = requestsData?.totalCount ?? 0
  const offerTotalCount = offersData?.totalCount ?? 0
  const activeTotalPages = activeTab === 'requests' ? requestTotalPages : offerTotalPages
  const activePage = activeTab === 'requests' ? requestPage : offerPage
  const activeTotalCount = activeTab === 'requests' ? requestTotalCount : offerTotalCount
  const setActivePage = activeTab === 'requests' ? setRequestPage : setOfferPage
  const activeError = activeTab === 'requests' ? requestsError : offersError
  const showInitialLoader =
    activeTab === 'requests' ? requestView.showInitialLoader : offerView.showInitialLoader
  const showBackgroundUpdate =
    activeTab === 'requests' ? requestView.showBackgroundUpdate : offerView.showBackgroundUpdate

  const rangeFrom = activeTotalCount === 0 ? 0 : (activePage - 1) * pageSize + 1
  const rangeTo = Math.min(activePage * pageSize, activeTotalCount)
  const fromOrders = searchParams.get('nav') === 'orders'

  return (
    <div className="space-y-5">
      <PageHeader
        eyebrow={fromOrders ? t('nav.orders') : t('nav.ads')}
        title={fromOrders ? t('nav.orderRequest') : t('nav.adRequest')}
        description={t('reqsOffers.description')}
        icon={fromOrders ? IconOrders : IconAds}
      />
      <ReqsOffersToolbar
        activeTab={activeTab}
        onTabChange={selectTab}
        requestFilter={requestFilter}
        onRequestFilterChange={handleRequestFilterChange}
        offerReview={offerReview}
        onOfferReviewChange={handleOfferReviewChange}
        localSearch={localSearch}
        onLocalSearchChange={setLocalSearch}
        onApplySearch={applySearch}
        createdOn={createdOn}
        onCreatedOnChange={handleCreatedOnChange}
      />

      <ReqsOffersStatsCards stats={stats} isLoading={statsLoading} />

      <div className="admin-card overflow-hidden rounded-2xl shadow-sm">
        {successMessage ? (
          <div className="admin-alert-success mx-4 mt-4 sm:mx-6">{successMessage}</div>
        ) : null}
        {actionError || activeError ? (
          <div className="admin-alert-error mx-4 mt-4 sm:mx-6">
            {actionError ??
              getRtkErrorMessage(
                activeError,
                activeTab === 'requests'
                  ? t('reqsOffers.requestsLoadError')
                  : t('reqsOffers.offersLoadError'),
              )}
          </div>
        ) : null}

        {showInitialLoader ? (
          <div className="flex justify-center py-24">
            <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
          </div>
        ) : (
          <>
            {showBackgroundUpdate ? (
              <p className="admin-text-subtle px-4 pb-2 pt-3 text-center text-xs sm:px-6">
                {t('updating')}
              </p>
            ) : null}

            {activeTab === 'requests' ? (
              <AdsTable
                products={requests}
                approvingId={approvingId}
                rejectingId={rejectingId}
                onApprove={handleApprove}
                onReject={handleReject}
                isRequestList
              />
            ) : (
              <OrdersTable orders={offers} isRequestOffersList />
            )}

            <div className="admin-border flex flex-wrap items-center justify-between gap-3 border-t px-4 py-4 sm:px-6">
              <p className="admin-text-muted text-xs sm:text-sm">
                {t('reqsOffers.showingRange', {
                  from: rangeFrom,
                  to: rangeTo,
                  total: activeTotalCount,
                })}
              </p>

              <div className="flex flex-wrap items-center gap-3" dir="ltr">
                <label className="admin-text-muted flex items-center gap-2 text-xs">
                  <span>{t('reqsOffers.perPage')}</span>
                  <select
                    value={pageSize}
                    onChange={(e) => handlePageSizeChange(Number(e.target.value))}
                    className="admin-input h-8 rounded-lg px-2 text-xs font-semibold"
                  >
                    {PAGE_SIZE_OPTIONS.map((size) => (
                      <option key={size} value={size}>
                        {size}
                      </option>
                    ))}
                  </select>
                </label>

                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    disabled={activePage <= 1}
                    onClick={() => setActivePage((p) => p - 1)}
                    className="inline-flex h-8 w-8 items-center justify-center rounded-full border border-slate-200 text-slate-500 transition hover:bg-slate-50 disabled:opacity-40"
                    aria-label={t('previous')}
                  >
                    ‹
                  </button>
                  <span className="inline-flex h-8 min-w-8 items-center justify-center rounded-full bg-[#2563eb] px-2 text-xs font-bold text-white">
                    {activePage}
                  </span>
                  <button
                    type="button"
                    disabled={activePage >= activeTotalPages}
                    onClick={() => setActivePage((p) => p + 1)}
                    className="inline-flex h-8 w-8 items-center justify-center rounded-full border border-slate-200 text-slate-500 transition hover:bg-slate-50 disabled:opacity-40"
                    aria-label={t('next')}
                  >
                    ›
                  </button>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
