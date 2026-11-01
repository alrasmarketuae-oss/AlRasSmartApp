import {
  hasMainCategory,
  isBookingProduct,
  isNegotiable,
  isOfferProduct,
  isPureRetailProduct,
  isRequestProduct,
  parseNumber,
} from '../products/productRules'
import { UNIT_OPTIONS, canonicalUnit } from '../products/units'
import { ownerListingPrice } from '../seller/listingRules'
import type { MyListing } from '../seller/sellerApi'
import { alwaysShowsPrice, EMPTY_AD_FORM, type AdForm, type AdType, type BookingPriceType, type Fulfillment } from './createAdApi'

const text = (value: unknown) => (value === null || value === undefined ? '' : String(value).trim())
const first = (...values: unknown[]) => values.map(text).find(Boolean) ?? ''

const groupedNumber = (value: number, decimals: number) =>
  value > 0 ? value.toLocaleString('en-US', { maximumFractionDigits: decimals, useGrouping: true }) : ''

/** `_resolveEditProductType`: hybrids and category listings stay on Categories. */
export function editTypeOf(p: MyListing): AdType | '' {
  if (hasMainCategory(p) && p.hasRetailPricing) return 'Categories'
  switch (p.productTypeId) {
    case 1:
      return hasMainCategory(p) ? 'Categories' : 'Retail'
    case 2:
      return 'Booking'
    case 3:
      return 'Offers'
    case 4:
      return 'Requests'
  }
  if (isRequestProduct(p)) return 'Requests'
  if (isOfferProduct(p)) return 'Offers'
  if (isBookingProduct(p)) return 'Booking'
  if (isPureRetailProduct(p)) return 'Retail'
  return hasMainCategory(p) ? 'Categories' : ''
}

function unitOption(value: string, fallback: string) {
  const unit = canonicalUnit(value)
  return (UNIT_OPTIONS as readonly string[]).includes(unit) ? unit : fallback
}

function fulfillmentOf(p: MyListing): Fulfillment {
  if (p.requestTypeId === 1) return 'Local'
  if (p.requestTypeId === 2) return 'Reexport'
  const name = first(p.requestTypeNameEn, p.requestTypeName, typeof p.requestType === 'string' ? p.requestType : p.requestType?.nameEn).toLowerCase()
  if (name.includes('export')) return 'Reexport'
  if (name.includes('local')) return 'Local'
  return ''
}

function bookingPriceTypeOf(p: MyListing): BookingPriceType {
  const name = first(p.bookingPriceTypeNameEn, p.bookingPriceTypeName).toUpperCase()
  if (name === 'FOB' || name === 'CNF' || name === 'CIF') return name
  return (['', 'FOB', 'CNF', 'CIF'] as const)[p.bookingPriceTypeId ?? 0] ?? ''
}

const packing = (value: unknown) => {
  const n = Math.trunc(parseNumber(value) ?? 0)
  return n >= 1 && n <= 255 ? String(n) : ''
}

export function listingMediaPaths(p: MyListing): string[] {
  const images = (p.images ?? []).map((item) => (typeof item === 'string' ? item : item?.path || item?.imagePath || item?.ImagePath || '')).filter(Boolean)
  const videos = [p.videoPath, ...(p.videos ?? []).map((v) => v.path || v.videoPath || v.url), ...(p.videoPaths ?? [])].map(text).filter(Boolean)
  return [...new Set([...images, ...videos])]
}

export type EditPrefill = {
  form: AdForm
  canonicalName: string
  loadedName: string
  canonicalSpecs: string
  loadedSpecs: string
}

