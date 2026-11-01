import type { StringKey } from '../i18n/strings'
import {
  hasMainCategory,
  isBookingProduct,
  isOfferProduct,
  isPureRetailProduct,
  isRequestProduct,
  isRetailProduct,
  isSoldOut,
  localized,
  parseNumber,
} from '../products/productRules'
import type { MyListing } from './sellerApi'

type T = (key: StringKey, vars?: Record<string, string | number>) => string

/** Backend ProductStatusCodes.Normalize: 1 review → 2 active → 3 paused | 5 rejected (legacy 4 → review). */
export const LISTING = { review: 1, active: 2, paused: 3, rejected: 5 } as const

export function listingStatus(p: MyListing): number {
  const raw = p.listingStatusCode
  if (raw > 0) {
    if (raw === 2 || raw === 3 || raw === 5) return raw
    if (raw === 1) return p.isApproved ? LISTING.active : LISTING.review
    return LISTING.review
  }
  const value = (p.statusNameEn ?? '').trim().toLowerCase()
  if (value === 'active' || value.includes('نشط')) return LISTING.active
  if (value === 'paused' || value.includes('متوقف')) return LISTING.paused
  if (value === 'rejected' || value.includes('مرفوض')) return LISTING.rejected
  return p.isApproved ? LISTING.active : LISTING.review
}

export const statusCanonical = (p: MyListing) => (p.statusNameEn ?? '').trim() || (p.status ?? '').trim()

export function isSellerPaused(p: MyListing) {
  if (typeof p.isSellerPaused === 'boolean') return p.isSellerPaused
  return listingStatus(p) === LISTING.paused && !isSoldOut(p, false)
}

export const isListingActive = (p: MyListing) => listingStatus(p) === LISTING.active
export const canToggleListing = (p: MyListing) => !statusCanonical(p).toLowerCase().includes('review')

export function isRejectedWithReason(p: MyListing) {
  const status = `${p.status ?? ''} ${p.approvalStatus ?? ''}`.toLowerCase()
  return status.includes('reject') && !!(p.supplierNotes ?? '').trim()
}

export const TYPE_FILTERS = ['all', 'categories', 'requests', 'offers', 'booking', 'retail'] as const
export type TypeFilter = (typeof TYPE_FILTERS)[number]

export const STATUS_FILTERS = ['all', 'active', 'paused', 'review', 'soldOut'] as const
export type StatusFilter = (typeof STATUS_FILTERS)[number]

export const TYPE_FILTER_LABEL: Record<TypeFilter, StringKey> = {
  all: 'filterAll',
  categories: 'categories',
  requests: 'requests',
  offers: 'offers',
  booking: 'booking',
  retail: 'retail',
}

export const STATUS_FILTER_META: Record<StatusFilter, { label: StringKey; color: string }> = {
  all: { label: 'filterAll', color: '#3A7DC5' },
  active: { label: 'listingActive', color: '#22A06B' },
  paused: { label: 'listingPaused', color: '#E67E22' },
  review: { label: 'underReviewAds', color: '#7C5CFC' },
  soldOut: { label: 'soldOut', color: '#E53935' },
}

export function matchesType(p: MyListing, filter: TypeFilter) {
  switch (filter) {
    case 'all':
      return true
    case 'categories':
      return hasMainCategory(p)
    case 'requests':
      return isRequestProduct(p)
    case 'offers':
      return isOfferProduct(p)
    case 'booking':
      return isBookingProduct(p)
    case 'retail':
      return isPureRetailProduct(p) || p.hasRetailPricing === true || isRetailProduct(p)
  }
}

export function matchesStatus(p: MyListing, filter: StatusFilter, preferRetail: boolean) {
  const code = listingStatus(p)
  const soldOut = isSoldOut(p, preferRetail)
  switch (filter) {
    case 'all':
      return true
    case 'active':
      return !soldOut && !isSellerPaused(p) && code !== LISTING.rejected && code !== LISTING.review
    case 'paused':
      return isSellerPaused(p)
    case 'review':
      return code === LISTING.review
    case 'soldOut':
      return soldOut
  }
}

