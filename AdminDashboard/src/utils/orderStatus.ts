export type OrderStatusStyle = {
  label: string
  className: string
}

const STATUS_CLASS: Record<number, string> = {
  1: 'bg-amber-100 text-amber-800 dark:bg-amber-950/50 dark:text-amber-300',
  2: 'bg-sky-100 text-sky-800 dark:bg-sky-950/50 dark:text-sky-300',
  3: 'bg-indigo-100 text-indigo-800 dark:bg-indigo-950/50 dark:text-indigo-300',
  4: 'bg-blue-100 text-blue-800 dark:bg-blue-950/50 dark:text-blue-300',
  5: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/50 dark:text-emerald-300',
  6: 'bg-red-100 text-red-800 dark:bg-red-950/50 dark:text-red-300',
  // Legacy Received (7) — same meaning as Delivered (5).
  7: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/50 dark:text-emerald-300',
  8: 'bg-violet-100 text-violet-800 dark:bg-violet-950/50 dark:text-violet-300',
  9: 'bg-orange-100 text-orange-800 dark:bg-orange-950/50 dark:text-orange-300',
  10: 'bg-teal-100 text-teal-800 dark:bg-teal-950/50 dark:text-teal-300',
  11: 'bg-purple-100 text-purple-800 dark:bg-purple-950/50 dark:text-purple-300',
}

/** Canonical labels by status id (matches backend OrderStatusCodes). */
export function getOrderStatusLabel(statusId: number, locale: 'ar' | 'en' = 'ar'): string {
  const ar = locale === 'ar'
  switch (statusId) {
    case 1:
      return ar ? 'تم الطلب' : 'Ordered'
    case 2:
      return ar ? 'موافق عليه' : 'Approved'
    case 3:
      return ar ? 'تم الدفع لـ Merge Spice' : 'Paid to Merge Spice'
    case 4:
      return ar ? 'قيد الشحن' : 'Shipping'
    case 5:
    case 7:
      // 7 = legacy Received — same as Delivered.
      return ar ? 'تم التسليم' : 'Delivered'
    case 6:
      return ar ? 'ملغي' : 'Cancelled'
    case 8:
      return ar ? 'تم الدفع للمورد من Merge Spice' : 'Paid to supplier from Merge Spice'
    case 9:
      return ar ? 'طلب استرجاع' : 'Return requested'
    case 10:
      return ar ? 'تمت الموافقة على الاسترجاع' : 'Return approved'
    case 11:
      return ar ? 'بانتظار موافقة البائع' : 'Awaiting seller approval'
    default:
      return ar ? 'غير معروف' : 'Unknown'
  }
}

export function getOrderStatusStyle(
  statusId: number,
  _statusLabelAr?: string,
): OrderStatusStyle {
  const className =
    STATUS_CLASS[statusId] ?? 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300'

  return {
    label: getOrderStatusLabel(statusId, 'ar'),
    className,
  }
}
