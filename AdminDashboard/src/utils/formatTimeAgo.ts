import type { Locale } from '../i18n/messages'

export function formatTimeAgo(createdAt: string, locale: Locale): string {
  if (!createdAt) return ''

  const date = new Date(createdAt)
  if (Number.isNaN(date.getTime())) return ''

  const minutes = Math.floor((Date.now() - date.getTime()) / 60_000)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)

  if (locale === 'ar') {
    if (minutes < 1) return 'الآن'
    if (minutes < 60) return `منذ ${minutes} دقيقة`
    if (hours < 24) return `منذ ${hours} ساعة`
    return `منذ ${days} يوم`
  }

  if (minutes < 1) return 'Just now'
  if (minutes < 60) return `${minutes} min ago`
  if (hours < 24) return `${hours} hr ago`
  return `${days} day${days === 1 ? '' : 's'} ago`
}
