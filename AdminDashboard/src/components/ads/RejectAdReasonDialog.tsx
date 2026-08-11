import { useEffect, useState } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'

type RejectAdReasonDialogProps = {
  open: boolean
  busy?: boolean
  initialReasonEn?: string
  initialReasonAr?: string
  onCancel: () => void
  onConfirm: (payload: { supplierNotesEn: string; supplierNotesAr: string }) => void
}

export default function RejectAdReasonDialog({
  open,
  busy = false,
  initialReasonEn = '',
  initialReasonAr = '',
  onCancel,
  onConfirm,
}: RejectAdReasonDialogProps) {
  const { t } = useAppPreferences()
  const [reasonEn, setReasonEn] = useState(initialReasonEn)
  const [reasonAr, setReasonAr] = useState(initialReasonAr)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!open) return
    setReasonEn(initialReasonEn)
    setReasonAr(initialReasonAr)
    setError(null)
  }, [open, initialReasonEn, initialReasonAr])

  if (!open) return null

  function submit() {
    const supplierNotesEn = reasonEn.trim()
    const supplierNotesAr = reasonAr.trim()
    if (!supplierNotesEn && !supplierNotesAr) {
      setError(t('ads.rejectReasonRequired'))
      return
    }
    onConfirm({ supplierNotesEn, supplierNotesAr })
  }

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-black/45 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="reject-ad-reason-title"
      onClick={busy ? undefined : onCancel}
    >
      <div
        className="admin-card w-full max-w-lg rounded-2xl p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id="reject-ad-reason-title" className="admin-text text-start text-lg font-bold">
          {t('ads.rejectAd')}
        </h2>
        <p className="admin-text-muted mt-2 text-start text-sm leading-relaxed">
          {t('ads.rejectReasonDialogHint')}
        </p>

        <label className="mt-4 block text-start">
          <span className="admin-text-subtle text-xs font-semibold">
            {t('ads.rejectReasonAr')}
          </span>
          <textarea
            value={reasonAr}
            onChange={(e) => {
              setReasonAr(e.target.value)
              setError(null)
            }}
            rows={3}
            disabled={busy}
            placeholder={t('ads.rejectReasonArPlaceholder')}
            className="admin-input mt-1 w-full resize-y rounded-xl px-3 py-2 text-sm"
          />
        </label>

        <label className="mt-3 block text-start">
          <span className="admin-text-subtle text-xs font-semibold">
            {t('ads.rejectReasonEn')}
          </span>
          <textarea
            value={reasonEn}
            onChange={(e) => {
              setReasonEn(e.target.value)
              setError(null)
            }}
            rows={3}
            disabled={busy}
            placeholder={t('ads.rejectReasonEnPlaceholder')}
            className="admin-input mt-1 w-full resize-y rounded-xl px-3 py-2 text-sm"
          />
        </label>

        {error ? (
          <p className="mt-3 text-start text-sm font-semibold text-red-600 dark:text-red-400">
            {error}
          </p>
        ) : null}

        <div className="mt-5 flex flex-wrap justify-end gap-2">
          <button
            type="button"
            disabled={busy}
            onClick={onCancel}
            className="admin-border rounded-xl border bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50 dark:bg-slate-900 dark:text-slate-200"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            disabled={busy}
            onClick={submit}
            className="rounded-xl bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50"
          >
            {busy ? t('ads.rejecting') : t('ads.rejectAd')}
          </button>
        </div>
      </div>
    </div>
  )
}