/** `loadProductForEdit`: prefill from the My Ads item, in the language the ad was written in. */
export function prefillFromListing(p: MyListing): EditPrefill {
  const type = editTypeOf(p)
  const authoredAr = text(p.createdLanguage).toLowerCase().startsWith('ar')
  const canonicalName = first(p.nameEn, p.productName)
  const loadedName = authoredAr ? first(p.nameAr, p.nameEn, p.productName) : first(p.nameEn, p.productName, p.nameAr)
  const canonicalSpecs = first(p.descriptionEn, p.description)
  const loadedSpecs = authoredAr ? first(p.descriptionAr, p.descriptionEn, p.description) : first(p.descriptionEn, p.description, p.descriptionAr)

  const form: AdForm = { ...EMPTY_AD_FORM, type, name: loadedName, specs: loadedSpecs }
  form.quantity = groupedNumber(Math.trunc(parseNumber(p.quantity) ?? 0), 0)
  form.unit = unitOption(first(p.unitNameEn, p.unitName), 'Ton')
  form.categoryId = type === 'Categories' && (p.categoryId ?? 0) > 0 ? (p.categoryId ?? null) : null
  form.negotiable = isNegotiable(p)
  form.showPrice = alwaysShowsPrice(type) || p.showPrice === true
  form.currency = type === 'Booking' ? 'USD' : type === 'Retail' ? 'AED' : first(p.ownerCurrency, p.currency).toUpperCase() === 'USD' ? 'USD' : 'AED'

  const details = text(p.packagingDetails)
  form.packingKg = packing(p.packaging)
  form.otherPacking = !!details
  form.packingOther = details

  const listed = ownerListingPrice(p)
  if (type === 'Offers') {
    const sale = parseNumber(p.priceUsd) ?? listed
    const pct = parseNumber(p.discountPercentage) ?? 0
    const before = sale > 0 && pct > 0 && pct < 100 ? sale / (1 - pct / 100) : sale
    form.afterDiscount = groupedNumber(sale, 2)
    form.beforeDiscount = groupedNumber(before, 2)
    form.days = first(p.offerDuration, p.discountDays, p.shippingDuration).replace(/\D/g, '')
  } else {
    form.price = groupedNumber(listed, 3)
    form.days = type === 'Requests' ? '' : text(p.shippingDuration).replace(/\D/g, '')
  }
  if (type === 'Requests') {
    const date = text(p.shippingDuration).match(/^\d{4}-\d{2}-\d{2}/)
    form.deliveryDate = date ? date[0] : ''
  }

  form.fulfillment = type === 'Requests' || type === 'Offers' || type === 'Categories' ? fulfillmentOf(p) : ''
  if (type === 'Booking') {
    const s = p.shipping ?? {}
    form.bookingPriceType = bookingPriceTypeOf(p)
    form.originCountry = first(p.originCountryNameEn, p.originCountryName, s.originCountryNameEn, s.originCountryName, p.routeFromCountry, s.routeFromCountry)
    form.originPort = first(p.loadingPortNameEn, p.loadingPortName, s.loadingPortNameEn, s.loadingPortName, p.routeFromPort, s.routeFromPort)
    form.destinationCountry = first(p.destinationCountryNameEn, p.destinationCountryName, s.destinationCountryNameEn, s.destinationCountryName, p.routeToCountry, s.routeToCountry)
    form.destinationPort = first(p.arrivalPortNameEn, p.arrivalPortName, s.arrivalPortNameEn, s.arrivalPortName, p.routeToPort, s.routeToPort)
  }

  const retailPrice = parseNumber(p.ownerRetailPrice) ?? parseNumber(p.retailPrice) ?? 0
  if (type === 'Categories' && (p.hasRetailPricing === true || retailPrice > 0)) {
    const retailDetails = text(p.retailPackagingDetails)
    form.retailEnabled = true
    form.retailPrice = groupedNumber(retailPrice, 3)
    form.retailQuantity = groupedNumber(Math.trunc(parseNumber(p.retailQuantity) ?? 0), 0)
    form.retailUnit = unitOption(first(p.retailUnitNameEn, p.retailUnitName), 'Kg')
    form.retailPackingKg = packing(p.retailPackaging)
    form.retailOtherPacking = !!retailDetails
    form.retailPackingOther = retailDetails
    form.retailSpecs = first(p.retailDescriptionEn, p.retailDescription, p.retailDescriptionAr)
  }

  return { form, canonicalName, loadedName, canonicalSpecs, loadedSpecs }
}
