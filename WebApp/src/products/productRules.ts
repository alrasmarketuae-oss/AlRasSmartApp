import type { AccountFlags } from '../auth/AuthProvider'
import type { StringKey } from '../i18n/strings'
import { resolveMediaUrl } from '../lib/media'
import type { ApiProduct } from './types'

export type Viewer = AccountFlags & { userId: string }

const TYPE_NAMES = {
  retail: ['retail', 'تجزئة'],
  booking: ['booking', 'حجز', 'بوكينج'],
  offers: ['offers', 'عروض', 'عرض'],
  requests: ['requests', 'طلبات', 'طلب'],
}

const text = (value: unknown) => (value === null || value === undefined ? '' : String(value).trim())

export function parseNumber(value: unknown): number | null {
  const raw = text(value).replace(/,/g, '')
  if (!raw) return null
  const match = raw.match(/-?\d+(\.\d+)?/)
  if (!match) return null
  const parsed = Number(match[0])
  return Number.isFinite(parsed) ? parsed : null
}

function typeMatches(p: ApiProduct, names: string[]) {
  const candidates = [p.productTypeName, p.productTypeNameEn].map((v) => text(v).toLowerCase())
  return candidates.some((c) => c && names.includes(c))
}

export const hasMainCategory = (p: ApiProduct) => (p.categoryId ?? 0) > 0
export const isRetailProduct = (p: ApiProduct) => p.productTypeId === 1 || typeMatches(p, TYPE_NAMES.retail)
export const isBookingProduct = (p: ApiProduct) => p.productTypeId === 2 || typeMatches(p, TYPE_NAMES.booking)
export const isOfferProduct = (p: ApiProduct) => p.productTypeId === 3 || typeMatches(p, TYPE_NAMES.offers)
export const isRequestProduct = (p: ApiProduct) => p.productTypeId === 4 || typeMatches(p, TYPE_NAMES.requests)
export const isPureRetailProduct = (p: ApiProduct) => isRetailProduct(p) && !hasMainCategory(p)
export const isServiceTypeProduct = (p: ApiProduct) =>
  (p.productTypeId != null && p.productTypeId >= 1 && p.productTypeId <= 4) ||
  isRetailProduct(p) ||
  isBookingProduct(p) ||
  isOfferProduct(p) ||
  isRequestProduct(p)
export const isRetailFeedProduct = (p: ApiProduct) => isRetailProduct(p) || p.hasRetailPricing === true

/** Home feed for guest / company / supplier: main-category catalog (incl. hybrids). */
export function isCategoryHomeProduct(p: ApiProduct) {
  if (!hasMainCategory(p)) return false
  if (isRetailProduct(p)) return true
  return !isServiceTypeProduct(p)
}

export const shouldShowPrice = (p: ApiProduct) =>
  p.showPrice === true || isBookingProduct(p) || isOfferProduct(p) || isPureRetailProduct(p)

export function localized(ar: unknown, en: unknown, fallback: unknown, isAr: boolean) {
  const arText = text(ar)
  const enText = text(en)
  if (isAr) return arText || enText || text(fallback)
  return enText || text(fallback) || arText
}

export const productTitle = (p: ApiProduct, isAr: boolean) => localized(p.nameAr, p.nameEn, p.productName, isAr)

export function productDescription(p: ApiProduct, isAr: boolean, preferRetail: boolean) {
  if (preferRetail && p.hasRetailPricing) {
    const retail = localized(p.retailDescriptionAr, p.retailDescriptionEn, '', isAr)
    if (retail) return retail
  }
  return localized(p.descriptionAr, p.descriptionEn, p.description, isAr)
}

export const categoryLabel = (p: ApiProduct, isAr: boolean) =>
  localized(p.categoryNameAr, p.categoryNameEn, p.categoryName, isAr)

const isOwner = (p: ApiProduct, viewer: Viewer) =>
  !!viewer.userId && !!p.ownerId && viewer.userId.toLowerCase() === text(p.ownerId).toLowerCase()