/** Ads with pending orders float to the top; backend order is kept inside each group. */
export const withPendingFirst = (list: MyListing[]) => [...list.filter((p) => p.pendingOffersCount > 0), ...list.filter((p) => p.pendingOffersCount <= 0)]

export function typeFilterFor(p: MyListing): TypeFilter {
  if (hasMainCategory(p)) return 'categories'
  if (isRequestProduct(p)) return 'requests'
  if (isOfferProduct(p)) return 'offers'
  if (isBookingProduct(p)) return 'booking'
  if (p.productTypeId === 1) return 'retail'
  return 'all'
}

export type BadgeStyle = { label: string; bg: string; fg: string; icon: 'check' | 'stop' | 'clock' }

export function listingBadge(p: MyListing, t: T, isAr: boolean): BadgeStyle {
  const code = listingStatus(p)
  const icon = code === LISTING.paused || code === LISTING.rejected ? 'stop' : code === LISTING.review ? 'clock' : 'check'
  if (isSoldOut(p, false)) return { label: t('soldOut'), bg: '#FFEBEE', fg: '#E53935', icon }
  switch (code) {
    case LISTING.active:
      return { label: t('listingActive'), bg: '#DCFAE6', fg: '#17B26A', icon }
    case LISTING.paused:
      return isSellerPaused(p)
        ? { label: t('listingPaused'), bg: '#F2F2F2', fg: '#7B8794', icon }
        : { label: t('listingActive'), bg: '#DCFAE6', fg: '#17B26A', icon }
    case LISTING.review:
      return { label: t('underReviewAds'), bg: '#FFFAEB', fg: '#FDB022', icon }
    case LISTING.rejected:
      return { label: t('rejectedAds'), bg: '#FFEBEE', fg: '#E53935', icon }
    default:
      return { label: localized(p.statusNameAr, statusCanonical(p), '', isAr) || '—', bg: '#F2F4F7', fg: '#475467', icon }
  }
}

/** Localised ad-type label (the card / details "type" badge). */
export function adTypeLabel(p: MyListing, t: T, preferRetail = false, preferCategory = false) {
  if (preferRetail) return t('retail')
  if (preferCategory && hasMainCategory(p)) return t('categories')
  if (isRequestProduct(p)) return t('requests')
  if (isOfferProduct(p)) return t('offers')
  if (isBookingProduct(p)) return t('booking')
  if (isRetailProduct(p) && !hasMainCategory(p)) return t('retail')
  if (hasMainCategory(p)) return t('categories')
  return (p.productTypeName ?? '').trim() || '—'
}

/** Owner price used by Change Prices (`ownerListingPrice`, falls back to raw `priceUsd`). */
export function ownerListingPrice(p: MyListing) {
  for (const candidate of [p.ownerPrice, p.ownerUsdPrice, p.priceUsd, p.price]) {
    const value = parseNumber(candidate)
    if (value !== null) return value
  }
  return 0
}

export function wholesaleCurrency(p: MyListing) {
  if (isPureRetailProduct(p)) return 'AED'
  if (isBookingProduct(p)) return 'USD'
  return (p.ownerCurrency || p.currency || 'USD').trim().toUpperCase() === 'AED' ? 'AED' : 'USD'
}

export const isHybridCategoryRetail = (p: MyListing) => p.hasRetailPricing === true && hasMainCategory(p)

/** Admin-moderated ad types only show orders after admin approval. */
export function requiresAdminOrderModeration(p: MyListing) {
  if (hasMainCategory(p)) return true
  if (isPureRetailProduct(p)) return false
  return isBookingProduct(p) || isOfferProduct(p) || isRequestProduct(p)
}
