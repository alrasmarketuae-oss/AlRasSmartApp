import { useEffect } from 'react'
import { Link } from 'react-router-dom'
import UserDetailContainer from '../users/UserDetailContainer'

type ChatUserInfoDialogProps = {
  userId: string | null
  title?: string | null
  onClose: () => void
  t: (key: string, params?: Record<string, string | number>) => string
}

export default function ChatUserInfoDialog({ userId, title, onClose, t }: ChatUserInfoDialogProps) {
  useEffect(() => {
    if (!userId) return
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [userId, onClose])

  if (!userId) return null

  return (
    <div
      className="fixed inset-0 z-[120] flex items-center justify-center bg-black/50 p-2 sm:p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="chat-user-info-title"
      onClick={onClose}
    >
      <div
        className="admin-card flex max-h-[94vh] w-full max-w-6xl flex-col overflow-hidden rounded-2xl shadow-2xl"
        onClick={(event) => event.stopPropagation()}
      >
        <header className="admin-border flex items-center gap-3 border-b px-4 py-3 sm:px-5">
          <h2
            id="chat-user-info-title"
            className="min-w-0 flex-1 truncate text-lg font-bold text-slate-900 dark:text-slate-100"
          >
            {title?.trim() || t('chat.contactInfoTitle')}
          </h2>
          <Link
            to={`/users/${userId}`}
            className="shrink-0 rounded-lg px-2 py-1 text-sm font-semibold text-[#3B7FC7] hover:bg-[#eff6ff] dark:hover:bg-slate-800"
          >
            {t('chat.openFullProfile')}
          </Link>
          <button
            type="button"
            onClick={onClose}
            className="shrink-0 rounded-lg px-2 py-1 text-sm font-semibold text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            {t('chat.close')}
          </button>
        </header>

        <div className="min-h-0 flex-1 space-y-6 overflow-y-auto px-3 py-4 sm:px-5">
          <UserDetailContainer key={userId} userId={userId} onDeleted={onClose} />
        </div>
      </div>
    </div>
  )
}
