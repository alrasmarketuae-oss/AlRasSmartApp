import type { AdminProduct } from '../types/adminProduct'
import type { Locale } from '../i18n/messages'
import { formatUtcDate } from './formatTimeAgo'

export type AdListStatus = 'pending' | 'active' | 'rejected'

export function resolveAdListStatus(product: AdminProduct): AdListStatus {
  if (product.statusLabelAr === 'مرفوض') return 'rejected'
  if (product.isApproved) return 'active'
  return 'pending'
}

export function productTypeKey(productTypeName: string): string {
  return productTypeName.trim().toLowerCase()
}

export function productTypeFieldAccent(typeName: string): {
  badgeClass: string
  iconClass: string
  fieldClassName: string
} {
  const key = productTypeKey(typeName)
  if (key === 'retail' || key === 'تجزئة') {
    return {
      badgeClass: 'bg-[#FFF4E5] text-[#FF8800] ring-1 ring-[#FFD4A8]',
      iconClass: 'bg-[#FFF4E5] text-[#FF8800]',
      fieldClassName: 'rounded-xl bg-[#FFF4E5]/70 px-2.5 py-2 ring-1 ring-[#FFD4A8]/80',
    }
  }
  if (key === 'offers' || key === 'عروض') {
    return {
      badgeClass: 'bg-rose-50 text-rose-600 ring-1 ring-rose-200',
      iconClass: 'bg-rose-50 text-rose-600',
      fieldClassName: 'rounded-xl bg-rose-50/70 px-2.5 py-2 ring-1 ring-rose-200',
    }
  }
  if (key === 'booking' || key === 'بوكينج') {
    return {
      badgeClass: 'bg-sky-50 text-sky-600 ring-1 ring-sky-100',
      iconClass: 'bg-sky-50 text-sky-600',
      fieldClassName: 'rounded-xl bg-sky-50/70 px-2.5 py-2 ring-1 ring-sky-100',
    }
  }
  if (
    key === 'wholesale' ||
    key === 'جملة' ||
    key === 'الجملة' ||
    key === 'category' ||
    key === 'categories' ||
    key === 'القسم'
  ) {
    return {
      badgeClass: 'bg-teal-50 text-teal-700 ring-1 ring-teal-100',
      iconClass: 'bg-teal-50 text-teal-700',
      fieldClassName: 'rounded-xl bg-teal-50/70 px-2.5 py-2 ring-1 ring-teal-100',
    }
  }
  if (key === 'requests' || key === 'طلبات') {
    return {
      badgeClass: 'bg-violet-50 text-violet-600 ring-1 ring-violet-100',
      iconClass: 'bg-violet-50 text-violet-600',
      fieldClassName: 'rounded-xl bg-violet-50/70 px-2.5 py-2 ring-1 ring-violet-100',
    }
  }
  return {
    badgeClass: 'bg-slate-100 text-slate-600 ring-1 ring-slate-200',
    iconClass: 'bg-slate-100 text-slate-600',
    fieldClassName: '',
  }
}

export function productTypeBadgeClass(productTypeName: string): string {
  return productTypeFieldAccent(productTypeName).badgeClass
}

export function productTypeBadgeClassForProduct(
  product: Pick<AdminProduct, 'productTypeName' | 'categoryName' | 'productTypeId'> & {
    categoryId?: number | null
  },
): string {
  return productTypeBadgeClass(resolveAdChannelTypeKey(product))
}

/**
 * Ads list/detail type label aligned with orders:
 * category / hybrid listings → Wholesale; pure retail → Retail.
 */
export function resolveAdChannelTypeKey(
  product: Pick<AdminProduct, 'productTypeName' | 'categoryName' | 'productTypeId'> & {
    categoryId?: number | null
  },
): string {
  const typeId = product.productTypeId
  if (typeId === 2) return 'Booking'
  if (typeId === 3) return 'Offers'
  if (typeId === 4) return 'Requests'

  const hasCategory =
    (product.categoryId != null && product.categoryId > 0) ||
    (product.categoryName.trim().length > 0 && product.categoryName.trim() !== '—')

  if (hasCategory) {
    return 'Wholesale'
  }

  if (typeId === 1) return 'Retail'

  const typeName = product.productTypeName?.trim() ?? ''
  const key = productTypeKey(typeName)
  if (!typeName || typeName === '—' || typeName === '-') {
    return '—'
  }
  if (key === 'category' || key === 'categories' || key === 'القسم') {
    return 'Wholesale'
  }
  if (key === 'retail' || key === 'تجزئة') {
    return 'Retail'
  }
  if (key === 'wholesale' || key === 'جملة' || key === 'الجملة') {
    return 'Wholesale'
  }

  return typeName
}

export function displayAdProductTypeName(
  product: Pick<AdminProduct, 'productTypeName' | 'categoryName' | 'productTypeId'> & {
    categoryId?: number | null
  },
  locale: Locale,
): string {
  const key = resolveAdChannelTypeKey(product)
  if (key === '—') return '—'
  return localizeProductTypeName(key, locale)
}

