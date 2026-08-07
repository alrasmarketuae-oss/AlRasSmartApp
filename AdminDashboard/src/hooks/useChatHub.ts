import { useEffect, useRef } from 'react'
import * as signalR from '@microsoft/signalr'
import { API_BASE_URL } from '../config/api.js'
import { getAuthToken } from '../lib/authStorage'
import { attachSignalRHealthCheck } from '../lib/signalRHealth'
import { signalRTransports } from '../lib/signalRTransports'
import type {
  ChatMessage,
  ChatPresence,
  ChatMessagesDeliveredPayload,
  ConversationSeenPayload,
} from '../types/chat'
import { normalizeChatMessage } from '../types/chat'

type ChatHubHandlers = {
  onReceiveMessage?: (message: ChatMessage) => void
  onMessageUpdated?: (message: ChatMessage) => void
  onConversationSeen?: (payload: ConversationSeenPayload) => void
  onMessagesDelivered?: (payload: ChatMessagesDeliveredPayload) => void
  onUserLastSeen?: (presence: ChatPresence) => void
  onSupportSessionChanged?: () => void
  onConnectionChanged?: (connected: boolean) => void
}

export function useChatHub(userId: string | null, handlers: ChatHubHandlers) {
  const handlersRef = useRef(handlers)
  handlersRef.current = handlers

  useEffect(() => {
    if (!userId) {
      handlersRef.current.onConnectionChanged?.(false)
      return
    }

    const token = getAuthToken()
    if (!token) {
      handlersRef.current.onConnectionChanged?.(false)
      return
    }

    const hubBase = `${API_BASE_URL.replace(/\/$/, '')}/chathub`
    const connection = new signalR.HubConnectionBuilder()
      .withUrl(hubBase, {
        accessTokenFactory: () => getAuthToken() ?? '',
        transport: signalRTransports(),
        withCredentials: true,
      })
      .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
      .configureLogging(signalR.LogLevel.Warning)
      .build()

    const setConnected = (connected: boolean) => {
      handlersRef.current.onConnectionChanged?.(connected)
    }

    connection.on('receiveMessage', (message: ChatMessage) => {
      handlersRef.current.onReceiveMessage?.(normalizeChatMessage(message))
    })

    connection.on('messageUpdated', (message: ChatMessage) => {
      handlersRef.current.onMessageUpdated?.(normalizeChatMessage(message))
    })

    connection.on('conversationSeen', (payload: ConversationSeenPayload) => {
      handlersRef.current.onConversationSeen?.(payload)
    })

    connection.on('messagesDelivered', (payload: ChatMessagesDeliveredPayload) => {
      handlersRef.current.onMessagesDelivered?.(payload)
    })

    connection.on('userLastSeen', (presence: ChatPresence) => {
      handlersRef.current.onUserLastSeen?.(presence)
    })

    connection.on('supportSessionStarted', () => {
      handlersRef.current.onSupportSessionChanged?.()
    })

    connection.on('supportSessionEnded', () => {
      handlersRef.current.onSupportSessionChanged?.()
    })

    connection.onreconnecting(() => setConnected(false))
    connection.onreconnected(() => {
      setConnected(true)
      void rejoin()
    })
    connection.onclose(() => setConnected(false))

    let cancelled = false

    const rejoin = async () => {
      if (cancelled || !getAuthToken()) return
      await connection.invoke('JoinUserChat', userId)
    }

    const clearHealthCheck = attachSignalRHealthCheck(connection, rejoin)

    async function start() {
      try {
        await connection.start()
        if (cancelled) return
        await rejoin()
        setConnected(true)
      } catch (error) {
        setConnected(false)
        if (import.meta.env.DEV) {
          console.warn('[ChatHub] connection failed', error)
        }
      }
    }

    void start()

    void fetch(`${API_BASE_URL.replace(/\/$/, '')}/api/Chat/presence`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      credentials: 'include',
    }).catch(() => undefined)

    const presenceTimer = window.setInterval(() => {
      const liveToken = getAuthToken()
      if (!liveToken) return

      void fetch(`${API_BASE_URL.replace(/\/$/, '')}/api/Chat/presence`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${liveToken}`,
          'Content-Type': 'application/json',
        },
        credentials: 'include',
      }).catch(() => undefined)
    }, 60_000)

    return () => {
      cancelled = true
      clearHealthCheck()
      window.clearInterval(presenceTimer)
      setConnected(false)
      void connection.invoke('LeaveUserChat', userId).catch(() => undefined)
      void connection.stop()
    }
  }, [userId])
}
