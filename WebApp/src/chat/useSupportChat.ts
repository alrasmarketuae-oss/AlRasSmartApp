import { HubConnectionBuilder, HubConnectionState, LogLevel, type HubConnection } from '@microsoft/signalr'
import { useQueryClient } from '@tanstack/react-query'
import { useCallback, useEffect, useRef, useState } from 'react'
import { API_BASE_URL } from '../lib/config'
import { readStoredSession } from '../lib/sessionStorage'
import {
  MessageType,
  deleteChatMessage,
  fetchConversation,
  markDelivered,
  markSeen,
  normalizeMessage,
  pingPresence,
  sameId,
  sendChatMessage,
  uploadChatMedia,
  type ChatMessage,
  type ChatMessageType,
  type SupportSession,
} from './chatApi'

const HUB_URL = `${new URL(API_BASE_URL).origin}/chathub`

type State = {
  messages: ChatMessage[]
  sessions: SupportSession[]
  agentName: string | null
  hasMore: boolean
  before: string | null
  loading: boolean
  loadingOlder: boolean
  error: string | null
}

const byTime = (a: ChatMessage, b: ChatMessage) => new Date(a.sentAtUtc).getTime() - new Date(b.sentAtUtc).getTime()

function upsert(list: ChatMessage[], message: ChatMessage) {
  const index = list.findIndex((m) => m.messageId === message.messageId)
  if (index === -1) return [...list, message].sort(byTime)
  const next = list.slice()
  next[index] = { ...next[index], ...message }
  return next
}

let localSeq = 0

