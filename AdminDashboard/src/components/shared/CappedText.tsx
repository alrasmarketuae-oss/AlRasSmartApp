import { type ReactNode, useEffect, useState } from 'react'
import { createPortal } from 'react-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'

type CappedTextProps = {
  /** Full text to display (specifications, rejection reason, etc.). */
  text?: string | null
  /** Truncate once the text exceeds this many characters. */
  maxChars?: number
  /** Title shown in the popup header (e.g. field label). */
  title?: string
  /** Class applied to the inline text. */
  className?: string
  /** Rendered when the text is empty. */
  fallback?: ReactNode
}

/**
 * Renders [text] inline, but when it is longer than [maxChars] it shows a
 * truncated preview followed by a blue "…" that opens a small popup with the
 * full content. Used for long order/ad fields so cards stay compact.
 */
export default function CappedText({
  text,
  maxChars = 200,
  title,
  className,
  fallback = '—',
}: CappedTextProps) {
  const { t } = useAppPreferences()
  const [open, setOpen] = useState(false)

  useEffect(() => {
    if (!open) return
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false)
    }
    window.addEventListener('keydown', handleKey)
    return () => window.removeEventListener('keydown', handleKey)
  }, [open])

  const value = (text ?? '').trim()
  if (!value) return <>{fallback}</>

  if (value.length <= maxChars) {
    return <span className={className}>{value}</span>
  }

  const preview = value.slice(0, maxChars).trimEnd()

  return (
    <>
      <span className={className}>
        {preview}
        <button
          type="button"
          onClick={() => setOpen(true)}
          title={title}
          aria-label={title}
          className="mx-1 align-baseline font-extrabold text-[#2563eb] transition hover:text-[#1d4ed8]"
        >
          …
        </button>
      </span>

      {open
        ? createPortal(
        <div
          className="fixed inset-0 z-[120] flex items-center justify-center bg-black/50 p-4 print:hidden"
          role="dialog"
          aria-modal="true"
          onClick={() => setOpen(false)}
        >
          <div
            className="admin-card flex max-h-[80vh] w-full max-w-lg flex-col overflow-hidden rounded-2xl shadow-xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="admin-border flex items-start justify-between gap-3 border-b px-5 py-3.5">
              <h3 className="admin-text min-w-0 text-start text-sm font-bold">
                {title?.trim() || ''}
              </h3>
              <button
                type="button"
                onClick={() => setOpen(false)}
                aria-label={t('cancel')}
                className="shrink-0 rounded-lg p-1.5 text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-800"
              >
                <svg
                  className="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={1.8}
                  aria-hidden
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="overflow-y-auto px-5 py-4">
              <p className="admin-text whitespace-pre-wrap break-words text-start text-sm leading-relaxed">
                {value}
              </p>
            </div>

            <div className="admin-border flex justify-end border-t px-5 py-3">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="admin-border rounded-xl border bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 dark:bg-slate-900 dark:text-slate-200"
              >
                {t('cancel')}
              </button>
            </div>
          </div>
        </div>,
            document.body,
          )
        : null}
    </>
  )
}
