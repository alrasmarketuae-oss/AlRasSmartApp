import { api } from '../lib/api'

export type CartItem = {
  id: number
  productId: string
  productName: string
  quantity: number
  unitName: string
  unitPriceAed: number
  totalPriceAed: number
  imageUrl?: string | null
  videoUrl?: string | null
  availableQuantity?: number | null
}

export type Cart = { cartId?: number | string | null; items: CartItem[]; totalAed: number }

type Raw = Record<string, unknown>
const num = (value: unknown) => {
  const parsed = Number(String(value ?? '').replace(/,/g, ''))
  return Number.isFinite(parsed) ? parsed : 0
}
const get = (raw: Raw, ...keys: string[]) => {
  for (const key of keys) {
    const value = raw[key] ?? raw[key.charAt(0).toUpperCase() + key.slice(1)]
    if (value !== undefined && value !== null) return value
  }
  return undefined
}

function parseCart(data: Raw | null): Cart {
  const rawItems = (data && (get(data, 'items') as Raw[] | undefined)) || []
  const items = rawItems.map((item) => {
    const quantity = num(get(item, 'quantity'))
    const unitPriceAed = num(get(item, 'unitPriceAed', 'unitPrice'))
    return {
      id: num(get(item, 'id', 'cartItemId')),
      productId: String(get(item, 'productId') ?? ''),
      productName: String(get(item, 'productName', 'name') ?? ''),
      quantity,
      unitName: String(get(item, 'unitName', 'unit') ?? ''),
      unitPriceAed,
      totalPriceAed: num(get(item, 'totalPriceAed', 'totalPrice')) || unitPriceAed * quantity,
      imageUrl: (get(item, 'imageUrl', 'imagePath') as string | undefined) ?? null,
      videoUrl: (get(item, 'videoUrl') as string | undefined) ?? null,
      availableQuantity: get(item, 'availableQuantity') !== undefined ? num(get(item, 'availableQuantity')) : null,
    }
  })
  return {
    cartId: (data && (get(data, 'cartId') as string | number | undefined)) ?? null,
    items,
    totalAed: items.reduce((sum, item) => sum + item.totalPriceAed, 0),
  }
}

export const fetchCart = async () => parseCart(await api.get<Raw>('/Carts/me'))

export async function addCartItem(productId: string, quantity: number, unitName: string) {
  await api.post('/Carts/items', { productId, quantity, unitName })
  return fetchCart()
}

export async function reduceCartItem(cartItemId: number, quantity: number) {
  await api.patch(`/Carts/items/${cartItemId}`, { quantity })
  return fetchCart()
}

export async function removeCartItem(cartItemId: number) {
  await api.delete(`/Carts/items/${cartItemId}`)
  return fetchCart()
}

export const VAT_RATE = 0.05

export function cartTotals(items: CartItem[], deliveryFeeAed: number) {
  const subtotal = items.reduce((sum, item) => sum + item.totalPriceAed, 0)
  const vat = items.length ? subtotal * VAT_RATE : 0
  return { subtotal, vat, total: items.length ? subtotal + vat + deliveryFeeAed : 0 }
}

function lineWeightKg(quantity: number, unitName: string) {
  if (quantity <= 0) return 0
  const unit = unitName.trim().toLowerCase()
  if (['kg', 'kilogram', 'kilograms', 'kilo', 'kilos', 'kgs'].includes(unit)) return quantity
  if (['gram', 'grams', 'g'].includes(unit)) return quantity * 0.001
  if (['ton', 'tons', 'tonne', 'tonnes'].includes(unit)) return quantity * 1000
  return 0
}

export type ShippingQuote = { priceAed: number; excessKgRateAed: number; freeWeightKg: number }

/** Emirate base + each whole kg above the free weight × excess rate (CartEntity.shippingFeeWithExcess). */
export function shippingFee(items: CartItem[], quote: ShippingQuote) {
  const weight = items.reduce((sum, item) => sum + lineWeightKg(item.quantity, item.unitName), 0)
  const excess = weight - quote.freeWeightKg
  const rate = Math.min(Math.max(quote.excessKgRateAed, 0), 255)
  return quote.priceAed + (excess <= 0 ? 0 : Math.ceil(excess)) * rate
}

const EMIRATES_EN = ['Abu Dhabi', 'Dubai', 'Sharjah', 'Ajman', 'Umm Al Quwain', 'Ras Al Khaimah', 'Fujairah']
const EMIRATES_AR = ['أبو ظبي', 'دبي', 'الشارقة', 'عجمان', 'أم القيوين', 'رأس الخيمة', 'الفجيرة']
export const DEFAULT_EMIRATE = 'Dubai'

