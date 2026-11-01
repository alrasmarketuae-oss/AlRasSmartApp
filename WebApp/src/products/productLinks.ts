import { isRetailFeedProduct, productImages, productMedia } from './productRules'
import type { ApiProduct } from './types'

export function slugify(value: string) {
  return value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f\u064B-\u065F]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9\u0600-\u06FF]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80)
}

export const RETAIL_CHANNEL_QUERY = 'channel=retail'

/**
 * Canonical, crawlable product path: `/product/{id}/{english-or-arabic-slug}`.
 * `retail` keeps the Retail-section channel (retail price, unit and Add to Cart) across reloads and shared links.
 */
export function productPath(p: Pick<ApiProduct, 'productId' | 'nameEn' | 'nameAr' | 'productName'> & Partial<ApiProduct>, retail = false) {
  const slug = slugify(p.nameEn || p.productName || p.nameAr || '')
  const channel = retail && isRetailFeedProduct(p as ApiProduct) ? `?${RETAIL_CHANNEL_QUERY}` : ''
  return `/product/${encodeURIComponent(p.productId)}${slug ? `/${slug}` : ''}${channel}`
}

export const productUrl = (p: Parameters<typeof productPath>[0], retail = false) => `${window.location.origin}${productPath(p, retail)}`

const line = (label: string, value: unknown) => {
  const text = value === null || value === undefined ? '' : String(value).trim()
  return text ? `${label}: ${text}` : ''
}

/** Exact support-chat payload the app sends for "Ask For Price" (English keys, never a price). */
export function askForPriceMessage(p: ApiProduct) {
  const image = (p.images ?? []).map((i) => (typeof i === 'string' ? i : i?.path || i?.imagePath || i?.ImagePath || '')).find((path) => path && !/\.(mp4|mov|webm|m4v|avi|mkv)(\?|$)/i.test(path))
  const video = image ? '' : productMedia(p).find((m) => m.kind === 'video')?.url
  const quantity = [p.quantity, p.unitNameEn || p.unitName].filter((v) => v !== null && v !== undefined && String(v).trim()).join(' ')
  return [
    'Ask For Price — product details:',
    `ASK_FOR_PRICE_PRODUCT:${p.productId}`,
    '',
    line('Product Name', p.nameEn || p.productName || p.nameAr),
    line('Product Code', p.productCode),
    line('Product ID', p.productId),
    image ? line('Image', image) : line('Video', video),
    line('Category', p.categoryNameEn || p.categoryName),
    line('Type', p.productTypeNameEn || p.productTypeName),
    line('Quantity', quantity),
    line('Description', p.descriptionEn || p.description || p.descriptionAr),
    line('Supplier ID', p.ownerId),
  ]
    .filter((l, i) => i === 2 || l)
    .join('\n')
}

export const firstImage = (p: ApiProduct) => productImages(p)[0] ?? ''
