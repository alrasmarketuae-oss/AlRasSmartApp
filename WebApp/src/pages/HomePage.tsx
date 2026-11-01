import { useCallback } from 'react'
import { useAuth } from '../auth/AuthProvider'
import { BannerSlider } from '../home/BannerSlider'
import { CategoriesStrip, SectionHeader } from '../home/CategoriesStrip'
import { ServiceIcons } from '../home/ServiceIcons'
import { useI18n } from '../i18n/I18nProvider'
import { PageContainer } from '../layout/MainLayout'
import { usePageTitle } from '../lib/usePageTitle'
import { InfiniteProductGrid } from '../products/ProductGrid'
import { isCategoryHomeProduct, isRetailFeedProduct } from '../products/productRules'
import { fetchProducts, fetchProductsByType } from '../products/productsApi'

export default function HomePage() {
  const { t } = useI18n()
  usePageTitle()
  const { isPersonalCustomer, session } = useAuth()

  const fetchPage = useCallback(
    (page: number, signal: AbortSignal) => (isPersonalCustomer ? fetchProductsByType('Retail', page, signal) : fetchProducts(page, signal)),
    [isPersonalCustomer],
  )

  return (
    <div className="pt-4 lg:pt-6">
      <BannerSlider />
      <PageContainer className="pt-4 lg:pt-8">
        {!isPersonalCustomer && (
          <>
            <ServiceIcons />
            <div className="mt-5 lg:mt-8">
              <SectionHeader title={t('categories')} viewAllTo="/categories" />
            </div>
            <div className="mt-3">
              <CategoriesStrip />
            </div>
          </>
        )}
        <div className="mt-5 lg:mt-8">
          {isPersonalCustomer && (
            <div className="mb-3">
              <SectionHeader title={t('retail')} />
            </div>
          )}
          <InfiniteProductGrid
            queryKey={['home', isPersonalCustomer ? 'retail' : 'catalog', session?.id ?? 'guest']}
            fetchPage={fetchPage}
            filter={isPersonalCustomer ? isRetailFeedProduct : isCategoryHomeProduct}
            preferRetail={isPersonalCustomer}
            emptyText={t('noSearchResults')}
          />
        </div>
      </PageContainer>
    </div>
  )
}
