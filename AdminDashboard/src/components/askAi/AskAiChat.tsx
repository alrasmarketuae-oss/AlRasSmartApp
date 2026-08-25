import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useLocation } from 'react-router-dom'
import { useAskAiPageData } from '../../context/AskAiPageDataProvider'
import { askAdminAi, type AskAiHistoryMessage } from '../../services/askAiApi'
import {
  buildAskAiPageSnapshot,
  serializeAskAiPageContext,
} from '../../utils/askAiPageSnapshot'

type ChatMessage = {
  id: string
  role: 'user' | 'assistant'
  text: string
}

type AskAiChatProps = {
  open: boolean
  onClose: () => void
  isRtl: boolean
  locale: 'ar' | 'en'
  labels: {
    title: string
    subtitle: string
    hello: string
    placeholder: string
    send: string
    close: string
    thinking: string
    error: string
    dataSafe: string
    poweredBy: string
  }
}

let messageSeq = 0
function nextId(role: string) {
  messageSeq += 1
  return `${role}-${messageSeq}-${Date.now()}`
}

function detectDir(text: string): 'rtl' | 'ltr' | 'auto' {
  const sample = text.trim().slice(0, 80)
  if (/[\u0600-\u06FF]/.test(sample)) return 'rtl'
  if (/[A-Za-z]/.test(sample)) return 'ltr'
  return 'auto'
}

const HISTORY_LIMIT = 8