export function adStatusBadgeClass(status: AdListStatus): string {
  if (status === 'pending') {
    return 'bg-amber-50 text-amber-700 ring-1 ring-amber-100'
  }
  if (status === 'active') {
    return 'bg-emerald-50 text-emerald-600 ring-1 ring-emerald-100'
  }
  return 'bg-rose-50 text-rose-600 ring-1 ring-rose-100'
}

export function localizeProductTypeName(name: string, locale: Locale): string {
  const trimmed = name.trim()
  if (!trimmed || trimmed === '—' || trimmed === '-') {
    return '—'
  }
  if (locale === 'en') {
    if (trimmed.toLowerCase() === 'categories') return 'Category'
    return trimmed
  }
  const map: Record<string, string> = {
    Retail: 'تجزئة',
    Wholesale: 'جملة',
    Booking: 'بوكينج',
    Offers: 'عروض',
    Requests: 'طلبات',
    Categories: 'القسم',
    Category: 'القسم',
  }
  return map[trimmed] ?? trimmed
}

/**
 * Orders on category / hybrid ads: show Wholesale vs Retail by purchase channel.
 * Do not trust raw ProductTypeName "Retail" for hybrids.
 */
export function resolveOrderChannelTypeName(
  order: {
    productTypeName?: string
    categoryId?: number | null
    categoryName?: string
    isRetailPurchase?: boolean
  },
  locale: Locale,
): string {
  const hasCategory =
    (order.categoryId != null && order.categoryId > 0) ||
    Boolean(order.categoryName?.trim() && order.categoryName.trim() !== '—')

  if (hasCategory) {
    return localizeProductTypeName(
      order.isRetailPurchase ? 'Retail' : 'Wholesale',
      locale,
    )
  }

  return localizeProductTypeName(order.productTypeName ?? '—', locale)
}

export function resolveOrderChannelTypeKey(order: {
  productTypeName?: string
  categoryId?: number | null
  categoryName?: string
  isRetailPurchase?: boolean
}): string {
  const hasCategory =
    (order.categoryId != null && order.categoryId > 0) ||
    Boolean(order.categoryName?.trim() && order.categoryName.trim() !== '—')

  if (hasCategory) {
    return order.isRetailPurchase ? 'Retail' : 'Wholesale'
  }

  return order.productTypeName?.trim() || '—'
}

export function formatAdListDate(value: string, _locale: Locale): string {
  if (!value) return '—'
  return formatUtcDate(value)
}

/**
 * Adds thousand separators (1,234.56) to the first numeric token in a price string.
 * Display-only — does not change underlying values or business logic.
 */
export function withThousandSeparators(text: string): string {
  const trimmed = text.trim()
  if (!trimmed) return trimmed

  // Match a full amount (optional commas already present), e.g. 137160.00 or 1,234.50
  const match = trimmed.match(/-?[\d,]+(?:\.\d+)?/)
  if (!match || match.index == null) return trimmed

  const raw = match[0]
  // Reject matches that are only commas/empty after strip
  if (!/\d/.test(raw)) return trimmed

  const normalized = raw.replace(/,/g, '')
  const num = Number(normalized)
  if (!Number.isFinite(num)) return trimmed

  const decimalPart = normalized.includes('.')
    ? (normalized.split('.')[1] ?? '')
    : null
  const fractionDigits =
    decimalPart != null
      ? Math.min(decimalPart.length, 2)
      : Number.isInteger(num)
        ? 0
        : 2

  const formatted = num.toLocaleString('en-US', {
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits === 0 ? 0 : 2,
  })

  return (
    trimmed.slice(0, match.index) +
    formatted +
    trimmed.slice(match.index + raw.length)
  )
}

export function formatAdAmount(
  priceFormatted: string | number | null | undefined,
  locale: Locale,
): string {
  if (priceFormatted == null) return '—'

  const asString =
    typeof priceFormatted === 'number'
      ? Number.isFinite(priceFormatted)
        ? priceFormatted.toLocaleString('en-US', {
            minimumFractionDigits: Number.isInteger(priceFormatted) ? 0 : 2,
            maximumFractionDigits: 2,
          })
        : ''
      : String(priceFormatted)

  const trimmed = asString.trim()
  if (!trimmed) return '—'

  const withSeparators = withThousandSeparators(trimmed)

  const isUsd =
    /\bUSD\b/i.test(withSeparators) ||
    withSeparators.startsWith('$') ||
    /\$\s*[\d,]/.test(withSeparators)

  if (locale !== 'ar' || isUsd) return withSeparators
  if (withSeparators.includes('درهم')) return withSeparators
  if (/\bAED\b/i.test(withSeparators)) {
    return withSeparators.replace(/\bAED\b/gi, 'درهم')
  }
  return `${withSeparators} درهم`
}

