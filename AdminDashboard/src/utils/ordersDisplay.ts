import type { Locale } from '../i18n/messages'

/** Home delivery vs self pickup — always follows dashboard locale (not raw API text). */
export function getDeliveryMethodLabel(
  isSelfPickup: boolean,
  locale: Locale = 'ar',
): string {
  if (isSelfPickup) {
    return locale === 'ar' ? 'استلام من المتجر' : 'Self pickup'
  }
  return locale === 'ar' ? 'توصيل للمنزل' : 'Home delivery'
}

/** City + street/building lines for order print sheets (retail delivery). */
export function resolveOrderDeliveryPrint(order: {
  isSelfPickup?: boolean
  deliveryCityName?: string | null
  deliveryAddressLine?: string | null
  destinationCountryName?: string | null
}): { city: string; addressLine: string } | null {
  if (order.isSelfPickup) return null

  const city =
    order.deliveryCityName?.trim() ||
    order.destinationCountryName?.trim() ||
    ''
  const addressLine = order.deliveryAddressLine?.trim() || ''

  if (!city && !addressLine) return null

  return {
    city: city || '—',
    addressLine: addressLine || '—',
  }
}

/** Formats order quantity without unnecessary trailing zeros (e.g. 1.5 instead of 1.500). */
export function formatOrderQuantity(quantity: number): string {
  if (!Number.isFinite(quantity) || quantity <= 0) return '—'
  return parseFloat(quantity.toFixed(3)).toString()
}

export function formatOrderQuantityWithUnit(quantity: number, unitName?: string | null): string {
  const formatted = formatOrderQuantity(quantity)
  if (formatted === '—') return '—'
  const unit = unitName?.trim()
  return unit ? `${formatted} ${unit}` : formatted
}

/** Order/offer line quantity — never product catalog stock. */
export function resolveOrderedQuantity(order: {
  quantity?: number | null
}): number {
  const qty = order.quantity
  return qty != null && qty > 0 ? qty : 0
}

/**
 * Request ads: quantity the client asked for on the advertisement.
 * Falls back to productAvailableQuantity, then order quantity.
 */
export function resolveRequiredQuantity(order: {
  requestedQuantity?: number | null
  productAvailableQuantity?: number | null
  quantity?: number | null
}): number {
  const requested = order.requestedQuantity
  if (requested != null && requested > 0) return requested
  const available = order.productAvailableQuantity
  if (available != null && available > 0) return available
  return resolveOrderedQuantity(order)
}

/** Supplier-offered quantity on a request (order line). */
export function resolveOfferedQuantity(order: {
  quantity?: number | null
}): number {
  return resolveOrderedQuantity(order)
}

type OrderAmountSource = {
  currency?: string | null
  vatAed?: number
  shippingCostAed?: number
  chargedShippingAed?: number
  chargedGrandTotalFormatted?: string | null
  chargedGrandTotalAed?: number
  customerTotalPriceFormatted?: string | null
  customerTotalPrice?: number
  amountFormatted?: string | null
}

/**
 * Prefer product/order currency for booking/offers (USD).
 * Only use charged AED checkout total when the order actually has AED extras
 * (VAT / domestic shipping / retail cart checkout).
 */
export function formatOrderAmount(order: OrderAmountSource): string {
  const currency = (order.currency ?? 'AED').trim().toUpperCase() || 'AED'
  const hasAedExtras =
    (order.vatAed ?? 0) > 0 ||
    (order.shippingCostAed ?? 0) > 0 ||
    (order.chargedShippingAed ?? 0) > 0

  // Prefer customer total (commission included) when this is not a retail cart checkout.
  if (!hasAedExtras) {
    if (order.customerTotalPriceFormatted?.trim()) return order.customerTotalPriceFormatted.trim()
    if ((order.customerTotalPrice ?? 0) > 0) {
      return `${Number(order.customerTotalPrice).toFixed(2)} ${currency}`
    }
  }

  if (currency === 'AED' || hasAedExtras) {
    if (order.chargedGrandTotalFormatted?.trim()) return order.chargedGrandTotalFormatted.trim()
    if ((order.chargedGrandTotalAed ?? 0) > 0) {
      return `${Number(order.chargedGrandTotalAed).toFixed(2)} AED`
    }
  }

  if (order.customerTotalPriceFormatted?.trim()) return order.customerTotalPriceFormatted.trim()
  if ((order.customerTotalPrice ?? 0) > 0) {
    return `${Number(order.customerTotalPrice).toFixed(2)} ${currency}`
  }

  if (order.chargedGrandTotalFormatted?.trim() && !/AED$/i.test(order.chargedGrandTotalFormatted) ) {
    return order.chargedGrandTotalFormatted.trim()
  }

  if (order.amountFormatted?.trim()) {
    // Avoid showing a hard-coded AED label for USD orders.
    if (currency === 'USD' && /AED$/i.test(order.amountFormatted) && !hasAedExtras) {
      if ((order.customerTotalPrice ?? 0) > 0) {
        return `${Number(order.customerTotalPrice).toFixed(2)} USD`
      }
    }
    return order.amountFormatted.trim()
  }

  return '—'
}
