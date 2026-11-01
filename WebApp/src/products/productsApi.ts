import { api } from '../lib/api'
import type { ApiProduct, AppVersionInfo, Banner, Category, Paged } from './types'

export const HOME_PAGE_SIZE = 20

export type ServiceType = 'Requests' | 'Offers' | 'Booking' | 'Retail'

export const fetchProducts = (page: number, signal?: AbortSignal) =>
  api.get<Paged<ApiProduct>>('/Products', { query: { page, pageSize: HOME_PAGE_SIZE }, signal })

export const fetchProductsByType = (type: ServiceType, page: number, signal?: AbortSignal) =>
  api.get<Paged<ApiProduct>>(`/Products/by-type/${encodeURIComponent(type)}`, {
    query: { page, pageSize: HOME_PAGE_SIZE },
    signal,
  })

export const fetchProductsByCategory = (categoryId: number, page: number, signal?: AbortSignal, publicCatalog?: boolean) =>
  api.get<Paged<ApiProduct> & { categoryName?: string }>(`/Products/by-category/${categoryId}`, {
    query: { page, pageSize: HOME_PAGE_SIZE, publicCatalog: publicCatalog || undefined },
    signal,
  })

export type ImageSearchResult = Paged<ApiProduct> & {
  suggestedNames?: string[]
  detectedProductName?: string | null
  detectedCategoryId?: number | null
  products?: Paged<ApiProduct> | ApiProduct[]
}

/** Downscales camera photos before upload; the app caps search images the same way. */
export async function compressImage(file: File, maxSide = 1280, quality = 0.82): Promise<File> {
  if (!file.type.startsWith('image/') || file.type === 'image/gif') return file
  try {
    const bitmap = await createImageBitmap(file)
    const scale = Math.min(1, maxSide / Math.max(bitmap.width, bitmap.height))
    const canvas = document.createElement('canvas')
    canvas.width = Math.round(bitmap.width * scale)
    canvas.height = Math.round(bitmap.height * scale)
    canvas.getContext('2d')?.drawImage(bitmap, 0, 0, canvas.width, canvas.height)
    bitmap.close()
    const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/jpeg', quality))
    if (!blob || blob.size >= file.size) return file
    return new File([blob], file.name.replace(/\.\w+$/, '') + '.jpg', { type: 'image/jpeg' })
  } catch {
    return file
  }
}

export async function detectByImage(file: File, signal?: AbortSignal): Promise<ImageSearchResult> {
  const form = new FormData()
  form.append('File', file)
  const data = await api.upload<ImageSearchResult>('/Products/detect-by-image', form, { signal })
  let items = data?.items ?? []
  if (!items.length && data?.products) items = Array.isArray(data.products) ? data.products : (data.products.items ?? [])
  return { ...data, items, page: data?.page || 1, pageSize: data?.pageSize || HOME_PAGE_SIZE }
}

export const searchProducts = (q: string, page: number, signal?: AbortSignal) =>
  api.get<Paged<ApiProduct>>('/Products/search', { query: { q, page, pageSize: HOME_PAGE_SIZE }, signal })

export const fetchSearchSuggestions = (q: string, signal?: AbortSignal) =>
  api.get<{ suggestions?: string[] }>('/Products/search-suggest', { query: { q, limit: 8 }, signal })

export async function fetchProduct(productId: string, asRetail = false): Promise<ApiProduct> {
  const data = await api.get<ApiProduct & { item?: ApiProduct; Item?: ApiProduct }>(`/Products/${encodeURIComponent(productId)}${asRetail ? '?asRetail=true' : ''}`)
  return data?.item ?? data?.Item ?? data
}

export const fetchCategories = () => api.get<{ items: Category[] }>('/Categories')

export const fetchBanners = () => api.get<{ items: Banner[] }>('/HomeBanners')

export const fetchAppVersion = () => api.get<AppVersionInfo>('/settings/app-version', { auth: false })

export function totalPagesOf(data: Paged<unknown>, page: number) {
  if (data.totalPages && data.totalPages > 0) return data.totalPages
  if (data.totalCount && data.pageSize) return Math.ceil(data.totalCount / data.pageSize)
  return (data.items?.length ?? 0) < HOME_PAGE_SIZE ? page : page + 1
}
