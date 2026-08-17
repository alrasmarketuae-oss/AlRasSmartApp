import { useEffect, useState } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useGetCancellationReasonsQuery } from '../../store'
import type { OrderCancellationReason } from '../../types/adminOrder'

type CancelOrderDialogProps = {
  open: boolean
  busy?: boolean
  onClose: () => void
  onConfirm: (payload: { cancellationReasonId: number; cancellationNote?: string }) => void
}

export default function CancelOrderDialog({
  open,
  busy = false,
  onClose,
  onConfirm,
}: CancelOrderDialogProps) {
  const { t, locale } = useAppPreferences()
  const { data: reasons, isLoading, isError } = useGetCancellationReasonsQuery(undefined, {
    skip: !open,
  })
  const [reasonId, setReasonId] = useState('')
  const [note, setNote] = useState('')
  const [validationError, setValidationError] = useState<string | null>(null)

  useEffect(() => {
    if (!open) {
      setReasonId('')
      setNote('')
      setValidationError(null)
    }
  }, [open])

  if (!open) return null

  const selected = (reasons ?? []).find((item) => String(item.id) === reasonId) as
    | OrderCancellationReason
    | undefined
  const requiresNote = Boolean(selected?.requiresNote)

  function submit() {
    if (!reasonId) {
      setValidationError(t('orders.cancelReasonRequired'))
      return
    }
    if (requiresNote && !note.trim()) {
      setValidationError(t('orders.cancelNoteRequired'))
      return
    }

    setValidationError(null)
    onConfirm({
      cancellationReasonId: Number(reasonId),
      cancellationNote: note.trim() || undefined,
    })
  }

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-black/45 p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="cancel-order-dialog-title"
      onClick={busy ? undefined : onClose}
    >
      <div
        className="admin-card w-full max-w-md rounded-2xl p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id="cancel-order-dialog-title" className="admin-text text-start text-lg font-bold">
          {t('orders.cancelDealTitle')}
        </h2>
        <p className="admin-text-muted mt-2 text-start text-sm leading-relaxed">
          {t('orders.cancelDealHint')}
        </p>

        {isError ? (
          <p className="mt-3 text-start text-sm text-red-600">{t('orders.loadCancellationReasonsError')}</p>
        ) : null}

        <label className="mt-4 block text-start">
          <span className="admin-text text-xs font-bold">{t('orders.cancelReason')}</span>
          <select
            value={reasonId}
            disabled={busy || isLoading}
            onChange={(e) => {
              setReasonId(e.target.value)
              setValidationError(null)
            }}
            className="admin-input mt-1 w-full rounded-xl px-3 py-2.5 text-sm"
          >
            <option value="">{t('orders.cancelReasonPlaceholder')}</option>
            {(reasons ?? []).map((reason) => (
              <option key={reason.id} value={reason.id}>
                {locale === 'ar' ? reason.nameAr : reason.nameEn}
              </option>
            ))}
          </select>
        </label>

        <label className="mt-3 block text-start">
          <span className="admin-text text-xs font-bold">{t('orders.cancelNote')}</span>
          <textarea
            value={note}
            disabled={busy}
            onChange={(e) => {
              setNote(e.target.value)
              setValidationError(null)
            }}
            rows={3}
            maxLength={2000}
            className="admin-input mt-1 w-full rounded-xl px-3 py-2.5 text-sm"
            placeholder={t('orders.cancelNotePlaceholder')}
          />
        </label>

        {validationError ? (
          <p className="mt-2 text-start text-xs text-red-600">{validationError}</p>
        ) : null}

        <div className="mt-6 flex flex-wrap justify-end gap-2">
          <button
            type="button"
            disabled={busy}
            onClick={onClose}
            className="admin-border rounded-xl border bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50 disabled:opacity-50 dark:bg-slate-900 dark:text-slate-200"
          >
            {t('cancel')}
          </button>
          <button
            type="button"
            disabled={busy || isLoading || isError}
            onClick={submit}
            className="rounded-xl bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50"
          >
            {busy ? t('orders.updatingStatus') : t('orders.cancelDealConfirm')}
          </button>
        </div>
      </div>
    </div>
  )
}
