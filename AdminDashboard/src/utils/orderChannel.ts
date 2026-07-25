import type { AdminOrder } from '../types/adminOrder'

export type OrderChannel = 'retail' | 'booking' | 'offers' | 'categories'

export const ORDER_CHANNELS: OrderChannel[] = [
  'retail',
  'booking',
  'offers',
  'categories',
]

export function orderChannelPath(channel: OrderChannel): string {
  return `/orders/${channel}`
}

export function isOrderChannelListPath(path: string): boolean {
  const base = path.split('?')[0] ?? path
  return ORDER_CHANNELS.some((channel) => base === `/orders/${channel}`)
}

export function resolveOrderChannelFromOrder(order: {
  productTypeName?: string
  categoryId?: number | null
  categoryName?: string
  isRetailPurchase?: boolean
}): OrderChannel {
  const typeName = order.productTypeName?.trim().toLowerCase() ?? ''
  const hasCategory =
    (order.categoryId != null && order.categoryId > 0) ||
    Boolean(order.categoryName?.trim() && order.categoryName.trim() !== '—')

  if (hasCategory) {
    return order.isRetailPurchase ? 'retail' : 'categories'
  }
  if (typeName.includes('offer')) return 'offers'
  if (typeName.includes('booking')) return 'booking'
  if (typeName.includes('retail')) return 'retail'

  return 'retail'
}

export function resolveOrderListFallbackPath(order?: AdminOrder | null): string {
  if (order) {
    return orderChannelPath(resolveOrderChannelFromOrder(order))
  }
  return orderChannelPath('retail')
}

export function resolveOrderListTitleKey(listPath: string): string {
  const base = listPath.split('?')[0] ?? listPath
  if (base.startsWith('/orders/booking')) return 'nav.ordersBooking'
  if (base.startsWith('/orders/offers')) return 'nav.ordersOffersType'
  if (base.startsWith('/orders/categories')) return 'nav.ordersCategories'
  return 'nav.ordersRetail'
}
