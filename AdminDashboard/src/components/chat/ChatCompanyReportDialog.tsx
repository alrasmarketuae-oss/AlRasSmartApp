import { resolveAssetUrl } from '../../lib/assets'
import type { ChatCompanyReport } from '../../types/chatCompanyReport'

type ChatCompanyReportDialogProps = {
  open: boolean
  busy: boolean
  error: string | null
  report: ChatCompanyReport | null
  onClose: () => void
  t: (key: string, params?: Record<string, string | number>) => string
}

export default function ChatCompanyReportDialog({
  open,
  busy,
  error,
  report,
  onClose,
  t,
}: ChatCompanyReportDialogProps) {
  if (!open) return null

  const imageUrl = report?.companyImageUrl ? resolveAssetUrl(report.companyImageUrl) : null

  return (
    <div
      className="fixed inset-0 z-[120] flex items-center justify-center bg-black/50 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="chat-company-report-title"
      onClick={busy ? undefined : onClose}
    >
      <div
        className="admin-card flex max-h-[90vh] w-full max-w-2xl flex-col overflow-hidden rounded-2xl shadow-2xl"
        onClick={(event) => event.stopPropagation()}
      >
        <header className="admin-border flex items-start gap-3 border-b px-5 py-4">
          {imageUrl ? (
            <img
              src={imageUrl}
              alt=""
              className="h-14 w-14 shrink-0 rounded-xl object-cover ring-2 ring-indigo-100 dark:ring-indigo-900"
            />
          ) : (
            <div className="flex h-14 w-14 shrink-0 items-center justify-center rounded-xl bg-indigo-100 text-lg font-bold text-indigo-700 dark:bg-indigo-950 dark:text-indigo-200">
              {(report?.companyName || '?').charAt(0).toUpperCase()}
            </div>
          )}
          <div className="min-w-0 flex-1">
            <h2 id="chat-company-report-title" className="truncate text-lg font-bold text-slate-900 dark:text-slate-100">
              {report?.companyName || t('chat.companyReportTitle')}
            </h2>
            {report?.contactFullName ? (
              <p className="truncate text-sm text-slate-500">{report.contactFullName}</p>
            ) : null}
            {report ? (
              <p className="mt-1 text-xs text-slate-400">
                {t('chat.companyReportAdsCount', { count: report.adsCount })}
              </p>
            ) : null}
          </div>
          <button
            type="button"
            disabled={busy}
            onClick={onClose}
            className="rounded-lg px-2 py-1 text-sm font-semibold text-slate-500 hover:bg-slate-100 disabled:opacity-50 dark:hover:bg-slate-800"
          >
            {t('cancel')}
          </button>
        </header>

        <div className="min-h-0 flex-1 overflow-y-auto px-5 py-4">
          {busy ? (
            <p className="py-8 text-center text-sm text-slate-500">{t('chat.companyReportGenerating')}</p>
          ) : error ? (
            <p className="py-8 text-center text-sm text-red-600">{error}</p>
          ) : report?.report ? (
            <article className="prose prose-sm max-w-none whitespace-pre-wrap text-slate-800 dark:prose-invert dark:text-slate-100">
              {report.report}
            </article>
          ) : (
            <p className="py-8 text-center text-sm text-slate-500">{t('noData')}</p>
          )}
        </div>
      </div>
    </div>
  )
}
