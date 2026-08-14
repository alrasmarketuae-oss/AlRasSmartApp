type BilingualNameLinesProps = {
  nameEn?: string | null
  nameAr?: string | null
  fallback: string
  className?: string
  primaryClassName?: string
  secondaryClassName?: string
}

function looksArabic(text: string): boolean {
  return /[\u0600-\u06FF]/.test(text)
}

export default function BilingualNameLines({
  nameEn,
  nameAr,
  fallback,
  className = '',
  primaryClassName = 'admin-text font-semibold',
  secondaryClassName = 'admin-text-muted text-xs',
}: BilingualNameLinesProps) {
  const trimmedFallback = fallback.trim() || '—'
  const en = nameEn?.trim()
    || (!looksArabic(trimmedFallback) && trimmedFallback !== '—' ? trimmedFallback : '')
  const ar = nameAr?.trim()
    || (looksArabic(trimmedFallback) && trimmedFallback !== '—' ? trimmedFallback : '')

  if (!en && !ar) {
    return <span className={primaryClassName}>{trimmedFallback}</span>
  }

  return (
    <div className={className}>
      {en ? <p className={`${primaryClassName} truncate`}>{en}</p> : null}
      {ar ? (
        <p className={`${secondaryClassName} mt-0.5 truncate`} dir="rtl">
          {ar}
        </p>
      ) : null}
    </div>
  )
}
