import { memo, useEffect, useState, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../auth/AuthProvider'
import { useI18n } from '../i18n/I18nProvider'
import { ProductCard } from '../products/ProductCard'
import { useViewer } from '../products/ProductGrid'
import { Icon } from '../ui/Icon'
import { useToast } from '../ui/Toast'
import { submitSupportCallback } from './aiApi'
import type { AiMessage } from './useAiAssistant'

export const AI_GRADIENT = 'bg-gradient-to-br from-[#2F6AAD] to-[#3A7DC5]'

export function AiAvatar({ size = 40, onDark = false }: { size?: number; onDark?: boolean }) {
  return (
    <span
      className={`grid shrink-0 place-items-center rounded-full ${onDark ? 'bg-white/20 ring-2 ring-white/40' : AI_GRADIENT} text-white`}
      style={{ width: size, height: size }}
    >
      <Icon name="sparkle" size={Math.round(size * 0.5)} />
    </span>
  )
}

const TOKEN = /\[([^\]]+)\]\(([^)\s]+)\)|\*\*([^*]+)\*\*|(https?:\/\/[^\s)]+)/g

function internalPath(url: string) {
  if (url.startsWith('/')) return url
  try {
    const u = new URL(url)
    if (u.origin === window.location.origin || /(^|\.)shop\.alrasmarketapp\.com$/i.test(u.hostname)) return `${u.pathname}${u.search}`
  } catch {
    return null
  }
  return null
}

function LinkOut({ href, children }: { href: string; children: ReactNode }) {
  const path = internalPath(href)
  const cls = 'font-semibold text-brand underline underline-offset-2 break-words'
  return path ? (
    <Link to={path} className={cls}>
      {children}
    </Link>
  ) : (
    <a href={href} target="_blank" rel="noreferrer noopener" className={cls}>
      {children}
    </a>
  )
}

/** Renders the subset of markdown the assistant emits: `[label](url)`, `**bold**` and bare links. */
export function RichText({ text: raw }: { text: string }) {
  const text = raw.replace(/!\[[^\]]*\]\([^)\s]*\)/g, '').replace(/\n{3,}/g, '\n\n').trim()
  const nodes: ReactNode[] = []
  let last = 0
  for (const m of text.matchAll(TOKEN)) {
    const index = m.index ?? 0
    if (index > last) nodes.push(text.slice(last, index))
    if (m[1] && m[2]) nodes.push(<LinkOut key={index} href={m[2]}>{m[1]}</LinkOut>)
    else if (m[3]) nodes.push(<strong key={index} className="font-bold">{m[3]}</strong>)
    else if (m[4]) nodes.push(<LinkOut key={index} href={m[4]}>{m[4]}</LinkOut>)
    last = index + m[0].length
  }
  if (last < text.length) nodes.push(text.slice(last))
  return <>{nodes}</>
}

export function ThinkingTrace({ steps, seconds, live = false, startedAt }: { steps: string[]; seconds?: number; live?: boolean; startedAt?: number | null }) {
  const { t } = useI18n()
  const [open, setOpen] = useState(live)
  const [now, setNow] = useState(() => Date.now())
  useEffect(() => {
    if (!live) return
    const id = window.setInterval(() => setNow(Date.now()), 1000)
    return () => window.clearInterval(id)
  }, [live])
  const elapsed = live && startedAt ? Math.max(0, Math.floor((now - startedAt) / 1000)) : seconds
  if (!steps.length && !live) return null
  const expanded = live || open

  return (
    <div className="mb-2 overflow-hidden rounded-xl border border-[#E6EAF2] bg-white">
      <button type="button" onClick={() => !live && setOpen((v) => !v)} className="flex w-full items-center gap-2 px-3 py-2 text-start text-[12px] font-semibold text-[#6B7280]">
        {live ? <span className="size-3.5 animate-spin rounded-full border-2 border-brand/25 border-t-brand" /> : <Icon name="sparkle" size={14} className="text-brand" />}
        <span className="flex-1">{live ? t('aiAssistantThinking') : elapsed ? t('aiThinkingFor', { seconds: elapsed }) : t('aiAgentActivityTitle')}</span>
        {live && elapsed !== undefined && <span className="tabular-nums text-[11px] text-[#9CA3AF]">{elapsed}s</span>}
        {!live && <Icon name="chevronDown" size={16} className={`transition ${open ? 'rotate-180' : ''}`} />}
      </button>
      {expanded && steps.length > 0 && (
        <ol className="space-y-1 border-t border-[#EEF1F6] px-3 py-2">
          {steps.map((step, i) => (
            <li key={`${i}-${step}`} className={`flex items-start gap-2 text-[12px] leading-5 ${live && i === steps.length - 1 ? 'text-title' : 'text-[#9CA3AF]'}`}>
              <span className={`mt-2 size-1.5 shrink-0 rounded-full ${live && i === steps.length - 1 ? 'animate-pulse bg-brand' : 'bg-[#CBD5E1]'}`} />
              <span dir="auto">{step}</span>
            </li>
          ))}
        </ol>
      )}
    </div>
  )
}

