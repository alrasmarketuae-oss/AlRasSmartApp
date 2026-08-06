import { useEffect, useMemo, useRef, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import AdsFilterBar from '../components/ads/AdsFilterBar'
import AdsStatsCards from '../components/ads/AdsStatsCards'
import AdsTable from '../components/ads/AdsTable'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useGlobalSearchParam } from '../hooks/useGlobalSearchParam'
import { useListPageParam } from '../hooks/useListPageParam'
import {
  useApproveProductMutation,
  useGetAdminProductStatsQuery,
  useGetAdminProductsQuery,
  useRejectProductMutation,
} from '../store'
import { queryViewState } from '../store/queryView'
import type { AdminProductsFilters } from '../types/adminProduct'
import { getRtkErrorMessage } from '../utils/rtkError'

type AppliedFilters = {
  search: string
  approval: 'pending' | 'approved' | 'rejected' | 'all'
  productTypeId: string
  createdOn: string
}

const defaultFilters: AppliedFilters = {
  search: '',
  approval: 'all',
  productTypeId: '',
  createdOn: '',
}

export default function AdsPage() {
  const { t, locale } = useAppPreferences()
  const location = useLocation()
  const navigate = useNavigate()
  const searchParams = new URLSearchParams(location.search)
  const adEditsOnly = searchParams.get('adEdits') === '1'
  const productTypeFromUrl = searchParams.get('productTypeId')?.trim() ?? ''
  const { page, setPage } = useListPageParam()
  const [search, setSearch] = useState('')
  const [approval, setApproval] = useState<AppliedFilters['approval']>('all')
  const [productTypeId, setProductTypeId] = useState(productTypeFromUrl)
  const [createdOn, setCreatedOn] = useState('')
  const [appliedFilters, setAppliedFilters] = useState<AppliedFilters>(() => ({
    ...defaultFilters,
    productTypeId: productTypeFromUrl,
  }))

  const { urlSearch, setUrlSearch } = useGlobalSearchParam()
  const syncingFromUrlRef = useRef(false)

  const [approvingId, setApprovingId] = useState<string | null>(null)
  const [rejectingId, setRejectingId] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const pageSize = 20

  const { data: stats, isLoading: statsLoading } = useGetAdminProductStatsQuery(
    undefined,
    { skip: adEditsOnly },
  )

  const queryParams = useMemo((): AdminProductsFilters => {
    const createdOnValue = appliedFilters.createdOn.trim()
    const typeId = appliedFilters.productTypeId
      ? Number(appliedFilters.productTypeId)
      : undefined
    return {
      page,
      pageSize,
      search: appliedFilters.search.trim() || undefined,
      approval: adEditsOnly ? 'pending' : appliedFilters.approval,
      excludeProductTypeId: adEditsOnly ? undefined : typeId ? undefined : 4,
      productTypeId: typeId,
      createdFrom: createdOnValue || undefined,
      createdTo: createdOnValue || undefined,
      editResubmitOnly: adEditsOnly ? true : undefined,
      lang: locale,
    }
  }, [page, pageSize, appliedFilters, adEditsOnly, locale])

  const {
    data: productsData,
    error: productsError,
    isLoading,
    isFetching,
  } = useGetAdminProductsQuery(queryParams)
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading,
    isFetching,
  })

  const [approveProduct] = useApproveProductMutation()
  const [rejectProduct] = useRejectProductMutation()

  function commitFilters(next: AppliedFilters) {
    setAppliedFilters(next)
    setPage(1)
  }

  function applyFilters() {
    commitFilters({
      search,
      approval,
      productTypeId,
      createdOn,
    })
    setUrlSearch(search)
  }

  useEffect(() => {
    setPage(1)
    // eslint-disable-next-line react-hooks/exhaustive-deps -- reset paging when switching ad-edits mode
  }, [adEditsOnly])

  useEffect(() => {
    if (productTypeFromUrl === productTypeId && productTypeFromUrl === appliedFilters.productTypeId) {
      return
    }
    setProductTypeId(productTypeFromUrl)
    commitFilters({
      search: appliedFilters.search,
      approval: appliedFilters.approval,
      productTypeId: productTypeFromUrl,
      createdOn: appliedFilters.createdOn,
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps -- sync type filter from URL only
  }, [productTypeFromUrl])

  useEffect(() => {
    const message = (location.state as { adsMessage?: string } | null)?.adsMessage
    if (!message) return
    setSuccessMessage(message)
    navigate(`${location.pathname}${location.search}`, { replace: true, state: null })
  }, [location.pathname, location.search, location.state, navigate])

  useEffect(() => {
    if (urlSearch === appliedFilters.search && urlSearch === search) return

    syncingFromUrlRef.current = true
    setSearch(urlSearch)
    if (urlSearch) {
      setApproval('all')
    }

    commitFilters({
      search: urlSearch,
      approval: urlSearch ? 'all' : approval,
      productTypeId,
      createdOn,
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps -- sync only when URL search changes
  }, [urlSearch])

  useEffect(() => {
    if (syncingFromUrlRef.current) {
      syncingFromUrlRef.current = false
      return
    }

    const timer = window.setTimeout(() => {
      const trimmed = search.trim()
      if (trimmed === appliedFilters.search.trim()) return

      commitFilters({
        search: trimmed,
        approval,
        productTypeId,
        createdOn,
      })
      setUrlSearch(trimmed)
    }, 400)

    return () => window.clearTimeout(timer)
    // eslint-disable-next-line react-hooks/exhaustive-deps -- debounce search input only
  }, [search])

  async function handleApprove(productId: string) {
    const confirmed = window.confirm(t('ads.approveConfirm'))
    if (!confirmed) return

    setApprovingId(productId)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await approveProduct({ productId }).unwrap()
      setSuccessMessage(result.message || t('ads.approveSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.approveError')))
    } finally {
      setApprovingId(null)
    }
  }

  async function handleReject(productId: string) {
    const reason = window.prompt(t('users.rejectReasonTitle')) ?? ''
    if (!reason.trim()) return

    const confirmed = window.confirm(t('ads.rejectConfirm'))
    if (!confirmed) return

    setRejectingId(productId)
    setActionError(null)
    setSuccessMessage(null)

    try {
      const result = await rejectProduct({
        productId,
        supplierNotesEn: reason.trim(),
      }).unwrap()
      setSuccessMessage(result.message || t('ads.rejectSuccess'))
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('ads.rejectError')))
    } finally {
      setRejectingId(null)
    }
  }

  const products = productsData?.items ?? []
  const totalPages = productsData?.totalPages ?? 1
  const pageTitle = adEditsOnly ? t('nav.adEdits') : t('ads.title')
  const crumb = adEditsOnly ? t('nav.adEdits') : t('nav.ads')

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div className="text-start">
          <h1 className="admin-text text-2xl font-bold tracking-tight">
            {pageTitle}
          </h1>
          <p className="admin-text-muted mt-1 text-xs">
            <Link to="/" className="hover:text-[#2563eb]">
              {t('nav.dashboard')}
            </Link>
            <span className="mx-1.5 opacity-50">›</span>
            <span>{crumb}</span>
          </p>
          {adEditsOnly ? (
            <p className="admin-text-muted mt-2 max-w-2xl text-sm">
              {t('ads.adEditsHint')}
            </p>
          ) : null}
        </div>
      </div>

      {!adEditsOnly ? (
        <AdsStatsCards stats={stats} isLoading={statsLoading} />
      ) : null}

      <div className="admin-card overflow-hidden rounded-2xl shadow-sm">
        <AdsFilterBar
          search={search}
          onSearchChange={setSearch}
          approval={approval}
          onApprovalChange={setApproval}
          productTypeId={productTypeId}
          onProductTypeIdChange={setProductTypeId}
          createdOn={createdOn}
          onCreatedOnChange={setCreatedOn}
          onApply={applyFilters}
          hideApproval={adEditsOnly}
        />

        {successMessage ? (
          <div className="admin-alert-success mx-4 mt-4 sm:mx-6">
            {successMessage}
          </div>
        ) : null}

        {productsError || actionError ? (
          <div className="admin-alert-error mx-4 mt-4 sm:mx-6">
            {actionError ??
              getRtkErrorMessage(productsError, t('ads.loadError'))}
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

            <AdsTable
              products={products}
              approvingId={approvingId}
              rejectingId={rejectingId}
              onApprove={handleApprove}
              onReject={handleReject}
            />

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
