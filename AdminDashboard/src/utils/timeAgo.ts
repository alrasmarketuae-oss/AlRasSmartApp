type Locale = 'ar' | 'en'

type RelativeUnit = {
  seconds: number
  en: string
  arSingular: string
  arDual: string
  arPlural: string
}

const UNITS: RelativeUnit[] = [
  { seconds: 31_536_000, en: 'year', arSingular: 'عام', arDual: 'عامين', arPlural: 'أعوام' },
  { seconds: 2_592_000, en: 'month', arSingular: 'شهر', arDual: 'شهرين', arPlural: 'أشهر' },
  { seconds: 604_800, en: 'week', arSingular: 'أسبوع', arDual: 'أسبوعين', arPlural: 'أسابيع' },
  { seconds: 86_400, en: 'day', arSingular: 'يوم', arDual: 'يومين', arPlural: 'أيام' },
  { seconds: 3_600, en: 'hour', arSingular: 'ساعة', arDual: 'ساعتين', arPlural: 'ساعات' },
  { seconds: 60, en: 'minute', arSingular: 'دقيقة', arDual: 'دقيقتين', arPlural: 'دقائق' },
  { seconds: 1, en: 'second', arSingular: 'ثانية', arDual: 'ثانيتين', arPlural: 'ثوانٍ' },
]

function formatArabic(count: number, unit: RelativeUnit): string {
  if (count === 1) return `منذ ${unit.arSingular}`
  if (count === 2) return `منذ ${unit.arDual}`
  if (count >= 3 && count <= 10) return `منذ ${count} ${unit.arPlural}`
  return `منذ ${count} ${unit.arSingular}`
}

function formatEnglish(count: number, unit: RelativeUnit): string {
  return `${count} ${unit.en}${count === 1 ? '' : 's'} ago`
}

/**
 * Formats a timestamp as a localized relative "time ago" string
 * (e.g. "منذ يوم" / "3 days ago"). Falls back to the raw value when unparsable.
 */
export function formatRelativeTime(value: string | null | undefined, locale: Locale): string {
  if (!value) return '—'
  const date = new Date(value)
  const time = date.getTime()
  if (Number.isNaN(time)) return value

  return formatRelativeFromSeconds(Math.floor((Date.now() - time) / 1000), locale)
}

/**
 * Formats an already-computed elapsed duration (in seconds) as a localized relative
 * "time ago" string. Useful when the server provides a timezone-safe age directly.
 */
export function formatRelativeFromSeconds(diffSeconds: number, locale: Locale): string {
  if (!Number.isFinite(diffSeconds)) return '—'
  const elapsed = Math.max(0, Math.floor(diffSeconds))

  if (elapsed < 10) {
    return locale === 'ar' ? 'منذ لحظات' : 'just now'
  }

  for (const unit of UNITS) {
    if (elapsed >= unit.seconds) {
      const count = Math.floor(elapsed / unit.seconds)
      return locale === 'ar' ? formatArabic(count, unit) : formatEnglish(count, unit)
    }
  }

  return locale === 'ar' ? 'منذ لحظات' : 'just now'
}