export function canShowProductPrice(p: ApiProduct, viewer: Viewer, preferRetail: boolean) {
  if (!viewer.isAuthenticated) return false
  if (preferRetail && p.hasRetailPricing) return true
  if (viewer.isCompanyCustomer) return true
  return shouldShowPrice(p)
}

export function shouldShowAskForPrice(p: ApiProduct, viewer: Viewer, preferRetail: boolean) {
  if (isRequestProduct(p)) return false
  if (preferRetail && p.hasRetailPricing) return false
  if (!viewer.isAuthenticated) return false
  if (viewer.isCompanyCustomer) return false
  return !canShowProductPrice(p, viewer, preferRetail)
}

function priceForChannel(p: ApiProduct, preferRetail: boolean) {
  if (preferRetail && p.hasRetailPricing && text(p.retailPrice)) return text(p.retailPrice)
  return text(p.price) || text(p.priceAed) || text(p.usdPrice)
}

export function amountValue(p: ApiProduct, viewer: Viewer, preferRetail: boolean): number {
  const candidates: unknown[] = []
  if (isOwner(p, viewer)) {
    if (preferRetail && p.hasRetailPricing) candidates.push(p.ownerRetailPrice)
    candidates.push(p.ownerPrice, p.ownerUsdPrice)
  }
  candidates.push(priceForChannel(p, preferRetail))
  if (preferRetail) candidates.push(p.retailPrice)
  candidates.push(p.price, p.usdPrice)
  for (const candidate of candidates) {
    const value = parseNumber(candidate)
    if (value !== null && value > 0) return value
  }
  return 0
}

export function currencyCode(p: ApiProduct, viewer: Viewer) {
  if (isOwner(p, viewer) && text(p.ownerCurrency)) return text(p.ownerCurrency).toUpperCase()
  return text(p.currency).toUpperCase() || 'USD'
}

export const discountPercent = (p: ApiProduct) => Math.trunc(parseNumber(p.discountPercentage) ?? 0)

function discountDays(p: ApiProduct) {
  const days = parseNumber(p.discountDays)
  if (days && days > 0) return days
  return parseNumber(p.offerDuration) ?? 0
}

export function discountEndsAt(p: ApiProduct): Date | null {
  const created = parseUtc(p.createdAt)
  const days = discountDays(p)
  if (!created || days <= 0) return null
  return new Date(created.getTime() + days * 86_400_000)
}

export function isDiscountActive(p: ApiProduct) {
  if (!(parseNumber(p.discountDays) ?? 0)) return false
  const ends = discountEndsAt(p)
  return !ends || Date.now() < ends.getTime()
}

export function saleAndOriginal(p: ApiProduct, viewer: Viewer) {
  const sale = isOwner(p, viewer) ? amountValue(p, viewer, false) : parseNumber(p.price) ?? parseNumber(p.usdPrice) ?? 0
  const pct = discountPercent(p)
  const original = sale > 0 && pct > 0 && pct < 100 ? sale / (1 - pct / 100) : sale
  return { sale, original }
}

export function isSoldOut(p: ApiProduct, preferRetail: boolean) {
  if (p.isListingSoldOut) return true
  if (isRequestProduct(p)) return false
  const qty = parseNumber(preferRetail && p.hasRetailPricing && text(p.retailQuantity) ? p.retailQuantity : p.quantity)
  return qty !== null && qty <= 0
}

export function unitName(p: ApiProduct, isAr: boolean, preferRetail: boolean) {
  if (preferRetail && p.hasRetailPricing) {
    const retail = localized(p.retailUnitNameAr, p.retailUnitNameEn, p.retailUnitName, isAr)
    if (retail) return retail
  }
  return localized(p.unitNameAr, p.unitNameEn, p.unitName, isAr)
}

const SHORT_UNITS: Record<string, { en: string; ar: string }> = {
  kilogram: { en: 'kg', ar: 'كجم' },
  kilograms: { en: 'kg', ar: 'كجم' },
  kg: { en: 'kg', ar: 'كجم' },
  كيلوجرام: { en: 'kg', ar: 'كجم' },
}

