import { getOrderStatusLabel } from './orderStatus'

const STATUS_LABEL_KEYS: Record<number, string> = {
  1: 'orders.statusOrdered',
  2: 'orders.statusApproved',
  3: 'orders.statusPaid',
  4: 'orders.statusShipping',
  5: 'orders.statusDelivered',
  6: 'orders.statusCancelled',
  // Legacy Received — same as Delivered.
  7: 'orders.statusDelivered',
  8: 'orders.statusPaidToSupplier',
}

export function getOrderStatusLabelKey(statusId: number): string {
  return STATUS_LABEL_KEYS[statusId] ?? 'orders.statusUnknown'
}

export function getOrderStatusLabelAr(statusId: number): string {
  return getOrderStatusLabel(statusId, 'ar')
}

export function getOrderStatusLabelEn(statusId: number): string {
  return getOrderStatusLabel(statusId, 'en')
}
