import { useMemo, useState } from 'react'
import { resolveContactAvatarUrl } from '../../lib/chatCompanyReport'
import { resolveProfileAssetUrl } from '../../lib/assets'
import type { ChatContact } from '../../types/chat'

type ChatForwardPickerProps = {
  contacts: ChatContact[]
  currentUserId?: string | null
  onSelect: (contactUserId: string) => void
  onClose: () => void
  t: (key: string) => string
}

export default function ChatForwardPicker({
  contacts,
  currentUserId,
  onSelect,
  onClose,
  t,
}: ChatForwardPickerProps) {
  const [query, setQuery] = useState('')

  const filtered = useMemo(() => {
    const term = query.trim().toLowerCase()
    return contacts.filter((contact) => {
      if (currentUserId && contact.contactUserId === currentUserId) return true
      if (!term) return true
      return (
        contact.displayName.toLowerCase().includes(term) ||
        (contact.companyName ?? '').toLowerCase().includes(term)
      )
    })
  }, [contacts, currentUserId, query])

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 p-3 sm:items-center">
      <div className="flex max-h-[80vh] w-full max-w-md flex-col rounded-2xl bg-white shadow-2xl dark:bg-slate-900">
        <div className="border-b border-slate-200 px-4 py-3 dark:border-slate-700">
          <h2 className="text-base font-bold">{t('chat.forwardTo')}</h2>
          <p className="mt-1 text-xs text-slate-500">{t('chat.forwardHint')}</p>
          <input
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            className="mt-3 w-full rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-[#3B7FC7]/30 dark:border-slate-700 dark:bg-slate-800"
            placeholder={t('chat.searchPlaceholder')}
          />
        </div>
        <div className="min-h-0 flex-1 overflow-y-auto py-1">
          {filtered.length === 0 ? (
            <p className="px-4 py-6 text-center text-sm text-slate-500">{t('chat.forwardEmpty')}</p>
          ) : (
            filtered.map((contact) => {
              const avatar = resolveProfileAssetUrl(resolveContactAvatarUrl(contact))
              return (
                <button
                  key={contact.contactUserId}
                  type="button"
                  className="flex w-full items-center gap-3 px-4 py-2.5 text-start hover:bg-slate-50 dark:hover:bg-slate-800"
                  onClick={() => onSelect(contact.contactUserId)}
                >
                  {avatar ? (
                    <img src={avatar} alt="" className="h-10 w-10 rounded-full object-cover" />
                  ) : (
                    <div className="flex h-10 w-10 items-center justify-center rounded-full bg-[#3B7FC7]/15 font-bold text-[#3B7FC7]">
                      {contact.displayName.charAt(0).toUpperCase()}
                    </div>
                  )}
                  <span className="truncate text-sm font-semibold">{contact.displayName}</span>
                </button>
              )
            })
          )}
        </div>
        <button
          type="button"
          className="border-t border-slate-200 px-4 py-3 text-sm font-semibold text-[#3B7FC7] dark:border-slate-700"
          onClick={onClose}
        >
          {t('chat.back')}
        </button>
      </div>
    </div>
  )
}