export function displayUnit(unit: string, quantity: number, isAr: boolean) {
  const short = SHORT_UNITS[unit.trim().toLowerCase()]
  if (short) return isAr ? short.ar : short.en
  if (isAr || quantity === 1 || /[\u0600-\u06FF]/.test(unit)) return unit
  if (/(s|x|ch|sh)$/i.test(unit)) return unit
  return `${unit}s`
}

export function formatAmount(value: number) {
  return new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 }).format(value)
}

export function quantityWithUnit(p: ApiProduct, isAr: boolean, preferRetail: boolean) {
  const qtyRaw = text(preferRetail && p.hasRetailPricing && text(p.retailQuantity) ? p.retailQuantity : p.quantity)
  const unit = unitName(p, isAr, preferRetail)
  if (!qtyRaw && !unit) return ''
  const qty = parseNumber(qtyRaw) ?? 1
  const shownUnit = unit ? displayUnit(unit, qty, isAr) : ''
  const shownQty = qtyRaw ? formatAmount(qty) : ''
  return [shownQty, shownUnit].filter(Boolean).join(' ')
}

export function unitSuffix(p: ApiProduct, isAr: boolean, preferRetail: boolean) {
  const unit = unitName(p, isAr, preferRetail)
  return unit ? ` / ${displayUnit(unit, 1, isAr)}` : ''
}

export function priceTypeLabel(p: ApiProduct, t: (key: StringKey) => string): string {
  if (p.productTypeId === 2 || text(p.productTypeName).toLowerCase() === 'booking') {
    const name = text(p.bookingPriceTypeName)
    if (name) return name.toUpperCase()
    return ({ 1: 'FOB', 2: 'CNF', 3: 'CIF' } as Record<number, string>)[p.bookingPriceTypeId ?? 0] ?? ''
  }
  const applies = isOfferProduct(p) || isRequestProduct(p) || hasMainCategory(p)
  if (!applies) return ''
  if (p.requestTypeId === 1) return t('local')
  if (p.requestTypeId === 2) return t('reexport')
  for (const raw of [p.requestTypeNameEn, p.requestTypeName, p.shippingDescriptionEn]) {
    const compact = text(raw).toLowerCase().replace(/[\s_-]+/g, '')
    if (!compact) continue
    if (compact === 'local' || compact === 'محلي' || compact === '1') return t('local')
    if (compact.includes('reexport') || compact.includes('rexport') || compact.includes('إعادةتصدير') || compact === '2')
      return t('reexport')
  }
  return ''
}

export function parseUtc(raw: unknown): Date | null {
  const value = text(raw)
  if (!value) return null
  const hasZone = /[zZ]|[+-]\d{2}:?\d{2}$/.test(value)
  const date = new Date(hasZone ? value : `${value}Z`)
  return Number.isNaN(date.getTime()) ? null : date
}

export function relativeTime(raw: unknown, t: (key: StringKey, vars?: Record<string, number>) => string) {
  const date = parseUtc(raw)
  if (!date) return ''
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000)
  if (seconds < 0) return t('justNow')
  if (seconds < 60) return seconds <= 1 ? t('oneSecondAgo') : t('secondsAgo', { count: seconds })
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return minutes === 1 ? t('oneMinuteAgo') : t('minutesAgo', { count: minutes })
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return hours === 1 ? t('oneHourAgo') : t('hoursAgo', { count: hours })
  const days = Math.floor(hours / 24)
  if (days < 7) return days === 1 ? t('oneDayAgo') : t('daysAgo', { count: days })
  const weeks = Math.floor(days / 7)
  if (weeks < 4) return weeks === 1 ? t('oneWeekAgo') : t('weeksAgo', { count: weeks })
  const months = Math.floor(days / 30)
  if (months < 12) {
    if (months <= 1) return t('oneMonthAgo')
    if (months === 2) return t('twoMonthsAgo')
    return t('monthsAgo', { count: months })
  }
  const years = Math.floor(days / 365)
  return years <= 1 ? t('oneYearAgo') : t('yearsAgo', { count: years })
}