const normalize = (value: string) => value.trim().toLowerCase().replace(/\s+/g, ' ')

/** Canonical English emirate for a city name (UaeRetailEmirates.canonicalEmirateNameEn). */
export function matchEmirate(cityName: string): string | null {
  const value = normalize(cityName)
  if (!value) return null
  const index = EMIRATES_EN.findIndex((en, i) => {
    const e = normalize(en)
    const a = normalize(EMIRATES_AR[i])
    return value === e || value === a || value.startsWith(`${e} `) || value.startsWith(`${a} `)
  })
  return index < 0 ? null : EMIRATES_EN[index]
}

const clampByte = (value: unknown, fallback: number) => {
  const parsed = Math.round(num(value))
  return value === undefined || value === null || value === '' ? fallback : Math.min(Math.max(parsed, 0), 255)
}

export async function fetchShippingQuote(emirate: string): Promise<ShippingQuote> {
  const data = await api.get<Raw>('/InternalDomesticShipping/price', { query: { emirate } })
  return {
    priceAed: num(get(data ?? {}, 'priceAed')),
    excessKgRateAed: clampByte(get(data ?? {}, 'excessKgRateAed'), 0),
    freeWeightKg: clampByte(get(data ?? {}, 'freeWeightKg'), 10),
  }
}

export type PaymentMethod = 'Online' | 'CashOnDelivery'

export type CheckoutBody = {
  paymentMethodName: PaymentMethod
  shippingCostAed: number
  isSelfPickup: boolean
  addressId?: string
  cityName?: string
}

export type CheckoutResult = { orderGroupId: string; firstOrderId: number | null; pendingOrderId: string | null; isOnlinePending: boolean }

export async function checkoutCart(body: CheckoutBody, signal?: AbortSignal): Promise<CheckoutResult> {
  const data = (await api.post<Raw>('/Orders', body, { signal })) ?? {}
  const orders = (get(data, 'orders') as Raw[] | undefined) ?? []
  const first = orders[0] ? get(orders[0], 'id', 'orderId') : get(data, 'orderId', 'id')
  const pending = get(data, 'pendingOrderId')
  const method = String(get(data, 'paymentMethod') ?? '').toLowerCase()
  const status = String(get(data, 'status') ?? '').toLowerCase()
  return {
    orderGroupId: String(get(data, 'orderGroupId') ?? ''),
    firstOrderId: first === undefined ? null : num(first) || null,
    pendingOrderId: pending === undefined || pending === null ? null : String(pending).trim() || null,
    isOnlinePending: pending !== undefined && pending !== null && (method === 'online' || status === 'pendingpayment'),
  }
}

/** Best-effort cleanup when the buyer cancels while the checkout request is in flight. */
export const abortLatestCheckout = () => api.post('/Orders/client-abort/latest', {}).catch(() => undefined)

export async function createStripeCheckout(orderId: string) {
  const data = (await api.post<Raw>('/Payments/CreateStripeCheckout', { orderId, client: 'web' })) ?? {}
  return { sessionId: String(get(data, 'sessionId') ?? ''), checkoutUrl: String(get(data, 'checkoutUrl') ?? '') }
}

export type CheckoutStatus = { status: string; orderGroupId: string; orderStatusId: number | null }

export async function fetchCheckoutStatus(sessionId: string): Promise<CheckoutStatus> {
  const data = (await api.get<Raw>('/Payments/CheckoutStatus', { query: { sessionId } })) ?? {}
  const statusId = get(data, 'orderStatusId')
  return {
    status: String(get(data, 'status') ?? '').toLowerCase(),
    orderGroupId: String(get(data, 'orderGroupId') ?? ''),
    orderStatusId: statusId === undefined ? null : num(statusId),
  }
}

export type PendingPayment = { sessionId: string; checkoutUrl: string }
const PENDING_KEY = 'alras_web_pending_payment'

export function readPendingPayment(): PendingPayment | null {
  try {
    const value = JSON.parse(sessionStorage.getItem(PENDING_KEY) ?? 'null') as PendingPayment | null
    return value?.sessionId ? value : null
  } catch {
    return null
  }
}

export const writePendingPayment = (value: PendingPayment | null) =>
  value ? sessionStorage.setItem(PENDING_KEY, JSON.stringify(value)) : sessionStorage.removeItem(PENDING_KEY)
