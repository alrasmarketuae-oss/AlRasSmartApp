import type { ChatSupportSession } from '../../types/chat'

type ChatSessionDividerProps = {
  session: ChatSupportSession
  kind: 'start' | 'end'
  t: (key: string, params?: Record<string, string | number>) => string
}

export default function ChatSessionDivider({ session, kind, t }: ChatSessionDividerProps) {
  const label =
    kind === 'end'
      ? t('chat.sessionClosedBy', { name: session.agentName })
      : session.isActive
        ? t('chat.sessionActive', { name: session.agentName })
        : t('chat.sessionStarted', { name: session.agentName })

  return (
    <div className="flex justify-center py-2">
      <div className="max-w-[92%] rounded-full bg-white/90 px-4 py-1.5 text-center text-xs font-semibold text-[#54656f] shadow-sm backdrop-blur dark:bg-slate-900/90 dark:text-slate-300">
        {label}
      </div>
    </div>
  )
}
