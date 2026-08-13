import type { AdminOrder, AdminOrderStatusHistory } from '../../types/adminOrder'
import type { Locale } from '../../i18n/messages'
import { formatAdAmount, amountsLookEqual } from '../../utils/adsDisplay'
import {
  formatOrderQuantityWithUnit,
  getDeliveryMethodLabel,
  resolveOrderDeliveryPrint,
} from '../../utils/ordersDisplay'
import type { OrderPrintOptions } from '../../utils/orderPrintOptions'

function formatDetailDate(value: string, locale: Locale) {
  if (!value?.trim()) return '—'
  try {
    return new Intl.DateTimeFormat(locale === 'ar' ? 'ar-AE' : 'en-GB', {
      dateStyle: 'medium',
      timeStyle: 'short',
    }).format(new Date(value))
  } catch {
    return value
  }
}

function paymentLabel(name: string, t: (key: string) => string) {
  const normalized = name.trim().toLowerCase()
  if (normalized.includes('cash') || normalized.includes('cod') || normalized.includes('delivery')) {
    return t('orders.paymentCod')
  }
  if (normalized.includes('online') || normalized.includes('card') || normalized.includes('stripe')) {
    return t('orders.paymentOnline')
  }
  return name.trim() || '—'
}

export type OrderPrintSheetProps = {
  order: AdminOrder
  locale: Locale
  t: (key: string) => string
  options: OrderPrintOptions
  statusLabel: string
  typeName: string
  isRequestOrder?: boolean
  customerUnitPrice: string
  grandTotal: string
  supplierTotal: string
  supplierUnitPrice: string
  customerTotal?: string
  appProfit?: string
  chargedAmount?: string
  vatAmount?: string
  shippingAmount?: string
  orderedQuantity: number
  offeredQuantity?: number
  specsComments?: string
  statusHistory?: AdminOrderStatusHistory[]
}

