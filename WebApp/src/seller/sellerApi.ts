import { api } from '../lib/api'
import type { ApiProduct } from '../products/types'

type Raw = Record<string, unknown>

/** `GET /Products/my-listings` item, normalised to the ApiProduct shape used by productRules. */
export type MyListing = ApiProduct & {
  status?: string | null
  statusNameAr?: string | null
  listingStatusCode: number
  isSellerPaused?: boolean | null
  isApproved?: boolean | null
  approvalStatus?: string | null
  priceUsd?: string | null
  pendingOffersCount: number
  retailDescription?: string | null
}

export type MyListingsResponse = { ownerName: string; products: MyListing[] }

const num = (value: unknown) => {
  const parsed = Number(String(value ?? '').replace(/,/g, '').trim())
  return Number.isFinite(parsed) ? parsed : 0
}
const positive = (value: unknown) => (num(value) > 0 ? num(value) : null)
const flag = (value: unknown) =>
  typeof value === 'boolean' ? value : ['true', 'yes', '1'].includes(String(value ?? '').trim().toLowerCase())

function normalizeListing(raw: Raw): MyListing {
  const images = Array.isArray(raw.images) ? raw.images.map(String).filter(Boolean) : []
  return {
    ...(raw as unknown as MyListing),
    productId: String(raw.productId ?? ''),
    images,
    categoryId: positive(raw.categoryId),
    productTypeId: positive(raw.productTypeId),
    requestTypeId: positive(raw.requestTypeId),
    bookingPriceTypeId: positive(raw.bookingPriceTypeId),
    viewsCount: num(raw.viewsCount),
    showPrice: flag(raw.showPrice),
    listingStatusCode: num(raw.listingStatusCode),
    pendingOffersCount: num(raw.pendingOffersCount),
    isSellerPaused: typeof raw.isSellerPaused === 'boolean' ? raw.isSellerPaused : null,
    retailDescriptionEn: (raw.retailDescriptionEn as string) || (raw.retailDescription as string) || null,
  }
}

export async function fetchMyListings(): Promise<MyListingsResponse> {
  const data = await api.get<Raw>('/Products/my-listings')
  const products = Array.isArray(data?.products) ? (data.products as Raw[]) : []
  return { ownerName: String(data?.ownerName ?? ''), products: products.map(normalizeListing).filter((p) => p.productId) }
}

export type ProductMessage = { message?: string }

export const setListingStatus = (productId: string, isActive: boolean) =>
  api.patch<ProductMessage>(`/Products/${encodeURIComponent(productId)}/listing-status`, { isActive })

export const markSoldOut = (productId: string) => api.patch<ProductMessage>(`/Products/${encodeURIComponent(productId)}/sold-out`, {})

export const deleteProduct = (productId: string) => api.delete<ProductMessage>(`/Products/${encodeURIComponent(productId)}`)

export const updateProductPrice = (productId: string, usdPrice: number, retailPrice?: number) =>
  api.patch<ProductMessage>(`/Products/${encodeURIComponent(productId)}/price`, retailPrice ? { usdPrice, retailPrice } : { usdPrice })

export type AdStatistics = {
  viewsCount: number
  cartAddsCount: number
  showCartAdds: boolean
  purchasesCount: number
  favoritesCount: number
  sharesCount: number
}

export async function fetchAdStatistics(productId: string): Promise<AdStatistics> {
  const data = await api.get<Raw>(`/Products/${encodeURIComponent(productId)}/statistics`)
  return {
    viewsCount: num(data?.viewsCount),
    cartAddsCount: num(data?.cartAddsCount),
    showCartAdds: flag(data?.showCartAdds),
    purchasesCount: num(data?.purchasesCount),
    favoritesCount: num(data?.favoritesCount),
    sharesCount: num(data?.sharesCount),
  }
}

export const ORDERS_PAGE_SIZE = 20

export type OrdersPage<T> = { items: T[]; page: number; totalPages: number; totalCount: number }

function toPage<T>(data: Raw | null, page: number, map: (raw: Raw) => T): OrdersPage<T> {
  const items = Array.isArray(data?.items) ? (data.items as Raw[]).map(map) : []
  const totalCount = num(data?.totalCount)
  const totalPages = num(data?.totalPages) || (totalCount ? Math.ceil(totalCount / ORDERS_PAGE_SIZE) : page)
  return { items, page: num(data?.page) || page, totalPages, totalCount }
}

const strings = (value: unknown) => (Array.isArray(value) ? value.map(String).filter((s) => s.trim()) : [])
const text = (value: unknown) => (value === null || value === undefined ? '' : String(value).trim())

