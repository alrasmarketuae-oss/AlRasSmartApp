import type { AdminOrder } from '../types/adminOrder'
import type { AdminProduct } from '../types/adminProduct'
import type { ProductShippingInfo } from '../types/productShipping'

/** Legacy mobile defaults for Offers/Retail that never collected real ports. */
function isLegacyOfferGeoPlaceholder(product: AdminProduct): boolean {
  const type = product.productTypeName.trim().toLowerCase()
  if (type !== 'offers' && type !== 'offer' && type !== 'retail') return false

  const origin = product.originCountryName.trim().toLowerCase()
  const destination = product.destinationCountryName.trim().toLowerCase()
  const loading = product.loadingPortName.trim().toLowerCase()
  const arrival = product.arrivalPortName.trim().toLowerCase()

  const countriesAreEgypt =
    (origin === '' || origin === 'egypt') &&
    (destination === '' || destination === 'egypt')
  const portsAreHurghada =
    (loading === '' || loading === 'hurghada') &&
    (arrival === '' || arrival === 'hurghada')

  return countriesAreEgypt && portsAreHurghada
}

export function shippingFromProduct(product: AdminProduct): ProductShippingInfo {
  const type = product.productTypeName.trim().toLowerCase()
  const isOffer = type === 'offers' || type === 'offer'
  const offerDuration = product.offerDuration?.trim() || ''

  if (isLegacyOfferGeoPlaceholder(product)) {
    return {
      shippingDescription: product.shippingDescription,
      shippingDuration: isOffer ? undefined : product.shippingDuration,
      offerDuration: isOffer ? offerDuration || product.shippingDuration : undefined,
      productAddress: product.productAddress,
    }
  }

  return {
    originCountryName: product.originCountryName,
    destinationCountryName: product.destinationCountryName,
    loadingPortName: product.loadingPortName,
    arrivalPortName: product.arrivalPortName,
    shippingDescription: product.shippingDescription,
    shippingRouteSummary: product.shippingRouteSummary,
    shippingDuration: isOffer ? undefined : product.shippingDuration,
    offerDuration: isOffer ? offerDuration || undefined : undefined,
    productAddress: product.productAddress,
  }
}

export function shippingFromOrder(order: AdminOrder): ProductShippingInfo {
  return {
    originCountryName: order.originCountryName,
    destinationCountryName: order.destinationCountryName,
    loadingPortName: order.loadingPortName,
    arrivalPortName: order.arrivalPortName,
    shippingDescription: order.shippingDescription,
    shippingRouteSummary: order.shippingRouteSummary,
    shippingDuration: order.shippingDuration,
    productAddress: order.productAddress,
    productLatitude: order.productLatitude,
    productLongitude: order.productLongitude,
    orderPortName: order.portName,
  }
}