/** Compare two display amounts ignoring separators/currency labels. */
export function amountsLookEqual(
  left: string | number | null | undefined,
  right: string | number | null | undefined,
): boolean {
  const normalize = (value: string | number | null | undefined): string | null => {
    if (value == null) return null
    const text = String(value).trim()
    if (!text || text === '—') return null
    const match = text.match(/-?[\d,]+(?:\.\d+)?/)
    if (!match) return null
    const num = Number(match[0].replace(/,/g, ''))
    if (!Number.isFinite(num)) return null
    return num.toFixed(2)
  }
  const a = normalize(left)
  const b = normalize(right)
  return a != null && b != null && a === b
}

/** Local / Rexport (Price Type) from API requestTypeName or requestTypeId. */
export function formatPriceTypeLabel(
  requestTypeName: string | null | undefined,
  t: (key: string) => string,
  requestTypeId?: number | null,
): string {
  const value = (requestTypeName ?? '').trim().toLowerCase()
  if (value === 'local') return t('ads.requestFulfillmentLocal')
  if (
    value === 'reexport' ||
    value === 'rexport' ||
    value === 'export' ||
    value === 're-export'
  ) {
    return t('ads.requestFulfillmentRexport')
  }
  if (value === 'booking') return t('ads.requestFulfillmentBooking')
  if (value) return requestTypeName!.trim()

  if (requestTypeId === 1) return t('ads.requestFulfillmentLocal')
  if (requestTypeId === 2) return t('ads.requestFulfillmentRexport')
  return '—'
}

export function isBookingAd(
  product: Pick<
    AdminProduct,
    'productTypeId' | 'productTypeName' | 'bookingPriceTypeId' | 'bookingPriceTypeName'
  >,
): boolean {
  if (product.productTypeId === 2) return true
  const key = productTypeKey(product.productTypeName ?? '')
  if (key === 'booking' || key === 'بوكينج' || key.includes('booking')) return true
  // Fallback: booking ads always carry an Incoterm id/name
  if (product.bookingPriceTypeId != null && product.bookingPriceTypeId > 0) return true
  const bp = (product.bookingPriceTypeName ?? '').trim().toUpperCase()
  return bp === 'FOB' || bp === 'CNF' || bp === 'CIF'
}

/** Category / hybrid listings shown as Wholesale in admin. */
export function isWholesaleAd(
  product: Pick<AdminProduct, 'productTypeId' | 'productTypeName' | 'categoryName'> & {
    categoryId?: number | null
  },
): boolean {
  if (isBookingAd(product) || isOffersAd(product)) return false
  if (product.productTypeId === 4) return false
  const key = productTypeKey(product.productTypeName ?? '')
  if (key === 'requests' || key === 'طلبات') return false

  const hasCategory =
    (product.categoryId != null && product.categoryId > 0) ||
    (product.categoryName.trim().length > 0 && product.categoryName.trim() !== '—')

  return hasCategory || key === 'wholesale' || key === 'جملة' || key === 'الجملة' || key === 'categories' || key === 'category' || key === 'القسم'
}

export function isOffersAd(
  product: Pick<AdminProduct, 'productTypeId' | 'productTypeName'>,
): boolean {
  if (product.productTypeId === 3) return true
  const key = productTypeKey(product.productTypeName ?? '')
  return key === 'offers' || key === 'عروض' || key.includes('offer')
}

export function isRetailAd(
  product: Pick<AdminProduct, 'productTypeId' | 'productTypeName' | 'categoryName'> & {
    categoryId?: number | null
  },
): boolean {
  if (isBookingAd(product) || isWholesaleAd(product) || isOffersAd(product)) return false
  if (product.productTypeId === 4) return false
  const key = productTypeKey(product.productTypeName ?? '')
  if (key === 'requests' || key === 'طلبات') return false
  return true
}

/** FOB / CNF / CIF for Booking ads. */
export function formatBookingPriceTypeLabel(
  bookingPriceTypeName: string | null | undefined,
  bookingPriceTypeId?: number | null,
): string {
  const value = (bookingPriceTypeName ?? '').trim()
  if (value) return value.toUpperCase()

  return (
    {
      1: 'FOB',
      2: 'CNF',
      3: 'CIF',
    }[bookingPriceTypeId ?? -1] ?? '—'
  )
}

/** Price type label for list/detail: booking incoterms vs Local/Rexport. */
export function formatAdPriceTypeLabel(
  product: Pick<
    AdminProduct,
    | 'productTypeId'
    | 'productTypeName'
    | 'requestTypeName'
    | 'requestTypeId'
    | 'bookingPriceTypeName'
    | 'bookingPriceTypeId'
  >,
  t: (key: string) => string,
): string {
  if (isBookingAd(product)) {
    return formatBookingPriceTypeLabel(
      product.bookingPriceTypeName,
      product.bookingPriceTypeId,
    )
  }
  return formatPriceTypeLabel(
    product.requestTypeName,
    t,
    product.requestTypeId,
  )
}

/** Packing weight in kg (tinyint 1–255). */
export function formatPackagingLabel(
  packaging: number | null | undefined,
  _packagingDetails?: string | null | undefined,
  _t?: (key: string) => string,
  _locale?: string,
): string {
  const id = packaging == null ? null : Number(packaging)
  if (id == null || !Number.isFinite(id) || id <= 0 || id > 255) return ''
  return `${id} kg`
}
