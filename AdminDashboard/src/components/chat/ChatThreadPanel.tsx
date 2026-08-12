import { useEffect, useMemo, useRef, useState } from 'react'
import { createVoiceFile, pickVoiceRecorderMimeType } from '../../lib/voiceRecording'
import ChatComposer from './ChatComposer'
import ChatMessageBubble from './ChatMessageBubble'
import ChatSessionDivider from './ChatSessionDivider'
import { PROJECT_IMAGES } from '../../constants/projectImages'
import { IconArrowLeft, IconChat } from '../icons'
import { resolveAssetUrl } from '../../lib/assets'
import type { ChatCompanyDisplay } from '../../lib/chatCompanyReport'
import type { ChatContact, ChatMessage, ChatSupportSession } from '../../types/chat'

export type VoiceDraft = {
  file: File
  previewUrl: string
  durationSeconds: number
}

type ChatThreadPanelProps = {
  contact: ChatContact | null
  messages: ChatMessage[]
  myUserId: string
  isLoading: boolean
  isRefreshing?: boolean
  hasMore?: boolean
  isLoadingOlder?: boolean
  onLoadOlder?: () => void
  isLocked?: boolean
  lockAgentName?: string | null
  supervisingAgentName?: string | null
  supportSessions?: ChatSupportSession[]
  canCloseConversation?: boolean
  isClosingConversation?: boolean
  onCloseConversation?: () => Promise<void>
  onSendText: (text: string) => Promise<void>
  onSendImages: (files: File[]) => Promise<void>
  onSendVoice: (file: File) => Promise<void>
  onSendVideo: (file: File) => Promise<void>
  onSendDocument: (file: File) => Promise<void>
  onSendLocation: () => Promise<void>
  onBack?: () => void
  companyDisplay?: ChatCompanyDisplay | null
  onCompanyClick?: () => void
  isGeneratingReport?: boolean
  className?: string
  t: (key: string, params?: Record<string, string | number>) => string
}