export default function AskAiChat({
  open,
  onClose,
  isRtl,
  locale,
  labels,
}: AskAiChatProps) {
  const location = useLocation()
  const { getPageData } = useAskAiPageData()
  const [input, setInput] = useState('')
  const [busy, setBusy] = useState(false)
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const listRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const sendingRef = useRef(false)
  const abortRef = useRef<AbortController | null>(null)
  const messagesRef = useRef<ChatMessage[]>([])

  useEffect(() => {
    messagesRef.current = messages
  }, [messages])

  useEffect(() => {
    if (!open) {
      abortRef.current?.abort()
      abortRef.current = null
      setBusy(false)
      sendingRef.current = false
      return
    }
    const id = window.setTimeout(() => inputRef.current?.focus(), 120)
    return () => window.clearTimeout(id)
  }, [open])

  useEffect(() => {
    if (listRef.current) {
      listRef.current.scrollTop = listRef.current.scrollHeight
    }
  }, [messages, busy, open])

  if (!open) return null

  async function sendMessage(text: string) {
    const trimmed = text.trim()
    if (!trimmed || busy || sendingRef.current) return

    sendingRef.current = true
    const prior = messagesRef.current
    const history: AskAiHistoryMessage[] = prior
      .slice(-HISTORY_LIMIT)
      .map((m) => ({ role: m.role, content: m.text }))

    const pagePath = `${location.pathname}${location.search}${location.hash}`
    const snapshot = buildAskAiPageSnapshot({
      path: pagePath,
      registeredData: getPageData(),
    })
    const pageContext = serializeAskAiPageContext(snapshot)

    setMessages((prev) => [
      ...prev,
      { id: nextId('user'), role: 'user', text: trimmed },
    ])
    setInput('')
    setBusy(true)

    abortRef.current?.abort()
    const controller = new AbortController()
    abortRef.current = controller

    try {
      const result = await askAdminAi({
        message: trimmed,
        language: locale,
        history,
        pagePath,
        pageContext,
        signal: controller.signal,
      })
      const answer = (result.answer || '').trim() || labels.error
      setMessages((prev) => [
        ...prev,
        { id: nextId('assistant'), role: 'assistant', text: answer },
      ])
    } catch (err) {
      if ((err as Error)?.name === 'AbortError') return
      setMessages((prev) => [
        ...prev,
        { id: nextId('assistant'), role: 'assistant', text: labels.error },
      ])
    } finally {
      setBusy(false)
      sendingRef.current = false
    }
  }

  function onSubmit(e: FormEvent) {
    e.preventDefault()
    void sendMessage(input)
  }

  return (
    <div className="fixed inset-0 z-[95] print:hidden" role="dialog" aria-modal="true">
      <button
        type="button"
        className="absolute inset-0 bg-slate-900/35"
        aria-label={labels.close}
        onClick={onClose}
      />

      <aside
        className={`absolute inset-y-0 flex w-full max-w-none flex-col bg-white shadow-2xl dark:bg-slate-900 sm:max-w-[440px] ${
          isRtl
            ? 'left-0 border-r border-slate-200 dark:border-slate-700'
            : 'right-0 border-l border-slate-200 dark:border-slate-700'
        }`}
        dir={isRtl ? 'rtl' : 'ltr'}
      >
        <div className="flex items-center gap-3 border-b border-slate-100 px-4 py-3 dark:border-slate-700">
          <img
            src="/seo/alras-agent-robot.png"
            alt=""
            className="h-10 w-10 rounded-full object-cover ring-2 ring-[#3B7FC7]/30"
          />
          <div className="min-w-0 flex-1">
            <p className="truncate text-base font-extrabold text-[#0b1f3a] dark:text-slate-100">
              {labels.title}
            </p>
            <p className="truncate text-xs font-medium text-slate-500 dark:text-slate-400">
              {labels.subtitle}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-full px-2 py-1 text-sm font-semibold text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            {labels.close}
          </button>
        </div>

        <div
          ref={listRef}
          className="flex-1 space-y-3 overflow-y-auto bg-[#3B7FC7]/[0.06] px-4 py-4 dark:bg-slate-950/60"
        >
          <div
            className="rounded-2xl bg-[#3B7FC7]/15 p-4 text-sm font-medium leading-6 text-[#0b1f3a] dark:bg-[#3B7FC7]/20 dark:text-slate-100"
            dir={isRtl ? 'rtl' : 'ltr'}
          >
            {labels.hello}
          </div>

          {messages.map((m) => (
            <div
              key={m.id}
              className={`max-w-[92%] ${m.role === 'user' ? 'ms-auto' : 'me-auto'}`}
            >
              <div
                dir={detectDir(m.text)}
                className={`rounded-2xl px-3.5 py-2.5 text-sm leading-6 shadow-sm whitespace-pre-wrap break-words [unicode-bidi:plaintext] ${
                  m.role === 'user'
                    ? 'bg-[#0b1f3a] text-white'
                    : 'border border-slate-100 bg-white text-slate-800 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-100'
                }`}
              >
                {m.text}
              </div>
            </div>
          ))}

          {busy ? (
            <div className="me-auto max-w-[85%] rounded-2xl border border-slate-100 bg-white px-3.5 py-2.5 text-sm text-slate-500 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300">
              <span className="inline-flex items-center gap-2">
                <span className="ask-ai-typing" aria-hidden>
                  <i />
                  <i />
                  <i />
                </span>
                {labels.thinking}
              </span>
            </div>
          ) : null}
        </div>

        <form
          onSubmit={onSubmit}
          className="border-t border-slate-100 bg-white p-3 dark:border-slate-700 dark:bg-slate-900"
        >
          <div className="flex items-center gap-2 rounded-full border border-slate-200 bg-slate-50 px-3 py-2 dark:border-slate-600 dark:bg-slate-800">
            <input
              ref={inputRef}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder={labels.placeholder}
              className="min-w-0 flex-1 bg-transparent text-sm outline-none dark:text-slate-100"
              dir="auto"
              spellCheck
              disabled={busy}
              autoComplete="off"
              enterKeyHint="send"
            />
            <button
              type="submit"
              disabled={busy || !input.trim()}
              className="rounded-full bg-[#3B7FC7] px-4 py-2 text-xs font-bold text-white disabled:opacity-50"
            >
              {labels.send}
            </button>
          </div>
          <p className="mt-2 text-center text-[11px] font-semibold text-[#0066cc] dark:text-[#7eb6ef]">
            {labels.dataSafe}
          </p>
          <p className="mt-1 text-center text-[11px] font-semibold tracking-wide text-slate-400">
            {labels.poweredBy}
          </p>
        </form>
      </aside>
    </div>
  )
}
