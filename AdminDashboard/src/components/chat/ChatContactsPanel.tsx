import { PROJECT_IMAGES } from '../../constants/projectImages'
import { useAppPreferences } from '../../context/AppPreferencesProvider'
import { formatChatRelativeTime } from '../../utils/formatChatRelativeTime'
import { IconSearch } from '../icons'
import { resolveProfileAssetUrl } from '../../lib/assets'
import { resolveChatCompanyDisplay } from '../../lib/chatCompanyReport'
import type { ChatContact } from '../../types/chat'

type ChatContactsPanelProps = {
  contacts: ChatContact[]
  selectedUserId: string | null
  onSelect: (contact: ChatContact) => void
  isLoading: boolean
  isSearching: boolean
  searchValue: string
  onSearchChange: (value: string) => void
  newChatUsers: Array<{ id: string; name: string; imgPath: string | null }>
  onStartChat: (userId: string, displayName: string, avatarUrl: string | null) => void
  className?: string
  t: (key: string, params?: Record<string, string | number>) => string
}

export default function ChatContactsPanel({
  contacts,
  selectedUserId,
  onSelect,
  isLoading,
  isSearching,
  searchValue,
  onSearchChange,
  newChatUsers,
  onStartChat,
  className = '',
  t,
}: ChatContactsPanelProps) {
  const { locale } = useAppPreferences()

  return (
    <aside
      className={`flex h-full min-h-0 w-full shrink-0 flex-col overflow-hidden border-e border-[#d1d7db] bg-white dark:border-slate-700 dark:bg-slate-900 lg:w-80 xl:w-96 ${className}`}
    >
      <div className="chat-sidebar-header shrink-0 px-4 pb-3 pt-4 text-white shadow-md sm:pb-4 sm:pt-5">
        <div className="flex items-center gap-3">
          <img src={PROJECT_IMAGES.logo} alt="" className="h-10 w-10 rounded-full bg-white/95 p-1 shadow" />
          <div>
            <h2 className="text-lg font-bold leading-tight">{t('chat.title')}</h2>
            <p className="text-xs text-white/85">{t('nav.chat')}</p>
          </div>
        </div>
        <div className="relative mt-3 sm:mt-4">
          <IconSearch className="pointer-events-none absolute start-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#3B7FC7]" />
          <input
            type="search"
            value={searchValue}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder={t('chat.searchPlaceholder')}
            className="w-full rounded-full border-0 bg-white/95 py-2.5 pe-3 ps-10 text-sm text-slate-800 shadow-sm outline-none ring-2 ring-transparent focus:ring-white/50"
          />
        </div>
        {isSearching ? (
          <p className="mt-2 text-xs text-white/90">{t('chat.searchHint')}</p>
        ) : null}
      </div>

      {isSearching && newChatUsers.length > 0 ? (
        <div className="shrink-0 border-b border-[#e9edef] bg-[#f0f2f5] p-2 dark:border-slate-700 dark:bg-slate-800/50">
          <p className="px-2 py-1 text-xs font-semibold text-[#008069]">{t('chat.startNew')}</p>
          <ul className="max-h-40 overflow-y-auto">
            {newChatUsers.map((user) => (
              <li key={user.id}>
                <button
                  type="button"
                  onClick={() => onStartChat(user.id, user.name, user.imgPath)}
                  className="flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-start transition hover:bg-white dark:hover:bg-slate-700"
                >
                  <Avatar name={user.name} src={user.imgPath} />
                  <span className="truncate text-sm font-medium text-slate-800 dark:text-slate-100">
                    {user.name}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </div>
      ) : null}

      <div className="min-h-0 flex-1 overflow-y-auto">
        {isSearching ? (
          <p className="px-4 py-2 text-xs font-semibold uppercase tracking-wide text-[#667781]">
            {t('chat.conversationResults')}
          </p>
        ) : null}

        {isLoading ? (
          <p className="p-4 text-center text-sm text-slate-500">{t('loading')}</p>
        ) : contacts.length === 0 ? (
          <p className="p-6 text-center text-sm text-slate-500">
            {isSearching ? t('chat.searchNoResults') : t('chat.noContacts')}
          </p>
        ) : (
          <ul>
            {contacts.map((contact) => {
              const active = contact.contactUserId === selectedUserId
              const company = resolveChatCompanyDisplay(contact)
              const avatarSrc = company.imageUrl
              return (
                <li key={contact.contactUserId} className="border-b border-[#e9edef] dark:border-slate-800">
                  <button
                    type="button"
                    onClick={() => onSelect(contact)}
                    className={`flex w-full items-center gap-3 px-3 py-3 text-start transition sm:px-4 ${
                      active
                        ? 'bg-[#f0f2f5] dark:bg-slate-800'
                        : 'hover:bg-[#f5f6f6] dark:hover:bg-slate-800/70'
                    }`}
                  >
                    <div className="relative shrink-0">
                      <Avatar name={company.title} src={avatarSrc} />
                      {contact.isOnline ? (
                        <span className="absolute bottom-0 end-0 h-3 w-3 rounded-full border-2 border-white bg-[#25d366] dark:border-slate-900" />
                      ) : null}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <div className="min-w-0">
                          <span className="block truncate text-[15px] font-semibold text-[#111b21] dark:text-slate-100">
                            {company.title}
                          </span>
                          {company.subtitle ? (
                            <span className="block truncate text-xs text-[#667781]">{company.subtitle}</span>
                          ) : null}
                        </div>
                        <span className="shrink-0 text-[11px] text-[#667781]">
                          {(contact.lastMessageSentAtUtc
                            ? formatChatRelativeTime(contact.lastMessageSentAtUtc, locale)
                            : null) || contact.lastMessageRelativeTime}
                        </span>
                      </div>
                      <div className="mt-0.5 flex items-center justify-between gap-2">
                        <span className="notranslate truncate text-sm text-[#667781]" translate="no">
                          {contact.lastMessagePreview ?? '—'}
                        </span>
                        {contact.unreadCount > 0 ? (
                          <span className="inline-flex min-w-[20px] shrink-0 items-center justify-center rounded-full bg-[#25d366] px-1.5 py-0.5 text-[11px] font-bold text-white">
                            {contact.unreadCount}
                          </span>
                        ) : null}
                      </div>
                      {contact.assignedAgentName ? (
                        <p className="mt-1 truncate text-[11px] font-semibold text-[#3B7FC7]">
                          {contact.isAssignedToMe
                            ? t('chat.assignedToYou')
                            : t('chat.handledBy', { name: contact.assignedAgentName })}
                        </p>
                      ) : null}
                    </div>
                  </button>
                </li>
              )
            })}
          </ul>
        )}
      </div>
    </aside>
  )
}

function Avatar({ name, src }: { name: string; src: string | null }) {
  const url = resolveProfileAssetUrl(src)
  if (url) {
    return <img src={url} alt="" className="h-12 w-12 rounded-full object-cover" />
  }

  return (
    <div className="flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-[#3B7FC7] to-[#619d51] text-sm font-bold text-white">
      {name.charAt(0).toUpperCase()}
    </div>
  )
}
