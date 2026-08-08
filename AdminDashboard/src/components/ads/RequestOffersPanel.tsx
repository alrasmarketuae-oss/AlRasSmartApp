import { useEffect, useMemo, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { PRODUCT_TYPE_REQUESTS } from '../../constants/productTypes'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import {
  useApproveRequestOfferMutation,
  useGetAdminOrdersQuery,
  useRejectRequestOfferMutation,
} from '../../store'
import type { AdminOrder } from '../../types/adminOrder'
import { buildListReturnState } from '../../utils/listPageParams'
import { formatAdAmount } from '../../utils/adsDisplay'
import { formatRelativeTime } from '../../utils/timeAgo'
import {
  formatOrderAmount,
  formatOrderQuantityWithUnit,
  resolveOfferedQuantity,
  resolveRequiredQuantity,
} from '../../utils/ordersDisplay'
import { getOrderStatusLabel, getOrderStatusStyle } from '../../utils/orderStatus'
import { getRtkErrorMessage } from '../../utils/rtkError'
import ContactSupplierDialog, {
  type ContactTarget,
} from '../shared/ContactSupplierDialog'
import WhatsAppPhoneLink from '../shared/WhatsAppPhoneLink'

type RequestOffersPanelProps = {
  productId: string
  onOffersCountChange?: (count: number) => void
}

type SortKey = 'bestMatch' | 'newest' | 'priceAsc' | 'priceDesc'

function offerAmount(order: AdminOrder): string {
  return formatOrderAmount(order)
}

function offerTotalNumber(order: AdminOrder): number {
  return Number(order.customerTotalPrice || order.totalPrice || 0)
}

function RankBadge({ rank }: { rank: number }) {
  const tone =
    rank === 1
      ? 'bg-amber-100 text-amber-700 ring-amber-200'
      : rank === 2
        ? 'bg-slate-200 text-slate-700 ring-slate-300'
        : rank === 3
          ? 'bg-orange-100 text-orange-800 ring-orange-200'
          : 'bg-slate-100 text-slate-600 ring-slate-200'

  return (
    <span
      className={`inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold ring-1 ${tone}`}
    >
      {rank}
    </span>
  )
}

function OfferThumb({ order }: { order: AdminOrder }) {
  const path = order.primaryImagePath ?? order.images?.[0]?.path ?? order.productImagePaths?.[0]
  const url = resolveAssetUrl(path)
  if (!url) return null
  return (
    <img
      src={url}
      alt=""
      className="h-10 w-10 rounded-lg object-cover ring-1 ring-slate-200"
    />
  )
}

export default function RequestOffersPanel({
  productId,
  onOffersCountChange,
}: RequestOffersPanelProps) {
  const { t, locale } = useAppPreferences()
  const location = useLocation()
  const listReturnState = buildListReturnState(location.pathname, location.search)
  const [sortKey, setSortKey] = useState<SortKey>('newest')
  const [contactTarget, setContactTarget] = useState<ContactTarget | null>(null)

  const { data, error, isLoading, isFetching } = useGetAdminOrdersQuery({
    page: 1,
    pageSize: 50,
    productTypeId: PRODUCT_TYPE_REQUESTS,
    productId,
  })

  const [approveOffer, { isLoading: isApproving }] = useApproveRequestOfferMutation()
  const [rejectOffer, { isLoading: isRejecting }] = useRejectRequestOfferMutation()

  const offers = data?.items ?? []
  const totalCount = data?.totalCount ?? 0

  useEffect(() => {
    onOffersCountChange?.(totalCount)
  }, [totalCount, onOffersCountChange])

  const sortedOffers = useMemo(() => {
    const list = [...offers]
    list.sort((a, b) => {
      if (sortKey === 'newest') {
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
      }
      if (sortKey === 'priceDesc') {
        return offerTotalNumber(b) - offerTotalNumber(a)
      }
      // bestMatch / priceAsc: lowest total first
      return offerTotalNumber(a) - offerTotalNumber(b)
    })
    return list
  }, [offers, sortKey])

  return (
    <section className="space-y-3">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="admin-text text-base font-bold">
          {t('reqsOffers.offersFromSuppliers', { count: totalCount })}
        </h2>
        <label className="admin-text-muted flex items-center gap-2 text-xs font-semibold">
          <span>{t('reqsOffers.sortBy')}</span>
          <select
            value={sortKey}
            onChange={(e) => setSortKey(e.target.value as SortKey)}
            className="admin-input h-8 rounded-lg px-2 text-xs font-semibold"
          >
            <option value="bestMatch">{t('reqsOffers.sortBestMatch')}</option>
            <option value="newest">{t('reqsOffers.sortNewest')}</option>
            <option value="priceAsc">{t('reqsOffers.sortPriceAsc')}</option>
            <option value="priceDesc">{t('reqsOffers.sortPriceDesc')}</option>
          </select>
        </label>
      </div>

      {error ? (
        <div className="admin-card rounded-2xl px-5 py-6 text-sm text-red-600 dark:text-red-400">
          {getRtkErrorMessage(error as never, t('reqsOffers.offersLoadError'))}
        </div>
      ) : isLoading ? (
        <div className="admin-card flex justify-center rounded-2xl py-16">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#3B7FC7] border-t-transparent" />
        </div>
      ) : offers.length === 0 ? (
        <div className="admin-card rounded-2xl px-5 py-10 text-center">
          <p className="admin-text-muted text-sm">{t('reqsOffers.noOffersYet')}</p>
        </div>
      ) : (
        <div className="space-y-3">
          {isFetching ? (
            <p className="admin-text-subtle text-center text-xs">{t('updating')}</p>
          ) : null}
          {sortedOffers.map((offer, index) => {
            const rank = index + 1
            const status = getOrderStatusStyle(offer.statusId)
            const statusLabel =
              locale === 'ar'
                ? offer.statusLabelAr?.trim() || getOrderStatusLabel(offer.statusId, locale)
                : offer.statusName?.trim() || getOrderStatusLabel(offer.statusId, locale)
            const needsReview = !offer.isAdminApproved && offer.statusId === 1
            const busy = isApproving || isRejecting
            const requiredQty = resolveRequiredQuantity(offer)
            const offeredQty = resolveOfferedQuantity(offer)
            const qtyDiff = offeredQty - requiredQty
            const unitPrice =
              offer.customerUnitPriceFormatted?.trim() ||
              (offer.customerUnitPrice > 0
                ? `${offer.customerUnitPrice.toFixed(2)} ${offer.currency || 'AED'}`
                : '—')
            const isBest = sortKey === 'bestMatch' && rank === 1
            const supplierInitials = (offer.supplierName || '—').slice(0, 2).toUpperCase()

            return (
              <article
                key={offer.id}
                className={`admin-card rounded-2xl p-4 shadow-sm sm:p-5 ${
                  isBest ? 'bg-emerald-50/40 ring-1 ring-emerald-200 dark:bg-emerald-950/20' : ''
                }`}
              >
                <div className="flex flex-col gap-4 lg:flex-row lg:items-start">
                  <div className="flex min-w-0 flex-1 gap-3">
                    <RankBadge rank={rank} />
                    <div className="min-w-0 flex-1 text-start">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-xs font-bold text-slate-600">
                          {supplierInitials}
                        </span>
                        <div className="min-w-0">
                          <p className="admin-text truncate text-sm font-bold">
                            {offer.supplierName}
                          </p>
                          <div className="mt-0.5 flex flex-wrap items-center gap-2">
                            <WhatsAppPhoneLink
                              phone={offer.supplierPhone}
                              className="text-[11px]"
                            />
                            {offer.isAdminApproved ? (
                              <span className="inline-flex rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-bold text-emerald-700">
                                {t('reqsOffers.verifiedSupplier')}
                              </span>
                            ) : null}
                            <span className="admin-text-muted text-[11px]">
                              {formatRelativeTime(offer.createdAt, locale)}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                        <div>
                          <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                            {t('reqsOffers.offeredQuantity')}
                          </p>
                          <p className="admin-text mt-0.5 text-sm font-bold">
                            {formatOrderQuantityWithUnit(offeredQty, offer.unitName)}
                            {qtyDiff > 0 ? (
                              <span className="ms-1 text-[11px] font-bold text-emerald-600">
                                +{formatOrderQuantityWithUnit(qtyDiff, offer.unitName)}
                              </span>
                            ) : null}
                          </p>
                        </div>
                        <div>
                          <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                            {t('reqsOffers.unitPrice')}
                          </p>
                          <p className="admin-text mt-0.5 text-sm font-bold">
                            {formatAdAmount(unitPrice, locale)}
                            {offer.unitName ? (
                              <span className="admin-text-muted text-xs font-medium">
                                {' '}
                                / {offer.unitName}
                              </span>
                            ) : null}
                          </p>
                        </div>
                        <div>
                          <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                            {t('reqsOffers.totalAmount')}
                          </p>
                          <p className="mt-0.5 text-sm font-bold text-emerald-600">
                            {formatAdAmount(offerAmount(offer), locale)}
                          </p>
                        </div>
                        <div>
                          <p className="admin-text-subtle text-[10px] font-semibold uppercase">
                            {t('orders.table.status')}
                          </p>
                          <span
                            className={`mt-0.5 inline-flex rounded-full px-2.5 py-1 text-[11px] font-bold ${status.className}`}
                          >
                            {statusLabel}
                          </span>
                          {needsReview ? (
                            <span className="mt-1 block text-[10px] font-semibold text-amber-600">
                              {t('reqsOffers.awaitingAdminReview')}
                            </span>
                          ) : null}
                        </div>
                      </div>

                      {(offer.notes?.trim() || offer.productDescription?.trim()) && (
                        <p className="admin-text-muted mt-3 line-clamp-2 text-xs">
                          {offer.notes?.trim() || offer.productDescription}
                        </p>
                      )}

                      <div className="mt-3">
                        <OfferThumb order={offer} />
                      </div>
                    </div>
                  </div>

                  <div className="flex w-full shrink-0 flex-col gap-2 lg:w-40">
                    {isBest ? (
                      <span className="inline-flex justify-center rounded-full bg-emerald-100 px-2.5 py-1 text-[10px] font-bold text-emerald-700">
                        {t('reqsOffers.bestMatch')}
                      </span>
                    ) : null}
                    <Link
                      to={`/orders/${offer.id}`}
                      state={listReturnState}
                      className="keep-white inline-flex h-9 items-center justify-center rounded-xl bg-[#2563eb] px-3 text-xs font-bold text-white transition hover:bg-[#1d4ed8]"
                    >
                      {t('reqsOffers.viewOffer')}
                    </Link>
                    {offer.supplierEmail || offer.supplierPhone || offer.supplierUserId ? (
                      <button
                        type="button"
                        onClick={() =>
                          setContactTarget({
                            displayName: offer.supplierName,
                            email: offer.supplierEmail,
                            phone: offer.supplierPhone,
                            userId: offer.supplierUserId,
                            avatarPath: offer.supplierAvatarPath,
                          })
                        }
                        className="admin-border inline-flex h-9 items-center justify-center rounded-xl border bg-white px-3 text-xs font-bold text-slate-600 transition hover:bg-slate-50"
                      >
                        {t('reqsOffers.contactSupplier')}
                      </button>
                    ) : null}
                    {needsReview ? (
                      <>
                        <button
                          type="button"
                          disabled={busy}
                          onClick={() => void approveOffer({ orderId: offer.id })}
                          className="inline-flex h-9 items-center justify-center rounded-xl bg-[#619D51] px-3 text-xs font-bold text-white disabled:opacity-60"
                        >
                          {t('orders.requestOfferApprove')}
                        </button>
                        <button
                          type="button"
                          disabled={busy}
                          onClick={() => void rejectOffer({ orderId: offer.id })}
                          className="inline-flex h-9 items-center justify-center rounded-xl bg-[#ef4444] px-3 text-xs font-bold text-white disabled:opacity-60"
                        >
                          {t('orders.requestOfferReject')}
                        </button>
                      </>
                    ) : null}
                  </div>
                </div>
              </article>
            )
          })}
        </div>
      )}

      <ContactSupplierDialog
        open={contactTarget != null}
        target={contactTarget}
        onClose={() => setContactTarget(null)}
      />
    </section>
  )
}
