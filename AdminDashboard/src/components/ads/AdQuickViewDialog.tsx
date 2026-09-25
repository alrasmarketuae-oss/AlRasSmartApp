import { type ReactNode, useEffect } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import { useGetAdminProductDetailQuery } from '../../store'
import type { AdminProductDetail } from '../../types/adminProduct'
import {
  displayAdProductTypeName,
  formatAdAmount,
  formatAdPriceTypeLabel,
} from '../../utils/adsDisplay'
import CompactMediaStrip from '../orders/CompactMediaStrip'

type AdQuickViewDialogProps = {
  productId: string | null
  onClose: () => void
}

function DetailRow({ label, value }: { label: string; value: ReactNode }) {
  if (value == null) return null
  const text = typeof value === 'string' ? value.trim() : value
  if (typeof text === 'string' && text.length === 0) return null

  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50/70 px-3 py-2.5 text-start dark:border-slate-700 dark:bg-slate-800/40">
      <p className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">
        {label}
      </p>
      <div className="admin-text mt-1 text-sm font-semibold break-words whitespace-pre-wrap">
        {text}
      </div>
    </div>
  )
}

function packagingLabel(product: AdminProductDetail): string {
  const details = product.packagingDetails?.trim()
  if (details) return details
  if (product.packaging != null && product.packaging > 0) {
    return `${product.packaging}`
  }
  return ''
}

function retailPackagingLabel(product: AdminProductDetail): string {
  const details = product.retailPackagingDetails?.trim()
  if (details) return details
  if (product.retailPackaging != null && product.retailPackaging > 0) {
    return `${product.retailPackaging}`
  }
  return ''
}

