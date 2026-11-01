import { api } from '../lib/api'

export type CreateOrderBody = {
  toUserId: string
  productId: string
  supplierEmail: string
  unitName: string
  quantity: number
  unitPrice: number
  totalPrice: number
  paymentMethodName?: string
  notes?: string
  imagePaths?: string[]
  videoPaths?: string[]
  documentPaths?: string[]
  addressLine?: string
  cityName?: string
  shippingCostAed?: number
  portName?: string
}

type Raw = Record<string, unknown>

/** Order id the backend returns under one of several shapes (see order_remote_data_source). */
export function orderNumberOf(data: unknown): string {
  if (!data || typeof data !== 'object') return ''
  const raw = data as Raw
  const nested = (raw.order ?? raw.Order) as Raw | undefined
  const value = raw.orderId ?? raw.id ?? raw.orderNumber ?? nested?.id ?? nested?.orderId ?? raw.pendingOrderId
  return value === undefined || value === null ? '' : String(value)
}

export async function createOrder(body: CreateOrderBody) {
  const data = await api.post<Raw>('/Orders', {
    paymentMethodName: 'CashOnDelivery',
    notes: '',
    imagePaths: [],
    videoPaths: [],
    documentPaths: [],
    addressLine: '',
    cityName: '',
    shippingCostAed: 0,
    ...body,
    ...(body.portName ? {} : { portName: undefined }),
  })
  return { data, orderNumber: orderNumberOf(data) }
}

/** Staging upload used by "Submit offer" before creating the order. */
export async function uploadOfferMedia(file: File): Promise<string> {
  const form = new FormData()
  form.append('File', file)
  const kind = file.type.startsWith('video/') ? 'videos' : 'images'
  const data = await api.upload<unknown>(`/Orders/offer-staging/${kind}/upload`, form)
  if (typeof data === 'string') return data
  const raw = (data ?? {}) as Raw
  return String(raw.path ?? raw.url ?? raw.imageUrl ?? raw.imagePath ?? raw.videoPath ?? '')
}

const pick = (raw: Raw, ...keys: string[]) => {
  for (const key of keys) {
    const value = raw[key] ?? raw[key.charAt(0).toUpperCase() + key.slice(1)]
    if (value !== undefined && value !== null && String(value).trim()) return String(value).trim()
  }
  return ''
}
const num = (value: unknown) => {
  const parsed = Number(String(value ?? '').replace(/,/g, ''))
  return Number.isFinite(parsed) ? parsed : 0
}
const bool = (raw: Raw, key: string, fallback = false) => {
  const value = raw[key] ?? raw[key.charAt(0).toUpperCase() + key.slice(1)]
  if (value === undefined || value === null) return fallback
  if (typeof value === 'boolean') return value
  const text = String(value).trim().toLowerCase()
  return text === 'true' || text === '1' ? true : text === 'false' || text === '0' ? false : fallback
}
const list = (raw: Raw, key: string) => ((raw[key] ?? raw[key.charAt(0).toUpperCase() + key.slice(1)]) as unknown[] | undefined) ?? []
const strings = (raw: Raw, key: string) => list(raw, key).map((v) => String(v ?? '').trim()).filter(Boolean)
const hasArabic = (text: string) => /[\u0600-\u06FF]/.test(text)

/** Localized pair; legacy rows sometimes store Arabic in the *En field. */
export type Localized = { en: string; ar: string; fallback: string }
function localizedPair(raw: Raw, enKeys: string[], arKeys: string[]): Localized {
  let en = pick(raw, ...enKeys)
  let ar = pick(raw, ...arKeys)
  if (!ar && hasArabic(en)) [en, ar] = ['', en]
  else if (en && hasArabic(en) && ar) en = ''
  return { en, ar, fallback: en || ar }
}
export const localize = (value: Localized, isAr: boolean) => (isAr ? value.ar || value.en : value.en || value.ar) || value.fallback

export type OrderHistoryEntry = { statusId: number; nameEn: string; nameAr: string; createdAtUtc: string }
export type RelatedOrder = { id: number; productName: Localized }

export type MyOrder = {
  id: number
  productId: string
  productName: Localized
  productDescription: Localized
  productType: Localized
  categoryName: Localized
  unitName: Localized
  primaryImagePath: string
  imagePaths: string[]
  videoPaths: string[]
  statusId: number
  statusName: string
  statusLabelAr: string
  displayTotal: number
  currency: string
  quantity: number
  paymentMethod: number
  paymentMethodName: string
  createdAt: string
  isApproved: boolean
  portName: string
  refundedAtUtc: string
  stripeRefundId: string
  isRefunded: boolean
  returnReason: string
  returnRequestedAtUtc: string
  returnAdminResponse: string
  returnRespondedAtUtc: string
  statusHistory: OrderHistoryEntry[]
  relatedOrders: RelatedOrder[]
}