const VIDEO_EXT = /\.(mp4|mov|webm|m4v|avi|mkv)(\?|$)/i

const imagePathOf = (item: NonNullable<ApiProduct['images']>[number]) =>
  typeof item === 'string' ? item : item?.path || item?.imagePath || item?.ImagePath || ''

export function productImages(p: ApiProduct) {
  return (p.images ?? [])
    .map(imagePathOf)
    .filter((path) => path && !VIDEO_EXT.test(path))
    .map(resolveMediaUrl)
    .filter(Boolean)
}

export type MediaItem = { kind: 'image' | 'video'; url: string; muted?: boolean }

/** Same order as the app: images first, then `videoPath`, `videos[]`, `videoPaths[]` (deduped). */
export function productMedia(p: ApiProduct): MediaItem[] {
  const items: MediaItem[] = productImages(p).map((url) => ({ kind: 'image', url }))
  const seen = new Set<string>()
  const pushVideo = (path?: string | null, muted?: boolean) => {
    const url = resolveMediaUrl(path)
    if (!url || seen.has(url)) return
    seen.add(url)
    items.push({ kind: 'video', url, muted })
  }
  pushVideo(p.videoPath)
  for (const v of p.videos ?? []) pushVideo(v.path || v.videoPath || v.url, v.isMuted)
  for (const path of p.videoPaths ?? []) pushVideo(path)
  return items
}

export function productVideos(p: ApiProduct) {
  return productMedia(p)
    .filter((m) => m.kind === 'video')
    .map((m) => m.url)
}

export const isProductOwner = (p: ApiProduct, viewer: Viewer) => isOwner(p, viewer)

export type DetailsLayout = 'request' | 'retail' | 'category' | 'booking' | 'offer'

/** Mirrors ProductNavigationHelper: which details body the app opens for a product. */
export function detailsLayout(p: ApiProduct, viewer: Viewer, preferRetail = false): DetailsLayout {
  const retailChannel = preferRetail || viewer.isPersonalCustomer
  if (isRequestProduct(p)) return 'request'
  if (retailChannel && isRetailFeedProduct(p)) return 'retail'
  if (hasMainCategory(p)) return isBookingProduct(p) ? 'booking' : 'category'
  if (isPureRetailProduct(p)) return 'retail'
  if (isBookingProduct(p)) return 'booking'
  if (isOfferProduct(p)) return 'offer'
  return 'retail'
}

export function isNegotiable(p: ApiProduct) {
  const v = p.negotiable
  if (typeof v === 'boolean') return v
  const s = text(v).toLowerCase()
  return s === 'true' || s === '1' || s === 'yes' || s === 'negotiable'
}

export function packagingDisplay(p: ApiProduct, isAr: boolean, retail = false) {
  if (retail && (text(p.retailPackaging) || text(p.retailPackagingDetails))) {
    const details = text(p.retailPackagingDetails)
    if (details) return details
    const kg = parseNumber(p.retailPackaging)
    return kg ? `${kg} ${isAr ? 'كجم' : 'kg'}` : ''
  }
  const details = text(p.packagingDetails)
  if (details) return details
  const kg = parseNumber(p.packaging)
  return kg ? `${kg} ${isAr ? 'كجم' : 'kg'}` : ''
}

export function descriptionLines(value: string) {
  return value
    .split(/[\n\r]+/)
    .map((line) => line.trim())
    .filter(Boolean)
}

const MODERATION_MARKERS = ['auto-approved:', 'auto approved', 'remove violations, then edit and resubmit', 'contains insults/profanity', 'أزل المخالفات ثم عدّل الإعلان', 'يحتوي على ألفاظ نابية']

