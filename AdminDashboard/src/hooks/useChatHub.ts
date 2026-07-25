import { useEffect, useRef } from 'react'
import * as signalR from '@microsoft/signalr'
import { API_BASE_URL } from '../config/api.js'
import { getAuthToken } from '../lib/authStorage'
import { attachSignalRHealthCheck } from '../lib/signalRHealth'
import { signalRTransports } from '../lib/signalRTransports'
import type { ChatMessage, ChatPresence, ChatMessagesDeliveredPayload, ConversationSeenPayload } from '../types/chat'
import { normalizeChatMessage } from '../types/chat'

type ChatHubHandlers = {
  onReceiveMessage?: (message: ChatMessage) => void
  onMessageUpdated?: (message: ChatMessage) => void
  onConversationSeen?: (payload: ConversationSeenPayload) => void
  onMessagesDelivered?: (payload: ChatMessagesDeliveredPayload) => void
  onUserLastSeen?: (presence: ChatPresence) => void
}

export function useChatHub(userId: string | null, handlers: ChatHubHandlers) {
  const handlersRef = useRef(handlers)
  handlersRef.current = handlers

  useEffect(() => {
    if (!userId) return

    const token = getAuthToken()
    if (!token) return

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

    let cancelled = false

    const rejoin = async () => {
      if (cancelled || !getAuthToken()) return
      await connection.invoke('JoinUserChat', userId)
    }

    const clearHealthCheck = attachSignalRHealthCheck(connection, rejoin)

    async function start() {
      try {
        await connection.start()
        if (!cancelled) {
          await rejoin()
        }
      } catch (error) {
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
      void connection.invoke('LeaveUserChat', userId).catch(() => undefined)
      void connection.stop()
    }
  }, [userId])
}
