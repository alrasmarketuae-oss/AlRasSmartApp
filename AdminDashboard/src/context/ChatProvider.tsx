import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  type ReactNode,
} from 'react'
import { getAuthUser } from '../lib/authStorage'
import { useChatHub } from '../hooks/useChatHub'
import { adminApi, useGetChatUnreadCountQuery } from '../store/adminApi'
import { liveQueryOptions } from '../store/cachePolicy'
import { useAppDispatch } from '../store/hooks'
import type {
  ChatMessage,
  ChatMessagesDeliveredPayload,
  ConversationSeenPayload,
} from '../types/chat'

type ChatContextValue = {
  totalUnread: number
  subscribeReceiveMessage: (handler: (message: ChatMessage) => void) => () => void
  subscribeMessageUpdated: (handler: (message: ChatMessage) => void) => () => void
  subscribeConversationSeen: (handler: (payload: ConversationSeenPayload) => void) => () => void
  subscribeMessagesDelivered: (handler: (payload: ChatMessagesDeliveredPayload) => void) => () => void
}

const ChatContext = createContext<ChatContextValue | null>(null)

export function ChatProvider({ children }: { children: ReactNode }) {
  const dispatch = useAppDispatch()
  const authUser = getAuthUser()
  const userId = authUser?.id ?? null

  const receiveListenersRef = useRef(new Set<(message: ChatMessage) => void>())
  const updatedListenersRef = useRef(new Set<(message: ChatMessage) => void>())
  const seenListenersRef = useRef(new Set<(payload: ConversationSeenPayload) => void>())
  const deliveredListenersRef = useRef(new Set<(payload: ChatMessagesDeliveredPayload) => void>())

  const { data: unreadData } = useGetChatUnreadCountQuery(undefined, {
    skip: !userId,
    pollingInterval: 10_000,
    ...liveQueryOptions,
  })

  const invalidateChat = useCallback(() => {
    dispatch(
      adminApi.util.invalidateTags([
        { type: 'Chat', id: 'INBOX' },
        { type: 'Chat', id: 'UNREAD' },
      ]),
    )
  }, [dispatch])

  const invalidateThread = useCallback(
    (otherUserId: string) => {
      dispatch(adminApi.util.invalidateTags([{ type: 'Chat', id: `THREAD:${otherUserId}` }]))
    },
    [dispatch],
  )

  useChatHub(userId, {
    onReceiveMessage: (message) => {
      receiveListenersRef.current.forEach((handler) => handler(message))
      invalidateChat()
      invalidateThread(message.fromUserId)
      invalidateThread(message.toUserId)
    },
    onMessageUpdated: (message) => {
      updatedListenersRef.current.forEach((handler) => handler(message))
      if (userId) {
        invalidateThread(message.fromUserId)
        invalidateThread(message.toUserId)
      }
    },
    onConversationSeen: (payload) => {
      seenListenersRef.current.forEach((handler) => handler(payload))
      invalidateChat()
    },
    onMessagesDelivered: (payload) => {
      deliveredListenersRef.current.forEach((handler) => handler(payload))
    },
    onUserLastSeen: () => {
      dispatch(adminApi.util.invalidateTags([{ type: 'Chat', id: 'INBOX' }]))
    },
  })

  const subscribeReceiveMessage = useCallback((handler: (message: ChatMessage) => void) => {
    receiveListenersRef.current.add(handler)
    return () => {
      receiveListenersRef.current.delete(handler)
    }
  }, [])

  const subscribeMessageUpdated = useCallback((handler: (message: ChatMessage) => void) => {
    updatedListenersRef.current.add(handler)
    return () => {
      updatedListenersRef.current.delete(handler)
    }
  }, [])

  const subscribeConversationSeen = useCallback((handler: (payload: ConversationSeenPayload) => void) => {
    seenListenersRef.current.add(handler)
    return () => {
      seenListenersRef.current.delete(handler)
    }
  }, [])

  const subscribeMessagesDelivered = useCallback(
    (handler: (payload: ChatMessagesDeliveredPayload) => void) => {
      deliveredListenersRef.current.add(handler)
      return () => {
        deliveredListenersRef.current.delete(handler)
      }
    },
    [],
  )

  const value = useMemo(
    (): ChatContextValue => ({
      totalUnread: unreadData?.totalUnread ?? 0,
      subscribeReceiveMessage,
      subscribeMessageUpdated,
      subscribeConversationSeen,
      subscribeMessagesDelivered,
    }),
    [
      unreadData?.totalUnread,
      subscribeReceiveMessage,
      subscribeMessageUpdated,
      subscribeConversationSeen,
      subscribeMessagesDelivered,
    ],
  )

  return <ChatContext.Provider value={value}>{children}</ChatContext.Provider>
}

export function useChat() {
  const context = useContext(ChatContext)
  if (!context) {
    throw new Error('useChat must be used within ChatProvider')
  }
  return context
}

export function useChatOptional() {
  return useContext(ChatContext)
}
