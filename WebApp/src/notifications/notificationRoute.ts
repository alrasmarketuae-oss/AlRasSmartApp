import { navigationRoute, type AppNotification } from './notificationsApi'

/** Web equivalent of NotificationNavigationHelper.open; `null` = no navigation. */
export function notificationTarget(item: AppNotification): string | null {
  const route = navigationRoute(item)
  const referenceId = item.referenceId.trim()
  const title = item.title.toLowerCase()
  const type = item.typeName.toLowerCase()
  const orderId = /^\d+$/.test(referenceId) ? Number(referenceId) : 0
  const looksLikeOrder =
    ['order', 'new_order', 'product_order'].includes(type) ||
    ['order_status', 'order_placed', 'order_refund', 'order_created'].some((k) => type.includes(k)) ||
    title.includes('new order') ||
    title.includes('طلب جديد')
  const isStatusUpdate = type.includes('order_status') || type.includes('order_refund') || route === 'track_order'
  const looksLikeRequestOffer =
    title.includes('offer on your request') ||
    title.includes('عرض جديد على طلبك') ||
    title.includes('عرض على طلبك') ||
    (type === 'request_offer' && !looksLikeOrder && !title.includes('new offer available') && title.trim() !== 'عرض جديد متاح')
  const orders = orderId > 0 ? `/orders/${orderId}` : '/orders'

  if (type.includes('chat') || route.includes('chat')) return '/chat'
  if (type.includes('registration_incomplete') || route === 'complete-registration' || route === 'complete_registration') return null
  if (route === 'profile') return '/profile'
  if (isStatusUpdate && orderId > 0) return orders
  if (route === 'track_order' || route === 'orders') return orders
  if (route === 'my_offers') return looksLikeOrder && orderId > 0 ? orders : '/my-ads'
  if (route === 'my_ads') {
    if (!referenceId) return '/my-ads'
    return looksLikeRequestOffer ? `/my-ads/${encodeURIComponent(referenceId)}` : `/my-ads?highlight=${encodeURIComponent(referenceId)}`
  }
  if (looksLikeOrder) return orders
  if (route === 'product-detail' || route === 'product_detail') return referenceId ? `/product/${encodeURIComponent(referenceId)}` : '/my-ads'
  if (route.includes('offer')) return '/services/offers'
  if (route.includes('request')) return '/services/requests'
  if (referenceId && (route.includes('order') || orderId > 0)) return orders
  return null
}
