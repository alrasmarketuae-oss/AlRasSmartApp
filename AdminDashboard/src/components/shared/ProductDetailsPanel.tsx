import type { ReactNode } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { DetailField, DetailStatGrid, DetailStatTile } from './DetailSectionCard'

type ProductDetailsPanelProps = {
  name: string
  description?: string | null
  categoryName?: string
  productTypeName?: string
  quantity?: number
  unitName?: string
  priceFormatted?: string
  createdAt?: string
  formatDate?: (value: string) => string
  imageUrl?: string | null
  imageAlt?: string
  imageCount?: number
  extraStats?: ReactNode
  layout?: 'card' | 'inline'
}

export default function ProductDetailsPanel({
  name,
  description,
  categoryName,
  productTypeName,
  quantity,
  unitName,
  priceFormatted,
  createdAt,
  formatDate,
  imageUrl,
  imageAlt,
  imageCount,
  extraStats,
  layout = 'inline',
}: ProductDetailsPanelProps) {
  const { t } = useAppPreferences()

  const content = (
    <div className="min-w-0 flex-1 space-y-4">
      <DetailField label={t('ads.productName')} value={name} />
      <DetailField
        label={t('ads.productDescription')}
        value={
          description?.trim() ? (
            <span className="admin-text-muted font-normal leading-relaxed">{description}</span>
          ) : (
            <span className="admin-text-subtle font-normal">{t('ads.noDescription')}</span>
          )
        }
      />

      <DetailStatGrid>
        <DetailStatTile label={t('ads.category')} value={categoryName?.trim() || '—'} />
        <DetailStatTile label={t('ads.productType')} value={productTypeName?.trim() || '—'} />
        {quantity != null ? (
          <DetailStatTile
            label={t('ads.availableQuantity')}
            value={`${quantity} ${unitName?.trim() || ''}`.trim()}
          />
        ) : null}
        {priceFormatted ? (
          <DetailStatTile label={t('ads.price')} value={priceFormatted} />
        ) : null}
        {createdAt && formatDate ? (
          <DetailStatTile label={t('ads.adCreatedAt')} value={formatDate(createdAt)} />
        ) : null}
        {extraStats}
      </DetailStatGrid>
    </div>
  )

  if (layout === 'card') {
    return content
  }

  return (
    <div className="flex flex-col gap-5 lg:flex-row">
      {imageUrl !== undefined ? (
        <div className="shrink-0 text-center lg:text-start">
          <p className="admin-text-subtle mb-2 text-xs font-medium">
            {t('ads.productImage')}
            {imageCount != null && imageCount > 0 ? ` (${imageCount})` : ''}
          </p>
          {imageUrl ? (
            <img
              src={imageUrl}
              alt={imageAlt ?? name}
              className="admin-border mx-auto h-28 w-28 rounded-xl border object-cover lg:mx-0 lg:ms-0"
            />
          ) : (
            <span className="admin-border admin-text-subtle admin-surface-muted mx-auto flex h-28 w-28 items-center justify-center rounded-xl border border-dashed text-xs lg:mx-0 lg:ms-0">
              {t('categories.noImage')}
            </span>
          )}
        </div>
      ) : null}
      {content}
    </div>
  )
}
