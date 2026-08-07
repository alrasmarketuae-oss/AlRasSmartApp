import { useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import AdsFilterBar from '../components/ads/AdsFilterBar'
import AdsTable from '../components/ads/AdsTable'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useListPageParam } from '../hooks/useListPageParam'
import { useReturnToListPath } from '../hooks/useReturnToListPath'
import {
  useApproveProductMutation,
  useGetAdminProductsQuery,
  useGetAdminUserDetailQuery,
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

export default function UserAdsPage() {
  const { userId = '' } = useParams()
  const navigate = useNavigate()
  const { t, locale } = useAppPreferences()
  const backToUsersPath = useReturnToListPath('/users')
  const { page, setPage } = useListPageParam()
  const [search, setSearch] = useState('')
  const [approval, setApproval] = useState<AppliedFilters['approval']>('all')
  const [productTypeId, setProductTypeId] = useState('')
  const [createdOn, setCreatedOn] = useState('')
  const [appliedFilters, setAppliedFilters] = useState<AppliedFilters>(defaultFilters)
  const [approvingId, setApprovingId] = useState<string | null>(null)
  const [rejectingId, setRejectingId] = useState<string | null>(null)
  const [successMessage, setSuccessMessage] = useState<string | null>(null)
  const [actionError, setActionError] = useState<string | null>(null)

  const pageSize = 20

  const {
    data: user,
    error: userError,
    isLoading: userLoading,
  } = useGetAdminUserDetailQuery(userId, { skip: !userId })

  const queryParams = useMemo((): AdminProductsFilters => {
    const createdOnValue = appliedFilters.createdOn.trim()
    const typeId = appliedFilters.productTypeId
      ? Number(appliedFilters.productTypeId)
      : undefined
    return {
      page,
      pageSize,
      search: appliedFilters.search.trim() || undefined,
      approval: appliedFilters.approval,
      productTypeId: typeId,
      createdFrom: createdOnValue || undefined,
      createdTo: createdOnValue || undefined,
      ownerId: userId || undefined,
      lang: locale,
    }
  }, [page, pageSize, appliedFilters, userId, locale])

  const {
    data: productsData,
    error: productsError,
    isLoading,
    isFetching,
  } = useGetAdminProductsQuery(queryParams, { skip: !userId })
  const { showInitialLoader, showBackgroundUpdate } = queryViewState({
    isLoading: isLoading || userLoading,
    isFetching,
  })

  const [approveProduct] = useApproveProductMutation()
  const [rejectProduct] = useRejectProductMutation()

  if (!userId) {
    navigate('/users', { replace: true })
    return null
  }

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
  }

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
  const companyTitle =
    user?.companyName?.trim() || user?.fullName?.trim() || t('users.company')

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div className="text-start">
          <h1 className="admin-text text-2xl font-bold tracking-tight">
            {t('users.companyAdsTitle')}
          </h1>
          <p className="admin-text-muted mt-1 text-xs">
            <Link to="/" className="hover:text-[#2563eb]">
              {t('nav.dashboard')}
            </Link>
            <span className="mx-1.5 opacity-50">›</span>
            <Link to={backToUsersPath} className="hover:text-[#2563eb]">
              {t('nav.users')}
            </Link>
            <span className="mx-1.5 opacity-50">›</span>
            <Link to={`/users/${userId}`} className="hover:text-[#2563eb]">
              {companyTitle}
            </Link>
            <span className="mx-1.5 opacity-50">›</span>
            <span>{t('users.companyAdsCrumb')}</span>
          </p>
          <p className="admin-text-muted mt-2 max-w-2xl text-sm">
            {t('users.companyAdsDescription', { name: companyTitle })}
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Link to={`/users/${userId}`} className="admin-btn-ghost text-sm font-semibold">
            {t('users.review')}
          </Link>
          <Link to={backToUsersPath} className="admin-btn-ghost text-sm font-semibold">
            {t('users.backToList')}
          </Link>
        </div>
      </div>

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
        />

        {successMessage ? (
          <div className="admin-alert-success mx-4 mt-4 sm:mx-6">{successMessage}</div>
        ) : null}

        {userError || productsError || actionError ? (
          <div className="admin-alert-error mx-4 mt-4 sm:mx-6">
            {actionError ??
              getRtkErrorMessage(
                (productsError || userError) as never,
                t('ads.loadError'),
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
