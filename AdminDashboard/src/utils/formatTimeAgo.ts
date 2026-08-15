import type { Locale } from '../i18n/messages'

/** Parse API datetime as UTC (naive strings from SQL are UTC wall-clock). */
export function parseApiUtcDate(createdAt: string): Date | null {
  if (!createdAt) return null

  const trimmed = createdAt.trim()
  const hasExplicitZone = /Z$/i.test(trimmed) || /[+-]\d{2}:\d{2}$/.test(trimmed)
  const normalized = hasExplicitZone
    ? trimmed
    : trimmed.includes('T')
      ? `${trimmed}Z`
      : `${trimmed.replace(' ', 'T')}Z`

  const date = new Date(normalized)
  return Number.isNaN(date.getTime()) ? null : date
}

export function formatTimeAgo(createdAt: string, locale: Locale): string {
  const date = parseApiUtcDate(createdAt)
  if (!date) return ''

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

export function formatUtcDate(value: string): string {
  const date = parseApiUtcDate(value)
  if (!date) return value || '—'
  const y = date.getUTCFullYear()
  const m = String(date.getUTCMonth() + 1).padStart(2, '0')
  const day = String(date.getUTCDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

export function formatUtcDateTime(value: string, locale: 'ar' | 'en' | Locale): string {
  const date = parseApiUtcDate(value)
  if (!date) return value || '—'
  return `${date.toLocaleString(locale === 'ar' ? 'ar-AE' : 'en-GB', {
    timeZone: 'UTC',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  })} UTC`
}
