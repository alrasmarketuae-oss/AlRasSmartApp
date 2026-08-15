import type { AdminOrder, AdminOrderStatusHistory } from '../../types/adminOrder'
import type { Locale } from '../../i18n/messages'
import { formatAdAmount, amountsLookEqual } from '../../utils/adsDisplay'
import {
  formatOrderQuantityWithUnit,
  getDeliveryMethodLabel,
  resolveOrderDeliveryPrint,
} from '../../utils/ordersDisplay'
import type { OrderPrintOptions } from '../../utils/orderPrintOptions'
import { formatUtcDateTime } from '../../utils/formatTimeAgo'
import BilingualNameLines from '../ui/BilingualNameLines'

function formatDetailDate(value: string, locale: Locale) {
  if (!value?.trim()) return '—'
  return formatUtcDateTime(value, locale)
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
    <div className="order-print-fit-host hidden print:block">
      <section className="order-print-sheet">
        {options.orderSummary ? (
          <>
            <div className="order-print-header">
              <div>
                <p className="order-print-kicker">{t('orders.orderDetailsPage')}</p>
                <h2 className="order-print-title">
                  {t('orders.orderNumber')} #{order.id}
                </h2>
              </div>
              <div className="order-print-meta">
                <p>
                  <span className="order-print-meta-label">{t('orders.createdOn')}: </span>
                  {formatDetailDate(order.createdAt, locale)}
                </p>
                <p>
                  <span className="order-print-meta-label">{t('orders.currentStatus')}: </span>
                  {statusLabel}
                </p>
              </div>
            </div>

            <div className="order-print-grid-4">
              <PrintCell label={t('orders.productName')} value={order.productName || '—'} bold />
              <PrintCell label={t('orders.unitPrice')} value={formatAdAmount(customerUnitPrice, locale)} price />
              <PrintCell
                label={quantityLabel}
                value={formatOrderQuantityWithUnit(quantityValue, order.unitName)}
                bold
              />
              <PrintCell label={t('orders.totalAmount')} value={formatAdAmount(grandTotal, locale)} price />
              <PrintCell label={t('orders.category')} value={order.categoryName || '—'} />
              <PrintCell label={t('orders.productType')} value={typeName || '—'} />
              <PrintCell
                label={t('orders.paymentMethod')}
                value={paymentLabel(order.paymentMethodName, t)}
              />
              <PrintCell
                label={t('orders.supplierTotalPrice')}
                value={formatAdAmount(supplierTotal, locale)}
                price
              />
            </div>
          </>
        ) : null}

        {options.pricingBreakdown ? (
          <div className="order-print-section">
            <h3 className="order-print-section-title">{t('orders.printSection.pricingBreakdown')}</h3>
            <div className="order-print-grid-3">
              <PrintCell label={t('orders.unitPrice')} value={formatAdAmount(customerUnitPrice, locale)} price />
              {customerTotal ? (
                <PrintCell label={t('orders.customerTotalPrice')} value={formatAdAmount(customerTotal, locale)} price />
              ) : null}
              {!amountsLookEqual(supplierUnitPrice, supplierTotal) ? (
                <PrintCell label={t('orders.supplierUnitPrice')} value={formatAdAmount(supplierUnitPrice, locale)} price />
              ) : null}
              <PrintCell label={t('orders.supplierTotalPrice')} value={formatAdAmount(supplierTotal, locale)} price />
              {vatAmount ? <PrintCell label={t('orders.vatAmount')} value={formatAdAmount(vatAmount, locale)} price /> : null}
              {shippingAmount ? (
                <PrintCell label={t('orders.shippingCost')} value={formatAdAmount(shippingAmount, locale)} price />
              ) : null}
              <PrintCell label={t('orders.grandTotal')} value={formatAdAmount(grandTotal, locale)} price />
              {appProfit ? (
                <PrintCell label={t('orders.appProfitAmount')} value={formatAdAmount(appProfit, locale)} price />
              ) : null}
              {chargedAmount && !amountsLookEqual(chargedAmount, grandTotal) ? (
                <PrintCell label={t('orders.chargedAmount')} value={formatAdAmount(chargedAmount, locale)} price />
              ) : null}
            </div>
          </div>
        ) : null}

        {showParties ? (
          <div
            className={`order-print-parties ${options.customerInfo && options.supplierInfo ? 'order-print-parties--two' : ''}`}
          >
            {options.customerInfo ? (
              <div className="order-print-section order-print-party">
                <h3 className="order-print-section-title">
                  {isRequestOrder ? t('reqsOffers.requestOwnerInfo') : t('orders.customerInfo')}
                </h3>
                <div className="order-print-party-body">
                  <div className="order-print-party-name">
                    <BilingualNameLines
                      nameEn={order.customerNameEn}
                      nameAr={order.customerNameAr}
                      fallback={order.customerName || '—'}
                      primaryClassName="order-print-party-name"
                      secondaryClassName="order-print-party-name text-xs mt-0.5"
                    />
                  </div>
                  <p dir="ltr">{order.customerPhone?.trim() || '—'}</p>
                  <p className="order-print-break">{order.customerEmail || '—'}</p>
                  <p>
                    <span className="order-print-inline-label">{t('orders.deliveryMethod')}: </span>
                    {getDeliveryMethodLabel(Boolean(order.isSelfPickup), locale)}
                  </p>
                  {deliveryPrint ? (
                    <>
                      <p className="order-print-address-label">{t('orders.deliveryAddress')}</p>
                      <p className="order-print-party-name">{deliveryPrint.city}</p>
                      <p className="order-print-address-line">{deliveryPrint.addressLine}</p>
                    </>
                  ) : (
                    <p>
                      {order.deliveryCityName?.trim() || order.destinationCountryName?.trim() || '—'}
                    </p>
                  )}
                </div>
              </div>
            ) : null}

            {options.supplierInfo ? (
              <div className="order-print-section order-print-party">
                <h3 className="order-print-section-title">
                  {isRequestOrder ? t('reqsOffers.offeringSupplierInfo') : t('orders.supplierInfo')}
                </h3>
                <div className="order-print-party-body">
                  <div className="order-print-party-name">
                    <BilingualNameLines
                      nameEn={order.supplierNameEn}
                      nameAr={order.supplierNameAr}
                      fallback={order.supplierName || '—'}
                      primaryClassName="order-print-party-name"
                      secondaryClassName="order-print-party-name text-xs mt-0.5"
                    />
                  </div>
                  <p dir="ltr">{order.supplierPhone?.trim() || '—'}</p>
                  <p className="order-print-break">{order.supplierEmail || '—'}</p>
                  {order.originCountryName?.trim() ? (
                    <p>
                      <span className="order-print-inline-label">{t('ads.originCountry')}: </span>
                      {order.originCountryName.trim()}
                    </p>
                  ) : null}
                  {!amountsLookEqual(supplierUnitPrice, supplierTotal) ? (
                    <p>
                      <span className="order-print-inline-label">{t('orders.supplierUnitPrice')}: </span>
                      <span className="order-print-price">{formatAdAmount(supplierUnitPrice, locale)}</span>
                    </p>
                  ) : null}
                  <p>
                    <span className="order-print-inline-label">{t('orders.supplierTotalPrice')}: </span>
                    <span className="order-print-price">{formatAdAmount(supplierTotal, locale)}</span>
                  </p>
                </div>
              </div>
            ) : null}
          </div>
        ) : null}

        {options.specifications && specsComments.trim() ? (
          <div className="order-print-section order-print-specs">
            <h3 className="order-print-section-title">{t('orders.specificationsComments')}</h3>
            <p className="order-print-specs-text">{specsComments.trim()}</p>
          </div>
        ) : null}

        {options.statusHistory && statusHistory.length > 0 ? (
          <div className="order-print-section order-print-history">
            <h3 className="order-print-section-title">{t('orders.tabHistory')}</h3>
            <ul className="order-print-history-list">
              {statusHistory.map((entry) => (
                <li key={entry.id} className="order-print-history-item">
                  <span className="order-print-history-status">
                    {locale === 'ar'
                      ? entry.statusNameAr?.trim() || entry.statusNameEn
                      : entry.statusNameEn?.trim() || entry.statusNameAr}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        ) : null}
      </section>
    </div>
  )
}

function PrintCell({
  label,
  value,
  bold = false,
  price = false,
}: {
  label: string
  value: string
  bold?: boolean
  price?: boolean
}) {
  return (
    <div className="order-print-cell">
      <p className="order-print-cell-label">{label}</p>
      <p
        className={[
          'order-print-cell-value',
          bold ? 'order-print-cell-value--bold' : '',
          price ? 'order-print-price' : '',
        ]
          .filter(Boolean)
          .join(' ')}
      >
        {value}
      </p>
    </div>
  )
}