export default function AdQuickViewDialog({ productId, onClose }: AdQuickViewDialogProps) {
  const { t, locale } = useAppPreferences()
  const open = Boolean(productId)
  const { data: product, isLoading, isError, error } = useGetAdminProductDetailQuery(
    { productId: productId ?? '', lang: locale === 'ar' ? 'ar' : 'en' },
    { skip: !productId },
  )

  useEffect(() => {
    if (!open) return
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [open, onClose])

  if (!open) return null

  const imagePaths = (() => {
    if (!product) return [] as string[]
    const fromImages = (product.images ?? []).map((img) => img.path).filter(Boolean)
    if (fromImages.length > 0) return fromImages
    if ((product.imagePaths ?? []).length > 0) return product.imagePaths
    return product.primaryImagePath?.trim() ? [product.primaryImagePath] : []
  })()

  const videoPaths = (() => {
    if (!product) return [] as string[]
    const fromVideos = (product.videos ?? []).map((v) => v.path).filter(Boolean)
    if (fromVideos.length > 0) return fromVideos
    if ((product.videoPaths ?? []).length > 0) return product.videoPaths.filter(Boolean)
    return product.videoPath?.trim() ? [product.videoPath] : []
  })()

  const documentPaths = (product?.documents ?? []).map((d) => d.path).filter(Boolean)

  const typeName = product ? displayAdProductTypeName(product, locale) : ''
  const priceTypeLabel = product ? formatAdPriceTypeLabel(product, t) : '—'
  const supplierName =
    product?.ownerCompanyName?.trim() || product?.ownerName?.trim() || '—'

  const basicRows: { label: string; value: string }[] = product
    ? [
        { label: t('ads.productType'), value: typeName },
        { label: t('ads.category'), value: product.categoryName?.trim() ?? '' },
        {
          label: t('ads.unit'),
          value: product.unitName?.trim() ?? '',
        },
        {
          label: t('ads.availableQuantity'),
          value:
            product.quantity != null
              ? `${product.quantity}${product.unitName ? ` ${product.unitName}` : ''}`
              : '',
        },
        {
          label: t('ads.table.amount'),
          value: formatAdAmount(product.priceFormatted, locale),
        },
        {
          label: t('chat.customerPrice'),
          value:
            product.customerPriceFormatted?.trim() ||
            (product.customerPriceUsd != null ? String(product.customerPriceUsd) : ''),
        },
        {
          label: t('ads.showPrice'),
          value: product.showPrice ? t('ads.negotiableYesShort') : t('ads.negotiableNoShort'),
        },
        {
          label: t('ads.negotiableShort'),
          value:
            product.negotiable == null
              ? ''
              : product.negotiable
                ? t('ads.negotiableYesShort')
                : t('ads.negotiableNoShort'),
        },
        {
          label: t('ads.priceTypeFixed'),
          value: priceTypeLabel !== '—' ? priceTypeLabel : '',
        },
        { label: t('ads.packagingType'), value: packagingLabel(product) },
        { label: t('ads.originCountry'), value: product.originCountryName?.trim() ?? '' },
        {
          label: t('ads.destinationCountry'),
          value: product.destinationCountryName?.trim() ?? '',
        },
        { label: t('ads.loadingPort'), value: product.loadingPortName?.trim() ?? '' },
        { label: t('ads.arrivalPort'), value: product.arrivalPortName?.trim() ?? '' },
        { label: t('ads.shippingRoute'), value: product.shippingRouteSummary?.trim() ?? '' },
        { label: t('ads.shippingDuration'), value: product.shippingDuration?.trim() ?? '' },
        { label: t('ads.offerDuration'), value: product.offerDuration?.trim() ?? '' },
        { label: t('ads.views'), value: String(product.viewsCount ?? 0) },
        {
          label: t('ads.requestFulfillment'),
          value: product.requestTypeName?.trim() ?? '',
        },
        {
          label: t('ads.bookingPriceType'),
          value: product.bookingPriceTypeName?.trim() ?? '',
        },
      ].filter((row) => row.value.trim().length > 0)
    : []

  const retailRows: { label: string; value: string }[] = product?.hasRetailPricing
    ? [
        {
          label: t('ads.retailPrice'),
          value:
            product.retailPrice != null
              ? formatAdAmount(String(product.retailPrice), locale)
              : '',
        },
        { label: t('ads.retailUnit'), value: product.retailUnitName?.trim() ?? '' },
        {
          label: t('ads.retailQuantity'),
          value:
            product.retailQuantity != null
              ? `${product.retailQuantity}${
                  product.retailUnitName ? ` ${product.retailUnitName}` : ''
                }`
              : '',
        },
        {
          label: t('ads.retailPackagingType'),
          value: retailPackagingLabel(product),
        },
      ].filter((row) => row.value.trim().length > 0)
    : []

  return (
    <div
      className="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 p-4 print:hidden"
      role="dialog"
      aria-modal="true"
      aria-labelledby="ad-quick-view-title"
      onClick={onClose}
    >
      <div
        className="admin-card flex max-h-[90vh] w-full max-w-3xl flex-col overflow-hidden rounded-2xl shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="admin-border flex items-start justify-between gap-3 border-b px-5 py-4">
          <div className="min-w-0 text-start">
            <p className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">
              {t('ads.quickView')}
            </p>
            <h2
              id="ad-quick-view-title"
              className="admin-text mt-1 text-lg font-bold leading-snug break-words"
            >
              {product?.name?.trim() || (isLoading ? t('ads.quickViewLoading') : '—')}
            </h2>
            {product ? (
              <p className="admin-text-muted mt-1 text-xs">
                {t('ads.postedBy')}: {supplierName}
              </p>
            ) : null}
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t('cancel')}
            className="shrink-0 rounded-lg p-1.5 text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-800"
          >
            <svg
              className="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={1.8}
              aria-hidden
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="overflow-y-auto px-5 py-4">
          {isLoading ? (
            <div className="flex items-center justify-center py-16">
              <span className="h-8 w-8 animate-spin rounded-full border-2 border-[#3B7FC7] border-t-transparent" />
            </div>
          ) : isError || !product ? (
            <p className="admin-alert-error text-sm">
              {(error as { data?: { message?: string } } | undefined)?.data?.message ||
                t('ads.quickViewLoadError')}
            </p>
          ) : (
            <>
              {imagePaths.length > 0 ? (
                <div className="mb-4">
                  <p className="admin-text-subtle mb-2 text-[11px] font-semibold uppercase tracking-wide">
                    {t('ads.productImage')}
                  </p>
                  <CompactMediaStrip paths={imagePaths} sizeClassName="h-24 w-28" />
                </div>
              ) : (
                <p className="admin-text-subtle mb-4 text-xs">{t('ads.noImageUploaded')}</p>
              )}

              {videoPaths.length > 0 ? (
                <div className="mb-4">
                  <p className="admin-text-subtle mb-2 text-[11px] font-semibold uppercase tracking-wide">
                    {t('ads.productVideo')}
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {videoPaths.map((path, index) => {
                      const url = resolveAssetUrl(path)
                      if (!url) return null
                      return (
                        <video
                          key={`${path}-${index}`}
                          src={url}
                          controls
                          className="h-36 w-56 rounded-lg bg-black object-contain"
                        />
                      )
                    })}
                  </div>
                </div>
              ) : null}

              {documentPaths.length > 0 ? (
                <div className="mb-4">
                  <p className="admin-text-subtle mb-2 text-[11px] font-semibold uppercase tracking-wide">
                    {t('ads.productDocuments')}
                  </p>
                  <ul className="space-y-1.5">
                    {documentPaths.map((path, index) => {
                      const url = resolveAssetUrl(path)
                      return (
                        <li key={`${path}-${index}`}>
                          <a
                            href={url || undefined}
                            target="_blank"
                            rel="noreferrer"
                            className="text-sm font-semibold text-[#3B7FC7] hover:underline"
                          >
                            {t('ads.openDocument')} #{index + 1}
                          </a>
                        </li>
                      )
                    })}
                  </ul>
                </div>
              ) : null}

              <p className="admin-text mb-2 text-sm font-bold">{t('ads.basicInfo')}</p>
              <div className="grid gap-3 sm:grid-cols-2">
                {basicRows.map((row) => (
                  <DetailRow key={row.label} label={row.label} value={row.value} />
                ))}
              </div>

              {product.description?.trim() ? (
                <div className="mt-3">
                  <DetailRow
                    label={t('ads.productDescription')}
                    value={product.description.trim()}
                  />
                </div>
              ) : null}

              {product.shippingDescription?.trim() ? (
                <div className="mt-3">
                  <DetailRow
                    label={t('ads.shippingNotes')}
                    value={product.shippingDescription.trim()}
                  />
                </div>
              ) : null}

              {product.productAddress?.trim() ? (
                <div className="mt-3">
                  <DetailRow
                    label={t('sharedShipping.productAddress')}
                    value={product.productAddress.trim()}
                  />
                </div>
              ) : null}

              {product.supplierNotesEn?.trim() ? (
                <div className="mt-3">
                  <DetailRow
                    label={t('ads.adminNotes')}
                    value={product.supplierNotesEn.trim()}
                  />
                </div>
              ) : null}

              {retailRows.length > 0 ? (
                <div className="mt-5">
                  <p className="admin-text mb-2 text-sm font-bold">
                    {t('ads.retailPricing')}
                  </p>
                  <div className="grid gap-3 sm:grid-cols-2">
                    {retailRows.map((row) => (
                      <DetailRow key={row.label} label={row.label} value={row.value} />
                    ))}
                  </div>
                  {product.retailDescription?.trim() ? (
                    <div className="mt-3">
                      <DetailRow
                        label={t('ads.retailProductDescription')}
                        value={product.retailDescription.trim()}
                      />
                    </div>
                  ) : null}
                </div>
              ) : null}

              <div className="mt-5">
                <p className="admin-text mb-2 text-sm font-bold">{t('ads.supplierInfo')}</p>
                <div className="grid gap-3 sm:grid-cols-2">
                  <DetailRow label={t('ads.table.supplier')} value={supplierName} />
                  <DetailRow label={t('ads.mobile')} value={product.ownerPhone?.trim() ?? ''} />
                  <DetailRow label={t('ads.city')} value={product.ownerCity?.trim() ?? ''} />
                  <DetailRow
                    label={t('users.email')}
                    value={product.ownerEmail?.trim() ?? ''}
                  />
                </div>
              </div>
            </>
          )}
        </div>

        <div className="admin-border flex justify-end border-t px-5 py-3">
          <button
            type="button"
            onClick={onClose}
            className="rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[#326fae]"
          >
            {t('ads.quickViewClose')}
          </button>
        </div>
      </div>
    </div>
  )
}
