import type { Locale } from '../i18n/messages'

const TYPE_LABELS: Record<string, string> = {
  مورد: 'Supplier',
  عميل: 'Customer',
  مدير: 'Admin',
  'شركة شحن': 'Shipping company',
}

const STATUS_LABELS: Record<string, string> = {
  مكتمل: 'Complete',
  'غير مكتمل': 'Incomplete',
  موقوف: 'Suspended',
  'بانتظار الموافقة': 'Pending approval',
  مرفوض: 'Rejected',
  'غير معروف': 'Unknown',
}

const PRODUCT_STATUS_LABELS: Record<string, string> = {
  موافق: 'Approved',
  'موافق عليه': 'Approved',
  'قيد المراجعة': 'Under review',
  نشط: 'Active',
  موقوف: 'Suspended',
  مرفوض: 'Rejected',
}

const ORDER_STATUS_LABELS: Record<string, string> = {
  'تم الطلب': 'Ordered',
  'موافق عليه': 'Approved',
  مدفوع: 'Paid',
  'قيد الشحن': 'Shipping',
  'تم التسليم': 'Delivered',
  ملغي: 'Cancelled',
  مكتمل: 'Completed',
  'قيد التنفيذ': 'In progress',
  'غير معروف': 'Unknown',
}

export function localizeLabel(
  label: string,
  locale: Locale,
  map: Record<string, string>,
): string {
  if (!label || locale === 'ar') return label
  return map[label] ?? label
}

export function localizeTypeLabel(label: string, locale: Locale): string {
  return localizeLabel(label, locale, TYPE_LABELS)
}

export function localizeStatusLabel(label: string, locale: Locale): string {
  return localizeLabel(label, locale, STATUS_LABELS)
}

export function localizeProductStatusLabel(label: string, locale: Locale): string {
  return localizeLabel(label, locale, PRODUCT_STATUS_LABELS)
}

export function localizeOrderStatusLabel(label: string, locale: Locale): string {
  return localizeLabel(label, locale, ORDER_STATUS_LABELS)
}

export function isUnknownLabel(label: string): boolean {
  return !label || label === '—' || label === 'غير معروف' || label === 'Unknown'
}