/** One order / offer received on an ad (`MyRequestOfferDto`). */
export type AdOrder = {
  orderId: number
  productNameEn: string
  productNameAr: string
  productName: string
  descriptionEn: string
  descriptionAr: string
  productTypeId: number
  productTypeNameEn: string
  quantity: number
  unitNameEn: string
  unitNameAr: string
  unitPrice: number
  totalPrice: number
  currency: string
  unitPriceFormatted: string
  totalPriceFormatted: string
  showPrice: boolean
  statusId: number
  statusName: string
  statusAr: string
  canAccept: boolean
  canReject: boolean
  createdAt: string
  portNameEn: string
  portNameAr: string
  destinationCountryEn: string
  destinationCountryAr: string
  notesEn: string
  notesAr: string
  imagePaths: string[]
  videoPaths: string[]
  documentPaths: string[]
}

function mapAdOrder(raw: Raw): AdOrder {
  return {
    orderId: num(raw.orderId ?? raw.id),
    productNameEn: text(raw.productNameEn ?? raw.nameEn),
    productNameAr: text(raw.productNameAr ?? raw.nameAr),
    productName: text(raw.productName),
    descriptionEn: text(raw.productDescriptionEn ?? raw.descriptionEn ?? raw.productDescription ?? raw.description),
    descriptionAr: text(raw.productDescriptionAr ?? raw.descriptionAr),
    productTypeId: num(raw.productTypeId),
    productTypeNameEn: text(raw.productTypeNameEn ?? raw.productTypeName),
    quantity: num(raw.quantity),
    unitNameEn: text(raw.unitNameEn ?? raw.unitName),
    unitNameAr: text(raw.unitNameAr),
    unitPrice: num(raw.unitPrice),
    totalPrice: num(raw.totalPrice),
    currency: text(raw.currency),
    unitPriceFormatted: text(raw.unitPriceFormatted),
    totalPriceFormatted: text(raw.totalPriceFormatted),
    showPrice: raw.showPrice === undefined || raw.showPrice === null ? true : flag(raw.showPrice),
    statusId: num(raw.statusId),
    statusName: text(raw.statusName),
    statusAr: text(raw.statusAr),
    canAccept: raw.canAccept === true,
    canReject: raw.canReject === true,
    createdAt: text(raw.createdAt),
    portNameEn: text(raw.portNameEn ?? raw.portName),
    portNameAr: text(raw.portNameAr),
    destinationCountryEn: text(raw.destinationCountryNameEn ?? raw.destinationCountryName),
    destinationCountryAr: text(raw.destinationCountryNameAr),
    notesEn: text(raw.notesEn ?? raw.notes),
    notesAr: text(raw.notesAr),
    imagePaths: strings(raw.imagePaths),
    videoPaths: strings(raw.videoPaths),
    documentPaths: strings(raw.documentPaths),
  }
}

export async function fetchAdOrders(productId: string, page: number, signal?: AbortSignal) {
  const data = await api.get<Raw>('/Orders/getMyOffersOnMyRequests', { query: { page, pageSize: ORDERS_PAGE_SIZE, productId }, signal })
  return toPage(data, page, mapAdOrder)
}

/** `PATCH /Orders/{id}/status` — 2 = accept (Approved), 6 = reject (Cancelled). */
export const updateOrderStatus = (orderId: number, statusId: 2 | 6, signal?: AbortSignal) =>
  api.patch<ProductMessage>(`/Orders/${orderId}/status`, { statusId }, { signal })

/** Offers the current supplier submitted on other users' Request ads (`GET /Orders/myOffers`). */
export type SubmittedOffer = {
  orderId: number
  productNameEn: string
  productNameAr: string
  productName: string
  descriptionEn: string
  descriptionAr: string
  imagePath: string
  quantity: number
  unitNameEn: string
  unitNameAr: string
  statusId: number
  statusName: string
  statusAr: string
  totalPrice: number
  currency: string
  createdAt: string
}

function mapSubmittedOffer(raw: Raw): SubmittedOffer {
  const images = strings(raw.imagePaths)
  return {
    orderId: num(raw.id ?? raw.orderId),
    productNameEn: text(raw.productNameEn),
    productNameAr: text(raw.productNameAr),
    productName: text(raw.productName),
    descriptionEn: text(raw.productDescriptionEn ?? raw.productDescription),
    descriptionAr: text(raw.productDescriptionAr),
    imagePath: text(raw.primaryImagePath) || images[0] || '',
    quantity: num(raw.quantity),
    unitNameEn: text(raw.unitNameEn ?? raw.unitName),
    unitNameAr: text(raw.unitNameAr),
    statusId: num(raw.statusId),
    statusName: text(raw.statusName),
    statusAr: text(raw.statusLabelAr ?? raw.statusAr),
    totalPrice: num(raw.totalPrice),
    currency: text(raw.currency) || 'AED',
    createdAt: text(raw.createdAt ?? raw.orderDate),
  }
}

export async function fetchMySubmittedOffers(page: number, signal?: AbortSignal) {
  const data = await api.get<Raw>('/Orders/myOffers', { query: { page, pageSize: ORDERS_PAGE_SIZE }, signal })
  return toPage(data, page, mapSubmittedOffer)
}