const VIDEO_PATH = /\.(mp4|mov|webm|m4v|avi|mkv)(\?|$)|\/(product|order)-videos\//i
export const isVideoPath = (path: string) => VIDEO_PATH.test(path)

export function parseMyOrder(raw: Raw): MyOrder {
  const images = list(raw, 'images')
    .map((item) => (typeof item === 'string' ? item : pick((item ?? {}) as Raw, 'path', 'imagePath', 'url')))
    .filter(Boolean)
  const productImages = strings(raw, 'productImagePaths')
  const charged = num(raw.chargedGrandTotalAed ?? raw.ChargedGrandTotalAed)
  const total = num(raw.totalPrice ?? raw.TotalPrice)
  const customerTotal = num(raw.customerTotalPrice ?? raw.CustomerTotalPrice)
  const formatted = pick(raw, 'chargedGrandTotalFormatted', 'amountFormatted', 'customerTotalPriceFormatted')
  return {
    id: num(raw.id ?? raw.Id),
    productId: pick(raw, 'productId'),
    productName: localizedPair(raw, ['productNameEn', 'nameEn', 'productName'], ['productNameAr', 'nameAr']),
    productDescription: localizedPair(raw, ['productDescriptionEn', 'descriptionEn', 'productDescription'], ['productDescriptionAr', 'descriptionAr']),
    productType: localizedPair(raw, ['productTypeNameEn', 'productTypeName'], ['productTypeNameAr']),
    categoryName: localizedPair(raw, ['categoryNameEn', 'categoryName'], ['categoryNameAr']),
    unitName: localizedPair(raw, ['unitNameEn', 'unitName'], ['unitNameAr']),
    primaryImagePath: pick(raw, 'primaryImagePath') || productImages[0] || '',
    imagePaths: images,
    videoPaths: strings(raw, 'videoPaths'),
    statusId: num(raw.statusId ?? raw.StatusId),
    statusName: pick(raw, 'statusName'),
    statusLabelAr: pick(raw, 'statusLabelAr'),
    displayTotal: charged > 0 ? charged : total > 0 ? total : customerTotal > 0 ? customerTotal : num(formatted.replace(/[^0-9.,]/g, '')),
    currency: pick(raw, 'currency').toUpperCase() || 'AED',
    quantity: num(raw.quantity ?? raw.Quantity),
    paymentMethod: num(raw.paymentMethod ?? raw.PaymentMethod),
    paymentMethodName: pick(raw, 'paymentMethodName'),
    createdAt: pick(raw, 'createdAt'),
    isApproved: bool(raw, 'isApproved'),
    portName: pick(raw, 'portName'),
    refundedAtUtc: pick(raw, 'refundedAtUtc'),
    stripeRefundId: pick(raw, 'stripeRefundId', 'refundId'),
    isRefunded: bool(raw, 'isRefunded'),
    returnReason: pick(raw, 'returnReason'),
    returnRequestedAtUtc: pick(raw, 'returnRequestedAtUtc'),
    returnAdminResponse: pick(raw, 'returnAdminResponse'),
    returnRespondedAtUtc: pick(raw, 'returnRespondedAtUtc'),
    statusHistory: list(raw, 'statusHistory').map((item) => {
      const h = (item ?? {}) as Raw
      return { statusId: num(h.statusId ?? h.StatusId), nameEn: pick(h, 'statusNameEn'), nameAr: pick(h, 'statusNameAr'), createdAtUtc: pick(h, 'createdAtUtc') }
    }),
    relatedOrders: list(raw, 'relatedOrders').map((item) => {
      const r = (item ?? {}) as Raw
      return { id: num(r.id ?? r.Id), productName: localizedPair(r, ['productNameEn', 'productName'], ['productNameAr']) }
    }),
  }
}

export const orderImage = (o: MyOrder) => [o.primaryImagePath, ...o.imagePaths].find((p) => p && !isVideoPath(p)) ?? ''
export const orderVideo = (o: MyOrder) => o.videoPaths[0] || (o.primaryImagePath && isVideoPath(o.primaryImagePath) ? o.primaryImagePath : '')
export const isOnlinePayment = (o: MyOrder) => o.paymentMethodName.trim().toLowerCase() === 'online' || o.paymentMethod === 1
export const isRetailOrder = (o: MyOrder) => {
  const type = (o.productType.en || o.productType.fallback).trim().toLowerCase()
  return type === 'retail' || type.includes('تجز')
}
export const canRequestReturn = (o: MyOrder) => isRetailOrder(o) && (o.statusId === 5 || o.statusId === 7) && !o.returnReason.trim()
export const canCancelOrder = (o: MyOrder) => [1, 11, 2, 3].includes(o.statusId)
export const hasRefundId = (o: MyOrder) => o.isRefunded || !!o.stripeRefundId

