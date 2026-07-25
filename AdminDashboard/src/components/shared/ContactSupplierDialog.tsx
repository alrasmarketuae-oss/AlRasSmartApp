import { useNavigate } from 'react-router-dom'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { resolveAssetUrl } from '../../lib/assets'

export type ContactTarget = {
  displayName: string
  email?: string | null
  phone?: string | null
  userId?: string | null
  avatarPath?: string | null
}

type ContactSupplierDialogProps = {
  open: boolean
  target: ContactTarget | null
  onClose: () => void
}

function digitsOnly(phone: string): string {
  return phone.replace(/\D/g, '')
}

function whatsappHref(phone: string | null | undefined): string | null {
  if (!phone?.trim()) return null
  const digits = digitsOnly(phone)
  if (digits.length < 8) return null
  return `https://wa.me/${digits}`
}

function mailtoHref(email: string | null | undefined): string | null {
  const value = email?.trim()
  if (!value || value === '—') return null
  return `mailto:${value}`
}

export default function ContactSupplierDialog({
  open,
  target,
  onClose,
}: ContactSupplierDialogProps) {
  const { t } = useAppPreferences()
  const navigate = useNavigate()

  if (!open || !target) return null

  const contact = target
  const whatsapp = whatsappHref(contact.phone)
  const email = mailtoHref(contact.email)
  const canChat = Boolean(contact.userId?.trim())
  const avatarUrl = resolveAssetUrl(contact.avatarPath)

  function openInAppChat() {
    const userId = contact.userId?.trim()
    if (!userId) return
    onClose()
    navigate('/chat', {
      state: {
        openChatWith: {
          userId,
          displayName: contact.displayName || '—',
          avatarUrl,
        },
      },
    })
  }

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center bg-black/45 p-4 print:hidden"
      role="dialog"
      aria-modal="true"
      aria-labelledby="contact-supplier-title"
      onClick={onClose}
    >
      <div
        className="admin-card w-full max-w-md rounded-2xl p-5 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id="contact-supplier-title" className="admin-text text-start text-lg font-bold">
          {t('reqsOffers.contactSupplier')}
        </h2>
        <p className="admin-text-muted mt-1 text-start text-sm">
          {t('reqsOffers.contactSupplierHint', { name: contact.displayName || '—' })}
        </p>

        <div className="mt-4 space-y-2">
          <button
            type="button"
            disabled={!whatsapp}
            onClick={() => {
              if (!whatsapp) return
              window.open(whatsapp, '_blank', 'noopener,noreferrer')
              onClose()
            }}
            className="flex w-full items-center gap-3 rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-start text-sm font-bold text-emerald-800 transition hover:bg-emerald-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-emerald-900/50 dark:bg-emerald-950/40 dark:text-emerald-200"
          >
            <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-emerald-600 text-white">
              W
            </span>
            <span className="min-w-0 flex-1">
              <span className="block">{t('reqsOffers.contactViaWhatsApp')}</span>
              <span className="admin-text-muted block text-xs font-medium" dir="ltr">
                {contact.phone?.trim() || t('reqsOffers.contactUnavailable')}
              </span>
            </span>
          </button>

          <button
            type="button"
            disabled={!canChat}
            onClick={openInAppChat}
            className="flex w-full items-center gap-3 rounded-xl border border-sky-200 bg-sky-50 px-4 py-3 text-start text-sm font-bold text-sky-800 transition hover:bg-sky-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-sky-900/50 dark:bg-sky-950/40 dark:text-sky-200"
          >
            <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#2563eb] text-white">
              ✉
            </span>
            <span className="min-w-0 flex-1">
              <span className="block">{t('reqsOffers.contactViaInApp')}</span>
              <span className="admin-text-muted block text-xs font-medium">
                {canChat
                  ? t('reqsOffers.contactViaInAppHint')
                  : t('reqsOffers.contactUnavailable')}
              </span>
            </span>
          </button>

          <button
            type="button"
            disabled={!email}
            onClick={() => {
              if (!email) return
              window.location.href = email
              onClose()
            }}
            className="flex w-full items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-start text-sm font-bold text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-50 dark:border-slate-700 dark:bg-slate-800/60 dark:text-slate-200"
          >
            <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-slate-600 text-white">
              @
            </span>
            <span className="min-w-0 flex-1">
              <span className="block">{t('reqsOffers.contactViaEmail')}</span>
              <span className="admin-text-muted block truncate text-xs font-medium">
                {email ? contact.email : t('reqsOffers.contactUnavailable')}
              </span>
            </span>
          </button>
        </div>

        <div className="mt-4 flex justify-end">
          <button
            type="button"
            onClick={onClose}
            className="rounded-xl px-4 py-2 text-sm font-semibold text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            {t('cancel')}
          </button>
        </div>
      </div>
    </div>
  )
}
