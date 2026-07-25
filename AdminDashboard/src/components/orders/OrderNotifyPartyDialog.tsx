import { useState, type FormEvent } from 'react'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { useSendAdminNotificationMutation } from '../../store'
import { getRtkErrorMessage } from '../../utils/rtkError'

type OrderNotifyPartyDialogProps = {
  open: boolean
  onClose: () => void
  targetUserId: string
  targetName: string
  partyLabel: string
  orderId: number
}

export default function OrderNotifyPartyDialog({
  open,
  onClose,
  targetUserId,
  targetName,
  partyLabel,
  orderId,
}: OrderNotifyPartyDialogProps) {
  const { t } = useAppPreferences()
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [sendNotification, { isLoading }] = useSendAdminNotificationMutation()

  if (!open) return null

  async function onSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setSuccess(null)

    if (!targetUserId.trim()) {
      setError(t('orders.notifyMissingUser'))
      return
    }
    if (!title.trim() || !body.trim()) {
      setError(t('orders.notifyRequiredEn'))
      return
    }

    try {
      await sendNotification({
        audience: 'SingleUser',
        targetUserId: targetUserId.trim(),
        title: title.trim(),
        body: body.trim(),
        type: 'order_admin_message',
      }).unwrap()
      setSuccess(t('orders.notifyQueued'))
      setTitle('')
      setBody('')
    } catch (err) {
      setError(getRtkErrorMessage(err as never, t('orders.notifyFailed')))
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 print:hidden">
      <div className="admin-card w-full max-w-lg rounded-2xl p-5 shadow-xl">
        <div className="mb-4 flex items-start justify-between gap-3">
          <div>
            <h3 className="admin-text text-lg font-bold">{t('orders.notifyTitle')}</h3>
            <p className="admin-text-muted mt-1 text-sm">
              {partyLabel}: <span className="font-semibold">{targetName || '—'}</span>
              {' · '}
              {t('orders.orderNumber')} #{orderId}
            </p>
            <p className="admin-text-subtle mt-1 text-xs">{t('orders.notifyHint')}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="admin-btn-ghost px-2 py-1 text-sm"
          >
            ✕
          </button>
        </div>

        <form onSubmit={onSubmit} className="space-y-3">
          <div>
            <label className="admin-text-muted mb-1 block text-xs font-bold">
              {t('orders.notifyTitleEn')}
            </label>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="admin-input h-10 w-full px-3 text-sm"
              required
            />
          </div>
          <div>
            <label className="admin-text-muted mb-1 block text-xs font-bold">
              {t('orders.notifyBodyEn')}
            </label>
            <textarea
              value={body}
              onChange={(e) => setBody(e.target.value)}
              rows={3}
              className="admin-input w-full px-3 py-2 text-sm"
              required
            />
          </div>

          {error ? <div className="admin-alert-error text-sm">{error}</div> : null}
          {success ? <div className="admin-alert-success text-sm">{success}</div> : null}

          <div className="flex justify-end gap-2 pt-1">
            <button type="button" onClick={onClose} className="admin-btn-ghost">
              {t('cancel')}
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="inline-flex h-10 items-center rounded-xl bg-[#3B7FC7] px-4 text-sm font-bold text-white hover:bg-[#2f6ab0] disabled:opacity-60"
            >
              {isLoading ? t('sending') : t('orders.notifySend')}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
