import { useQuery } from '@tanstack/react-query'
import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import {
  bookingIncotermHint,
  detectAdPlanKind,
  fetchAiConversations,
  looksLikeAdCreationIntent,
  looksLikeCancelPlan,
  planModePrompt,
  replyPrompt,
  transcribeVoice,
  type AdPlanKind,
  type AiConversation,
} from '../ai/aiApi'
import { AI_GRADIENT, AiAvatar, AiBubble, ThinkingTrace } from '../ai/AiParts'
import { useAiAssistant, type AiMessage } from '../ai/useAiAssistant'
import { useAuth } from '../auth/AuthProvider'
import { formatClock, useVoiceRecorder } from '../chat/useVoiceRecorder'
import { useI18n } from '../i18n/I18nProvider'
import { BackButton, Screen } from '../layout/ScreenLayout'
import { isVideoFile, uploadDraftImage, uploadDraftVideo, videoDurationSeconds } from '../lib/draftUpload'
import { usePageTitle } from '../lib/usePageTitle'
import type { StringKey } from '../i18n/strings'
import { Icon } from '../ui/Icon'
import { useToast } from '../ui/Toast'

export function AiAssistantHubPage() {
  const { t } = useI18n()
  const toast = useToast()
  usePageTitle(t('aiAssistantTitle'))

  return (
    <Screen title={t('aiAssistantTitle')} fallback="/profile">
      <div className="flex flex-col items-center pt-4 text-center">
        <span className={`grid size-24 place-items-center rounded-full p-1 shadow-[0_12px_30px_rgba(47,106,173,0.35)] ${AI_GRADIENT}`}>
          <span className="grid size-full place-items-center rounded-full border-2 border-white/40">
            <Icon name="sparkle" size={44} className="text-white" />
          </span>
        </span>
        <h1 className="mt-4 text-2xl font-extrabold text-title">{t('aiAssistantTitle')}</h1>
        <p className="mt-1 text-sm text-subtitle">{t('aiAssistantHubSubtitle')}</p>
      </div>

      <div className="mt-6 rounded-2xl border border-[#E6EAF2] bg-white p-4 shadow-sm">
        <div className="flex items-start gap-3">
          <AiAvatar size={36} />
          <div className="min-w-0">
            <p className="text-[15px] font-extrabold text-title">{t('aiAssistantHubHello')}</p>
            <p className="mt-1 text-[13px] leading-relaxed text-subtitle">{t('aiAssistantHubIntro')}</p>
          </div>
        </div>
      </div>

      <p className="mt-6 text-[15px] font-extrabold text-title">{t('aiAssistantHowToStart')}</p>
      <div className="mt-3 grid gap-3 sm:grid-cols-2">
        <Link to="/ai-assistant/chat" className={`flex items-center gap-3 rounded-2xl p-4 text-white shadow-[0_10px_24px_rgba(47,106,173,0.3)] transition hover:-translate-y-0.5 ${AI_GRADIENT}`}>
          <span className="grid size-12 shrink-0 place-items-center rounded-full bg-white/20">
            <Icon name="chat" size={24} />
          </span>
          <span className="min-w-0 flex-1 text-start">
            <span className="block text-[15px] font-extrabold">{t('aiAssistantChatWithAi')}</span>
            <span className="block text-[12px] text-white/85">{t('aiAssistantChatWithAiSubtitle')}</span>
          </span>
          <Icon name="chevronRight" size={20} className="rtl:rotate-180" />
        </Link>
        <button
          type="button"
          onClick={() => toast.info(t('aiComingSoon'))}
          className="flex items-center gap-3 rounded-2xl border border-[#E6EAF2] bg-white p-4 text-start shadow-sm transition hover:-translate-y-0.5"
        >
          <span className="grid size-12 shrink-0 place-items-center rounded-full bg-[#EEF4FB] text-brand">
            <Icon name="mic" size={24} />
          </span>
          <span className="min-w-0 flex-1">
            <span className="flex items-center gap-2 text-[15px] font-extrabold text-title">
              {t('aiAssistantTalkWithAi')}
              <span className="rounded-full bg-[#FFF4DB] px-2 py-0.5 text-[10px] font-bold text-[#B8860B]">{t('aiComingSoon')}</span>
            </span>
            <span className="block text-[12px] text-subtitle">{t('aiAssistantTalkWithAiSubtitle')}</span>
          </span>
        </button>
      </div>

      <div className="mt-8 flex items-center gap-3 rounded-2xl bg-[#F1F6FC] p-4">
        <Icon name="shield" size={26} className="shrink-0 text-brand" />
        <div>
          <p className="text-[13px] font-bold text-title">{t('dataSafeTitle')}</p>
          <p className="text-[12px] text-subtitle">{t('dataSafeSubtitle')}</p>
        </div>
      </div>
    </Screen>
  )
}

