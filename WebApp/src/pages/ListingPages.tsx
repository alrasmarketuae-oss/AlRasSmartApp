import { useQuery } from '@tanstack/react-query'
import { useCallback, useEffect, useMemo } from 'react'
import { Navigate, useLocation, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { Spinner } from '../auth/components'
import { ProductCardSkeleton } from '../products/ProductCard'
import { GRID_CLASSES } from '../products/ProductGrid'
import { categoryName, CategoryTile, useCategories } from '../home/CategoriesStrip'
import { useI18n } from '../i18n/I18nProvider'
import type { StringKey } from '../i18n/strings'
import { PageContainer } from '../layout/MainLayout'
import { usePageTitle } from '../lib/usePageTitle'
import { InfiniteProductGrid } from '../products/ProductGrid'
import { isRetailFeedProduct } from '../products/productRules'
import { compressImage, detectByImage, fetchProductsByCategory, fetchProductsByType, searchProducts, type ServiceType } from '../products/productsApi'
import { Icon } from '../ui/Icon'

function PageTitle({ title, subtitle }: { title: string; subtitle?: string }) {
  const { isAr } = useI18n()
  const navigate = useNavigate()
  return (
    <div className="mb-4 flex items-center gap-2 lg:mb-6">
      <button
        type="button"
        onClick={() => (window.history.length > 1 ? navigate(-1) : navigate('/'))}
        className="grid size-9 shrink-0 place-items-center rounded-full text-brand hover:bg-white"
        aria-label="Back"
      >
        <Icon name={isAr ? 'chevronRight' : 'chevronLeft'} size={22} />
      </button>
      <div className="min-w-0">
        <h1 className="truncate text-lg font-bold text-title sm:text-xl lg:text-2xl">{title}</h1>
        {subtitle && <p className="truncate text-xs text-subtitle sm:text-sm">{subtitle}</p>}
      </div>
    </div>
  )
}

export function CategoriesPage() {
  const { t, isAr } = useI18n()
  usePageTitle(t('categories'))
  const { data, isPending } = useCategories()
  return (
    <PageContainer className="py-4 lg:py-8">
      <PageTitle title={t('categories')} />
      <div className="grid grid-cols-3 gap-2.5 sm:grid-cols-4 sm:gap-4 md:grid-cols-5 lg:grid-cols-6 xl:grid-cols-8">
        {isPending
          ? Array.from({ length: 12 }, (_, i) => (
              <div key={i} className="overflow-hidden rounded-xl bg-[#E5E7EB]">
                <div className="shimmer aspect-square" />
                <div className="h-9" />
              </div>
            ))
          : (data ?? []).map((c) => <CategoryTile key={c.categoryId} category={c} label={categoryName(c, isAr)} />)}
      </div>
    </PageContainer>
  )
}

export function CategoryProductsPage() {
  const { t, isAr } = useI18n()
  const { id } = useParams()
  const categoryId = Number(id)
  const { data: categories } = useCategories()
  const { session } = useAuth()
  const category = categories?.find((c) => c.categoryId === categoryId)
  const title = category ? categoryName(category, isAr) : t('category')
  usePageTitle(title)

  const fetchPage = useCallback((page: number, signal: AbortSignal) => fetchProductsByCategory(categoryId, page, signal), [categoryId])

  if (!Number.isFinite(categoryId) || categoryId <= 0) return <Navigate to="/categories" replace />

  return (
    <PageContainer className="py-4 lg:py-8">
      <PageTitle title={title} />
      <InfiniteProductGrid queryKey={['category', categoryId, session?.id ?? 'guest']} fetchPage={fetchPage} emptyText={t('noProducts')} />
    </PageContainer>
  )
}

const SERVICES: Record<string, { type: ServiceType; label: StringKey }> = {
  requests: { type: 'Requests', label: 'requests' },
  offers: { type: 'Offers', label: 'offers' },
  booking: { type: 'Booking', label: 'booking' },
  retail: { type: 'Retail', label: 'retail' },
}

export function ServiceProductsPage() {
  const { t } = useI18n()
  const { type = '' } = useParams()
  const { session } = useAuth()
  const service = SERVICES[type.toLowerCase()]
  usePageTitle(service ? t(service.label) : undefined)

  const fetchPage = useCallback(
    (page: number, signal: AbortSignal) => fetchProductsByType(service?.type ?? 'Offers', page, signal),
    [service?.type],
  )

  if (!service) return <Navigate to="/" replace />
  const isRetail = service.type === 'Retail'

  return (
    <PageContainer className="py-4 lg:py-8">
      <PageTitle title={t(service.label)} />
      <InfiniteProductGrid
        queryKey={['service', service.type, session?.id ?? 'guest']}
        fetchPage={fetchPage}
        filter={isRetail ? isRetailFeedProduct : undefined}
        preferRetail={isRetail}
        emptyText={t('noProducts')}
      />
    </PageContainer>
  )
}

export function ImageSearchPage() {
  const { t } = useI18n()
  usePageTitle(t('searchByImage'))
  const navigate = useNavigate()
  const location = useLocation()
  const { session, isPersonalCustomer } = useAuth()
  const state = location.state as { file?: File; at?: number } | null
  const file = state?.file
  const previewUrl = useMemo(() => (file ? URL.createObjectURL(file) : ''), [file])
  useEffect(() => () => URL.revokeObjectURL(previewUrl), [previewUrl])

  const detect = useQuery({
    queryKey: ['image-search', state?.at, session?.id ?? 'guest'],
    queryFn: async ({ signal }) => detectByImage(await compressImage(file as File), signal),
    enabled: !!file,
    staleTime: Infinity,
    retry: 0,
  })
  const result = detect.data
  const detectedName = (result?.detectedProductName ?? '').trim() || result?.suggestedNames?.[0]?.trim() || ''
  const categoryId = result?.detectedCategoryId && result.detectedCategoryId > 0 ? result.detectedCategoryId : null

  const fetchPage = useCallback(
    (page: number, signal: AbortSignal) => {
      if (page === 1 && result) return Promise.resolve(result)
      if (categoryId && !isPersonalCustomer) return fetchProductsByCategory(categoryId, page, signal, true)
      return searchProducts(detectedName, page, signal)
    },
    [result, categoryId, isPersonalCustomer, detectedName],
  )

  if (!file) return <Navigate to="/" replace />

  const names = Array.from(new Set((result?.items ?? []).map((p) => (p.productName ?? '').trim()).filter(Boolean))).slice(0, 8)
  const chips = names.length ? names : (result?.suggestedNames ?? []).slice(0, 8)

  return (
    <PageContainer className="py-4 lg:py-8">
      <PageTitle title={t('imageSearchPeekTitle')} />
      <div className="mb-5 flex items-center gap-4 rounded-2xl bg-white p-3 shadow-[0_4px_14px_rgba(22,35,58,0.05)]">
        <img src={previewUrl} alt="" className="size-20 shrink-0 rounded-xl object-cover sm:size-24" />
        <div className="min-w-0 flex-1">
          {detect.isPending ? (
            <>
              <p className="flex items-center gap-2 text-sm font-bold text-title">
                <Spinner className="size-4 border-2 border-brand/25 border-t-brand" />
                {t('analyzingImage')}
              </p>
              <p className="mt-1 text-xs text-subtitle">{t('analyzingImageHint')}</p>
            </>
          ) : detect.isError ? (
            <p className="text-sm font-semibold text-[#d92d20]">{(detect.error as Error).message || t('unexpectedError')}</p>
          ) : (
            <>
              <p className="flex items-start gap-1.5 text-sm font-semibold text-title">
                <Icon name="sparkle" size={18} className="mt-0.5 shrink-0 text-brand" />
                {detectedName ? t('aiIdentifiedProduct', { name: detectedName }) : t('aiIdentifiedProducts')}
              </p>
              {chips.length > 0 && (
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {chips.map((name) => (
                    <button
                      key={name}
                      type="button"
                      onClick={() => navigate(`/search?q=${encodeURIComponent(name)}`)}
                      className="rounded-full border border-brand/30 bg-brand/5 px-3 py-1 text-xs font-semibold text-brand hover:bg-brand/10"
                    >
                      {name}
                    </button>
                  ))}
                </div>
              )}
            </>
          )}
        </div>
      </div>
      {detect.isPending ? (
        <div className={GRID_CLASSES}>
          {Array.from({ length: 8 }, (_, i) => (
            <ProductCardSkeleton key={i} />
          ))}
        </div>
      ) : detect.isError ? (
        <div className="flex justify-center py-10">
          <button type="button" onClick={() => void detect.refetch()} className="rounded-xl bg-brand px-5 py-2.5 text-sm font-bold text-white">
            {t('retry')}
          </button>
        </div>
      ) : (
        <InfiniteProductGrid queryKey={['image-search-grid', state?.at, session?.id ?? 'guest']} fetchPage={fetchPage} emptyText={t('noSearchResults')} />
      )}
    </PageContainer>
  )
}

export function SearchPage() {
  const { t } = useI18n()
  const [params] = useSearchParams()
  const { session } = useAuth()
  const q = (params.get('q') ?? '').trim()
  usePageTitle(q ? `${t('searchResultsFor')} "${q}"` : t('searchForProducts'))

  const fetchPage = useCallback((page: number, signal: AbortSignal) => searchProducts(q, page, signal), [q])

  if (!q) return <Navigate to="/" replace />

  return (
    <PageContainer className="py-4 lg:py-8">
      <PageTitle title={`${t('searchResultsFor')} "${q}"`} />
      <InfiniteProductGrid queryKey={['search', q, session?.id ?? 'guest']} fetchPage={fetchPage} emptyText={t('noSearchResults')} />
    </PageContainer>
  )
}