export default function OrderPrintSheet({
  order,
  locale,
  t,
  options,
  statusLabel,
  typeName,
  isRequestOrder = false,
  customerUnitPrice,
  grandTotal,
  supplierTotal,
  supplierUnitPrice,
  customerTotal,
  appProfit,
  chargedAmount,
  vatAmount,
  shippingAmount,
  orderedQuantity,
  offeredQuantity,
  specsComments = '',
  statusHistory = [],
}: OrderPrintSheetProps) {
  const deliveryPrint = resolveOrderDeliveryPrint(order)
  const quantityValue = isRequestOrder ? (offeredQuantity ?? orderedQuantity) : orderedQuantity
  const quantityLabel = isRequestOrder ? t('orders.offeredQuantity') : t('orders.orderedQuantity')
  const showParties =
    (options.customerInfo || options.supplierInfo) &&
    (options.customerInfo ? 1 : 0) + (options.supplierInfo ? 1 : 0) > 0

  return (
    <section className="order-print-sheet hidden print:block">
      {options.orderSummary ? (
        <>
          <div className="mb-3 flex items-end justify-between gap-4 border-b border-slate-300 pb-2">
            <div>
              <p className="text-xs font-semibold text-slate-500">{t('orders.orderDetailsPage')}</p>
              <h2 className="text-xl font-bold text-slate-900">
                {t('orders.orderNumber')} #{order.id}
              </h2>
            </div>
            <div className="text-end text-xs text-slate-600">
              <p>
                <span className="font-semibold">{t('orders.createdOn')}: </span>
                {formatDetailDate(order.createdAt, locale)}
              </p>
              <p className="mt-0.5">
                <span className="font-semibold">{t('orders.currentStatus')}: </span>
                {statusLabel}
              </p>
            </div>
          </div>

          <div className="mb-3 grid grid-cols-4 gap-2 text-xs">
            <PrintCell label={t('orders.productName')} value={order.productName || '—'} bold />
            <PrintCell label={t('orders.unitPrice')} value={formatAdAmount(customerUnitPrice, locale)} bold />
            <PrintCell
              label={quantityLabel}
              value={formatOrderQuantityWithUnit(quantityValue, order.unitName)}
              bold
            />
            <PrintCell label={t('orders.totalAmount')} value={formatAdAmount(grandTotal, locale)} bold />
            <PrintCell label={t('orders.category')} value={order.categoryName || '—'} />
            <PrintCell label={t('orders.productType')} value={typeName || '—'} />
            <PrintCell
              label={t('orders.paymentMethod')}
              value={paymentLabel(order.paymentMethodName, t)}
            />
            <PrintCell
              label={t('orders.supplierTotalPrice')}
              value={formatAdAmount(supplierTotal, locale)}
            />
          </div>
        </>
      ) : null}

      {options.pricingBreakdown ? (
        <div className="mb-3 rounded border border-slate-200 p-3 text-xs">
          <h3 className="mb-2 text-sm font-bold text-slate-900">{t('orders.printSection.pricingBreakdown')}</h3>
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            <PrintCell label={t('orders.unitPrice')} value={formatAdAmount(customerUnitPrice, locale)} />
            {customerTotal ? (
              <PrintCell label={t('orders.customerTotalPrice')} value={formatAdAmount(customerTotal, locale)} />
            ) : null}
            {!amountsLookEqual(supplierUnitPrice, supplierTotal) ? (
              <PrintCell label={t('orders.supplierUnitPrice')} value={formatAdAmount(supplierUnitPrice, locale)} />
            ) : null}
            <PrintCell label={t('orders.supplierTotalPrice')} value={formatAdAmount(supplierTotal, locale)} />
            {vatAmount ? <PrintCell label={t('orders.vatAmount')} value={formatAdAmount(vatAmount, locale)} /> : null}
            {shippingAmount ? (
              <PrintCell label={t('orders.shippingCost')} value={formatAdAmount(shippingAmount, locale)} />
            ) : null}
            <PrintCell label={t('orders.grandTotal')} value={formatAdAmount(grandTotal, locale)} bold />
            {appProfit ? (
              <PrintCell label={t('orders.appProfitAmount')} value={formatAdAmount(appProfit, locale)} />
            ) : null}
            {chargedAmount && !amountsLookEqual(chargedAmount, grandTotal) ? (
              <PrintCell label={t('orders.chargedAmount')} value={formatAdAmount(chargedAmount, locale)} />
            ) : null}
          </div>
        </div>
      ) : null}

      {showParties ? (
        <div
          className={`grid gap-3 ${options.customerInfo && options.supplierInfo ? 'grid-cols-2' : 'grid-cols-1'}`}
        >
          {options.customerInfo ? (
            <div className="rounded border border-slate-300 p-3">
              <h3 className="mb-2 text-sm font-bold text-slate-900">
                {isRequestOrder ? t('reqsOffers.requestOwnerInfo') : t('orders.customerInfo')}
              </h3>
              <div className="space-y-1 text-xs text-slate-800">
                <p className="text-sm font-bold">{order.customerName || '—'}</p>
                <p dir="ltr">{order.customerPhone?.trim() || '—'}</p>
                <p className="break-all">{order.customerEmail || '—'}</p>
                <p>
                  <span className="font-semibold text-slate-500">{t('orders.deliveryMethod')}: </span>
                  {getDeliveryMethodLabel(Boolean(order.isSelfPickup), locale)}
                </p>
                {deliveryPrint ? (
                  <>
                    <p className="pt-1 text-[10px] font-semibold uppercase tracking-wide text-slate-500">
                      {t('orders.deliveryAddress')}
                    </p>
                    <p className="font-semibold text-slate-900">{deliveryPrint.city}</p>
                    <p className="whitespace-pre-wrap break-words text-slate-800">
                      {deliveryPrint.addressLine}
                    </p>
                  </>
                ) : (
                  <p className="text-slate-600">
                    {order.deliveryCityName?.trim() || order.destinationCountryName?.trim() || '—'}
                  </p>
                )}
              </div>
            </div>
          ) : null}

          {options.supplierInfo ? (
            <div className="rounded border border-slate-300 p-3">
              <h3 className="mb-2 text-sm font-bold text-slate-900">
                {isRequestOrder ? t('reqsOffers.offeringSupplierInfo') : t('orders.supplierInfo')}
              </h3>
              <div className="space-y-1 text-xs text-slate-800">
                <p className="text-sm font-bold">{order.supplierName || '—'}</p>
                <p dir="ltr">{order.supplierPhone?.trim() || '—'}</p>
                <p className="break-all">{order.supplierEmail || '—'}</p>
                {order.originCountryName?.trim() ? (
                  <p>
                    <span className="font-semibold text-slate-500">{t('ads.originCountry')}: </span>
                    {order.originCountryName.trim()}
                  </p>
                ) : null}
                {!amountsLookEqual(supplierUnitPrice, supplierTotal) ? (
                  <p>
                    <span className="font-semibold text-slate-500">{t('orders.supplierUnitPrice')}: </span>
                    {formatAdAmount(supplierUnitPrice, locale)}
                  </p>
                ) : null}
                <p>
                  <span className="font-semibold text-slate-500">{t('orders.supplierTotalPrice')}: </span>
                  {formatAdAmount(supplierTotal, locale)}
                </p>
              </div>
            </div>
          ) : null}
        </div>
      ) : null}

      {options.specifications && specsComments.trim() ? (
        <div className="mt-3 rounded border border-slate-200 p-3 text-xs">
          <h3 className="mb-1 text-sm font-bold text-slate-900">{t('orders.specificationsComments')}</h3>
          <p className="whitespace-pre-wrap text-slate-800">{specsComments.trim()}</p>
        </div>
      ) : null}

      {options.statusHistory && statusHistory.length > 0 ? (
        <div className="mt-3 rounded border border-slate-200 p-3 text-xs">
          <h3 className="mb-2 text-sm font-bold text-slate-900">{t('orders.tabHistory')}</h3>
          <ul className="space-y-1">
            {statusHistory.map((entry) => (
              <li key={entry.id} className="flex flex-wrap justify-between gap-2 border-b border-slate-100 py-1 last:border-0">
                <span className="font-semibold">
                  {locale === 'ar'
                    ? entry.statusNameAr?.trim() || entry.statusNameEn
                    : entry.statusNameEn?.trim() || entry.statusNameAr}
                </span>
                <span className="text-slate-600">{formatDetailDate(entry.createdAtUtc, locale)}</span>
              </li>
            ))}
          </ul>
        </div>
      ) : null}
    </section>
  )
}

function PrintCell({
  label,
  value,
  bold = false,
}: {
  label: string
  value: string
  bold?: boolean
}) {
  return (
    <div className="rounded border border-slate-200 p-2">
      <p className="font-semibold text-slate-500">{label}</p>
      <p className={`mt-0.5 ${bold ? 'font-bold text-slate-900' : 'font-semibold text-slate-800'}`}>
        {value}
      </p>
    </div>
  )
}
