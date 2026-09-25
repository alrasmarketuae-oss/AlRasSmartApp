import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import type { AdminProduct, AdminProductReviewLock } from '../../types/adminProduct'
import { buildListReturnState } from '../../utils/listPageParams'
import CompanyAvatar from '../ui/CompanyAvatar'
import {
  adStatusBadgeClass,
  displayAdProductTypeName,
  formatAdAmount,
  formatAdPriceTypeLabel,
  productTypeBadgeClassForProduct,
  resolveAdListStatus,
} from '../../utils/adsDisplay'
import { formatRelativeTime } from '../../utils/timeAgo'
import { useClaimProductReviewLockMutation } from '../../store'
import { getRtkErrorMessage } from '../../utils/rtkError'
import { normalizeProductReviewLock } from '../../store/normalizers'
import AdQuickViewDialog from './AdQuickViewDialog'

type AdsTableProps = {
  products: AdminProduct[]
  approvingId?: string | null
  rejectingId?: string | null
  onApprove?: (productId: string) => void
  onReject?: (productId: string) => void
  /** When true, owner column shows client/requester label (request ads). */
  isRequestList?: boolean
}

function ProductThumb({ path, name }: { path: string | null; name: string }) {
  const url = resolveAssetUrl(path)
  if (url) {
    return (
      <img
        src={url}
        alt={name}
        className="h-11 w-11 shrink-0 rounded-xl object-cover ring-1 ring-slate-200"
      />
    )
  }
  return (
    <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-[#eff6ff] text-[#3B7FC7]">
      <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="m21 7.5-9-5.25L3 7.5m18 0-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9"
        />
      </svg>
    </span>
  )
}

function CalendarIcon() {
  return (
    <svg className="h-3.5 w-3.5 shrink-0 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5" />
    </svg>
  )
}

function extractLockedPayload(err: unknown): AdminProductReviewLock | null {
  const data =
    (err as { data?: unknown } | null)?.data ??
    (err as { error?: unknown } | null)?.error
  if (!data || typeof data !== 'object') return null
  const normalized = normalizeProductReviewLock(data as Record<string, unknown>)
  return normalized.isLockedByOther ? normalized : null
}

export default function AdsTable({
  products,
  isRequestList = false,
}: AdsTableProps) {
  const { t, locale } = useAppPreferences()
  const location = useLocation()
  const navigate = useNavigate()
  const listReturnState = buildListReturnState(location.pathname, location.search)
  const [claimReviewLock] = useClaimProductReviewLockMutation()
  const [previewBusyId, setPreviewBusyId] = useState<string | null>(null)
  const [lockedLock, setLockedLock] = useState<AdminProductReviewLock | null>(null)
  const [previewError, setPreviewError] = useState<string | null>(null)
  const [quickViewProductId, setQuickViewProductId] = useState<string | null>(null)

  async function handlePreview(productId: string) {
    setPreviewError(null)
    setPreviewBusyId(productId)
    try {
      const result = await claimReviewLock({ productId }).unwrap()
      if (!result.isLockedByMe || result.isLockedByOther) {
        setLockedLock({
          ...result,
          isLockedByMe: false,
          isLockedByOther: true,
        })
        return
      }
      navigate(`/ads/${productId}`, { state: listReturnState })
    } catch (err) {
      const locked = extractLockedPayload(err)
      if (locked) {
        setLockedLock(locked)
        return
      }
      setPreviewError(getRtkErrorMessage(err as never, t('ads.reviewLockClaimError')))
    } finally {
      setPreviewBusyId(null)
    }
  }

  if (products.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center px-6 py-20 text-center">
        <p className="admin-text text-sm font-medium">{t('ads.noPendingAds')}</p>
        <p className="admin-text-subtle mt-1 max-w-xs text-xs leading-relaxed">
          {t('ads.noPendingHint')}
        </p>
      </div>
    )
  }

  return (
    <div className="overflow-x-auto">
      {previewError ? <div className="admin-alert-error mb-3 mx-4">{previewError}</div> : null}

      {lockedLock ? (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
          role="dialog"
          aria-modal="true"
          aria-labelledby="review-locked-title"
        >
          <div className="admin-card w-full max-w-md px-6 py-8 text-center shadow-xl">
            <p id="review-locked-title" className="text-lg font-bold text-amber-700 dark:text-amber-300">
              {t('ads.reviewLockedTitle')}
            </p>
            <p className="admin-text-muted mt-3 text-sm leading-relaxed">
              {lockedLock.agentName
                ? t('ads.reviewLockedMessage', { name: lockedLock.agentName })
                : lockedLock.message || t('ads.reviewLockedGeneric')}
            </p>
            <button
              type="button"
              className="keep-white mt-6 inline-block rounded-xl bg-[#3B7FC7] px-5 py-2.5 text-sm font-semibold text-white"
              onClick={() => setLockedLock(null)}
            >
              {t('ads.backToList')}
            </button>
          </div>
        </div>
      ) : null}

      <table className="w-full min-w-[1080px] border-collapse text-sm">
        <thead>
          <tr className="admin-text-muted border-b border-slate-100 bg-[#f8fafc] dark:border-slate-700 dark:bg-slate-800/60">
            <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
              {t('ads.table.product')}
            </th>
            <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
              {isRequestList ? t('ads.table.requestOwner') : t('ads.table.supplier')}
            </th>
            <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
              {t('ads.table.type')}
            </th>
            <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
              {t('ads.table.amount')}
            </th>
            <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
              {t('ads.table.status')}
            </th>
            {isRequestList ? (
              <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                {t('reqsOffers.offersTab')}
              </th>
            ) : null}
            <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
              {t('ads.table.date')}
            </th>
            <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
              {t('ads.table.actions')}
            </th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => {
            const listStatus = resolveAdListStatus(product)
            const isPreviewBusy = previewBusyId === product.productId
            const supplierName =
              product.ownerCompanyName?.trim() || product.ownerName || '—'
            const statusLabel =
              listStatus === 'pending'
                ? product.isEditResubmit
                  ? t('ads.editAdRequest')
                  : t('ads.statusPending')
                : listStatus === 'active'
                  ? t('ads.statusActive')
                  : t('ads.statusRejected')
            const typeName = displayAdProductTypeName(product, locale)
            const priceTypeLabel = formatAdPriceTypeLabel(product, t)
            const imagePath = product.primaryImagePath ?? product.imagePaths?.[0] ?? null
            const typeKey = product.productTypeName.trim().toLowerCase()
            const isRequestAd =
              isRequestList || typeKey === 'requests' || typeKey.includes('طلب')
            const isOfferAd = typeKey === 'offers' || typeKey.includes('عرض')
            const showPriceTypeBadge = priceTypeLabel !== '—'
            const pendingOffers = product.pendingOffersCount ?? 0
            // Offers still in progress (not yet received/settled) keep the row
            // blinking; falls back to new-offer count on older API responses.
            const activeOffers = Math.max(
              product.activeOffersCount ?? 0,
              pendingOffers,
            )
            const attentionClass =
              listStatus === 'pending'
                ? isOfferAd
                  ? 'row-attention-offer'
                  : isRequestAd
                    ? 'row-attention-request'
                    : 'row-attention-ad'
                : // Approved request ads keep blinking (green) while they still
                  // have offers in progress that have not been received yet.
                  isRequestList && activeOffers > 0
                  ? 'row-attention-offer'
                  : 'bg-white'

            return (
              <tr
                key={product.productId}
                className={`admin-border border-t border-slate-100 transition hover:bg-slate-50/80 dark:border-slate-700/80 ${attentionClass}`}
              >
                <td className="px-4 py-3.5 text-start sm:px-5">
                  <div className="flex items-center gap-3">
                    <ProductThumb path={imagePath} name={product.name} />
                    <div className="min-w-0 text-start">
                      <p className="admin-text truncate text-sm font-bold">{product.name}</p>
                      <p className="admin-text-muted mt-0.5 truncate text-[11px]">{supplierName}</p>
                      <span
                        className={`mt-1 inline-flex rounded-md px-2 py-0.5 text-[10px] font-bold ${productTypeBadgeClassForProduct(product)}`}
                      >
                        {typeName}
                      </span>
                      {showPriceTypeBadge ? (
                        <span className="mt-1 ms-1 inline-flex rounded-md bg-indigo-50 px-2 py-0.5 text-[10px] font-bold text-indigo-700 ring-1 ring-indigo-100">
                          {priceTypeLabel}
                        </span>
                      ) : null}
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3.5 text-start sm:px-5">
                  <div className="flex items-center gap-2">
                    <CompanyAvatar path={product.ownerImgPath} name={supplierName} />
                    <span className="admin-text text-sm font-medium">{supplierName}</span>
                  </div>
                </td>
                <td className="admin-text px-4 py-3.5 text-start text-sm sm:px-5">{typeName}</td>
                <td className="px-4 py-3.5 text-start text-sm font-bold text-emerald-600 sm:px-5">
                  {formatAdAmount(product.priceFormatted, locale)}
                </td>
                <td className="px-4 py-3.5 text-start sm:px-5">
                  <span
                    className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-bold ${adStatusBadgeClass(listStatus)}`}
                  >
                    {statusLabel}
                  </span>
                </td>
                {isRequestList ? (
                  <td className="px-4 py-3.5 text-start sm:px-5">
                    {pendingOffers > 0 ? (
                      <span className="inline-flex items-center gap-1.5 rounded-full bg-[#3B7FC7]/10 px-3 py-1 text-xs font-bold text-[#3B7FC7]">
                        <span className="inline-flex h-2 w-2 rounded-full bg-[#3B7FC7]" aria-hidden="true" />
                        {t('reqsOffers.pendingOffersOnAd', { count: pendingOffers })}
                      </span>
                    ) : activeOffers > 0 ? (
                      <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/10 px-3 py-1 text-xs font-bold text-emerald-600">
                        <span className="inline-flex h-2 w-2 rounded-full bg-emerald-500" aria-hidden="true" />
                        {t('reqsOffers.offersInProgressOnAd', { count: activeOffers })}
                      </span>
                    ) : (
                      <span className="admin-text-muted text-xs">—</span>
                    )}
                  </td>
                ) : null}
                <td className="px-4 py-3.5 text-start sm:px-5">
                  <span className="admin-text-muted inline-flex items-center gap-1.5 text-xs">
                    <CalendarIcon />
                    {formatRelativeTime(product.createdAt, locale)}
                  </span>
                </td>
                <td className="px-4 py-3.5 text-start sm:px-5">
                  <div className="flex flex-wrap items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => setQuickViewProductId(product.productId)}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-xs font-bold text-slate-700 transition hover:bg-slate-50 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
                    >
                      <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 3.75v4.5m0-4.5h4.5m-4.5 0L9 9m11.25-5.25v4.5m0-4.5h-4.5m4.5 0L15 9m-11.25 11.25v-4.5m0 4.5h4.5m-4.5 0L9 15m11.25 5.25v-4.5m0 4.5h-4.5m4.5 0L15 15" />
                      </svg>
                      {t('ads.quickView')}
                    </button>
                    <button
                      type="button"
                      disabled={isPreviewBusy || previewBusyId != null}
                      onClick={() => void handlePreview(product.productId)}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-[#3B7FC7]/40 bg-white px-3 py-1.5 text-xs font-bold text-[#3B7FC7] transition hover:bg-[#3B7FC7]/5 disabled:opacity-60"
                    >
                      {isPreviewBusy ? (
                        <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-[#3B7FC7] border-t-transparent" />
                      ) : (
                        <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" />
                          <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
                        </svg>
                      )}
                      {t('ads.preview')}
                    </button>
                  </div>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>

      <AdQuickViewDialog
        productId={quickViewProductId}
        onClose={() => setQuickViewProductId(null)}
      />
    </div>
  )
}