export function supplierNotes(p: ApiProduct, isAr: boolean) {
  const notes = localized(p.supplierNotesAr, p.supplierNotesEn, p.supplierNotes, isAr)
  const normalized = notes.toLowerCase()
  if (!notes || normalized.startsWith('auto-approved') || normalized.startsWith('موافقة تلقائية')) return ''
  return MODERATION_MARKERS.some((m) => normalized.includes(m)) ? '' : notes
}

export function shippingFacts(p: ApiProduct, isAr: boolean) {
  const s = p.shipping ?? {}
  const pick = (ar: unknown, en: unknown, plain: unknown, route: unknown) => localized(ar, en, text(plain) || text(route), isAr)
  const origin = pick(s.originCountryNameAr ?? p.originCountryNameAr, s.originCountryNameEn ?? p.originCountryNameEn, s.originCountryName ?? p.originCountryName, s.routeFromCountry ?? p.routeFromCountry)
  const destination = pick(s.destinationCountryNameAr ?? p.destinationCountryNameAr, s.destinationCountryNameEn ?? p.destinationCountryNameEn, s.destinationCountryName ?? p.destinationCountryName, s.routeToCountry ?? p.routeToCountry)
  const loadingPort = text(s.loadingPortNameEn ?? p.loadingPortNameEn) || text(s.loadingPortName ?? p.loadingPortName) || text(s.routeFromPort ?? p.routeFromPort)
  const arrivalPort = text(s.arrivalPortNameEn ?? p.arrivalPortNameEn) || text(s.arrivalPortName ?? p.arrivalPortName) || text(s.routeToPort ?? p.routeToPort)
  const notes = text(s.additionalShippingNotes ?? p.additionalShippingNotes)
  const duration = text(p.shippingDuration)
  return { origin, destination, loadingPort, arrivalPort, notes, duration, routeSummary: text(s.routeSummary ?? p.routeSummary) }
}

export function documentUrls(p: ApiProduct) {
  return (p.documents ?? [])
    .map((d) => (typeof d === 'string' ? d : d?.path || d?.documentPath || ''))
    .filter(Boolean)
    .map((path) => ({ url: resolveMediaUrl(path), name: decodeURIComponent(path.split('/').pop() ?? path) }))
}

export function bookingPriceTypeLabel(p: ApiProduct) {
  const name = text(p.bookingPriceTypeName) || text(p.bookingPriceTypeNameEn)
  if (name) return name.toUpperCase()
  return ({ 1: 'FOB', 2: 'CNF', 3: 'CIF' } as Record<number, string>)[p.bookingPriceTypeId ?? 0] ?? ''
}

export const productTypeLabel = (p: ApiProduct, isAr: boolean) => localized(p.productTypeNameAr, p.productTypeNameEn, p.productTypeName, isAr)

export function availableQuantity(p: ApiProduct, retail: boolean) {
  return parseNumber(retail && p.hasRetailPricing && text(p.retailQuantity) ? p.retailQuantity : p.quantity)
}

/** Canonical unit sent to the orders/cart API ("Kg" → "Kilogram"), like `unitNameForChannel`. */
export function apiUnitName(p: ApiProduct, retail: boolean) {
  const raw = retail && p.hasRetailPricing ? text(p.retailUnitNameEn) || text(p.retailUnitName) || text(p.unitNameEn) || text(p.unitName) : text(p.unitNameEn) || text(p.unitName)
  return /^kg$/i.test(raw) ? 'Kilogram' : raw
}

/** Stable accent per category, same palette as the app's ProductCardTheme. */
const PALETTE = ['#3A7DC5', '#2F6B4F', '#C45C26', '#7C3AED', '#0F766E', '#B45309', '#BE185D', '#1D4ED8', '#15803D', '#9333EA', '#DC2626', '#0891B2']

export function accentFor(p: ApiProduct) {
  const key = hasMainCategory(p) ? `id:${p.categoryId}` : `product:${p.productId}`
  let hash = 0
  for (const ch of key) hash = (hash * 31 + ch.charCodeAt(0)) | 0
  return PALETTE[Math.abs(hash) % PALETTE.length]
}