/** Support thread with the admin inbox: REST history + `/chathub` realtime, mirroring ChatCubit. */
export function useSupportChat(myId: string, peerId: string) {
  const queryClient = useQueryClient()
  const [state, setState] = useState<State>({ messages: [], sessions: [], agentName: null, hasMore: false, before: null, loading: true, loadingOlder: false, error: null })
  const [connected, setConnected] = useState(false)
  const hubRef = useRef<HubConnection | null>(null)

  const isThread = useCallback(
    (m: { fromUserId?: string; toUserId?: string }) => (sameId(m.fromUserId, myId) && sameId(m.toUserId, peerId)) || (sameId(m.fromUserId, peerId) && sameId(m.toUserId, myId)),
    [myId, peerId],
  )

  const refreshUnread = useCallback(() => queryClient.invalidateQueries({ queryKey: ['chat-unread'] }), [queryClient])

  const acknowledge = useCallback(async () => {
    await markDelivered(peerId)
    if (document.visibilityState === 'visible') await markSeen(peerId)
    refreshUnread()
  }, [peerId, refreshUnread])

  const load = useCallback(async () => {
    setState((s) => ({ ...s, loading: true, error: null }))
    try {
      const data = await fetchConversation(peerId)
      setState((s) => ({
        ...s,
        messages: data.messages.sort(byTime),
        sessions: data.supportSessions,
        agentName: data.activeAgentName ?? null,
        hasMore: data.hasMore,
        before: data.nextBeforeMessageId ?? null,
        loading: false,
      }))
      void acknowledge()
    } catch (error) {
      setState((s) => ({ ...s, loading: false, error: (error as Error).message }))
    }
  }, [peerId, acknowledge])

  const loadOlder = useCallback(async () => {
    if (!state.hasMore || state.loadingOlder || !state.before) return
    setState((s) => ({ ...s, loadingOlder: true }))
    try {
      const data = await fetchConversation(peerId, state.before)
      setState((s) => {
        const known = new Set(s.messages.map((m) => m.messageId))
        return {
          ...s,
          messages: [...data.messages.filter((m) => !known.has(m.messageId)), ...s.messages].sort(byTime),
          sessions: data.supportSessions.length ? data.supportSessions : s.sessions,
          hasMore: data.hasMore,
          before: data.nextBeforeMessageId ?? null,
          loadingOlder: false,
        }
      })
    } catch {
      setState((s) => ({ ...s, loadingOlder: false }))
    }
  }, [peerId, state.hasMore, state.loadingOlder, state.before])

  useEffect(() => {
    if (!myId) return
    void load()
    void pingPresence()
    const heartbeat = window.setInterval(() => void pingPresence(), 30_000)

    const hub = new HubConnectionBuilder()
      .withUrl(HUB_URL, { accessTokenFactory: () => readStoredSession()?.token ?? '' })
      .withAutomaticReconnect()
      .configureLogging(LogLevel.Warning)
      .build()
    hubRef.current = hub

    const onMessage = (raw: Record<string, unknown>) => {
      const message = normalizeMessage(raw)
      if (!isThread(message)) return
      setState((s) => ({ ...s, messages: upsert(s.messages, message) }))
      if (sameId(message.fromUserId, peerId)) {
        void hub.invoke('AcknowledgeDelivery', message.fromUserId).catch(() => undefined)
        void acknowledge()
      }
    }
    hub.on('receiveMessage', onMessage)
    hub.on('messageUpdated', onMessage)
    hub.on('messageDeleted', (e: { messageId: string; scope?: string; message?: Record<string, unknown> }) => {
      setState((s) => ({
        ...s,
        messages:
          e.scope === 'me' || !e.message
            ? s.messages.filter((m) => m.messageId !== e.messageId)
            : s.messages.map((m) => (m.messageId === e.messageId ? { ...m, ...normalizeMessage(e.message!), isDeleted: true, content: '' } : m)),
      }))
    })
    hub.on('conversationSeen', (e: { otherUserId?: string }) => {
      if (!sameId(e.otherUserId, myId)) return
      setState((s) => ({ ...s, messages: s.messages.map((m) => (sameId(m.fromUserId, myId) ? { ...m, isSeen: true, isDelivered: true } : m)) }))
    })
    hub.on('messagesDelivered', (e: { fromUserId?: string; messageIds?: string[] }) => {
      if (!sameId(e.fromUserId, myId)) return
      const ids = new Set(e.messageIds ?? [])
      setState((s) => ({ ...s, messages: s.messages.map((m) => (ids.has(m.messageId) || ids.size === 0 ? { ...m, isDelivered: true } : m)) }))
    })
    hub.on('supportSessionStarted', (session: SupportSession) => {
      setState((s) => ({
        ...s,
        agentName: session.agentName,
        sessions: [...s.sessions.map((x) => (x.isActive ? { ...x, isActive: false, releasedAtUtc: x.releasedAtUtc ?? session.assignedAtUtc } : x)), session],
      }))
    })
    hub.on('supportSessionEnded', (session: SupportSession) => {
      setState((s) => ({
        ...s,
        agentName: null,
        sessions: s.sessions.some((x) => x.assignedAtUtc === session.assignedAtUtc && sameId(x.agentUserId, session.agentUserId))
          ? s.sessions.map((x) => (x.assignedAtUtc === session.assignedAtUtc && sameId(x.agentUserId, session.agentUserId) ? { ...x, ...session, isActive: false } : x))
          : [...s.sessions, { ...session, isActive: false }],
      }))
    })
    hub.onreconnected(() => {
      setConnected(true)
      void hub.invoke('JoinUserChat', myId).catch(() => undefined)
      void load()
    })
    hub.onreconnecting(() => setConnected(false))
    hub.onclose(() => setConnected(false))

    let disposed = false
    hub
      .start()
      .then(() => {
        if (disposed) return hub.stop()
        setConnected(true)
        return hub.invoke('JoinUserChat', myId)
      })
      .catch(() => setConnected(false))

    const onVisible = () => document.visibilityState === 'visible' && void markSeen(peerId).then(refreshUnread)
    document.addEventListener('visibilitychange', onVisible)

    return () => {
      disposed = true
      window.clearInterval(heartbeat)
      document.removeEventListener('visibilitychange', onVisible)
      if (hub.state === HubConnectionState.Connected) {
        void hub.invoke('LeaveUserChat', myId).catch(() => undefined).finally(() => hub.stop())
      } else {
        void hub.stop()
      }
      hubRef.current = null
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [myId, peerId])

  const pushLocal = (partial: Partial<ChatMessage> & { messageType: ChatMessageType; content: string }) => {
    const local: ChatMessage = {
      messageId: `local_${++localSeq}`,
      fromUserId: myId,
      toUserId: peerId,
      sentAtUtc: new Date().toISOString(),
      status: 'sending',
      ...partial,
    }
    setState((s) => ({ ...s, messages: [...s.messages, local] }))
    return local.messageId
  }

  const settle = (localId: string, result: ChatMessage | null) =>
    setState((s) => ({
      ...s,
      messages: result
        ? upsert(s.messages.filter((m) => m.messageId !== localId), result)
        : s.messages.map((m) => (m.messageId === localId ? { ...m, status: 'failed' as const } : m)),
    }))

  const sendText = useCallback(
    async (text: string, reply?: ChatMessage | null) => {
      const content = text.trim()
      if (!content) return
      const localId = pushLocal({ messageType: MessageType.text, content, replyToMessageId: reply?.messageId, replyToPreview: reply?.content?.slice(0, 120), replyToMessageType: reply?.messageType })
      try {
        settle(localId, await sendChatMessage(peerId, MessageType.text, content, reply?.messageId))
      } catch {
        settle(localId, null)
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [peerId, myId],
  )

  const sendFile = useCallback(
    async (file: File, messageType: ChatMessageType) => {
      const url = URL.createObjectURL(file)
      const localId = pushLocal({ messageType, content: '', localFile: { url, name: file.name } })
      try {
        const uploaded = await uploadChatMedia(file, messageType)
        settle(localId, await sendChatMessage(peerId, uploaded.messageType, uploaded.content))
      } catch {
        settle(localId, null)
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [peerId, myId],
  )

  const sendLocation = useCallback(
    async (lat: number, lng: number, label: string) => {
      const content = JSON.stringify({ lat, lng, label })
      const localId = pushLocal({ messageType: MessageType.location, content })
      try {
        settle(localId, await sendChatMessage(peerId, MessageType.location, content))
      } catch {
        settle(localId, null)
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [peerId, myId],
  )

  const remove = useCallback(async (message: ChatMessage, scope: 'me' | 'everyone') => {
    const result = await deleteChatMessage(message.messageId, scope)
    setState((s) => ({
      ...s,
      messages:
        scope === 'me'
          ? s.messages.filter((m) => m.messageId !== message.messageId)
          : s.messages.map((m) => (m.messageId === message.messageId ? { ...m, ...(result?.message ? normalizeMessage(result.message) : {}), isDeleted: true, content: '' } : m)),
    }))
  }, [])

  const retry = useCallback(
    (message: ChatMessage) => {
      setState((s) => ({ ...s, messages: s.messages.filter((m) => m.messageId !== message.messageId) }))
      if (message.messageType === MessageType.text) void sendText(message.content)
    },
    [sendText],
  )

  return { ...state, connected, loadOlder, sendText, sendFile, sendLocation, remove, retry, reload: load }
}