export function SupportCallbackForm({ question, sessionId }: { question?: string; sessionId: string }) {
  const { t, isAr } = useI18n()
  const { session } = useAuth()
  const [name, setName] = useState(session?.name?.trim() ?? '')
  const [phone, setPhone] = useState(session?.phone?.trim() ?? '')
  const [email, setEmail] = useState(session?.email?.trim() ?? '')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [done, setDone] = useState<string | null>(null)

  const submit = async () => {
    if (busy || done) return
    if (name.trim().length < 2 || phone.trim().length < 6 || !email.includes('@')) {
      setError(t('aiCallbackInvalid'))
      return
    }
    setBusy(true)
    setError(null)
    try {
      const res = await submitSupportCallback({
        fullName: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        ...(question?.trim() ? { question: question.trim().slice(0, 1000) } : {}),
        language: isAr ? 'ar' : 'en',
        source: 'ai_assistant',
        aiConversationId: sessionId,
      })
      setDone(res?.message?.trim() || t('aiCallbackDone'))
    } catch (e) {
      setError((e as Error).message)
    } finally {
      setBusy(false)
    }
  }

  if (done) return <div className="mt-2 rounded-xl border border-[#17B26A] bg-[#DCFAE6] p-3 text-[13px] font-semibold leading-relaxed text-[#067647]">{done}</div>

  const input = 'h-11 w-full rounded-[10px] border border-line bg-[#F8FAFC] px-3 text-[14px] text-title outline-none focus:border-brand'
  return (
    <div className="mt-2 space-y-2 rounded-xl border border-brand/35 bg-white p-3">
      <p className="text-[13px] font-bold text-brand">{t('aiCallbackTitle')}</p>
      <p className="text-[11px] text-subtitle">{t('aiCallbackSubtitle')}</p>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder={t('aiCallbackName')} className={input} />
      <input value={phone} onChange={(e) => setPhone(e.target.value.replace(/[^\d+\s\-()]/g, ''))} placeholder={t('aiCallbackPhone')} dir="ltr" inputMode="tel" className={`${input} text-left`} />
      <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder={t('aiCallbackEmail')} dir="ltr" type="email" className={`${input} text-left`} onKeyDown={(e) => e.key === 'Enter' && void submit()} />
      {error && <p className="text-[12px] text-[#B42318]">{error}</p>}
      <button type="button" onClick={() => void submit()} disabled={busy} className="grid h-11 w-full place-items-center rounded-[10px] bg-brand text-[13px] font-bold text-white disabled:opacity-60">
        {busy ? <span className="size-4 animate-spin rounded-full border-2 border-white/40 border-t-white" /> : t('aiCallbackSubmit')}
      </button>
    </div>
  )
}

function Listings({ items }: { items: NonNullable<AiMessage['listings']> }) {
  const viewer = useViewer()
  return (
    <div className="mt-2 grid grid-cols-2 gap-2.5 sm:grid-cols-3">
      {items.map((p) => (
        <ProductCard key={p.productId} product={p} viewer={viewer} preferRetail={p.hasRetailPricing === true && p.productTypeId === 1} />
      ))}
    </div>
  )
}

type BubbleProps = { message: AiMessage; sessionId: string; onReply: (m: AiMessage) => void }

export const AiBubble = memo(function AiBubble({ message, sessionId, onReply }: BubbleProps) {
  const { t } = useI18n()
  const toast = useToast()
  const mine = message.role === 'user'
  if (!mine && !message.text && !message.listings?.length) return null

  const copy = async () => {
    await navigator.clipboard?.writeText(message.text).catch(() => undefined)
    toast.success(t('chatCopied'))
  }

  if (mine) {
    return (
      <div className="flex justify-end">
        <div className={`max-w-[85%] rounded-2xl rounded-ee-md px-3.5 py-2.5 text-[15px] leading-relaxed text-white shadow-sm sm:max-w-[70%] ${AI_GRADIENT}`}>
          {message.replyPreview && (
            <div className="mb-1.5 rounded-lg border-s-[3px] border-white/70 bg-white/15 px-2 py-1 text-[12px] text-white/90">
              <p className="line-clamp-2" dir="auto">{message.replyPreview}</p>
            </div>
          )}
          <p className="whitespace-pre-wrap break-words" dir="auto">{message.text}</p>
        </div>
      </div>
    )
  }

  return (
    <div className="group flex items-start gap-2">
      <AiAvatar size={30} />
      <div className="min-w-0 flex-1">
        {message.thinkingSteps && <ThinkingTrace steps={message.thinkingSteps} seconds={message.thinkingSeconds} />}
        {message.text && (
          <div className={`w-fit max-w-full rounded-2xl rounded-ss-md border bg-white px-3.5 py-2.5 text-[15px] leading-relaxed shadow-sm sm:max-w-[85%] ${message.failed ? 'border-[#FECACA] text-[#B42318]' : 'border-[#E6EAF2] text-[#1F2937]'}`}>
            <p className="whitespace-pre-wrap break-words" dir="auto">
              <RichText text={message.text} />
              {message.streaming && <span className="ms-0.5 inline-block h-4 w-1.5 animate-pulse bg-brand align-middle" />}
            </p>
          </div>
        )}
        {!message.streaming && message.id !== 'welcome' && message.text && (
          <div className="mt-1 flex gap-1 opacity-70 transition group-hover:opacity-100">
            <button type="button" onClick={() => void copy()} className="flex items-center gap-1 rounded-full px-2 py-1 text-[11px] font-semibold text-subtitle hover:bg-black/5">
              <Icon name="copy" size={13} />
              {t('aiCopy')}
            </button>
            <button type="button" onClick={() => onReply(message)} className="flex items-center gap-1 rounded-full px-2 py-1 text-[11px] font-semibold text-subtitle hover:bg-black/5">
              <Icon name="reply" size={13} />
              {t('chatReply')}
            </button>
          </div>
        )}
        {message.showCallback && <SupportCallbackForm question={message.question} sessionId={sessionId} />}
        {message.listings && message.listings.length > 0 && <Listings items={message.listings} />}
      </div>
    </div>
  )
})
