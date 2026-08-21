import { useEffect, useRef, useState } from 'react'
import { aiAgentContent } from '../data/aiAgent'
import { createAskAiSession } from '../services/aiAssistantRealtime'
import { textDir } from '../utils/langDetect'
import ChatRichText from './ChatRichText'
import AiSupportCallbackForm, {
  looksLikeSupportCallbackCue,
} from './AiSupportCallbackForm'

const TITLE_BLUE = '#163A6B'
const BODY_BLUE = '#3A6AA5'
const PURPLE = '#7B61FF'

let messageSeq = 0
function nextMessageId(role) {
  messageSeq += 1
  return `${role}-${messageSeq}-${Date.now()}`
}

export default function AskAiChat({ lang, open, onClose }) {
  const t = aiAgentContent[lang] ?? aiAgentContent.en
  const isAr = lang === 'ar'
  const [input, setInput] = useState('')
  const [busy, setBusy] = useState(false)
  const [thinking, setThinking] = useState(false)
  const [messages, setMessages] = useState([])
  const listRef = useRef(null)
  const inputRef = useRef(null)
  const sessionRef = useRef(null)
  const streamingIdRef = useRef(null)
  const sendingRef = useRef(false)
  const lastUserQuestionRef = useRef('')

  useEffect(() => {
    if (!open) {
      setInput('')
      setBusy(false)
      setThinking(false)
      setMessages([])
      streamingIdRef.current = null
      sendingRef.current = false
      lastUserQuestionRef.current = ''
      const session = sessionRef.current
      sessionRef.current = null
      void session?.close()
      return
    }

    sessionRef.current = createAskAiSession()
    const id = window.setTimeout(() => inputRef.current?.focus(), 120)
    return () => {
      window.clearTimeout(id)
      const session = sessionRef.current
      sessionRef.current = null
      void session?.close()
    }
  }, [open])

  useEffect(() => {
    if (listRef.current) {
      listRef.current.scrollTop = listRef.current.scrollHeight
    }
  }, [messages, thinking, busy])

  if (!open) return null

  function ensureAssistantBubble() {
    if (streamingIdRef.current) return streamingIdRef.current
    const id = nextMessageId('assistant')
    streamingIdRef.current = id
    setMessages((prev) => [
      ...prev,
      {
        id,
        role: 'assistant',
        text: '',
        streaming: true,
        dir: 'auto',
        showSupportForm: false,
      },
    ])
    return id
  }

  function patchAssistant(id, patch) {
    setMessages((prev) =>
      prev.map((m) => (m.id === id ? { ...m, ...patch } : m)),
    )
  }

  async function sendMessage(text) {
    const trimmed = text.trim()
    if (!trimmed || busy || sendingRef.current) return

    const session = sessionRef.current
    if (!session) return

    sendingRef.current = true
    streamingIdRef.current = null
    lastUserQuestionRef.current = trimmed
    setMessages((prev) => [
      ...prev,
      {
        id: nextMessageId('user'),
        role: 'user',
        text: trimmed,
        dir: textDir(trimmed),
      },
    ])
    setInput('')
    setBusy(true)
    setThinking(true)

    await session.ask({
      message: trimmed,
      handlers: {
        onThinking: (value) => setThinking(Boolean(value)),
        onResponseStarted: () => {
          setThinking(false)
          ensureAssistantBubble()
        },
        onDelta: (chunk) => {
          setThinking(false)
          const id = ensureAssistantBubble()
          setMessages((prev) =>
            prev.map((m) =>
              m.id === id
                ? {
                    ...m,
                    text: `${m.text}${chunk}`,
                    streaming: true,
                    dir: textDir(`${m.text}${chunk}`),
                  }
                : m,
            ),
          )
        },
        onCompleted: (answer, meta = {}) => {
          const id = streamingIdRef.current
          const showSupportForm =
            Boolean(meta.offerSupportCallback) || looksLikeSupportCallbackCue(answer)

          if (id) {
            patchAssistant(id, {
              text: answer || '',
              streaming: false,
              dir: textDir(answer),
              showSupportForm,
              question: lastUserQuestionRef.current,
            })
          } else if (answer) {
            setMessages((prev) => [
              ...prev,
              {
                id: nextMessageId('assistant'),
                role: 'assistant',
                text: answer,
                streaming: false,
                dir: textDir(answer),
                showSupportForm,
                question: lastUserQuestionRef.current,
              },
            ])
          }
          streamingIdRef.current = null
          setThinking(false)
          setBusy(false)
          sendingRef.current = false
        },
        onError: () => {
          const id = streamingIdRef.current
          if (id) {
            setMessages((prev) => prev.filter((m) => m.id !== id))
          }
          streamingIdRef.current = null
          setThinking(false)
          setBusy(false)
          sendingRef.current = false
          setMessages((prev) => [
            ...prev,
            {
              id: nextMessageId('assistant'),
              role: 'assistant',
              text: t.error,
              dir: textDir(t.error),
              showSupportForm: true,
              question: lastUserQuestionRef.current,
            },
          ])
        },
      },
    })
  }

  function onSubmit(e) {
    e.preventDefault()
    void sendMessage(input)
  }

  return (
    <div className="fixed inset-0 z-[80]" role="dialog" aria-modal="true">
      <button
        type="button"
        className="absolute inset-0 bg-slate-900/35"
        aria-label={t.close}
        onClick={onClose}
      />

      <aside
        className={`absolute inset-y-0 flex w-full max-w-none flex-col bg-white shadow-2xl sm:max-w-[440px] ${
          isAr ? 'left-0 border-r border-slate-200' : 'right-0 border-l border-slate-200'
        }`}
        dir={isAr ? 'rtl' : 'ltr'}
      >
        <div className="flex items-center gap-3 border-b border-slate-100 px-4 py-3">
          <img
            src="/seo/alras-agent-robot.png"
            alt=""
            className="h-10 w-10 rounded-full object-cover ring-2 ring-[#7B61FF]/25"
          />
          <div className="min-w-0 flex-1">
            <p className="truncate text-base font-extrabold" style={{ color: TITLE_BLUE }}>
              {t.hubTitle}
            </p>
            <p className="truncate text-xs font-medium text-[#8A97AB]">{t.hubSubtitle}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-full px-2 py-1 text-sm font-semibold text-slate-500 hover:bg-slate-100"
          >
            {t.close}
          </button>
        </div>

        <div
          ref={listRef}
          className="flex-1 space-y-3 overflow-y-auto bg-[#F7FAFF] px-4 py-4"
          lang="und"
        >
          <div
            className="rounded-2xl bg-[#EAF3FF] p-4 text-sm leading-6 font-medium"
            style={{ color: TITLE_BLUE }}
            dir={isAr ? 'rtl' : 'ltr'}
          >
            {t.hubHello}
          </div>
          {messages.map((m) => (
            <div
              key={m.id}
              className={`max-w-[92%] ${
                m.role === 'user' ? 'ms-auto' : 'me-auto'
              }`}
            >
              <div
                dir={m.dir || 'auto'}
                lang="und"
                className={`rounded-2xl px-3.5 py-2.5 text-sm leading-6 shadow-sm [unicode-bidi:plaintext] ${
                  m.role === 'user'
                    ? 'bg-[#163A6B] text-white'
                    : 'border border-slate-100 bg-white text-slate-800'
                }`}
              >
                {m.role === 'assistant' && !m.streaming ? (
                  <ChatRichText text={m.text} />
                ) : (
                  <span className="whitespace-pre-wrap break-words">{m.text}</span>
                )}
                {m.streaming ? (
                  <span
                    className="ml-0.5 inline-block h-3.5 w-0.5 animate-pulse align-middle bg-[#7B61FF]"
                    aria-hidden
                  />
                ) : null}
              </div>
              {m.role === 'assistant' && m.showSupportForm && !m.streaming ? (
                <AiSupportCallbackForm
                  lang={lang}
                  question={m.question || lastUserQuestionRef.current}
                  onSubmitted={() =>
                    patchAssistant(m.id, { showSupportForm: true, supportSubmitted: true })
                  }
                />
              ) : null}
            </div>
          ))}
          {thinking ? (
            <div className="me-auto max-w-[85%] rounded-2xl border border-slate-100 bg-white px-3.5 py-2.5 text-sm text-slate-500">
              <span className="inline-flex items-center gap-2">
                <span className="ask-ai-typing" aria-hidden>
                  <i />
                  <i />
                  <i />
                </span>
                {t.thinking}
              </span>
            </div>
          ) : null}
        </div>

        <form onSubmit={onSubmit} className="border-t border-slate-100 bg-white p-3">
          <div className="flex items-center gap-2 rounded-full border border-slate-200 bg-slate-50 px-3 py-2">
            <input
              ref={inputRef}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder={t.chatPlaceholder}
              className="min-w-0 flex-1 bg-transparent text-sm outline-none"
              dir="auto"
              lang="und"
              spellCheck
              disabled={busy}
              autoComplete="off"
              enterKeyHint="send"
            />
            <button
              type="submit"
              disabled={busy || !input.trim()}
              className="rounded-full px-4 py-2 text-xs font-bold text-white disabled:opacity-50"
              style={{ background: PURPLE }}
            >
              {t.send}
            </button>
          </div>
          <div className="mt-2 flex items-center justify-center gap-2 text-[11px] font-semibold" style={{ color: BODY_BLUE }}>
            <span aria-hidden>🛡</span>
            <span>{t.dataSafe}</span>
          </div>
          <p className="mt-1 text-center text-[11px] font-semibold tracking-wide text-slate-400">{t.poweredBy}</p>
        </form>
      </aside>
    </div>
  )
}
