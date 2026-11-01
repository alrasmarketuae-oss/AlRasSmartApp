import { useQuery } from '@tanstack/react-query'
import { useI18n } from '../i18n/I18nProvider'
import { Screen } from '../layout/ScreenLayout'
import { ApiError } from '../lib/api'
import { usePageTitle } from '../lib/usePageTitle'
import { useSavedAds } from '../products/engagement'
import { ProductCard, ProductCardSkeleton } from '../products/ProductCard'
import { useViewer } from '../products/ProductGrid'
import { fetchProduct } from '../products/productsApi'
import type { ApiProduct } from '../products/types'

const GRID = 'grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4 lg:grid-cols-4'

export default function SavedAdsPage() {
  const { t } = useI18n()
  const viewer = useViewer()
  const saved = useSavedAds()
  usePageTitle(t('savedAds'))

  const query = useQuery({
    queryKey: ['saved-ads', saved.ids, viewer.userId],
    queryFn: async () => {
      const loaded: ApiProduct[] = []
      for (const id of saved.ids) {
        try {
          loaded.push(await fetchProduct(id))
        } catch (error) {
          if (error instanceof ApiError && error.status >= 400 && error.status < 500) saved.remove(id)
        }
      }
      return loaded
    },
    placeholderData: (previous) => previous,
  })

  const products = (query.data ?? []).filter((p) => saved.ids.includes(p.productId))

  return (
    <Screen title={t('savedAds')} width="wide" fallback="/profile">
      {query.isPending ? (
        <div className={GRID}>
          {Array.from({ length: Math.min(Math.max(saved.ids.length, 2), 8) }, (_, i) => (
            <ProductCardSkeleton key={i} />
          ))}
        </div>
      ) : products.length === 0 ? (
        <div className="flex flex-col items-center gap-3 py-20 text-center">
          <span className="grid size-20 place-items-center rounded-full bg-[#EEF4FB]">
            <img src="/assets/profile/ADS.svg" alt="" className="size-9 opacity-70" />
          </span>
          <p className="text-base font-bold text-title">{t('noSavedAds')}</p>
          <p className="max-w-xs text-sm text-subtitle">{t('noSavedAdsHint')}</p>
        </div>
      ) : (
        <div className={GRID}>
          {products.map((p) => (
            <ProductCard key={p.productId} product={p} viewer={viewer} preferRetail={viewer.isPersonalCustomer} />
          ))}
        </div>
      )}
    </Screen>
  )
}