function narrativeFor(query: string, t: (k: StringKey) => string) {
  const q = query.toLowerCase()
  const steps = [t('aiAgentActivityWorking')]
  if (/price|cost|cheap|expensive|سعر|اسعار|أسعار|ارخص|أرخص|اغلى|أغلى|بكام/.test(q)) steps.push(t('aiAgentActivityCheckingPrice'))
  if (/order|cart|buy|طلب|اطلب|شراء|اشتري/.test(q)) steps.push(t('aiAgentActivityPreparing'))
  steps.push(t('aiAgentActivitySearching'), t('aiAgentActivityCheckingAvailability'), t('aiAgentActivityStillWorking'))
  return [...new Set(steps)]
}

function HistoryPanel({ currentSessionId, onPick, onClose }: { currentSessionId: string; onPick: (c: AiConversation) => void; onClose: () => void }) {
  const { t, isAr } = useI18n()
  const [search, setSearch] = useState('')
  const query = useQuery({ queryKey: ['ai-conversations'], queryFn: fetchAiConversations, staleTime: 30_000 })
  const items = useMemo(() => {
    const q = search.trim().toLowerCase()
    return (query.data ?? []).filter((c) => !q || (c.titlePreview ?? '').toLowerCase().includes(q))
  }, [query.data, search])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [onClose])

  const when = (raw?: string | null) => {
    if (!raw) return ''
    const d = new Date(raw)
    return d.toDateString() === new Date().toDateString()
      ? d.toLocaleTimeString(isAr ? 'ar-EG' : 'en-GB', { hour: '2-digit', minute: '2-digit' })
      : d.toLocaleDateString(isAr ? 'ar-EG' : 'en-GB')
  }

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/40" onClick={onClose}>
      <aside onClick={(e) => e.stopPropagation()} className="flex h-full w-full max-w-md flex-col bg-white shadow-2xl">
        <div className="flex h-16 items-center gap-2 border-b border-line px-4">
          <Icon name="history" size={20} className="text-brand" />
          <p className="flex-1 text-[16px] font-extrabold text-title">{t('aiAssistantHistoryTitle')}</p>
          <button type="button" onClick={onClose} className="grid size-9 place-items-center rounded-full hover:bg-black/5" aria-label={t('cancel')}>
            <Icon name="close" size={18} />
          </button>
        </div>
        <div className="p-3">
          <div className="flex h-11 items-center gap-2 rounded-xl border border-line bg-[#F8FAFC] px-3">
            <Icon name="search" size={18} className="text-subtitle" />
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder={t('aiAssistantHistorySearchHint')} className="h-full flex-1 bg-transparent text-sm outline-none" />
          </div>
        </div>
        <div className="min-h-0 flex-1 overflow-y-auto px-3 pb-4">
          {query.isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 6 }, (_, i) => (
                <div key={i} className="shimmer h-16 rounded-xl" />
              ))}
            </div>
          ) : query.isError ? (
            <div className="flex flex-col items-center gap-3 py-16 text-center text-sm text-subtitle">
              {t('aiAssistantHistoryLoadError')}
              <button type="button" onClick={() => void query.refetch()} className="rounded-xl bg-brand px-4 py-2 font-bold text-white">
                {t('retry')}
              </button>
            </div>
          ) : items.length === 0 ? (
            <p className="py-16 text-center text-sm text-subtitle">{search ? t('aiAssistantHistoryNoResults') : t('aiAssistantHistoryEmpty')}</p>
          ) : (
            <ul className="space-y-2">
              {items.map((c) => {
                const current = c.clientSessionId === currentSessionId
                return (
                  <li key={c.id}>
                    <button
                      type="button"
                      onClick={() => onPick(c)}
                      className={`flex w-full items-center gap-3 rounded-xl border p-3 text-start transition hover:bg-[#F4F8FC] ${current ? 'border-brand bg-[#EEF4FB]' : 'border-[#E6EAF2]'}`}
                    >
                      <span className="grid size-10 shrink-0 place-items-center rounded-full bg-[#EEF4FB] text-brand">
                        <Icon name="chat" size={18} />
                      </span>
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-[14px] font-bold text-title" dir="auto">{c.titlePreview?.trim() || t('aiAssistantHistoryUntitled')}</span>
                        <span className="block text-[12px] text-subtitle">
                          {when(c.lastMessageAtUtc)} · {c.messageCount ?? 0} {t('aiAssistantHistoryMessages')}
                        </span>
                      </span>
                    </button>
                  </li>
                )
              })}
            </ul>
          )}
        </div>
      </aside>
    </div>
  )
}

