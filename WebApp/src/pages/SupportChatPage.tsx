import { Fragment, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { ChatBubble } from '../chat/ChatBubble'
import { MessageType, SUPPORT_ADMIN_ID, fileMessageType, sameId, type ChatMessage, type SupportSession } from '../chat/chatApi'
import { useSupportChat } from '../chat/useSupportChat'
import { formatClock, useVoiceRecorder } from '../chat/useVoiceRecorder'
import { useI18n } from '../i18n/I18nProvider'
import { BackButton } from '../layout/ScreenLayout'
import { usePageTitle } from '../lib/usePageTitle'
import { MediaPreview } from '../products/details/MediaViewer'
import { Icon } from '../ui/Icon'
import { useToast } from '../ui/Toast'

const MAX_VIDEO_MB = 30
const MAX_FILE_MB = 20

type TimelineItem =
  | { kind: 'day'; key: string; label: string }
  | { kind: 'message'; key: string; message: ChatMessage }
  | { kind: 'session'; key: string; text: string }

function dayLabel(date: Date, t: (k: 'chatToday' | 'chatYesterday') => string, isAr: boolean) {
  const today = new Date()
  const yesterday = new Date(Date.now() - 86_400_000)
  if (date.toDateString() === today.toDateString()) return t('chatToday')
  if (date.toDateString() === yesterday.toDateString()) return t('chatYesterday')
  return date.toLocaleDateString(isAr ? 'ar-EG' : 'en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
}

export default function SupportChatPage() {
  const { t, isAr } = useI18n()
  const { session, isAuthenticated } = useAuth()
  const location = useLocation()
  const navigate = useNavigate()
  const toast = useToast()
  usePageTitle(t('liveChat'))

  const myId = session?.id ?? ''
  const chat = useSupportChat(myId, SUPPORT_ADMIN_ID)
  const [text, setText] = useState('')
  const [reply, setReply] = useState<ChatMessage | null>(null)
  const [attachOpen, setAttachOpen] = useState(false)
  const [preview, setPreview] = useState<{ urls: string[]; index: number } | null>(null)
  const listRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLTextAreaElement>(null)
  const mediaRef = useRef<HTMLInputElement>(null)
  const fileRef = useRef<HTMLInputElement>(null)
  const stickToBottom = useRef(true)
  const prevHeight = useRef<number | null>(null)
  const initialSent = useRef(false)

  const voice = useVoiceRecorder(
    (file) => void chat.sendFile(file, MessageType.voice),
    () => toast.error(t('chatMicDenied')),
  )

  const initialMessage = (location.state as { initialMessage?: string } | null)?.initialMessage
  useEffect(() => {
    if (!initialMessage || initialSent.current || chat.loading || !chat.connected) return
    initialSent.current = true
    void chat.sendText(initialMessage)
    navigate(location.pathname, { replace: true, state: null })
  }, [initialMessage, chat.loading, chat.connected, chat, navigate, location.pathname])

  const timeline = useMemo<TimelineItem[]>(() => {
    const events: { at: number; item: TimelineItem }[] = chat.messages.map((m) => ({ at: new Date(m.sentAtUtc).getTime(), item: { kind: 'message', key: m.messageId, message: m } }))
    chat.sessions.forEach((s: SupportSession, i) => {
      events.push({
        at: new Date(s.assignedAtUtc).getTime(),
        item: { kind: 'session', key: `s-start-${i}-${s.assignedAtUtc}`, text: t(s.isActive ? 'chatSessionActiveWith' : 'chatSessionStartedWith', { name: s.agentName }) },
      })
      if (s.releasedAtUtc) {
        events.push({ at: new Date(s.releasedAtUtc).getTime(), item: { kind: 'session', key: `s-end-${i}-${s.releasedAtUtc}`, text: t('chatSessionClosedBy', { name: s.agentName }) } })
      }
    })
    events.sort((a, b) => a.at - b.at)
    const out: TimelineItem[] = []
    let lastDay = ''
    for (const e of events) {
      const d = new Date(e.at)
      const key = d.toDateString()
      if (key !== lastDay) {
        lastDay = key
        out.push({ kind: 'day', key: `d-${key}`, label: dayLabel(d, t, isAr) })
      }
      out.push(e.item)
    }
    return out
  }, [chat.messages, chat.sessions, t, isAr])

  useLayoutEffect(() => {
    const el = listRef.current
    if (!el) return
    if (prevHeight.current !== null) {
      el.scrollTop += el.scrollHeight - prevHeight.current
      prevHeight.current = null
    } else if (stickToBottom.current) {
      el.scrollTop = el.scrollHeight
    }
  }, [timeline])

  if (!isAuthenticated) return <Navigate to="/login" replace />

  const onScroll = () => {
    const el = listRef.current
    if (!el) return
    stickToBottom.current = el.scrollHeight - el.scrollTop - el.clientHeight < 120
    if (el.scrollTop < 80 && chat.hasMore && !chat.loadingOlder) {
      prevHeight.current = el.scrollHeight
      void chat.loadOlder()
    }
  }

  const submit = () => {
    const value = text.trim()
    if (!value) return
    stickToBottom.current = true
    void chat.sendText(value, reply)
    setText('')
    setReply(null)
    inputRef.current?.focus()
  }

  const pickFiles = (files: FileList | null) => {
    setAttachOpen(false)
    for (const file of Array.from(files ?? [])) {
      const type = fileMessageType(file)
      const limit = type === MessageType.video ? MAX_VIDEO_MB : type === MessageType.image ? 15 : MAX_FILE_MB
      if (file.size > limit * 1024 * 1024) {
        toast.error(t('chatFileTooLarge', { size: limit }))
        continue
      }
      stickToBottom.current = true
      void chat.sendFile(file, type)
    }
  }

  const shareLocation = () => {
    setAttachOpen(false)
    navigator.geolocation.getCurrentPosition(
      (pos) => void chat.sendLocation(pos.coords.latitude, pos.coords.longitude, t('chatMyLocation')),
      () => toast.error(t('chatLocationDenied')),
      { enableHighAccuracy: true, timeout: 15_000 },
    )
  }

  const title = chat.agentName || t('liveChat')

  return (
    <div className="flex h-dvh flex-col bg-[#EEF3F9]">
      <header className="z-20 border-b border-line bg-white">
        <div className="mx-auto flex h-16 w-full max-w-3xl items-center gap-2 px-2 sm:px-4">
          <BackButton fallback="/profile" />
          <span className="relative grid size-10 shrink-0 place-items-center rounded-full bg-gradient-to-br from-[#2F6AAD] to-[#3A7DC5] text-white">
            <Icon name="headset" size={20} />
            <span className={`absolute bottom-0 end-0 size-3 rounded-full border-2 border-white ${chat.connected ? 'bg-[#22C55E]' : 'bg-[#CBD5E1]'}`} />
          </span>
          <div className="min-w-0 flex-1">
            <p className="truncate text-[15px] font-extrabold text-title">{title}</p>
            <p className="truncate text-xs text-subtitle">{chat.connected ? t('supportTeam') : t('chatConnecting')}</p>
          </div>
        </div>
      </header>

      <div ref={listRef} onScroll={onScroll} className="min-h-0 flex-1 overflow-y-auto">
        <div className="mx-auto flex w-full max-w-3xl flex-col gap-1.5 px-3 py-4 sm:px-5">
          {chat.loadingOlder && (
            <div className="flex justify-center py-2">
              <span className="size-5 animate-spin rounded-full border-2 border-brand/25 border-t-brand" />
            </div>
          )}
          {chat.loading ? (
            <div className="space-y-3 py-4">
              {[60, 40, 70, 50].map((w, i) => (
                <div key={i} className={`flex ${i % 2 ? 'justify-end' : ''}`}>
                  <div className="shimmer h-12 rounded-2xl" style={{ width: `${w}%` }} />
                </div>
              ))}
            </div>
          ) : chat.error && !chat.messages.length ? (
            <div className="flex flex-col items-center gap-3 py-20 text-center">
              <p className="text-sm text-auth-body">{chat.error}</p>
              <button type="button" onClick={() => void chat.reload()} className="rounded-xl bg-brand px-5 py-2.5 text-sm font-bold text-white">
                {t('retry')}
              </button>
            </div>
          ) : timeline.length === 0 ? (
            <div className="flex flex-col items-center gap-3 py-20 text-center">
              <span className="grid size-20 place-items-center rounded-full bg-white shadow-sm">
                <img src="/assets/profile/message.svg" alt="" className="size-9" />
              </span>
              <p className="text-base font-extrabold text-title">{t('chatEmptyTitle')}</p>
              <p className="max-w-xs text-sm text-subtitle">{t('chatWithTheSupportTeamNow')}</p>
            </div>
          ) : (
            timeline.map((item) => (
              <Fragment key={item.key}>
                {item.kind === 'day' && (
                  <div className="my-2 flex justify-center">
                    <span className="rounded-full bg-white/90 px-3 py-1 text-[11px] font-semibold text-subtitle shadow-sm">{item.label}</span>
                  </div>
                )}
                {item.kind === 'session' && (
                  <div className="my-2 flex justify-center">
                    <span className="rounded-full bg-[#E1ECF8] px-3 py-1 text-[11px] font-bold text-[#2F6AAD]">{item.text}</span>
                  </div>
                )}
                {item.kind === 'message' && (
                  <ChatBubble
                    message={item.message}
                    mine={sameId(item.message.fromUserId, myId)}
                    onReply={(m) => {
                      setReply(m)
                      inputRef.current?.focus()
                    }}
                    onDelete={(m, scope) => void chat.remove(m, scope).catch((e: Error) => toast.error(e.message))}
                    onRetry={chat.retry}
                    onOpenImage={(urls, index) => setPreview({ urls, index })}
                  />
                )}
              </Fragment>
            ))
          )}
        </div>
      </div>

      <div className="border-t border-line bg-white pb-[env(safe-area-inset-bottom)]">
        <div className="mx-auto w-full max-w-3xl px-2 py-2 sm:px-4">
          {reply && (
            <div className="mb-2 flex items-center gap-2 rounded-xl border-s-[3px] border-brand bg-[#F4F8FC] px-3 py-2">
              <div className="min-w-0 flex-1 text-[12px]">
                <p className="font-bold text-brand">{t('chatReplyTo')}</p>
                <p className="truncate text-subtitle">{reply.messageType === MessageType.text ? reply.content : t('chatAttachFile')}</p>
              </div>
              <button type="button" onClick={() => setReply(null)} className="grid size-7 place-items-center rounded-full hover:bg-black/5" aria-label={t('cancel')}>
                <Icon name="close" size={16} />
              </button>
            </div>
          )}
          {voice.recording ? (
            <div className="flex items-center gap-3 px-2 py-1.5">
              <span className="size-3 animate-pulse rounded-full bg-[#DC2626]" />
              <span className="flex-1 text-sm font-semibold text-title" dir="ltr">
                {t('chatRecording')} {formatClock(voice.seconds)}
              </span>
              <button type="button" onClick={() => voice.stop(true)} className="grid size-11 place-items-center rounded-full text-[#DC2626] hover:bg-[#FDECEC]" aria-label={t('cancel')}>
                <Icon name="trash" size={20} />
              </button>
              <button type="button" onClick={() => voice.stop()} className="grid size-11 place-items-center rounded-full bg-brand text-white" aria-label={t('chatSend')}>
                <Icon name="send" size={19} />
              </button>
            </div>
          ) : (
            <div className="relative flex items-end gap-1.5">
              <button
                type="button"
                onClick={() => setAttachOpen((v) => !v)}
                className={`grid size-11 shrink-0 place-items-center rounded-full text-subtitle hover:bg-black/5 ${attachOpen ? 'rotate-45 text-brand' : ''} transition`}
                aria-label="Attach"
              >
                <Icon name="plus" size={24} />
              </button>
              {attachOpen && (
                <div className="absolute bottom-full start-0 z-30 mb-2 grid grid-cols-3 gap-2 rounded-2xl border border-line bg-white p-3 shadow-xl">
                  {[
                    { icon: 'image' as const, label: t('chatAttachPhoto'), color: '#7C3AED', run: () => mediaRef.current?.click() },
                    { icon: 'doc' as const, label: t('chatAttachFile'), color: '#DC2626', run: () => fileRef.current?.click() },
                    { icon: 'location' as const, label: t('chatAttachLocation'), color: '#0F766E', run: shareLocation },
                  ].map((a) => (
                    <button key={a.label} type="button" onClick={a.run} className="flex w-20 flex-col items-center gap-1.5 rounded-xl p-2 text-[12px] font-semibold text-title hover:bg-[#F4F8FC]">
                      <span className="grid size-11 place-items-center rounded-full text-white" style={{ backgroundColor: a.color }}>
                        <Icon name={a.icon} size={20} />
                      </span>
                      {a.label}
                    </button>
                  ))}
                </div>
              )}
              <textarea
                ref={inputRef}
                value={text}
                rows={1}
                onChange={(e) => {
                  setText(e.target.value)
                  e.target.style.height = 'auto'
                  e.target.style.height = `${Math.min(e.target.scrollHeight, 140)}px`
                }}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
                    e.preventDefault()
                    submit()
                  }
                }}
                placeholder={t('chatInputHint')}
                className="max-h-36 min-h-11 flex-1 resize-none rounded-3xl border border-line bg-[#F8FAFC] px-4 py-2.5 text-[15px] text-title outline-none focus:border-brand"
              />
              {text.trim() ? (
                <button type="button" onClick={submit} className="grid size-11 shrink-0 place-items-center rounded-full bg-gradient-to-br from-[#2F6AAD] to-[#3A7DC5] text-white" aria-label={t('chatSend')}>
                  <Icon name="send" size={19} className={isAr ? '-scale-x-100' : ''} />
                </button>
              ) : (
                <button type="button" onClick={() => void voice.start()} className="grid size-11 shrink-0 place-items-center rounded-full bg-gradient-to-br from-[#2F6AAD] to-[#3A7DC5] text-white" aria-label={t('chatVoiceMessage')}>
                  <Icon name="mic" size={20} />
                </button>
              )}
            </div>
          )}
          <input ref={mediaRef} type="file" accept="image/*,video/*" multiple hidden onChange={(e) => {
              pickFiles(e.target.files)
              e.target.value = ''
            }} />
          <input
            ref={fileRef}
            type="file"
            accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.csv,.rtf,.zip"
            hidden
            onChange={(e) => {
              pickFiles(e.target.files)
              e.target.value = ''
            }}
          />
        </div>
      </div>

      {preview && <MediaPreview media={preview.urls.map((url) => ({ kind: 'image' as const, url }))} index={preview.index} onClose={() => setPreview(null)} />}
    </div>
  )
}
