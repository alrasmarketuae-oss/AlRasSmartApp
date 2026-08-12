import { hasPermission, PERMISSIONS } from '../lib/permissions'
import type { AdminNavCounts } from '../types/adminRealtime'
import { GLOBAL_SEARCH_PARAM } from './globalSearch'
import type { OrderChannel } from './orderChannel'

export type AdsChannelId =
  | 'all'
  | 'retail'
  | 'booking'
  | 'offers'
  | 'categories'
  | 'requests'

export type OrdersChannelId =
  | 'all'
  | 'retail'
  | 'booking'
  | 'offers'
  | 'categories'
  | 'requests'

function withSearch(path: string, searchTerm?: string): string {
  const trimmed = searchTerm?.trim() ?? ''
  if (!trimmed) return path
  const sep = path.includes('?') ? '&' : '?'
  return `${path}${sep}${GLOBAL_SEARCH_PARAM}=${encodeURIComponent(trimmed)}`
}

export function adsChannelFromLocation(search: string, pathname = ''): AdsChannelId {
  if (pathname === '/reqs-offers' || pathname.startsWith('/reqs-offers/')) {
    return 'requests'
  }
  const params = new URLSearchParams(search.startsWith('?') ? search.slice(1) : search)
  if (params.get('channel') === 'categories') return 'categories'
  switch (params.get('productTypeId')) {
    case '1':
      return 'retail'
    case '2':
      return 'booking'
    case '3':
      return 'offers'
    case '4':
      return 'requests'
    default:
      return 'all'
  }
}

export function adsChannelPath(id: AdsChannelId, searchTerm?: string): string {
  const path =
    id === 'retail'
      ? '/ads?productTypeId=1'
      : id === 'booking'
        ? '/ads?productTypeId=2'
        : id === 'offers'
          ? '/ads?productTypeId=3'
          : id === 'categories'
            ? '/ads?channel=categories'
            : id === 'requests'
              ? '/reqs-offers'
              : '/ads'
  return withSearch(path, searchTerm)
}

export function ordersChannelFromLocation(
  pathname: string,
  _search = '',
): OrdersChannelId {
  if (pathname === '/reqs-offers' || pathname.startsWith('/reqs-offers/')) {
    return 'requests'
  }
  if (pathname.startsWith('/orders/booking')) return 'booking'
  if (pathname.startsWith('/orders/offers')) return 'offers'
  if (pathname.startsWith('/orders/categories')) return 'categories'
  if (pathname.startsWith('/orders/retail')) return 'retail'
  return 'all'
}

export function ordersChannelPath(id: OrdersChannelId, searchTerm?: string): string {
  const path =
    id === 'retail'
      ? '/orders/retail'
      : id === 'booking'
        ? '/orders/booking'
        : id === 'offers'
          ? '/orders/offers'
          : id === 'categories'
            ? '/orders/categories'
            : id === 'requests'
              ? '/reqs-offers?nav=orders'
              : '/orders/all'
  return withSearch(path, searchTerm)
}

export function ordersChannelFromProp(channel?: OrderChannel): OrdersChannelId {
  return channel ?? 'all'
}

export function canSeeRequestChannel(): boolean {
  return hasPermission(PERMISSIONS.ordersReqsOffers)
}

export function adsTabCounts(counts: AdminNavCounts): Partial<Record<AdsChannelId, number>> {
  return {
    all: counts.ads,
    requests: counts.requestAds,
  }
}

export function ordersTabCounts(
  counts: AdminNavCounts,
): Partial<Record<OrdersChannelId, number>> {
  return {
    retail: counts.retailOrders,
    booking: counts.bookingOrders,
    offers: counts.offersOrders,
    categories: counts.categoriesOrders,
    requests: counts.offers,
  }
}
