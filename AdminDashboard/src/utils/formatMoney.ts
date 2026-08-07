import { withThousandSeparators } from './adsDisplay'

export function formatDashboardAmount(
  amount: number,
  locale: 'en' | 'ar',
  formattedFallback?: string,
): string {
  if (locale === 'ar') {
    if (formattedFallback?.includes('درهم')) {
      return withThousandSeparators(formattedFallback)
    }
    return `${amount.toLocaleString('en-US', { maximumFractionDigits: 0 })} درهم`
  }

  if (formattedFallback?.trim()) {
    return withThousandSeparators(formattedFallback)
  }

  return `${amount.toLocaleString('en-US', { maximumFractionDigits: 0 })} AED`
}