export function AiChatPage() {
  const { t, isAr } = useI18n()
  const auth = useAuth()
  const toast = useToast()
  const location = useLocation()
  const navigate = useNavigate()
  usePageTitle(t('aiAssistantTitle'))

  const ai = useAiAssistant({
    language: isAr ? 'ar' : 'en',
    welcome: t('aiAssistantWelcome'),
    connectionError: t('aiConnectionError'),
    companyCustomerSeesPrices: auth.isCompanyCustomer,
    narrative: (q) => narrativeFor(q, t),
    completedStep: t('aiAgentActivityCompleted'),
  })

  const [text, setText] = useState('')
  const [reply, setReply] = useState<AiMessage | null>(null)
  const [planMode, setPlanMode] = useState(false)
  const [planKind, setPlanKind] = useState<AdPlanKind | null>(null)
  const [draftImages, setDraftImages] = useState<string[]>([])
  const [draftVideo, setDraftVideo] = useState<{ path: string; duration: number } | null>(null)
  const [uploading, setUploading] = useState(false)
  const [transcribing, setTranscribing] = useState(false)
  const [historyOpen, setHistoryOpen] = useState(false)
  const listRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLTextAreaElement>(null)
  const mediaRef = useRef<HTMLInputElement>(null)
  const seeded = useRef(false)
  const stickRef = useRef(true)
  const queueRef = useRef<Array<{ text: string; reply: AiMessage | null }>>([])
  const [queued, setQueued] = useState<string[]>([])

  const isShipping = auth.session?.isShippingCompanyAccount === true

  const voice = useVoiceRecorder(
    async (file) => {
      setTranscribing(true)
      try {
        const heard = await transcribeVoice(file, isAr ? 'ar' : 'en')
        if (!heard) throw new Error('empty')
        setText((prev) => (prev.trim() ? `${prev.trim()} ${heard}` : heard))
        inputRef.current?.focus()
      } catch {
        toast.error(t('aiTranscribeFailed'))
      } finally {
        setTranscribing(false)
      }
    },
    () => toast.error(t('chatMicDenied')),
  )

  const scrollToEnd = () => {
    const el = listRef.current
    if (!el || !stickRef.current) return
    el.scrollTop = el.scrollHeight
  }

  useLayoutEffect(() => {
    scrollToEnd()
    const el = listRef.current
    const content = el?.firstElementChild
    if (!el || !content) return
    const observer = new ResizeObserver(() => scrollToEnd())
    observer.observe(content)
    return () => observer.disconnect()
  }, [ai.messages, ai.liveSteps, ai.thinking, draftImages.length, draftVideo, queued.length])

  const resize = (el: HTMLTextAreaElement | null) => {
    if (!el) return
    el.style.height = 'auto'
    el.style.height = `${Math.min(el.scrollHeight, 160)}px`
  }
  useEffect(() => resize(inputRef.current), [text])

  const cancelPlan = () => {
    setPlanMode(false)
    setPlanKind(null)
    setDraftImages([])
    setDraftVideo(null)
    ai.addLocal('assistant', t('aiPlanCancelled'))
  }

  const unauthorizedReason = (detected: AdPlanKind | null) => {
    const canCreate = auth.isSupplier || auth.isCompanyCustomer || isShipping
    if (!canCreate) return t('aiNotAllowedAds')
    if (auth.isCompanyCustomer && detected && detected !== 'request') return t('aiNotAllowedCompanyCustomer')
    if (isShipping && detected && detected !== 'shipping') return t('aiNotAllowedShipping')
    return null
  }

  const send = (raw = text, queuedReply?: AiMessage | null, fromQueue = false) => {
    const visible = raw.trim()
    if (!visible || uploading) return
    if (ai.busy && !fromQueue) {
      queueRef.current.push({ text: visible, reply })
      setQueued(queueRef.current.map((item) => item.text))
      stickRef.current = true
      setText('')
      setReply(null)
      return
    }
    if (ai.busy) {
      queueRef.current.unshift({ text: visible, reply: queuedReply ?? null })
      setQueued(queueRef.current.map((item) => item.text))
      return
    }
    const activeReply = fromQueue ? queuedReply : reply
    let inPlan = planMode
    let kind = planKind

    if (!inPlan && looksLikeAdCreationIntent(visible)) {
      const detected = detectAdPlanKind(visible)
      const reason = unauthorizedReason(detected)
      if (reason) {
        ai.addLocal('user', visible)
        ai.addLocal('assistant', reason)
        setText('')
        return
      }
      const locked: AdPlanKind | null = isShipping ? 'shipping' : auth.isCompanyCustomer ? 'request' : auth.isSupplier && !auth.isUaePhone ? 'booking' : null
      inPlan = true
      kind = locked ?? detected
      setPlanMode(true)
      setPlanKind(kind)
    } else if (inPlan && looksLikeCancelPlan(visible)) {
      ai.addLocal('user', visible)
      setText('')
      cancelPlan()
      return
    }

    const replyPreview = activeReply?.text.trim() || undefined
    let apiText = replyPreview ? replyPrompt(replyPreview, visible, isAr) : visible
    if (inPlan) {
      const parts = [planModePrompt(kind, isAr)]
      if (kind === 'booking') {
        const prior = ai.messages.filter((m) => m.role === 'user').map((m) => m.text).reverse()
        parts.push(bookingIncotermHint(prior, visible, isAr))
      }
      parts.push(apiText)
      apiText = parts.join('\n')
    }
    if (draftImages.length) apiText += `\n[draft_image_paths: ${draftImages.join(' | ')}]`
    if (draftVideo) apiText += `\n[draft_video_path: ${draftVideo.path}${draftVideo.duration ? `, duration: ${draftVideo.duration}` : ''}]`

    stickRef.current = true
    void ai.ask(visible, apiText, replyPreview)
    setText('')
    setReply(null)
    setDraftImages([])
    setDraftVideo(null)
  }

  const sendRef = useRef(send)
  sendRef.current = send

  useEffect(() => {
    if (ai.busy || uploading || queueRef.current.length === 0) return
    const next = queueRef.current.shift()
    if (!next) return
    setQueued(queueRef.current.map((item) => item.text))
    sendRef.current(next.text, next.reply, true)
  }, [ai.busy, uploading])

  const initialMessage = (location.state as { initialMessage?: string } | null)?.initialMessage
  useEffect(() => {
    if (!initialMessage || seeded.current) return
    seeded.current = true
    navigate(location.pathname, { replace: true, state: null })
    send(initialMessage)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initialMessage])

  const pickMedia = async (files: FileList | null) => {
    const list = Array.from(files ?? [])
    if (!list.length) return
    if (!auth.isAuthenticated) {
      toast.error(t('aiSignInFirst'))
      return
    }
    setUploading(true)
    stickRef.current = true
    ai.setThinkingNote(t('aiUploadingMedia'))
    let images = 0
    let video = false
    try {
      for (const file of list) {
        if (isVideoFile(file)) {
          if (video) continue
          const [path, duration] = await Promise.all([uploadDraftVideo(file), videoDurationSeconds(file)])
          setDraftVideo({ path, duration: duration > 0 ? Math.min(duration, 60) : 30 })
          video = true
        } else {
          const path = await uploadDraftImage(file)
          setDraftImages((prev) => (prev.includes(path) ? prev : [...prev, path]))
          images++
        }
      }
      if (images) toast.success(t('aiImagesUploaded', { count: images }))
      if (video) toast.success(t('aiVideoUploaded'))
    } catch {
      toast.error(t('aiUploadFailed'))
    } finally {
      ai.setThinkingNote(null)
      setUploading(false)
    }
  }

  const attachedCount = draftImages.length + (draftVideo ? 1 : 0)
  const lastPending = ai.messages[ai.messages.length - 1]
  const showLiveTrace = ai.thinking && (!lastPending || lastPending.role === 'user' || !lastPending.text)

  return (
    <div className={`flex h-dvh flex-col ${planMode ? 'bg-[#FFF8E7]' : 'bg-[#F6F8FC]'}`}>
      <header
        className={`z-20 rounded-b-3xl text-white shadow-[0_6px_16px_rgba(47,106,173,0.25)] ${planMode ? 'bg-gradient-to-br from-[#E6A817] to-[#F0D48A]' : AI_GRADIENT}`}
      >
        <div className="mx-auto w-full max-w-3xl px-2 pb-3 pt-2 sm:px-4">
          <div className="flex h-12 items-center gap-2">
            <BackButton fallback="/ai-assistant" className="text-white hover:bg-white/15" />
            <AiAvatar size={40} onDark />
            <div className="min-w-0 flex-1">
              <p className="truncate text-[16px] font-extrabold">{planMode ? t('aiPlanMode') : t('aiAssistantTitle')}</p>
              <p className="flex items-center gap-1.5 text-[11px] font-semibold tracking-wide text-white/90">
                <span className={`size-2 rounded-full ${planMode ? 'bg-[#FFF8E7]' : 'bg-[#6EE7A8]'}`} />
                {planMode ? t('aiPlanCreateAd') : t('aiAssistantFabLabel')}
              </p>
            </div>
            {planMode && (
              <button type="button" onClick={cancelPlan} className="rounded-full px-3 py-1.5 text-[12px] font-bold hover:bg-white/15">
                {t('cancel')}
              </button>
            )}
            <button type="button" onClick={ai.newChat} disabled={ai.busy} className="grid size-10 place-items-center rounded-full hover:bg-white/15 disabled:opacity-50" aria-label={t('aiNewChat')} title={t('aiNewChat')}>
              <Icon name="compose" size={21} />
            </button>
            {auth.isAuthenticated && (
              <button
                type="button"
                onClick={() => setHistoryOpen(true)}
                disabled={ai.busy || ai.historyLoading}
                className="grid size-10 place-items-center rounded-full hover:bg-white/15 disabled:opacity-50"
                aria-label={t('aiAssistantHistoryTitle')}
                title={t('aiAssistantHistoryTitle')}
              >
                {ai.historyLoading ? <span className="size-5 animate-spin rounded-full border-2 border-white/40 border-t-white" /> : <Icon name="history" size={21} />}
              </button>
            )}
          </div>
          <div className="mt-2 flex items-center gap-2 rounded-xl bg-white/15 px-3 py-2 text-[11px] font-medium leading-snug text-white/95">
            <Icon name="sparkle" size={14} className="shrink-0" />
            {planMode ? t('aiPlanHint') : t('aiAssistantSubtitle')}
          </div>
        </div>
      </header>

      <div
        ref={listRef}
        className="min-h-0 flex-1 overflow-y-auto"
        onScroll={(e) => {
          const el = e.currentTarget
          stickRef.current = el.scrollHeight - el.scrollTop - el.clientHeight < 120
        }}
      >
        <div className="mx-auto flex w-full max-w-3xl flex-col gap-4 px-3 py-5 sm:px-5">
          {ai.messages.map((m) => (
            <AiBubble
              key={m.id}
              message={m}
              sessionId={ai.sessionId}
              onReply={(msg) => {
                setReply(msg)
                inputRef.current?.focus()
              }}
            />
          ))}
          {showLiveTrace && (
            <div className="flex items-start gap-2">
              <AiAvatar size={30} />
              <div className="min-w-0 flex-1 sm:max-w-[85%]">
                <ThinkingTrace steps={ai.liveSteps} live startedAt={ai.thinkingStartedAt} />
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="border-t border-[#E6EAF2] bg-white pb-[env(safe-area-inset-bottom)]">
        <div className="mx-auto w-full max-w-3xl px-2 py-2 sm:px-4">
          {reply && (
            <div className="mb-2 flex items-center gap-2 rounded-xl border-s-[3px] border-brand bg-[#F4F8FC] px-3 py-2">
              <div className="min-w-0 flex-1 text-[12px]">
                <p className="font-bold text-brand">{t('aiAssistantReplyTo')}</p>
                <p className="truncate text-subtitle" dir="auto">{reply.text}</p>
              </div>
              <button type="button" onClick={() => setReply(null)} className="grid size-7 place-items-center rounded-full hover:bg-black/5" aria-label={t('aiAssistantCancelReply')}>
                <Icon name="close" size={16} />
              </button>
            </div>
          )}
          {queued.length > 0 && (
            <div className="mb-2 space-y-1">
              {queued.map((item, index) => (
                <div key={`${index}-${item}`} className="rounded-xl border border-brand/20 bg-[#F4F8FC] px-3 py-2 text-[12px] font-semibold text-title" dir="auto">
                  <span className="me-2 text-brand">{index + 1}.</span>
                  {item}
                </div>
              ))}
            </div>
          )}
          {attachedCount > 0 && (
            <div className="mb-2 flex items-center gap-2 rounded-xl bg-[#FFF4DB] px-3 py-2 text-[12px] font-semibold text-[#8A6100]">
              <Icon name="paperclip" size={15} />
              <span className="flex-1">{t('aiAttachedMedia', { count: attachedCount })}</span>
              <button
                type="button"
                onClick={() => {
                  setDraftImages([])
                  setDraftVideo(null)
                }}
                className="grid size-6 place-items-center rounded-full hover:bg-black/5"
                aria-label={t('cancel')}
              >
                <Icon name="close" size={14} />
              </button>
            </div>
          )}
          {voice.recording || transcribing ? (
            <div className="flex items-center gap-3 px-2 py-1.5">
              <span className={`size-3 rounded-full ${transcribing ? 'animate-spin border-2 border-brand/25 border-t-brand' : 'animate-pulse bg-[#DC2626]'}`} />
              <span className="flex-1 text-sm font-semibold text-title" dir="auto">
                {transcribing ? t('aiTranscribing') : `${t('aiAssistantListening')} ${formatClock(voice.seconds)}`}
              </span>
              {!transcribing && (
                <>
                  <button type="button" onClick={() => voice.stop(true)} className="grid size-11 place-items-center rounded-full text-[#DC2626] hover:bg-[#FDECEC]" aria-label={t('cancel')}>
                    <Icon name="trash" size={20} />
                  </button>
                  <button type="button" onClick={() => voice.stop()} className={`grid size-11 place-items-center rounded-full text-white ${AI_GRADIENT}`} aria-label={t('aiAssistantVoiceHint')}>
                    <Icon name="check" size={20} />
                  </button>
                </>
              )}
            </div>
          ) : (
            <div className="flex items-end gap-1.5">
              {planMode && (
                <button
                  type="button"
                  onClick={() => mediaRef.current?.click()}
                  disabled={uploading || ai.busy}
                  className="grid size-11 shrink-0 place-items-center rounded-full bg-[#FFF4DB] text-[#B8860B] hover:bg-[#FFEBC0] disabled:opacity-50"
                  aria-label={t('aiUploadAdMedia')}
                  title={t('aiUploadAdMedia')}
                >
                  {uploading ? <span className="size-5 animate-spin rounded-full border-2 border-[#B8860B]/30 border-t-[#B8860B]" /> : <Icon name="image" size={21} />}
                </button>
              )}
              <textarea
                ref={inputRef}
                value={text}
                rows={1}
                onChange={(e) => setText(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
                    e.preventDefault()
                    send()
                  }
                }}
                placeholder={t('aiAssistantHint')}
                dir="auto"
                className="max-h-40 min-h-11 flex-1 resize-none rounded-3xl border border-[#E6EAF2] bg-[#F8FAFC] px-4 py-2.5 text-[15px] text-title outline-none focus:border-brand"
              />
              {text.trim() ? (
                <button type="button" onClick={() => send()} disabled={uploading || !text.trim()} className={`grid size-11 shrink-0 place-items-center rounded-full text-white disabled:opacity-50 ${AI_GRADIENT}`} aria-label={t('chatSend')}>
                  <Icon name="send" size={19} className={isAr ? '-scale-x-100' : ''} />
                </button>
              ) : (
                <button type="button" onClick={() => void voice.start()} disabled={ai.busy} className={`grid size-11 shrink-0 place-items-center rounded-full text-white disabled:opacity-50 ${AI_GRADIENT}`} aria-label={t('chatVoiceMessage')}>
                  <Icon name="mic" size={20} />
                </button>
              )}
            </div>
          )}
          <input
            ref={mediaRef}
            type="file"
            accept="image/*,video/*"
            multiple
            hidden
            onChange={(e) => {
              void pickMedia(e.target.files)
              e.target.value = ''
            }}
          />
        </div>
      </div>

      {historyOpen && (
        <HistoryPanel
          currentSessionId={ai.sessionId}
          onClose={() => setHistoryOpen(false)}
          onPick={(c) => {
            setHistoryOpen(false)
            setPlanMode(false)
            setPlanKind(null)
            ai.resume(c.id, c.clientSessionId).catch(() => toast.error(t('aiAssistantHistoryLoadMessagesError')))
          }}
        />
      )}
    </div>
  )
}