export default function ChatThreadPanel({
  contact,
  messages,
  isLoading,
  isRefreshing = false,
  hasMore = false,
  isLoadingOlder = false,
  onLoadOlder,
  isLocked = false,
  lockAgentName = null,
  supervisingAgentName = null,
  supportSessions = [],
  canCloseConversation = false,
  isClosingConversation = false,
  onCloseConversation,
  onSendText,
  onSendImages,
  onSendVoice,
  onSendVideo,
  onSendDocument,
  onSendLocation,
  onBack,
  companyDisplay = null,
  onCompanyClick,
  isGeneratingReport = false,
  className = '',
  t,
}: ChatThreadPanelProps) {
  const [draft, setDraft] = useState('')
  const [recording, setRecording] = useState(false)
  const [recordingSeconds, setRecordingSeconds] = useState(0)
  const [voiceDraft, setVoiceDraft] = useState<VoiceDraft | null>(null)
  const recorderRef = useRef<MediaRecorder | null>(null)
  const recordingStartedAtRef = useRef<number>(0)
  const cancelRecordingRef = useRef(false)
  const chunksRef = useRef<Blob[]>([])
  const bottomRef = useRef<HTMLDivElement | null>(null)
  const scrollRef = useRef<HTMLDivElement | null>(null)
  const loadingOlderRef = useRef(false)
  const prevTailIdRef = useRef<string | null>(null)
  const imageInputRef = useRef<HTMLInputElement | null>(null)
  const videoInputRef = useRef<HTMLInputElement | null>(null)
  const documentInputRef = useRef<HTMLInputElement | null>(null)

  const sortedMessages = useMemo(
    () => [...messages].sort((a, b) => a.sentAtUtc.localeCompare(b.sentAtUtc)),
    [messages],
  )

  const threadItems = useMemo(() => {
    type ThreadItem =
      | { kind: 'session-start'; session: ChatSupportSession }
      | { kind: 'session-end'; session: ChatSupportSession }
      | { kind: 'message'; message: ChatMessage }

    if (supportSessions.length === 0) {
      return sortedMessages.map((message) => ({ kind: 'message' as const, message }))
    }

    const events: Array<{ at: string; order: number; item: ThreadItem }> = []
    let order = 0
    const sessions = [...supportSessions].sort((a, b) =>
      a.assignedAtUtc.localeCompare(b.assignedAtUtc),
    )

    for (const session of sessions) {
      events.push({
        at: session.assignedAtUtc,
        order: order++,
        item: { kind: 'session-start', session },
      })
      if (!session.isActive) {
        events.push({
          at: session.releasedAtUtc ?? session.assignedAtUtc,
          order: order++,
          item: { kind: 'session-end', session },
        })
      }
    }

    for (const message of sortedMessages) {
      events.push({
        at: message.sentAtUtc,
        order: order++,
        item: { kind: 'message', message },
      })
    }

    events.sort((a, b) => a.at.localeCompare(b.at) || a.order - b.order)
    return events.map((entry) => entry.item)
  }, [sortedMessages, supportSessions])

  useEffect(() => {
    const tailId = sortedMessages[sortedMessages.length - 1]?.messageId ?? null
    if (tailId && tailId !== prevTailIdRef.current && !isLoadingOlder) {
      bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
    }
    prevTailIdRef.current = tailId
  }, [sortedMessages, isLoadingOlder, contact?.contactUserId, voiceDraft])

  useEffect(() => {
    loadingOlderRef.current = isLoadingOlder
  }, [isLoadingOlder])

  useEffect(() => {
    const node = scrollRef.current
    if (!node || !onLoadOlder) return

    function handleScroll() {
      if (!node || loadingOlderRef.current || !hasMore) return
      if (node.scrollTop <= 72) {
        onLoadOlder?.()
      }
    }

    node.addEventListener('scroll', handleScroll, { passive: true })
    return () => node.removeEventListener('scroll', handleScroll)
  }, [contact?.contactUserId, hasMore, onLoadOlder])

  useEffect(() => {
    if (!recording) {
      setRecordingSeconds(0)
      return
    }

    const timer = window.setInterval(() => {
      setRecordingSeconds((value) => value + 1)
    }, 1000)

    return () => window.clearInterval(timer)
  }, [recording])

  useEffect(() => {
    return () => {
      if (voiceDraft?.previewUrl) {
        URL.revokeObjectURL(voiceDraft.previewUrl)
      }
    }
  }, [voiceDraft])

  if (!contact) {
    return (
      <section
        className={`chat-thread-bg hidden flex-1 flex-col items-center justify-center p-8 text-center lg:flex ${className}`}
      >
        <div className="max-w-sm rounded-3xl border border-[#3B7FC7]/15 bg-white/80 p-8 shadow-xl backdrop-blur dark:border-slate-700 dark:bg-slate-900/80">
          <div className="mx-auto mb-4 flex h-20 w-20 items-center justify-center rounded-3xl bg-gradient-to-br from-[#3B7FC7] to-[#619d51] shadow-lg">
            <IconChat className="h-10 w-10 text-white" />
          </div>
          <img src={PROJECT_IMAGES.logo} alt="" className="mx-auto mb-3 h-12 w-12 object-contain opacity-90" />
          <p className="text-lg font-bold text-slate-800 dark:text-white">{t('chat.selectContact')}</p>
          <p className="mt-2 text-sm text-slate-500">{t('chat.selectContactHint')}</p>
        </div>
      </section>
    )
  }

  async function handleSendText() {
    const text = draft.trim()
    if (!text) return
    setDraft('')
    await onSendText(text)
  }

  function clearVoiceDraft() {
    setVoiceDraft((current) => {
      if (current?.previewUrl) {
        URL.revokeObjectURL(current.previewUrl)
      }
      return null
    })
  }

  async function startRecording() {
    if (recording || voiceDraft) return

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const mimeType = pickVoiceRecorderMimeType()
      const recorder = mimeType ? new MediaRecorder(stream, { mimeType }) : new MediaRecorder(stream)
      chunksRef.current = []
      recordingStartedAtRef.current = Date.now()

      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) chunksRef.current.push(event.data)
      }

      recorder.onstop = () => {
        stream.getTracks().forEach((track) => track.stop())

        if (cancelRecordingRef.current) {
          cancelRecordingRef.current = false
          chunksRef.current = []
          setRecording(false)
          return
        }

        if (chunksRef.current.length === 0) {
          setRecording(false)
          return
        }

        const recordedMime = recorder.mimeType || mimeType || chunksRef.current[0]?.type
        const blob = new Blob(chunksRef.current, { type: recordedMime || 'audio/mp4' })
        const durationSeconds = Math.max(
          1,
          Math.round((Date.now() - recordingStartedAtRef.current) / 1000),
        )
        const file = createVoiceFile(blob, recordedMime)
        const previewUrl = URL.createObjectURL(blob)
        setVoiceDraft({ file, previewUrl, durationSeconds })
        setRecording(false)
      }

      recorderRef.current = recorder
      recorder.start()
      setRecording(true)
    } catch {
      window.alert(t('chat.micDenied'))
    }
  }

  function stopRecording() {
    if (!recording) return
    recorderRef.current?.stop()
    recorderRef.current = null
  }

  function cancelRecording() {
    if (recording) {
      cancelRecordingRef.current = true
      chunksRef.current = []
      recorderRef.current?.stop()
      recorderRef.current = null
      setRecording(false)
      return
    }

    clearVoiceDraft()
  }

  async function sendVoiceDraft() {
    if (!voiceDraft) return
    const file = voiceDraft.file
    clearVoiceDraft()
    await onSendVoice(file)
  }

  const avatarUrl = resolveAssetUrl(companyDisplay?.imageUrl ?? contact.avatarUrl)
  const headerTitle = companyDisplay?.title ?? contact.displayName
  const headerSubtitle = companyDisplay?.subtitle

  return (
    <section className={`chat-thread-bg flex min-h-0 flex-1 flex-col ${className}`}>
      <header className="chat-thread-header flex shrink-0 items-center gap-2 px-2 py-2.5 shadow-sm sm:gap-3 sm:px-4 sm:py-3">
        {onBack ? (
          <button
            type="button"
            onClick={onBack}
            className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-white/95 transition hover:bg-white/10 lg:hidden"
            aria-label={t('chat.back')}
          >
            <IconArrowLeft className="h-5 w-5 rtl:rotate-180" />
          </button>
        ) : null}

        {(() => {
          const headerContent = (
            <>
              {avatarUrl ? (
                <img
                  src={avatarUrl}
                  alt=""
                  className="h-10 w-10 shrink-0 rounded-full object-cover ring-2 ring-white/30 sm:h-11 sm:w-11"
                />
              ) : (
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-white/20 text-sm font-bold text-white sm:h-11 sm:w-11">
                  {headerTitle.charAt(0).toUpperCase()}
                </div>
              )}

              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <h3 className="truncate text-base font-bold text-white sm:text-lg">{headerTitle}</h3>
                  {companyDisplay?.isCompany ? (
                    <span className="shrink-0 rounded-full bg-white/20 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-white">
                      {t('chat.companyBadge')}
                    </span>
                  ) : null}
                  {isGeneratingReport ? (
                    <span className="shrink-0 text-[11px] text-white/80">{t('chat.companyReportGenerating')}</span>
                  ) : null}
                </div>
                {headerSubtitle ? (
                  <p className="truncate text-xs text-white/75">{headerSubtitle}</p>
                ) : null}
                <p className="flex items-center gap-1.5 text-xs text-white/85">
                  <span
                    className={`inline-block h-2 w-2 rounded-full ${contact.isOnline ? 'bg-[#25d366]' : 'bg-white/40'}`}
                  />
                  {supervisingAgentName
                    ? t('chat.supervising', { name: supervisingAgentName })
                    : contact.isOnline
                      ? t('chat.online')
                      : contact.contactLastSeenAtUtc
                        ? t('chat.lastSeen')
                        : t('chat.offline')}
                </p>
              </div>
            </>
          )

          if (onCompanyClick) {
            return (
              <button
                type="button"
                onClick={onCompanyClick}
                disabled={isGeneratingReport}
                className="flex min-w-0 flex-1 items-center gap-2 rounded-xl text-start transition hover:bg-white/10 disabled:opacity-70 sm:gap-3"
                title={t('chat.companyReportHint')}
              >
                {headerContent}
              </button>
            )
          }

          return (
            <div className="flex min-w-0 flex-1 items-center gap-2 sm:gap-3">
              {headerContent}
            </div>
          )
        })()}

        {canCloseConversation && onCloseConversation ? (
          <button
            type="button"
            onClick={() => void onCloseConversation()}
            disabled={isClosingConversation}
            className="shrink-0 rounded-full border border-white/30 bg-white/10 px-3 py-1.5 text-xs font-semibold text-white transition hover:bg-white/20 disabled:opacity-60"
          >
            {isClosingConversation ? t('chat.closing') : t('chat.closeConversation')}
          </button>
        ) : null}
      </header>

      <div
        ref={scrollRef}
        className="chat-messages-scroll min-h-0 flex-1 space-y-2 overflow-y-auto px-2 py-3 sm:space-y-3 sm:px-4 sm:py-4"
      >
        {isLoadingOlder ? (
          <p className="sticky top-0 z-10 rounded-full bg-white/90 py-1 text-center text-xs text-slate-500 shadow-sm backdrop-blur dark:bg-slate-900/90">
            {t('chat.loadingOlder')}
          </p>
        ) : null}
        {!isLoadingOlder && hasMore ? (
          <p className="text-center text-xs text-slate-400">{t('chat.scrollForOlder')}</p>
        ) : null}
        {isRefreshing ? (
          <p className="sticky top-0 z-10 rounded-full bg-white/90 py-1 text-center text-xs text-slate-500 shadow-sm backdrop-blur dark:bg-slate-900/90">
            {t('chat.refreshing')}
          </p>
        ) : null}
        {isLoading ? (
          <p className="text-center text-sm text-slate-500">{t('chat.loadingMessages')}</p>
        ) : isLocked ? (
          <div className="flex flex-1 flex-col items-center justify-center px-6 text-center">
            <p className="text-base font-bold text-[#111b21] dark:text-slate-100">{t('chat.lockedTitle')}</p>
            <p className="mt-2 max-w-sm text-sm text-[#667781]">
              {lockAgentName
                ? t('chat.lockedByOther', { name: lockAgentName })
                : t('chat.lockedHint')}
            </p>
          </div>
        ) : threadItems.length === 0 ? (
          <p className="rounded-2xl bg-white/70 py-6 text-center text-sm text-slate-500 dark:bg-slate-800/70">
            {t('chat.noMessages')}
          </p>
        ) : (
          threadItems.map((item) => {
            if (item.kind === 'session-start') {
              return (
                <ChatSessionDivider
                  key={`session-start-${item.session.agentUserId}-${item.session.assignedAtUtc}`}
                  session={item.session}
                  kind="start"
                  t={t}
                />
              )
            }
            if (item.kind === 'session-end') {
              return (
                <ChatSessionDivider
                  key={`session-end-${item.session.agentUserId}-${item.session.releasedAtUtc ?? item.session.assignedAtUtc}`}
                  session={item.session}
                  kind="end"
                  t={t}
                />
              )
            }
            return (
              <ChatMessageBubble
                key={item.message.messageId}
                message={item.message}
                isMine={item.message.toUserId === contact.contactUserId}
              />
            )
          })
        )}
        <div ref={bottomRef} />
      </div>

      <input
        ref={imageInputRef}
        type="file"
        accept="image/*"
        multiple
        className="hidden"
        onChange={(e) => {
          const files = Array.from(e.target.files ?? []).filter((file) => file.type.startsWith('image/'))
          e.target.value = ''
          if (files.length > 0) void onSendImages(files)
        }}
      />

      <input
        ref={videoInputRef}
        type="file"
        accept="video/mp4,video/quicktime,video/webm,.mp4,.mov,.webm"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0]
          e.target.value = ''
          if (file) void onSendVideo(file)
        }}
      />

      <input
        ref={documentInputRef}
        type="file"
        accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.csv,.rtf,.zip"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0]
          e.target.value = ''
          if (file) void onSendDocument(file)
        }}
      />

      {!isLocked ? (
      <ChatComposer
        draft={draft}
        onDraftChange={setDraft}
        onSubmit={() => void handleSendText()}
        onPickImage={() => imageInputRef.current?.click()}
        onPickVideo={() => videoInputRef.current?.click()}
        onPickDocument={() => documentInputRef.current?.click()}
        onShareLocation={() => void onSendLocation()}
        recording={recording}
        recordingSeconds={recordingSeconds}
        voiceDraft={voiceDraft}
        onStartRecording={() => void startRecording()}
        onStopRecording={stopRecording}
        onCancelRecording={cancelRecording}
        onSendVoiceDraft={() => void sendVoiceDraft()}
        t={t}
      />
      ) : null}
    </section>
  )
}
