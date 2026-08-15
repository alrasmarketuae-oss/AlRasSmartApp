import type { Locale } from '../i18n/messages'
import { parseApiUtcDate } from './formatTimeAgo'

export function formatChatRelativeTime(sentAtUtc: string, locale: Locale): string {
  if (!sentAtUtc) return ''

  const sentAt = parseApiUtcDate(sentAtUtc)
  if (!sentAt) return ''

  const diffMs = Date.now() - sentAt.getTime()
  const seconds = Math.floor(diffMs / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)
  const weeks = Math.floor(days / 7)
  const months = Math.floor(days / 30)
  const years = Math.floor(days / 365)

  if (locale === 'ar') {
    if (seconds < 60) return 'الآن'
    if (minutes < 60) return `${minutes} دقيقة`
    if (hours < 24) return `${hours} ساعة`
    if (days < 7) return `${days} يوم`
    if (weeks < 4) return `${weeks} أسبوع`
    if (months < 12) return `${months} شهر`
    return `${years} سنة`
  }

  if (seconds < 60) return 'Just now'
  if (minutes < 60) return `${minutes} min`
  if (hours < 24) return `${hours} hr`
  if (days < 7) return `${days} day${days === 1 ? '' : 's'}`
  if (weeks < 4) return `${weeks} wk`
  if (months < 12) return `${months} mo`
  return `${years} yr`
}
