import { api } from '../lib/api'
import { parseNumber } from '../products/productRules'
import { unitApiName } from '../products/units'

export const AD_TYPES = ['Categories', 'Requests', 'Offers', 'Booking', 'Retail'] as const
export type AdType = (typeof AD_TYPES)[number]

export const AD_TYPE_LABEL = { Categories: 'categories', Requests: 'requests', Offers: 'offers', Booking: 'booking', Retail: 'retail' } as const

export const alwaysShowsPrice = (type: AdType | '') => type === 'Retail' || type === 'Booking' || type === 'Offers'
export const supportsFulfillment = (type: AdType | '') => type === 'Requests' || type === 'Offers' || type === 'Categories'

export type Fulfillment = '' | 'Local' | 'Reexport'
export type BookingPriceType = '' | 'FOB' | 'CNF' | 'CIF'
export const BOOKING_PRICE_TYPES = ['FOB', 'CNF', 'CIF'] as const

export type AdForm = {
  name: string
  type: AdType | ''
  categoryId: number | null
  specs: string
  price: string
  currency: 'AED' | 'USD'
  unit: string
  quantity: string
  beforeDiscount: string
  afterDiscount: string
  negotiable: boolean
  showPrice: boolean
  fulfillment: Fulfillment
  bookingPriceType: BookingPriceType
  originCountry: string
  originPort: string
  destinationCountry: string
  destinationPort: string
  /** Offer duration / shipping duration / delivery time, in days. */
  days: string
  /** Requests: required delivery date (yyyy-MM-dd). */
  deliveryDate: string
  packingKg: string
  otherPacking: boolean
  packingOther: string
  retailEnabled: boolean
  retailPrice: string
  retailUnit: string
  retailQuantity: string
  retailPackingKg: string
  retailOtherPacking: boolean
  retailPackingOther: string
  retailSpecs: string
}

export const EMPTY_AD_FORM: AdForm = {
  name: '',
  type: '',
  categoryId: null,
  specs: '',
  price: '',
  currency: 'AED',
  unit: 'Ton',
  quantity: '',
  beforeDiscount: '',
  afterDiscount: '',
  negotiable: true,
  showPrice: false,
  fulfillment: '',
  bookingPriceType: '',
  originCountry: '',
  originPort: '',
  destinationCountry: '',
  destinationPort: '',
  days: '',
  deliveryDate: '',
  packingKg: '',
  otherPacking: false,
  packingOther: '',
  retailEnabled: false,
  retailPrice: '',
  retailUnit: 'Kg',
  retailQuantity: '',
  retailPackingKg: '',
  retailOtherPacking: false,
  retailPackingOther: '',
  retailSpecs: '',
}

/** Same side effects as the app's `setSelectedType`. */
export function withType(form: AdForm, type: AdType): AdForm {
  return {
    ...form,
    type,
    currency: type === 'Booking' ? 'USD' : 'AED',
    showPrice: alwaysShowsPrice(type) ? true : form.showPrice,
    fulfillment: supportsFulfillment(type) ? form.fulfillment : '',
    bookingPriceType: type === 'Booking' ? form.bookingPriceType : '',
    categoryId: type === 'Categories' ? form.categoryId : null,
    retailEnabled: type === 'Categories' ? form.retailEnabled : false,
  }
}

export const num = (value: string) => parseNumber(value) ?? 0
const int = (value: string) => Math.trunc(num(value.replace(/\./g, '')))
export const daysOnly = (value: string) => value.replace(/\D/g, '').slice(0, 4)

/** 1-255 kg, anything else is rejected by the backend. */
export function packingValue(value: string): number | null {
  const n = int(value)
  return n >= 1 && n <= 255 ? n : null
}

export type MediaPayload = {
  draftImages: string[]
  draftVideos: { path: string; duration: number }[]
}

export type SubmitOptions = { isEdit: boolean; lang: 'en' | 'ar'; canonicalName?: string; loadedName?: string; canonicalSpecs?: string; loadedSpecs?: string }

function discountFor(form: AdForm) {
  if (form.type !== 'Offers') return null
  const before = num(form.beforeDiscount)
  const after = num(form.afterDiscount)
  const days = int(form.days)
  if (!(before > 0 && after > 0 && after < before && days > 0)) return null
  return Math.min(99, Math.max(1, Math.round(((before - after) / before) * 100)))
}

