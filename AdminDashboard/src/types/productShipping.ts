export type ProductShippingInfo = {
  originCountryName?: string
  destinationCountryName?: string
  loadingPortName?: string
  arrivalPortName?: string
  shippingDescription?: string
  shippingRouteSummary?: string
  shippingDuration?: string
  /** When set, panel shows "Offer duration" instead of shipping duration. */
  offerDuration?: string
  productAddress?: string | null
  productLatitude?: number | null
  productLongitude?: number | null
  orderPortName?: string | null
}

function hasText(value?: string | null): value is string {
  return Boolean(value?.trim())
}

export function hasInternationalShipping(info: ProductShippingInfo): boolean {
  return (
    hasText(info.originCountryName) ||
    hasText(info.destinationCountryName) ||
    hasText(info.loadingPortName) ||
    hasText(info.arrivalPortName) ||
    hasText(info.shippingRouteSummary)
  )
}

export function hasDomesticShipping(info: ProductShippingInfo): boolean {
  return hasText(info.productAddress)
}

export function hasAnyShippingInfo(info: ProductShippingInfo): boolean {
  return (
    hasInternationalShipping(info) ||
    hasDomesticShipping(info) ||
    hasText(info.orderPortName) ||
    hasText(info.shippingDuration) ||
    hasText(info.offerDuration) ||
    hasText(info.shippingDescription)
  )
}

export function shippingTypeKey(info: ProductShippingInfo): 'international' | 'domestic' | 'none' {
  if (hasInternationalShipping(info)) {
    return 'international'
  }

  if (hasDomesticShipping(info) || hasText(info.orderPortName)) {
    return 'domestic'
  }

  return 'none'
}
