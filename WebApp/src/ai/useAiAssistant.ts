import { HubConnectionBuilder, HubConnectionState, LogLevel, type HubConnection } from '@microsoft/signalr'
import { useCallback, useEffect, useRef, useState } from 'react'
import { API_BASE_URL } from '../lib/config'
import { readStoredSession } from '../lib/sessionStorage'
import type { ApiProduct } from '../products/types'
import { fetchAiMessages, looksLikeSupportCallbackCue, looksLikeSupportCallbackIntent, looksLikeTemporaryFailure, newAiSessionId, parseAiListings } from './aiApi'

const HUB_URL = `${new URL(API_BASE_URL).origin}/aihub`

export type AiMessage = {
  id: string
  role: 'user' | 'assistant'
  text: string
  replyPreview?: string
  listings?: ApiProduct[]
  thinkingSteps?: string[]
  thinkingSeconds?: number
  showCallback?: boolean
  question?: string
  streaming?: boolean
  failed?: boolean
}

type Payload = Record<string, unknown>

function payloadOf(args: unknown[]): Payload {
  const first = args[0]
  if (first && typeof first === 'object') return first as Payload
  if (typeof first === 'string') {
    try {
      const parsed = JSON.parse(first)
      if (parsed && typeof parsed === 'object') return parsed as Payload
    } catch {
      /* not JSON */
    }
  }
  return {}
}

const read = (p: Payload, ...keys: string[]) => {
  for (const k of keys) if (p[k] !== undefined && p[k] !== null) return p[k]
  return undefined
}

const truthy = (v: unknown) => v === true || (typeof v === 'number' && v !== 0) || ['true', '1', 'yes'].includes(String(v ?? '').trim().toLowerCase())

let seq = 0
const nextId = (prefix: string) => `${prefix}_${++seq}_${Date.now()}`

type Options = {
  language: 'ar' | 'en'
  welcome: string
  connectionError: string
  companyCustomerSeesPrices: boolean
  narrative: (query: string) => string[]
  completedStep: string
}