export type RequestOffer = {
  orderId: number
  productId: string
  productName: Localized
  productDescription: Localized
  productTypeId: number
  productTypeNameEn: string
  quantity: number
  unitName: Localized
  unitPrice: number
  totalPrice: number
  currency: string
  showPrice: boolean
  statusId: number
  statusName: string
  statusAr: string
  isApproved: boolean
  canAccept: boolean
  canReject: boolean
  createdAt: string
  portName: Localized
  destinationCountry: Localized
  notes: Localized
  imagePaths: string[]
  videoPaths: string[]
  documentPaths: string[]
}

export function parseRequestOffer(raw: Raw): RequestOffer {
  return {
    orderId: num(raw.orderId ?? raw.OrderId),
    productId: pick(raw, 'productId'),
    productName: localizedPair(raw, ['productNameEn', 'nameEn', 'productName'], ['productNameAr', 'nameAr']),
    productDescription: localizedPair(raw, ['productDescriptionEn', 'descriptionEn', 'productDescription', 'description'], ['productDescriptionAr', 'descriptionAr']),
    productTypeId: num(raw.productTypeId ?? raw.ProductTypeId),
    productTypeNameEn: pick(raw, 'productTypeNameEn', 'productTypeName'),
    quantity: num(raw.quantity ?? raw.Quantity),
    unitName: localizedPair(raw, ['unitNameEn', 'unitName'], ['unitNameAr']),
    unitPrice: num(raw.unitPrice ?? raw.UnitPrice),
    totalPrice: num(raw.totalPrice ?? raw.TotalPrice),
    currency: pick(raw, 'currency').toUpperCase(),
    showPrice: bool(raw, 'showPrice', true),
    statusId: num(raw.statusId ?? raw.StatusId),
    statusName: pick(raw, 'statusName'),
    statusAr: pick(raw, 'statusAr'),
    isApproved: bool(raw, 'isApproved'),
    canAccept: bool(raw, 'canAccept'),
    canReject: bool(raw, 'canReject'),
    createdAt: pick(raw, 'createdAt'),
    portName: localizedPair(raw, ['portNameEn', 'portName'], ['portNameAr']),
    destinationCountry: localizedPair(raw, ['destinationCountryNameEn', 'destinationCountryName'], ['destinationCountryNameAr']),
    notes: localizedPair(raw, ['notesEn', 'notes'], ['notesAr']),
    imagePaths: strings(raw, 'imagePaths'),
    videoPaths: strings(raw, 'videoPaths'),
    documentPaths: strings(raw, 'documentPaths'),
  }
}

/** Offers on Inquiry ads use "Accept Offer"; other ads use "Accept Order". */
export function isRequestProductOffer(o: RequestOffer) {
  if (o.productTypeId === 4) return true
  const type = o.productTypeNameEn.trim().toLowerCase()
  return type.includes('request') || type.includes('inquiry')
}

const pageItems = (data: unknown): Raw[] => {
  if (Array.isArray(data)) return data as Raw[]
  const raw = (data ?? {}) as Raw
  return ((raw.items ?? raw.Items) as Raw[] | undefined) ?? []
}

export const fetchMyOrders = async () => pageItems(await api.get('/Orders/myOrders', { query: { page: 1, pageSize: 20 } })).map(parseMyOrder)

export const fetchIncomingOrders = async () =>
  pageItems(await api.get('/Orders/getMyOffersOnMyRequests', { query: { page: 1, pageSize: 20 } })).map(parseRequestOffer)

export const fetchOrder = async (orderId: number | string) => parseMyOrder((await api.get<Raw>(`/Orders/${orderId}`)) ?? {})

/** PATCH status; online cancellations answer `{ order, refundMessage, refundMessageAr }`. */
export async function updateOrderStatus(orderId: number, statusId: number, signal?: AbortSignal) {
  const data = await api.patch<Raw | null>(`/Orders/${orderId}/status`, { statusId }, { signal })
  return { refundMessage: data ? pick(data, 'refundMessage') : '', refundMessageAr: data ? pick(data, 'refundMessageAr') : '' }
}

export const RETURN_MEDIA_ACCEPT = '.jpg,.jpeg,.png,.mp4,.mov,.webm'
export const RETURN_MEDIA_MAX_BYTES = 40 * 1024 * 1024

export async function requestOrderReturn(orderId: number, reason: string, files: File[]) {
  const form = new FormData()
  form.append('reason', reason)
  for (const file of files) form.append('mediaFiles', file)
  return parseMyOrder((await api.upload<Raw>(`/Orders/${orderId}/return`, form)) ?? {})
}

export type GeoPort = { id: number; portNameEn: string; portNameAr?: string | null; unLocode?: string | null }

export async function fetchPorts(countryName: string): Promise<GeoPort[]> {
  const data = await api.get<{ ports?: GeoPort[] } | GeoPort[]>(`/Geo/countries/${encodeURIComponent(countryName)}/ports`, { auth: false })
  return Array.isArray(data) ? data : (data?.ports ?? [])
}