/** `CreateAdFormMapper.buildRequest` + `CreateAdProductRequest.toFormData`. */
export function buildProductForm(form: AdForm, media: MediaPayload, options: SubmitOptions): FormData {
  const { isEdit } = options
  const fields: Record<string, string> = {}
  const put = (key: string, value: string | number | null | undefined) => {
    const text = value === null || value === undefined ? '' : String(value).trim()
    if (text) fields[key] = text
  }
  const type = form.type
  const isRequest = type === 'Requests'
  const isOffers = type === 'Offers'
  const isCategories = type === 'Categories'

  const typedName = form.name.trim()
  const typedSpecs = form.specs.trim()
  const name = isEdit && options.canonicalName && typedName === (options.loadedName ?? '').trim() ? options.canonicalName : typedName
  const specs = isEdit && options.canonicalSpecs && typedSpecs === (options.loadedSpecs ?? '').trim() ? options.canonicalSpecs : typedSpecs

  const price = isOffers ? (num(form.afterDiscount) > 0 ? num(form.afterDiscount) : num(form.beforeDiscount)) : num(form.price)
  const quantity = int(form.quantity)
  const currency = type === 'Booking' ? 'USD' : type === 'Retail' ? 'AED' : isRequest && price <= 0 ? '' : form.currency
  const unit = isRequest && !form.quantity.trim() && !form.price.trim() ? '' : unitApiName(form.unit)

  fields.NameEn = name
  fields.USDPrice = String(price)
  fields.Currency = currency
  fields.Quantity = String(quantity)
  fields.UnitName = unit
  fields.Negotiable = String(form.negotiable)
  fields.ShowPrice = String(alwaysShowsPrice(type) || form.showPrice)
  if (isEdit) fields.DescriptionEn = specs
  else {
    fields.ProductTypeName = isCategories ? '' : type
    put('CreatedLanguage', options.lang)
    put('DescriptionEn', specs)
  }
  if (!isCategories) put('ProductTypeName', type)
  if (isCategories) put('CategoryId', form.categoryId)

  const discount = discountFor(form)
  if (discount !== null) put('DiscountPercentage', discount)
  if (isOffers) {
    const days = int(form.days)
    if (days > 0) {
      put('DiscountDays', days)
      put('OfferDuration', days)
    }
  }
  if (type === 'Booking' || type === 'Retail') put('ShippingDuration', form.days)
  if (isRequest) put('ShippingDuration', form.deliveryDate)

  if (form.otherPacking && form.packingOther.trim()) put('PackagingDetails', form.packingOther.slice(0, 60))
  else put('Packaging', packingValue(form.packingKg))

  if (supportsFulfillment(type)) put('RequestTypeName', form.fulfillment)
  if (type === 'Booking') {
    put('BookingPriceTypeName', form.bookingPriceType)
    put('OriginCountryName', form.originCountry)
    put('LoadingPortName', form.originPort)
    if (form.bookingPriceType !== 'FOB') {
      put('DestinationCountryName', form.destinationCountry)
      put('ArrivalPortName', form.destinationPort)
    }
  }

  if (isCategories && form.retailEnabled) {
    fields.EnableRetailPricing = 'true'
    put('RetailPrice', num(form.retailPrice))
    put('RetailUnitName', unitApiName(form.retailUnit))
    put('RetailQuantity', int(form.retailQuantity))
    if (form.retailOtherPacking && form.retailPackingOther.trim()) put('RetailPackagingDetails', form.retailPackingOther.slice(0, 60))
    else put('RetailPackaging', packingValue(form.retailPackingKg))
    put('RetailDescriptionEn', form.retailSpecs)
  } else if (isCategories && !isEdit) {
    fields.EnableRetailPricing = 'false'
  }

  if (!isEdit) {
    if (media.draftImages.length) fields.DraftImagePathsCsv = media.draftImages.join(',')
    const video = media.draftVideos[0]
    if (video) {
      fields.DraftVideoPath = video.path
      if (video.duration > 0) fields.DraftVideoDurationSeconds = String(video.duration)
    }
  }

  const body = new FormData()
  for (const [key, value] of Object.entries(fields)) body.append(key, value)
  return body
}

type Raw = Record<string, unknown>
export type ProductMutation = { productId: string; requiresAdminReview: boolean; message: string }

function mutationOf(data: Raw | null): ProductMutation {
  const raw = data ?? {}
  return {
    productId: String(raw.productId ?? raw.ProductId ?? ''),
    requiresAdminReview: raw.requiresAdminReview !== false,
    message: String(raw.message ?? ''),
  }
}

export const createProduct = async (body: FormData) => mutationOf(await api.upload<Raw>('/Products', body))

export const updateProduct = async (productId: string, body: FormData) =>
  mutationOf(await api.putUpload<Raw>(`/Products/${encodeURIComponent(productId)}`, body))

export const submitForReview = (productId: string) => api.post<unknown>(`/Products/${encodeURIComponent(productId)}/submit-for-review`, {})

export const confirmAssetsBatch = (productId: string, imagePaths: string[], video?: { path: string; duration: number }) =>
  api.post<unknown>(`/ProductAssets/${encodeURIComponent(productId)}/assets/confirm-batch`, {
    imagePaths,
    ...(video ? { videoPath: video.path, videoDurationSeconds: Math.min(180, Math.max(1, video.duration)) } : {}),
  })

export const confirmVideo = (productId: string, video: { path: string; duration: number }) =>
  api.post<unknown>(`/ProductAssets/${encodeURIComponent(productId)}/videos/confirm`, {
    path: video.path,
    videoDurationSeconds: Math.min(180, Math.max(1, video.duration)),
  })

export const deleteDraft = (path: string, keepalive = false) => api.delete<unknown>('/ProductAssets/draft', { body: { path }, keepalive })

/** Backend `NormalizeAssetPath`: strip the host and keep `/product-images/...`. */
export function normalizeRemoteImagePath(path: string) {
  let value = path.trim().replace(/\\/g, '/')
  if (/^https?:\/\//i.test(value)) {
    try {
      value = new URL(value).pathname
    } catch {
      // keep as-is
    }
  }
  const index = value.toLowerCase().indexOf('/product-images/')
  if (index >= 0) value = value.slice(index)
  return value && !value.startsWith('/') ? `/${value.replace(/^\/+/, '')}` : value
}

export const deleteRemoteImage = (productId: string, path: string) =>
  api.delete<unknown>(`/ProductAssets/${encodeURIComponent(productId)}/images`, { query: { path: normalizeRemoteImagePath(path) } })