/** `/aihub` streaming session, following AiAssistantRealtimeService + ai_assistant_view event handling. */
export function useAiAssistant(opts: Options) {
  const optsRef = useRef(opts)
  optsRef.current = opts
  const [messages, setMessages] = useState<AiMessage[]>(() => [{ id: 'welcome', role: 'assistant', text: opts.welcome }])
  const [thinking, setThinking] = useState(false)
  const [liveSteps, setLiveSteps] = useState<string[]>([])
  const [thinkingStartedAt, setThinkingStartedAt] = useState<number | null>(null)
  const [sessionId, setSessionId] = useState(newAiSessionId)
  const [historyLoading, setHistoryLoading] = useState(false)
  const [asking, setAsking] = useState(false)

  const hubRef = useRef<HubConnection | null>(null)
  const connectingRef = useRef<Promise<void> | null>(null)
  const activeRef = useRef<string | null>(null)
  const completedRef = useRef(false)
  const backendSteps = useRef<string[]>([])
  const narrativeRef = useRef<string[]>([])
  const revealTimer = useRef<number | null>(null)
  const startedAt = useRef(0)
  const sessionRef = useRef(sessionId)
  sessionRef.current = sessionId
  const liveRef = useRef<string[]>([])
  const setLive = useCallback((steps: string[]) => {
    liveRef.current = steps
    setLiveSteps(steps)
  }, [])

  const endActive = () => {
    activeRef.current = null
    setAsking(false)
  }

  const stopReveal = () => {
    if (revealTimer.current) window.clearInterval(revealTimer.current)
    revealTimer.current = null
  }

  const plannedSteps = () => {
    const merged = [...narrativeRef.current]
    for (const step of backendSteps.current) if (!merged.includes(step)) merged.splice(Math.min(merged.length, 2 + backendSteps.current.indexOf(step)), 0, step)
    return merged
  }

  const finishThinking = useCallback(() => {
    stopReveal()
    setThinking(false)
    setThinkingStartedAt(null)
  }, [])

  const patchActive = useCallback((patch: (m: AiMessage) => AiMessage) => {
    const id = activeRef.current
    if (!id) return
    setMessages((list) => list.map((m) => (m.id === id ? patch(m) : m)))
  }, [])

  const finalSteps = useCallback((live: string[]) => {
    const out: string[] = []
    for (const s of [...live, ...plannedSteps()]) {
      if (out.length >= 9) break
      if (s.trim() && !out.includes(s)) out.push(s)
    }
    out.push(optsRef.current.completedStep)
    return out
  }, [])

  const connect = useCallback(async () => {
    const existing = hubRef.current
    if (existing?.state === HubConnectionState.Connected) return
    if (connectingRef.current) return connectingRef.current

    const token = readStoredSession()?.token
    const hub = new HubConnectionBuilder()
      .withUrl(HUB_URL, token ? { accessTokenFactory: () => readStoredSession()?.token ?? token } : {})
      .configureLogging(LogLevel.Warning)
      .build()

    hub.on('aiThinking', (...args) => {
      if (truthy(read(payloadOf(args), 'isThinking'))) setThinking(true)
    })
    hub.on('aiThinkingStep', (...args) => {
      const text = String(read(payloadOf(args), 'text') ?? '').trim()
      if (text && !backendSteps.current.includes(text)) backendSteps.current.push(text)
    })
    hub.on('aiResponseStarted', () => {
      if (!activeRef.current) return
      patchActive((m) => ({ ...m, streaming: true }))
    })
    hub.on('aiListings', (...args) => {
      const p = payloadOf(args)
      const listings = parseAiListings(read(p, 'listingsJson', 'ListingsJson', 'listings', 'Listings'), optsRef.current.companyCustomerSeesPrices)
      if (listings.length) patchActive((m) => ({ ...m, listings }))
    })
    hub.on('aiDelta', (...args) => {
      const text = String(read(payloadOf(args), 'text') ?? '')
      if (!text) return
      finishThinking()
      patchActive((m) => ({ ...m, text: m.text + text, streaming: true }))
    })
    hub.on('aiResponseCompleted', (...args) => {
      completedRef.current = true
      const p = payloadOf(args)
      const answer = String(read(p, 'answer', 'Answer') ?? '')
      const offer = truthy(read(p, 'offerSupportCallback', 'OfferSupportCallback'))
      const listings = parseAiListings(read(p, 'listingsJson', 'ListingsJson', 'listings', 'Listings', 'productListings'), optsRef.current.companyCustomerSeesPrices)
      const serverSteps = read(p, 'thinkingSteps', 'ThinkingSteps')
      const live = liveRef.current
      const steps = finalSteps(Array.isArray(serverSteps) ? [...live, ...serverSteps.map(String)] : live)
      const seconds = Math.max(1, Math.round((Date.now() - startedAt.current) / 1000))
      patchActive((m) => ({
        ...m,
        text: answer || m.text,
        listings: listings.length ? listings : m.listings,
        thinkingSteps: steps,
        thinkingSeconds: seconds,
        streaming: false,
        showCallback: offer || looksLikeSupportCallbackCue(answer) || looksLikeTemporaryFailure(answer) || looksLikeSupportCallbackIntent(m.question ?? ''),
      }))
      setLive([])
      finishThinking()
      endActive()
    })
    hub.on('aiError', (...args) => {
      if (completedRef.current) return
      const message = String(read(payloadOf(args), 'message') ?? '').trim() || optsRef.current.connectionError
      patchActive((m) => ({ ...m, text: message, streaming: false, failed: true, showCallback: true }))
      finishThinking()
      endActive()
    })
    hub.onclose(() => {
      if (hubRef.current === hub) hubRef.current = null
    })

    hubRef.current = hub
    connectingRef.current = hub
      .start()
      .catch((error) => {
        hubRef.current = null
        throw error
      })
      .finally(() => {
        connectingRef.current = null
      })
    return connectingRef.current
  }, [finalSteps, finishThinking, patchActive])

  useEffect(() => {
    void connect().catch(() => undefined)
    return () => {
      stopReveal()
      const hub = hubRef.current
      hubRef.current = null
      void hub?.stop()
    }
  }, [connect])

  const ask = useCallback(
    async (visibleText: string, apiText: string, replyPreview?: string) => {
      if (activeRef.current) return
      const responseId = nextId('ai')
      const userMsg: AiMessage = { id: nextId('u'), role: 'user', text: visibleText, replyPreview }
      const pending: AiMessage = { id: responseId, role: 'assistant', text: '', question: visibleText, streaming: true }
      activeRef.current = responseId
      setAsking(true)
      completedRef.current = false
      backendSteps.current = []
      narrativeRef.current = optsRef.current.narrative(visibleText)
      startedAt.current = Date.now()
      setMessages((list) => [...list, userMsg, pending])
      setThinking(true)
      setThinkingStartedAt(startedAt.current)
      setLive(narrativeRef.current.slice(0, 1))
      stopReveal()
      let index = 1
      revealTimer.current = window.setInterval(() => {
        const planned = plannedSteps()
        if (index >= planned.length) return
        const next = planned[index++]
        const steps = liveRef.current
        if (steps[steps.length - 1] !== next) setLive([...steps, next])
      }, 900)

      try {
        await connect()
        await hubRef.current?.invoke('AskInSession', apiText, optsRef.current.language, sessionRef.current)
      } catch {
        if (activeRef.current !== responseId) return
        patchActive((m) => ({ ...m, text: optsRef.current.connectionError, streaming: false, failed: true, showCallback: true }))
        finishThinking()
        endActive()
      }
    },
    [connect, finishThinking, patchActive],
  )

  const addLocal = useCallback((role: AiMessage['role'], text: string) => {
    setMessages((list) => [...list, { id: nextId(role), role, text }])
  }, [])

  const newChat = useCallback(() => {
    if (activeRef.current) return
    setSessionId(newAiSessionId())
    setMessages([{ id: 'welcome', role: 'assistant', text: optsRef.current.welcome }])
  }, [])

  const resume = useCallback(async (conversationId: string, clientSessionId: string) => {
    if (activeRef.current) return
    setHistoryLoading(true)
    try {
      const history = await fetchAiMessages(conversationId)
      const mapped: AiMessage[] = history
        .slice()
        .sort((a, b) => a.id - b.id)
        .map((m) => ({
          id: `h_${m.id}`,
          role: m.role.toLowerCase() === 'user' ? 'user' : 'assistant',
          text: m.content,
          listings: parseAiListings(m.listings, optsRef.current.companyCustomerSeesPrices),
          thinkingSteps: m.thinkingSteps?.length ? m.thinkingSteps : undefined,
        }))
      setSessionId(clientSessionId || newAiSessionId())
      setMessages([{ id: 'welcome', role: 'assistant', text: optsRef.current.welcome }, ...mapped])
    } finally {
      setHistoryLoading(false)
    }
  }, [])

  const setThinkingNote = useCallback((note: string | null) => {
    if (note) {
      setThinking(true)
      setThinkingStartedAt(Date.now())
      setLive([note])
    } else {
      finishThinking()
      setLive([])
    }
  }, [finishThinking, setLive])

  return { messages, thinking, liveSteps, thinkingStartedAt, sessionId, historyLoading, busy: asking, ask, addLocal, newChat, resume, setThinkingNote }
}
