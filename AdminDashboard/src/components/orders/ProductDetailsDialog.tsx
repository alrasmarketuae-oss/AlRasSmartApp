import { type ReactNode, useEffect } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import type { AdminOrder } from '../../types/adminOrder'
import { resolveOrderChannelTypeName } from '../../utils/adsDisplay'
import { formatOrderQuantityWithUnit } from '../../utils/ordersDisplay'
import CompactMediaStrip from './CompactMediaStrip'

type ProductDetailsDialogProps = {
  open: boolean
  order: AdminOrder
  onClose: () => void
}

function DetailRow({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="rounded-xl border border-slate-200 bg-slate-50/70 px-3 py-2.5 text-start dark:border-slate-700 dark:bg-slate-800/40">
      <p className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">{label}</p>
      <p className="admin-text mt-1 text-sm font-semibold break-words whitespace-pre-wrap">
        {value}
      </p>
    </div>
  )
}

export default function ProductDetailsDialog({ open, order, onClose }: ProductDetailsDialogProps) {
  const { t, locale } = useAppPreferences()

  useEffect(() => {
    if (!open) return
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [open, onClose])

  if (!open) return null

  const typeName = resolveOrderChannelTypeName(order, locale)

  const productImagePaths = (() => {
    const fromProduct = (order.productImagePaths ?? []).filter(Boolean)
    if (fromProduct.length > 0) return fromProduct
    const fromImages = order.images.map((img) => img.path).filter(Boolean)
    if (fromImages.length > 0) return fromImages
    return order.primaryImagePath?.trim() ? [order.primaryImagePath] : []
  })()

  const packagingDisplay = order.packagingDetails?.trim()
    ? order.packagingDetails.trim()
    : order.packaging != null && order.packaging > 0
      ? formatOrderQuantityWithUnit(order.packaging, order.unitName)
      : ''

  const availableQuantity =
    order.productAvailableQuantity != null && order.productAvailableQuantity >= 0
      ? formatOrderQuantityWithUnit(order.productAvailableQuantity, order.unitName)
      : ''

  const rows: { label: string; value: string }[] = [
    { label: t('ads.productType'), value: typeName },
    { label: t('ads.category'), value: order.categoryName?.trim() ?? '' },
    { label: t('ads.availableQuantity'), value: availableQuantity },
    { label: t('ads.packagingType'), value: packagingDisplay },
    { label: t('ads.originCountry'), value: order.originCountryName?.trim() ?? '' },
    { label: t('ads.destinationCountry'), value: order.destinationCountryName?.trim() ?? '' },
    { label: t('ads.loadingPort'), value: order.loadingPortName?.trim() ?? '' },
    { label: t('ads.arrivalPort'), value: order.arrivalPortName?.trim() ?? '' },
    { label: t('ads.shippingRoute'), value: order.shippingRouteSummary?.trim() ?? '' },
    { label: t('ads.shippingDuration'), value: order.shippingDuration?.trim() ?? '' },
    { label: t('ads.views'), value: String(order.productViewsCount ?? 0) },
  ].filter((row) => row.value.trim().length > 0)

  const description = order.productDescription?.trim() ?? ''
  const shippingNotes = order.shippingDescription?.trim() ?? ''
  const productAddress = order.productAddress?.trim() ?? ''

  return (
    <div
      className="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 p-4 print:hidden"
      role="dialog"
      aria-modal="true"
      aria-labelledby="product-details-dialog-title"
      onClick={onClose}
    >
      <div
        className="admin-card flex max-h-[88vh] w-full max-w-2xl flex-col overflow-hidden rounded-2xl shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="admin-border flex items-start justify-between gap-3 border-b px-5 py-4">
          <div className="min-w-0 text-start">
            <p className="admin-text-subtle text-[11px] font-semibold uppercase tracking-wide">
              {t('ads.productDetails')}
            </p>
            <h2
              id="product-details-dialog-title"
              className="admin-text mt-1 text-lg font-bold leading-snug break-words"
            >
              {order.productName || '—'}
            </h2>
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
          {productImagePaths.length > 0 ? (
            <div className="mb-4">
              <p className="admin-text-subtle mb-2 text-[11px] font-semibold uppercase tracking-wide">
                {t('ads.productImage')}
              </p>
              <div className="flex flex-wrap gap-2">
                <CompactMediaStrip paths={productImagePaths} sizeClassName="h-24 w-28" />
              </div>
            </div>
          ) : null}

          {rows.length > 0 ? (
            <div className="grid gap-3 sm:grid-cols-2">
              {rows.map((row) => (
                <DetailRow key={row.label} label={row.label} value={row.value} />
              ))}
            </div>
          ) : null}

          {description ? (
            <div className="mt-3">
              <DetailRow label={t('ads.productDescription')} value={description} />
            </div>
          ) : null}

          {shippingNotes ? (
            <div className="mt-3">
              <DetailRow label={t('ads.shippingNotes')} value={shippingNotes} />
            </div>
          ) : null}

          {productAddress ? (
            <div className="mt-3">
              <DetailRow label={t('orders.deliveryAddress')} value={productAddress} />
            </div>
          ) : null}

          {order.productLatitude != null && order.productLongitude != null ? (
            <div className="mt-3">
              <DetailRow
                label={t('orders.productCoordinates')}
                value={(
                  <span dir="ltr">
                    {`${order.productLatitude}, ${order.productLongitude}`}
                  </span>
                )}
              />
            </div>
          ) : null}
        </div>

        <div className="admin-border flex justify-end border-t px-5 py-3">
          <button
            type="button"
            onClick={onClose}
            className="admin-border rounded-xl border bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 dark:bg-slate-900 dark:text-slate-200"
          >
            {t('cancel')}
          </button>
        </div>
      </div>
    </div>
  )
}
