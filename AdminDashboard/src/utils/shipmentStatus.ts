export function getShipmentStatusStyle(statusId: number) {
  switch (statusId) {
    case 3:
      return {
        labelKey: 'shippingPage.completed' as const,
        className:
          'bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300',
      }
    case 2:
      return {
        labelKey: 'shippingPage.inDelivery' as const,
        className: 'bg-blue-50 text-blue-700 dark:bg-blue-950/40 dark:text-blue-300',
      }
    case 4:
      return {
        labelKey: 'shippingPage.late' as const,
        className: 'bg-red-50 text-red-700 dark:bg-red-950/40 dark:text-red-300',
      }
    default:
      return {
        labelKey: 'shippingPage.inDelivery' as const,
        className: 'bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300',
      }
  }
}

export function formatShipmentDate(value: string, locale: 'ar' | 'en') {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleDateString(locale === 'ar' ? 'ar-EG' : 'en-US', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  })
}

export function formatRegistrationDate(value: string, locale: 'ar' | 'en') {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleDateString(locale === 'ar' ? 'ar-EG' : 'en-US', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  })
}
