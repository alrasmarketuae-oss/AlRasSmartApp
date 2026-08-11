import { useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'
import type { AdminOrder } from '../../types/adminOrder'
import { buildListReturnState } from '../../utils/listPageParams'
import {
  formatAdAmount,
  productTypeBadgeClass,
  resolveOrderChannelTypeKey,
  resolveOrderChannelTypeName,
} from '../../utils/adsDisplay'
import { formatRelativeTime } from '../../utils/timeAgo'
import {
  formatOrderAmount,
  formatOrderQuantityWithUnit,
  resolveOfferedQuantity,
  resolveRequiredQuantity,
} from '../../utils/ordersDisplay'
import { getOrderStatusLabel, getOrderStatusStyle } from '../../utils/orderStatus'
import {
  isRequestOfferOrder,
  orderApprovalBlink,
  orderNeedsAttention,
} from '../../utils/orderWorkflow'
import OrderNotifyPartyDialog from './OrderNotifyPartyDialog'

type OrdersTableProps = {
  orders: AdminOrder[]
  /** When true, supplier column = offering supplier on a request. */
  isRequestOffersList?: boolean
}

type NotifyTarget = {
  userId: string
  name: string
  partyLabel: string
  orderId: number
}

function ProductThumb({ path, name }: { path: string | null | undefined; name: string }) {
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
        <path strokeLinecap="round" strokeLinejoin="round" d="m21 7.5-9-5.25L3 7.5m18 0-9 5.25m9-5.25v9l-9 5.25M3 7.5l9 5.25M3 7.5v9l9 5.25m0-9v9" />
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

function StatusIcon({ statusId }: { statusId: number }) {
  if (statusId === 5 || statusId === 7 || statusId === 2) {
    return (
      <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
        <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
      </svg>
    )
  }
  return (
    <svg className="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
      <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
    </svg>
  )
}

function orderAmount(order: AdminOrder): string {
  return formatOrderAmount(order)
}

export default function OrdersTable({
  orders,
  isRequestOffersList = false,
}: OrdersTableProps) {
  const { t, locale } = useAppPreferences()
  const location = useLocation()
  const listReturnState = buildListReturnState(location.pathname, location.search)
  const [notifyTarget, setNotifyTarget] = useState<NotifyTarget | null>(null)

  if (orders.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center px-6 py-20 text-center">
        <p className="admin-text text-sm font-medium">{t('orders.noOrders')}</p>
        <p className="admin-text-subtle mt-1 max-w-xs text-xs leading-relaxed">
          {t('orders.noOrdersHint')}
        </p>
      </div>
    )
  }

  return (
    <>
      <div className="overflow-x-auto">
        <table className={`w-full border-collapse text-sm ${isRequestOffersList ? 'min-w-[1380px]' : 'min-w-[1180px]'}`}>
          <thead>
            <tr className="admin-text-muted border-b border-slate-100 bg-[#f8fafc] dark:border-slate-700 dark:bg-slate-800/60">
              <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                {t('orders.table.orderNumber')}
              </th>
              <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                {t('orders.table.product')}
              </th>
              <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                {isRequestOffersList ? t('reqsOffers.offeringSupplier') : t('orders.table.supplier')}
              </th>
              {isRequestOffersList ? (
                <>
                  <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                    {t('reqsOffers.requiredQuantity')}
                  </th>
                  <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                    {t('reqsOffers.offeredQuantity')}
                  </th>
                </>
              ) : null}
              <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                {t('orders.table.type')}
              </th>
              <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                {t('orders.table.amount')}
              </th>
              <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                {t('orders.table.status')}
              </th>
              <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                {t('orders.table.date')}
              </th>
              <th className="px-4 py-3.5 text-start text-xs font-semibold sm:px-5">
                {t('orders.table.actions')}
              </th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order) => {
              const status = getOrderStatusStyle(order.statusId)
              const statusLabel =
                locale === 'ar'
                  ? order.statusLabelAr?.trim() || getOrderStatusLabel(order.statusId, locale)
                  : order.statusName?.trim() || getOrderStatusLabel(order.statusId, locale)
              const attention = orderNeedsAttention(order)
              const approvalBlink = orderApprovalBlink(order)
              // A supplier offer on a buyer request: either the dedicated offers
              // list, or an order whose product type is a request/offer.
              const isOfferRow = isRequestOffersList || isRequestOfferOrder(order)
              // Offers keep blinking until the order is actually received/delivered
              // (5/7) or reaches a terminal state (6 cancelled, 8 paid-to-supplier,
              // 9/10 return). i.e. blink for every non-settled offer status.
              const offerBlink =
                isOfferRow && ![5, 6, 7, 8, 9, 10].includes(order.statusId)
              const typeKey = resolveOrderChannelTypeKey(order)
              const typeName = resolveOrderChannelTypeName(order, locale)
              const companyLabel = order.customerName?.trim() || '—'
              // Approval stage drives the blink color: yellow while awaiting the
              // app/seller approval, green once the seller has approved. Request
              // offers keep blinking (green) until received. Other attention
              // states (e.g. return requests) keep the yellow cue.
              const attentionClass =
                approvalBlink === 'approved'
                  ? 'row-attention-offer'
                  : approvalBlink === 'pending'
                    ? 'row-attention-order'
                    : offerBlink
                      ? 'row-attention-offer'
                      : attention
                        ? isRequestOffersList
                          ? 'row-attention-offer'
                          : 'row-attention-order'
                        : 'bg-white'
              const buyerId = order.customerUserId?.trim() || ''
              const sellerId = order.supplierUserId?.trim() || ''

              return (
                <tr
                  key={order.id}
                  className={`border-t border-slate-100 transition hover:bg-slate-50/80 dark:border-slate-700/80 ${attentionClass}`}
                >
                  <td className="px-4 py-3.5 text-start sm:px-5">
                    <span className="admin-text inline-flex rounded-lg bg-slate-100 px-2.5 py-1 text-xs font-bold tabular-nums dark:bg-slate-800">
                      #{order.id}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-start sm:px-5">
                    <div className="flex items-center gap-3">
                      <ProductThumb
                        path={order.primaryImagePath ?? order.images?.[0]?.path}
                        name={order.productName}
                      />
                      <div className="min-w-0 text-start">
                        <p className="admin-text truncate text-sm font-bold">{order.productName}</p>
                        <p className="admin-text-muted mt-0.5 truncate text-[11px]">{companyLabel}</p>
                        <span
                          className={`mt-1 inline-flex rounded-md px-2 py-0.5 text-[10px] font-bold ${productTypeBadgeClass(typeKey)}`}
                        >
                          {typeName}
                        </span>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3.5 text-start sm:px-5">
                    <div className="flex items-center gap-2">
                      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-slate-100 text-[10px] font-bold text-slate-600">
                        {(order.supplierName || '—').slice(0, 2).toUpperCase()}
                      </span>
                      <span className="admin-text text-sm font-medium">{order.supplierName}</span>
                    </div>
                  </td>
                  {isRequestOffersList ? (
                    <>
                      <td className="admin-text px-4 py-3.5 text-start text-sm sm:px-5">
                        {formatOrderQuantityWithUnit(
                          resolveRequiredQuantity(order),
                          order.unitName,
                        )}
                      </td>
                      <td className="admin-text px-4 py-3.5 text-start text-sm font-semibold sm:px-5">
                        {formatOrderQuantityWithUnit(
                          resolveOfferedQuantity(order),
                          order.unitName,
                        )}
                      </td>
                    </>
                  ) : null}
                  <td className="admin-text px-4 py-3.5 text-start text-sm sm:px-5">{typeName}</td>
                  <td className="px-4 py-3.5 text-start text-sm font-bold text-emerald-600 sm:px-5">
                    {formatAdAmount(orderAmount(order), locale)}
                  </td>
                  <td className="px-4 py-3.5 text-start sm:px-5">
                    <span
                      className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-bold ${status.className}`}
                    >
                      <StatusIcon statusId={order.statusId} />
                      {statusLabel}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-start sm:px-5">
                    <span className="admin-text-muted inline-flex items-center gap-1.5 text-xs">
                      <CalendarIcon />
                      {formatRelativeTime(order.createdAt, locale)}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-start sm:px-5">
                    <div className="flex flex-wrap items-center gap-1.5">
                      <Link
                        to={`/orders/${order.id}`}
                        state={listReturnState}
                        className="inline-flex items-center gap-1.5 rounded-lg border border-[#3B7FC7]/40 bg-white px-3 py-1.5 text-xs font-bold text-[#3B7FC7] transition hover:bg-[#3B7FC7]/5"
                      >
                        <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" />
                          <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
                        </svg>
                        {t('orders.preview')}
                      </Link>
                      {buyerId ? (
                        <button
                          type="button"
                          onClick={() =>
                            setNotifyTarget({
                              userId: buyerId,
                              name: order.customerName || '',
                              partyLabel: isRequestOffersList
                                ? t('reqsOffers.requestOwnerInfo')
                                : t('orders.customerInfo'),
                              orderId: order.id,
                            })
                          }
                          className="inline-flex items-center rounded-lg border border-emerald-500/30 bg-emerald-50 px-2.5 py-1.5 text-xs font-bold text-emerald-700 transition hover:bg-emerald-100"
                        >
                          {t('orders.notifyBuyer')}
                        </button>
                      ) : null}
                      {sellerId ? (
                        <button
                          type="button"
                          onClick={() =>
                            setNotifyTarget({
                              userId: sellerId,
                              name: order.supplierName || '',
                              partyLabel: isRequestOffersList
                                ? t('reqsOffers.offeringSupplierInfo')
                                : t('orders.supplierInfo'),
                              orderId: order.id,
                            })
                          }
                          className="inline-flex items-center rounded-lg border border-amber-500/30 bg-amber-50 px-2.5 py-1.5 text-xs font-bold text-amber-800 transition hover:bg-amber-100"
                        >
                          {t('orders.notifySeller')}
                        </button>
                      ) : null}
                    </div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      <OrderNotifyPartyDialog
        open={notifyTarget != null}
        onClose={() => setNotifyTarget(null)}
        targetUserId={notifyTarget?.userId ?? ''}
        targetName={notifyTarget?.name ?? ''}
        partyLabel={notifyTarget?.partyLabel ?? ''}
        orderId={notifyTarget?.orderId ?? 0}
      />
    </>
  )
}
