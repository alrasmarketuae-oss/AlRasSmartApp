import { useInfiniteQuery } from '@tanstack/react-query'
import { useEffect, useMemo, useRef } from 'react'
import { useAuth } from '../auth/AuthProvider'
import { Spinner } from '../auth/components'
import { useI18n } from '../i18n/I18nProvider'
import { ProductCard, ProductCardSkeleton } from './ProductCard'
import { totalPagesOf } from './productsApi'
import type { Viewer } from './productRules'
import type { ApiProduct, Paged } from './types'

export function useViewer(): Viewer {
  const auth = useAuth()
  return useMemo(
    () => ({
      isAuthenticated: auth.isAuthenticated,
      isGuest: auth.isGuest,
      isAdmin: auth.isAdmin,
      isSupplier: auth.isSupplier,
      isCompanyCustomer: auth.isCompanyCustomer,
      isPersonalCustomer: auth.isPersonalCustomer,
      isUaePhone: auth.isUaePhone,
      displayName: auth.displayName,
      userId: auth.session?.id ?? '',
    }),
    [auth],
  )
}

export const GRID_CLASSES =
  'grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 lg:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6'

type Props = {
  queryKey: readonly unknown[]
  fetchPage: (page: number, signal: AbortSignal) => Promise<Paged<ApiProduct>>
  filter?: (product: ApiProduct) => boolean
  preferRetail?: boolean
  emptyText: string
}

export function InfiniteProductGrid({ queryKey, fetchPage, filter, preferRetail, emptyText }: Props) {
  const { t } = useI18n()
  const viewer = useViewer()
  const sentinel = useRef<HTMLDivElement>(null)

  const query = useInfiniteQuery({
    queryKey,
    initialPageParam: 1,
    queryFn: ({ pageParam, signal }) => fetchPage(pageParam, signal),
    getNextPageParam: (last, _all, page) => (page < totalPagesOf(last, page) && (last.items?.length ?? 0) > 0 ? page + 1 : undefined),
  })

  const products = useMemo(() => {
    const seen = new Set<string>()
    const all: ApiProduct[] = []
    for (const page of query.data?.pages ?? []) {
      for (const item of page.items ?? []) {
        if (seen.has(item.productId) || (filter && !filter(item))) continue
        seen.add(item.productId)
        all.push(item)
      }
    }
    return all
  }, [query.data, filter])

  const { hasNextPage, isFetchingNextPage, fetchNextPage } = query

  useEffect(() => {
    const node = sentinel.current
    if (!node || !hasNextPage) return
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0]?.isIntersecting && !isFetchingNextPage) void fetchNextPage()
      },
      { rootMargin: `${Math.round(window.innerHeight * 1.25)}px 0px` },
    )
    observer.observe(node)
    return () => observer.disconnect()
  }, [hasNextPage, isFetchingNextPage, fetchNextPage, products.length])

  // Filtered feeds can leave a page short; keep pulling until the viewport fills.
  useEffect(() => {
    if (!query.isFetching && hasNextPage && products.length < 8) void fetchNextPage()
  }, [query.isFetching, hasNextPage, products.length, fetchNextPage])

  if (query.isPending) {
    return (
      <div className={GRID_CLASSES}>
        {Array.from({ length: 8 }, (_, i) => (
          <ProductCardSkeleton key={i} />
        ))}
      </div>
    )
  }

  if (query.isError && products.length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 py-16 text-center">
        <p className="text-sm text-auth-body">{(query.error as Error).message || t('unexpectedError')}</p>
        <button type="button" onClick={() => void query.refetch()} className="rounded-xl bg-brand px-5 py-2.5 text-sm font-bold text-white">
          {t('retry')}
        </button>
      </div>
    )
  }

  if (products.length === 0 && !hasNextPage) {
    return (
      <div className="flex flex-col items-center gap-3 py-16 text-center">
        <img src="/assets/logo/brand_mark.png" alt="" className="h-16 w-auto opacity-40" />
        <p className="text-sm font-medium text-auth-body">{emptyText}</p>
      </div>
    )
  }

  return (
    <>
      <div className={GRID_CLASSES}>
        {products.map((product) => (
          <ProductCard key={product.productId} product={product} viewer={viewer} preferRetail={preferRetail} />
        ))}
        {isFetchingNextPage &&
          Array.from({ length: 4 }, (_, i) => <ProductCardSkeleton key={`s-${i}`} />)}
      </div>
      <div ref={sentinel} className="h-px" />
      {isFetchingNextPage && (
        <div className="flex justify-center py-4">
          <Spinner className="size-6 border-brand/25 border-t-brand" />
        </div>
      )}
    </>
  )
}
