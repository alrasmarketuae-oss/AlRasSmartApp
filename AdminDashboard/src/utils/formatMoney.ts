export function formatDashboardAmount(
  amount: number,
  locale: 'en' | 'ar',
  formattedFallback?: string,
): string {
  if (locale === 'ar') {
    if (formattedFallback?.includes('درهم')) {
      return formattedFallback
    }
    return `${amount.toLocaleString('ar-AE', { maximumFractionDigits: 0 })} درهم`
  }

  return `${amount.toLocaleString('en-US', { maximumFractionDigits: 0 })} AED`
}
