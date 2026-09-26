import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import ChatContactsPanel from '../components/chat/ChatContactsPanel'
import ChatThreadPanel from '../components/chat/ChatThreadPanel'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useChat } from '../context/ChatProvider'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import { resolveChatCompanyDisplay, resolveContactAvatarUrl } from '../lib/chatCompanyReport'
import { getAuthUser, getChatWrapSecret, saveChatWrapSecret } from '../lib/authStorage'
import { hasPermission, isSuperAdmin, PERMISSIONS } from '../lib/permissions'
import {
  createOptimisticMessageId,
  mergeOlderMessages,
  mergeThreadTail,
  mergeThreadWithPending,
  revokeMessagePreview,
} from '../lib/chatOptimistic'
import {
  decryptChatPayload,
  ensureSupportE2eKeys,
  isChatE2eEnvelope,
  resolveChatKeyWrapSecrets,
} from '../lib/chatE2e'
import {
  useGetAdminUserDetailQuery,
  useGetChatInboxQuery,
  useGetChatConversationDetailsQuery,
  useLazyGetChatConversationDetailsQuery,
  useGetUsersQuery,
  useMarkChatSeenMutation,
  useMarkChatDeliveredMutation,
  useSearchChatConversationsQuery,
  useSendChatMessageMutation,
  useForwardChatMessageMutation,
  useDeleteChatMessageMutation,
  useUploadChatMediaMutation,
  useUploadChatImagesMutation,
  useClaimSupportConversationMutation,
  useReleaseSupportConversationMutation,
  useLazyGetChatPublicKeyQuery,
  useLazyGetSupportChatPrivateKeyQuery,
  useUpsertSupportChatKeysMutation,
  adminApi,
} from '../store'
import { liveQueryOptions } from '../store/cachePolicy'
import { useAppDispatch } from '../store/hooks'
import type { ChatContact, ChatMessage, ChatMessageTypeCode } from '../types/chat'
import { CHAT_MESSAGES_PAGE_SIZE } from '../types/chat'
import { getRtkErrorMessage } from '../utils/rtkError'
import type { AskSupplierTarget } from '../components/chat/ChatMessageBubble'
import { buildAskSupplierPriceMessage, parseAskSupplierContent } from '../utils/askSupplierPrice'

type OpenChatWithState = {
  openChatWith?: {
    userId: string
    displayName: string
    avatarUrl?: string | null
  }
}

type DualMobileTab = 'asker' | 'supplier'

export default function ChatPage() {
  const { t } = useAppPreferences()
  const dispatch = useAppDispatch()
  const location = useLocation()
  const navigate = useNavigate()
  const { subscribeReceiveMessage, subscribeMessageUpdated, subscribeConversationSeen, subscribeMessagesDelivered, subscribeMessageDeleted, chatPollingInterval } = useChat()
  const authUser = getAuthUser()
  const myUserId = authUser?.id ?? null
  const viewerIsSuperAdmin = isSuperAdmin(authUser?.roleName)

  const [selectedContact, setSelectedContact] = useState<ChatContact | null>(null)
  const [secondaryContact, setSecondaryContact] = useState<ChatContact | null>(null)
  const [dualMobileTab, setDualMobileTab] = useState<DualMobileTab>('asker')
  const [searchValue, setSearchValue] = useState('')
  const [localMessages, setLocalMessages] = useState<ChatMessage[]>([])
  const [secondaryLocalMessages, setSecondaryLocalMessages] = useState<ChatMessage[]>([])
  const [hasMoreMessages, setHasMoreMessages] = useState(false)
  const [secondaryHasMoreMessages, setSecondaryHasMoreMessages] = useState(false)
  const [nextBeforeMessageId, setNextBeforeMessageId] = useState<string | null>(null)
  const [secondaryNextBeforeMessageId, setSecondaryNextBeforeMessageId] = useState<string | null>(null)
  const [isLoadingOlder, setIsLoadingOlder] = useState(false)
  const [isSecondaryLoadingOlder, setIsSecondaryLoadingOlder] = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)
  const [isConversationLocked, setIsConversationLocked] = useState(false)
  const [lockAgentName, setLockAgentName] = useState<string | null>(null)
  const [supervisingAgentName, setSupervisingAgentName] = useState<string | null>(null)
  const [replyTo, setReplyTo] = useState<ChatMessage | null>(null)
  const [secondaryReplyTo, setSecondaryReplyTo] = useState<ChatMessage | null>(null)
  const [forwardingMessage, setForwardingMessage] = useState<ChatMessage | null>(null)

  const [claimSupportConversation] = useClaimSupportConversationMutation()
  const [releaseSupportConversation, { isLoading: isReleasingConversation }] =
    useReleaseSupportConversationMutation()
  const previousContactIdRef = useRef<string | null>(null)

  const debouncedSearch = useDebouncedValue(searchValue.trim(), 300)
  const isSearching = debouncedSearch.length >= 2

  const {
    data: inbox,
    isLoading: inboxLoading,
  } = useGetChatInboxQuery(undefined, {
    skip: !myUserId,
    pollingInterval: chatPollingInterval,
    refetchOnMountOrArgChange: true,
    ...liveQueryOptions,
  })

  const {
    data: searchedContacts,
    isFetching: isSearchingConversations,
  } = useSearchChatConversationsQuery(debouncedSearch, {
    skip: !myUserId || !isSearching,
  })

  const selectedUserId = selectedContact?.contactUserId ?? null
  const selectedUserIdRef = useRef(selectedUserId)
  selectedUserIdRef.current = selectedUserId
  const secondaryUserId = secondaryContact?.contactUserId ?? null
  const secondaryUserIdRef = useRef(secondaryUserId)
  secondaryUserIdRef.current = secondaryUserId
  const isDualPane = Boolean(selectedContact && secondaryContact)

  const {
    data: threadDetails,
    isLoading: threadLoading,
    isFetching: threadFetching,
  } = useGetChatConversationDetailsQuery(
    { otherUserId: selectedUserId ?? '', limit: CHAT_MESSAGES_PAGE_SIZE },
    {
    skip: !selectedUserId || (isConversationLocked && !viewerIsSuperAdmin),
    pollingInterval: chatPollingInterval,
    ...liveQueryOptions,
  })

  const {
    data: secondaryThreadDetails,
    isLoading: secondaryThreadLoading,
    isFetching: secondaryThreadFetching,
  } = useGetChatConversationDetailsQuery(
    { otherUserId: secondaryUserId ?? '', limit: CHAT_MESSAGES_PAGE_SIZE },
    {
      skip: !secondaryUserId,
      pollingInterval: chatPollingInterval,
      ...liveQueryOptions,
    },
  )

  const [fetchOlderConversationPage] = useLazyGetChatConversationDetailsQuery()

  const { data: participantDetail } = useGetAdminUserDetailQuery(selectedUserId ?? '', {
    skip: !selectedUserId,
    ...liveQueryOptions,
  })

  const { data: secondaryParticipantDetail } = useGetAdminUserDetailQuery(secondaryUserId ?? '', {
    skip: !secondaryUserId,
    ...liveQueryOptions,
  })

  const companyDisplay = useMemo(() => {
    if (!selectedContact) return null
    const fromContact = resolveChatCompanyDisplay(selectedContact)
    if (!participantDetail) return fromContact

    const companyName = participantDetail.companyName?.trim()
    const isCompany = Boolean(companyName) || fromContact.isCompany
    const profileImage =
      participantDetail.imgPath?.trim() ||
      resolveContactAvatarUrl(selectedContact)

    return {
      title: companyName || fromContact.title,
      subtitle: companyName ? participantDetail.fullName : fromContact.subtitle,
      imageUrl: profileImage,
      isCompany,
    }
  }, [participantDetail, selectedContact])

  const secondaryCompanyDisplay = useMemo(() => {
    if (!secondaryContact) return null
    const fromContact = resolveChatCompanyDisplay(secondaryContact)
    if (!secondaryParticipantDetail) return fromContact

    const companyName = secondaryParticipantDetail.companyName?.trim()
    const isCompany = Boolean(companyName) || fromContact.isCompany
    const profileImage =
      secondaryParticipantDetail.imgPath?.trim() ||
      resolveContactAvatarUrl(secondaryContact)

    return {
      title: companyName || fromContact.title,
      subtitle: companyName ? secondaryParticipantDetail.fullName : fromContact.subtitle,
      imageUrl: profileImage,
      isCompany,
    }
  }, [secondaryParticipantDetail, secondaryContact])

  const supportSessions = threadDetails?.supportSessions ?? []
  const secondarySupportSessions = secondaryThreadDetails?.supportSessions ?? []

  const [sendMessage] = useSendChatMessageMutation()
  const [forwardMessage] = useForwardChatMessageMutation()
  const [deleteMessage] = useDeleteChatMessageMutation()
  const [uploadMedia] = useUploadChatMediaMutation()
  const [uploadImages] = useUploadChatImagesMutation()
  const [markSeen] = useMarkChatSeenMutation()
  const [markDelivered] = useMarkChatDeliveredMutation()
  const [fetchPublicKey] = useLazyGetChatPublicKeyQuery()
  const [fetchSupportPrivate] = useLazyGetSupportChatPrivateKeyQuery()
  const [upsertSupportKeys] = useUpsertSupportChatKeysMutation()

  const e2eRef = useRef<{
    supportUserId: string
    publicKeyJwk: string
    privateKeyJwk: string
  } | null>(null)

  async function ensureE2eReady() {
    if (e2eRef.current) return e2eRef.current

    const user = getAuthUser()
    const wrapSecrets = await resolveChatKeyWrapSecrets({
      passwordDerivedSecret: getChatWrapSecret(),
      email: user?.email,
      userId: user?.id,
    })
    if (wrapSecrets.length === 0) {
      throw new Error('Missing chat wrap secret')
    }
    if (!getChatWrapSecret()) {
      saveChatWrapSecret(wrapSecrets[0])
    }

    const keys = await ensureSupportE2eKeys({
      wrapSecrets,
      getSupportPrivate: async () => {
        try {
          return await fetchSupportPrivate().unwrap()
        } catch {
          return null
        }
      },
      getSupportPublic: async (userId) => {
        try {
          const pub = await fetchPublicKey(userId).unwrap()
          return pub.publicKeySpkiBase64 || null
        } catch {
          return null
        }
      },
      upsertSupportKeys: async (payload) => {
        await upsertSupportKeys(payload).unwrap()
      },
    })
    const privateRemote = await fetchSupportPrivate()
      .unwrap()
      .catch(() => null)
    const supportUserId = privateRemote?.userId ?? keys.supportUserId ?? ''
    let publicKeyJwk = keys.publicKeyJwk
    if (supportUserId) {
      try {
        const pub = await fetchPublicKey(supportUserId).unwrap()
        if (pub.publicKeySpkiBase64) publicKeyJwk = pub.publicKeySpkiBase64
      } catch {
        // keep local
      }
    }
    e2eRef.current = {
      supportUserId,
      publicKeyJwk,
      privateKeyJwk: keys.privateKeyJwk,
    }
    return e2eRef.current
  }

  // Publish support public key as soon as chat page opens (required for customer encryption).
  useEffect(() => {
    void ensureE2eReady().catch(() => undefined)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  async function decryptForDisplay(message: ChatMessage): Promise<ChatMessage> {
    if (!isChatE2eEnvelope(message.content)) return message
    try {
      const e2e = await ensureE2eReady()
      if (!e2e.supportUserId) return { ...message, content: '🔒' }
      const clear = await decryptChatPayload({
        envelopeJson: message.content,
        myUserId: e2e.supportUserId,
        privateKeyJwk: e2e.privateKeyJwk,
      })
      return { ...message, content: clear }
    } catch {
      return { ...message, content: '🔒' }
    }
  }

  useEffect(() => {
    setHasMoreMessages(false)
    setNextBeforeMessageId(null)
    setIsLoadingOlder(false)
  }, [selectedUserId])

  useEffect(() => {
    setSecondaryHasMoreMessages(false)
    setSecondaryNextBeforeMessageId(null)
    setIsSecondaryLoadingOlder(false)
    setSecondaryReplyTo(null)
  }, [secondaryUserId])

  useEffect(() => {
    let cancelled = false
    async function hydrate() {
      const source = threadDetails?.messages ?? []
      const decrypted: ChatMessage[] = []
      for (const m of source) {
        decrypted.push(await decryptForDisplay(m))
      }
      if (cancelled) return
      setHasMoreMessages(Boolean(threadDetails?.hasMore))
      setNextBeforeMessageId(threadDetails?.nextBeforeMessageId ?? null)
      setLocalMessages((prev) => {
        const merged =
          prev.length > decrypted.length
            ? mergeThreadTail(decrypted, prev, selectedUserId, myUserId)
            : mergeThreadWithPending(decrypted, prev, selectedUserId, myUserId)
        return merged
      })
    }
    void hydrate()
    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [threadDetails, selectedUserId, myUserId])

  useEffect(() => {
    let cancelled = false
    async function hydrateSecondary() {
      const source = secondaryThreadDetails?.messages ?? []
      const decrypted: ChatMessage[] = []
      for (const m of source) {
        decrypted.push(await decryptForDisplay(m))
      }
      if (cancelled) return
      setSecondaryHasMoreMessages(Boolean(secondaryThreadDetails?.hasMore))
      setSecondaryNextBeforeMessageId(secondaryThreadDetails?.nextBeforeMessageId ?? null)
      setSecondaryLocalMessages((prev) => {
        const merged =
          prev.length > decrypted.length
            ? mergeThreadTail(decrypted, prev, secondaryUserId, myUserId)
            : mergeThreadWithPending(decrypted, prev, secondaryUserId, myUserId)
        return merged
      })
    }
    void hydrateSecondary()
    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [secondaryThreadDetails, secondaryUserId, myUserId])

  const handleLoadOlderMessages = useCallback(async () => {
    if (!selectedUserId || !hasMoreMessages || !nextBeforeMessageId || isLoadingOlder) {
      return
    }

    const scrollEl = document.querySelector('.chat-messages-scroll')
    const previousScrollHeight = scrollEl?.scrollHeight ?? 0

    setIsLoadingOlder(true)
    try {
      const page = await fetchOlderConversationPage({
        otherUserId: selectedUserId,
        limit: CHAT_MESSAGES_PAGE_SIZE,
        before: nextBeforeMessageId,
      }).unwrap()

      const decrypted: ChatMessage[] = []
      for (const message of page.messages) {
        decrypted.push(await decryptForDisplay(message))
      }

      setHasMoreMessages(page.hasMore)
      setNextBeforeMessageId(page.nextBeforeMessageId)
      setLocalMessages((prev) => mergeOlderMessages(decrypted, prev))

      requestAnimationFrame(() => {
        if (!scrollEl) return
        scrollEl.scrollTop = scrollEl.scrollHeight - previousScrollHeight
      })
    } finally {
      setIsLoadingOlder(false)
    }
  }, [
    selectedUserId,
    hasMoreMessages,
    nextBeforeMessageId,
    isLoadingOlder,
    fetchOlderConversationPage,
  ])

  const handleLoadOlderSecondaryMessages = useCallback(async () => {
    if (
      !secondaryUserId ||
      !secondaryHasMoreMessages ||
      !secondaryNextBeforeMessageId ||
      isSecondaryLoadingOlder
    ) {
      return
    }

    setIsSecondaryLoadingOlder(true)
    try {
      const page = await fetchOlderConversationPage({
        otherUserId: secondaryUserId,
        limit: CHAT_MESSAGES_PAGE_SIZE,
        before: secondaryNextBeforeMessageId,
      }).unwrap()

      const decrypted: ChatMessage[] = []
      for (const message of page.messages) {
        decrypted.push(await decryptForDisplay(message))
      }

      setSecondaryHasMoreMessages(page.hasMore)
      setSecondaryNextBeforeMessageId(page.nextBeforeMessageId)
      setSecondaryLocalMessages((prev) => mergeOlderMessages(decrypted, prev))
    } finally {
      setIsSecondaryLoadingOlder(false)
    }
  }, [
    secondaryUserId,
    secondaryHasMoreMessages,
    secondaryNextBeforeMessageId,
    isSecondaryLoadingOlder,
    fetchOlderConversationPage,
  ])

  useEffect(() => {
    if (!selectedUserId) return
    if (isConversationLocked) return
    void markDelivered({ otherUserId: selectedUserId }).catch(() => undefined)
    void markSeen({ otherUserId: selectedUserId }).catch(() => undefined)
  }, [selectedUserId, isConversationLocked, markSeen, markDelivered, localMessages.length])

  useEffect(() => {
    if (!secondaryUserId) return
    void markDelivered({ otherUserId: secondaryUserId }).catch(() => undefined)
    void markSeen({ otherUserId: secondaryUserId }).catch(() => undefined)
  }, [secondaryUserId, markSeen, markDelivered, secondaryLocalMessages.length])

  const { data: userSearchData } = useGetUsersQuery(
    { page: 1, pageSize: 8, search: debouncedSearch || undefined },
    { skip: !isSearching },
  )

  useEffect(() => {
    const previousId = previousContactIdRef.current
    if (previousId && previousId !== selectedUserId && hasPermission(PERMISSIONS.chatAccess)) {
      void releaseSupportConversation({ otherUserId: previousId }).catch(() => undefined)
    }
    previousContactIdRef.current = selectedUserId
  }, [selectedUserId, releaseSupportConversation])

  useEffect(() => {
    const main = document.querySelector('main')
    if (!main) return

    main.classList.add('overflow-hidden')

    return () => {
      main.classList.remove('overflow-hidden')
    }
  }, [])

  const mergeMessage = useCallback((message: ChatMessage) => {
    setLocalMessages((prev) => {
      if (prev.some((m) => m.messageId === message.messageId)) {
        return prev.map((m) => (m.messageId === message.messageId ? message : m))
      }
      return [...prev, message]
    })
  }, [])

  const mergeSecondaryMessage = useCallback((message: ChatMessage) => {
    setSecondaryLocalMessages((prev) => {
      if (prev.some((m) => m.messageId === message.messageId)) {
        return prev.map((m) => (m.messageId === message.messageId ? message : m))
      }
      return [...prev, message]
    })
  }, [])

  const routeIncomingMessage = useCallback(
    (message: ChatMessage) => {
      const primaryId = selectedUserIdRef.current
      const secondaryId = secondaryUserIdRef.current
      const involves = (otherId: string | null) =>
        Boolean(
          otherId &&
            (message.fromUserId === otherId || message.toUserId === otherId),
        )

      if (involves(primaryId)) {
        void decryptForDisplay(message).then((decoded) => {
          mergeMessage(decoded)
          invalidateProductAfterAskSupplierReply(decoded.content)
          if (primaryId && decoded.fromUserId === primaryId) {
            void markDelivered({ otherUserId: decoded.fromUserId }).catch(() => undefined)
            void markSeen({ otherUserId: decoded.fromUserId }).catch(() => undefined)
          }
        })
      }
      if (involves(secondaryId) && secondaryId !== primaryId) {
        void decryptForDisplay(message).then((decoded) => {
          mergeSecondaryMessage(decoded)
          invalidateProductAfterAskSupplierReply(decoded.content)
          if (secondaryId && decoded.fromUserId === secondaryId) {
            void markDelivered({ otherUserId: decoded.fromUserId }).catch(() => undefined)
            void markSeen({ otherUserId: decoded.fromUserId }).catch(() => undefined)
          }
        })
      }
    },
    [mergeMessage, mergeSecondaryMessage, markSeen, markDelivered, dispatch],
  )

  const replaceOptimisticMessage = useCallback(
    (optimisticId: string, confirmed: ChatMessage, intoSecondary = false) => {
      const apply = (prev: ChatMessage[]) => {
        const optimistic = prev.find((message) => message.messageId === optimisticId)
        if (optimistic) {
          revokeMessagePreview(optimistic)
        }
        return prev
          .filter((message) => message.messageId !== optimisticId)
          .concat(confirmed)
          .sort((a, b) => a.sentAtUtc.localeCompare(b.sentAtUtc))
      }
      if (intoSecondary) {
        setSecondaryLocalMessages(apply)
      } else {
        setLocalMessages(apply)
      }
    },
    [],
  )

  const markOptimisticFailed = useCallback((optimisticId: string, intoSecondary = false) => {
    const apply = (prev: ChatMessage[]): ChatMessage[] =>
      prev.map((message) =>
        message.messageId === optimisticId
          ? { ...message, deliveryStatus: 'failed' as const, relativeTime: t('chat.failed') }
          : message,
      )
    if (intoSecondary) {
      setSecondaryLocalMessages(apply)
    } else {
      setLocalMessages(apply)
    }
  }, [t])

  useEffect(() => {
    return subscribeReceiveMessage((message) => {
      routeIncomingMessage(message)
    })
  }, [subscribeReceiveMessage, routeIncomingMessage])

  useEffect(() => {
    return subscribeConversationSeen((payload) => {
      const primaryId = selectedUserIdRef.current
      const secondaryId = secondaryUserIdRef.current
      const viewer = payload.viewerUserId.toLowerCase()

      if (primaryId && viewer === primaryId.toLowerCase()) {
        setLocalMessages((prev) =>
          prev.map((message) =>
            message.toUserId.toLowerCase() === primaryId.toLowerCase()
              ? { ...message, isSeen: true, isDelivered: true, seenAtUtc: payload.seenAtUtc }
              : message,
          ),
        )
      }
      if (secondaryId && viewer === secondaryId.toLowerCase()) {
        setSecondaryLocalMessages((prev) =>
          prev.map((message) =>
            message.toUserId.toLowerCase() === secondaryId.toLowerCase()
              ? { ...message, isSeen: true, isDelivered: true, seenAtUtc: payload.seenAtUtc }
              : message,
          ),
        )
      }
    })
  }, [subscribeConversationSeen])

  useEffect(() => {
    return subscribeMessagesDelivered((payload) => {
      const deliveredSet = new Set(payload.messageIds)
      if (deliveredSet.size === 0) return

      const apply = (prev: ChatMessage[]) =>
        prev.map((message) =>
          deliveredSet.has(message.messageId)
            ? { ...message, isDelivered: true, deliveredAtUtc: payload.deliveredAtUtc }
            : message,
        )
      setLocalMessages(apply)
      setSecondaryLocalMessages(apply)
    })
  }, [subscribeMessagesDelivered])

  useEffect(() => {
    return subscribeMessageUpdated((message) => {
      routeIncomingMessage(message)
    })
  }, [subscribeMessageUpdated, routeIncomingMessage])

  useEffect(() => {
    return subscribeMessageDeleted((payload) => {
      const primaryId = selectedUserIdRef.current
      const secondaryId = secondaryUserIdRef.current
      const involves = (otherId: string | null) =>
        Boolean(
          otherId &&
            (payload.fromUserId === otherId || payload.toUserId === otherId),
        )

      const apply = (prev: ChatMessage[]) => {
        if (payload.scope === 'me' || !payload.message) {
          return prev.filter((message) => message.messageId !== payload.messageId)
        }
        return prev.map((message) =>
          message.messageId === payload.messageId
            ? { ...message, ...payload.message, isDeleted: true, content: '' }
            : message,
        )
      }

      if (involves(primaryId)) {
        setLocalMessages(apply)
      }
      if (involves(secondaryId)) {
        setSecondaryLocalMessages(apply)
      }
    })
  }, [subscribeMessageDeleted])

  const contacts = inbox?.contacts ?? []

  const displayedContacts = useMemo(() => {
    if (!isSearching) return contacts
    return searchedContacts ?? []
  }, [contacts, isSearching, searchedContacts])

  const newChatUsers = useMemo(() => {
    if (!userSearchData?.items?.length) return []
    const existingIds = new Set(contacts.map((c) => c.contactUserId))
    return userSearchData.items
      .filter((user) => user.id !== myUserId && !existingIds.has(user.id))
      .map((user) => ({
        id: user.id,
        name: user.companyName?.trim() || user.fullName,
        imgPath: user.imgPath,
      }))
  }, [userSearchData, myUserId, contacts])

  async function invalidateChatCaches(otherUserId: string) {
    dispatch(
      adminApi.util.invalidateTags([
        { type: 'Chat', id: 'INBOX' },
        { type: 'Chat', id: 'UNREAD' },
        { type: 'Chat', id: `THREAD:${otherUserId}` },
      ]),
    )
  }

  function invalidateProductAfterAskSupplierReply(content: string) {
    const parsed = parseAskSupplierContent(content)
    if (parsed?.kind !== 'reply' || parsed.confirmed) return
    dispatch(
      adminApi.util.invalidateTags([{ type: 'Products', id: parsed.productId }]),
    )
  }

  function pushOptimisticMessage(
    otherUserId: string,
    intoSecondary: boolean,
    reply: ChatMessage | null,
    messageType: ChatMessageTypeCode,
    content: string,
    localPreviewUrl?: string,
    localPreviewMime?: string,
  ): string {
    if (!otherUserId || !myUserId) return ''

    const optimisticId = createOptimisticMessageId()
    const optimistic: ChatMessage = {
      messageId: optimisticId,
      fromUserId: myUserId,
      toUserId: otherUserId,
      messageType,
      content: localPreviewUrl ?? content,
      sentAtUtc: new Date().toISOString(),
      relativeTime: t('chat.sending'),
      isEdited: false,
      isSeen: false,
      seenAtUtc: null,
      isDelivered: false,
      deliveredAtUtc: null,
      deliveryStatus: 'sending',
      localPreviewUrl,
      localPreviewMime,
      replyToMessageId: reply?.messageId ?? null,
      replyToPreview: reply
        ? reply.messageType === 1
          ? reply.content.slice(0, 80)
          : reply.replyToPreview ?? null
        : null,
      replyToMessageType: reply?.messageType ?? null,
    }

    if (intoSecondary) {
      mergeSecondaryMessage(optimistic)
    } else {
      mergeMessage(optimistic)
    }
    return optimisticId
  }

  async function handleSend(
    otherUserId: string,
    intoSecondary: boolean,
    reply: ChatMessage | null,
    clearReply: () => void,
    messageType: ChatMessageTypeCode,
    content: string,
    optimisticId: string,
  ) {
    if (!otherUserId) return
    setActionError(null)

    try {
      const result = await sendMessage({
        toUserId: otherUserId,
        messageType,
        content,
        replyToMessageId: reply?.messageId ?? undefined,
      }).unwrap()
      replaceOptimisticMessage(optimisticId, { ...result, content }, intoSecondary)
      clearReply()
      await invalidateChatCaches(otherUserId)
    } catch (err) {
      markOptimisticFailed(optimisticId, intoSecondary)
      setActionError(getRtkErrorMessage(err as never, t('chat.sendError')))
    }
  }

  async function handleSendText(text: string) {
    if (!selectedUserId) return
    const optimisticId = pushOptimisticMessage(selectedUserId, false, replyTo, 1, text)
    await handleSend(selectedUserId, false, replyTo, () => setReplyTo(null), 1, text, optimisticId)
  }

  async function handleSendSecondaryText(text: string) {
    if (!secondaryUserId) return
    const optimisticId = pushOptimisticMessage(secondaryUserId, true, secondaryReplyTo, 1, text)
    await handleSend(
      secondaryUserId,
      true,
      secondaryReplyTo,
      () => setSecondaryReplyTo(null),
      1,
      text,
      optimisticId,
    )
  }

  async function handleSendImages(files: File[]) {
    if (!selectedUserId || files.length === 0) return
    setActionError(null)

    const previewUrl = files.length === 1 ? URL.createObjectURL(files[0]) : undefined
    const optimisticId = pushOptimisticMessage(
      selectedUserId,
      false,
      replyTo,
      3,
      previewUrl ?? `${files.length} images`,
      previewUrl,
    )

    try {
      const upload = files.length === 1
        ? await uploadMedia({ file: files[0], messageType: 3 }).unwrap()
        : await uploadImages({ files }).unwrap()
      await handleSend(
        selectedUserId,
        false,
        replyTo,
        () => setReplyTo(null),
        3,
        upload.content,
        optimisticId,
      )
    } catch (err) {
      markOptimisticFailed(optimisticId)
      setActionError(getRtkErrorMessage(err as never, t('chat.uploadError')))
    }
  }

  async function handleSendSecondaryImages(files: File[]) {
    if (!secondaryUserId || files.length === 0) return
    setActionError(null)

    const previewUrl = files.length === 1 ? URL.createObjectURL(files[0]) : undefined
    const optimisticId = pushOptimisticMessage(
      secondaryUserId,
      true,
      secondaryReplyTo,
      3,
      previewUrl ?? `${files.length} images`,
      previewUrl,
    )

    try {
      const upload = files.length === 1
        ? await uploadMedia({ file: files[0], messageType: 3 }).unwrap()
        : await uploadImages({ files }).unwrap()
      await handleSend(
        secondaryUserId,
        true,
        secondaryReplyTo,
        () => setSecondaryReplyTo(null),
        3,
        upload.content,
        optimisticId,
      )
    } catch (err) {
      markOptimisticFailed(optimisticId, true)
      setActionError(getRtkErrorMessage(err as never, t('chat.uploadError')))
    }
  }

  async function handleSendVoice(file: File) {
    if (!selectedUserId) return
    setActionError(null)

    const previewUrl = URL.createObjectURL(file)
    const optimisticId = pushOptimisticMessage(
      selectedUserId,
      false,
      replyTo,
      2,
      previewUrl,
      previewUrl,
      file.type || undefined,
    )

    try {
      const upload = await uploadMedia({ file, messageType: 2 }).unwrap()
      await handleSend(
        selectedUserId,
        false,
        replyTo,
        () => setReplyTo(null),
        2,
        upload.content,
        optimisticId,
      )
    } catch (err) {
      markOptimisticFailed(optimisticId)
      setActionError(getRtkErrorMessage(err as never, t('chat.uploadError')))
    }
  }

  async function handleSendSecondaryVoice(file: File) {
    if (!secondaryUserId) return
    setActionError(null)

    const previewUrl = URL.createObjectURL(file)
    const optimisticId = pushOptimisticMessage(
      secondaryUserId,
      true,
      secondaryReplyTo,
      2,
      previewUrl,
      previewUrl,
      file.type || undefined,
    )

    try {
      const upload = await uploadMedia({ file, messageType: 2 }).unwrap()
      await handleSend(
        secondaryUserId,
        true,
        secondaryReplyTo,
        () => setSecondaryReplyTo(null),
        2,
        upload.content,
        optimisticId,
      )
    } catch (err) {
      markOptimisticFailed(optimisticId, true)
      setActionError(getRtkErrorMessage(err as never, t('chat.uploadError')))
    }
  }

  async function handleSendVideo(file: File) {
    if (!selectedUserId) return
    if (file.size > 30 * 1024 * 1024) {
      setActionError(t('chat.videoTooLarge'))
      return
    }

    setActionError(null)
    const previewUrl = URL.createObjectURL(file)
    const optimisticId = pushOptimisticMessage(
      selectedUserId,
      false,
      replyTo,
      5,
      previewUrl,
      previewUrl,
      file.type || undefined,
    )

    try {
      const upload = await uploadMedia({ file, messageType: 5 }).unwrap()
      await handleSend(
        selectedUserId,
        false,
        replyTo,
        () => setReplyTo(null),
        5,
        upload.content,
        optimisticId,
      )
    } catch (err) {
      markOptimisticFailed(optimisticId)
      setActionError(getRtkErrorMessage(err as never, t('chat.uploadError')))
    }
  }

  async function handleSendSecondaryVideo(file: File) {
    if (!secondaryUserId) return
    if (file.size > 30 * 1024 * 1024) {
      setActionError(t('chat.videoTooLarge'))
      return
    }

    setActionError(null)
    const previewUrl = URL.createObjectURL(file)
    const optimisticId = pushOptimisticMessage(
      secondaryUserId,
      true,
      secondaryReplyTo,
      5,
      previewUrl,
      previewUrl,
      file.type || undefined,
    )

    try {
      const upload = await uploadMedia({ file, messageType: 5 }).unwrap()
      await handleSend(
        secondaryUserId,
        true,
        secondaryReplyTo,
        () => setSecondaryReplyTo(null),
        5,
        upload.content,
        optimisticId,
      )
    } catch (err) {
      markOptimisticFailed(optimisticId, true)
      setActionError(getRtkErrorMessage(err as never, t('chat.uploadError')))
    }
  }

  async function handleSendDocument(file: File) {
    if (!selectedUserId) return
    if (file.size > 20 * 1024 * 1024) {
      setActionError(t('chat.documentTooLarge'))
      return
    }

    setActionError(null)
    const placeholder = JSON.stringify({ path: '', name: file.name, size: file.size })
    const optimisticId = pushOptimisticMessage(selectedUserId, false, replyTo, 6, placeholder)

    try {
      const upload = await uploadMedia({ file, messageType: 6 }).unwrap()
      await handleSend(
        selectedUserId,
        false,
        replyTo,
        () => setReplyTo(null),
        6,
        upload.content,
        optimisticId,
      )
    } catch (err) {
      markOptimisticFailed(optimisticId)
      setActionError(getRtkErrorMessage(err as never, t('chat.uploadError')))
    }
  }

  async function handleSendSecondaryDocument(file: File) {
    if (!secondaryUserId) return
    if (file.size > 20 * 1024 * 1024) {
      setActionError(t('chat.documentTooLarge'))
      return
    }

    setActionError(null)
    const placeholder = JSON.stringify({ path: '', name: file.name, size: file.size })
    const optimisticId = pushOptimisticMessage(
      secondaryUserId,
      true,
      secondaryReplyTo,
      6,
      placeholder,
    )

    try {
      const upload = await uploadMedia({ file, messageType: 6 }).unwrap()
      await handleSend(
        secondaryUserId,
        true,
        secondaryReplyTo,
        () => setSecondaryReplyTo(null),
        6,
        upload.content,
        optimisticId,
      )
    } catch (err) {
      markOptimisticFailed(optimisticId, true)
      setActionError(getRtkErrorMessage(err as never, t('chat.uploadError')))
    }
  }

  async function handleSendLocation() {
    if (!selectedUserId) return
    setActionError(null)

    if (!navigator.geolocation) {
      setActionError(t('chat.locationUnsupported'))
      return
    }

    await new Promise<void>((resolve) => {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          const payload = JSON.stringify({
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
            label: t('chat.myLocation'),
          })
          const optimisticId = pushOptimisticMessage(selectedUserId, false, replyTo, 4, payload)
          await handleSend(
            selectedUserId,
            false,
            replyTo,
            () => setReplyTo(null),
            4,
            payload,
            optimisticId,
          )
          resolve()
        },
        () => {
          setActionError(t('chat.locationDenied'))
          resolve()
        },
        { enableHighAccuracy: true, timeout: 15000 },
      )
    })
  }

  async function handleSendSecondaryLocation() {
    if (!secondaryUserId) return
    setActionError(null)

    if (!navigator.geolocation) {
      setActionError(t('chat.locationUnsupported'))
      return
    }

    await new Promise<void>((resolve) => {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          const payload = JSON.stringify({
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
            label: t('chat.myLocation'),
          })
          const optimisticId = pushOptimisticMessage(
            secondaryUserId,
            true,
            secondaryReplyTo,
            4,
            payload,
          )
          await handleSend(
            secondaryUserId,
            true,
            secondaryReplyTo,
            () => setSecondaryReplyTo(null),
            4,
            payload,
            optimisticId,
          )
          resolve()
        },
        () => {
          setActionError(t('chat.locationDenied'))
          resolve()
        },
        { enableHighAccuracy: true, timeout: 15000 },
      )
    })
  }

  async function handleDeleteMessage(message: ChatMessage, scope: 'me' | 'everyone') {
    setActionError(null)
    try {
      const result = await deleteMessage({ messageId: message.messageId, scope }).unwrap()
      const apply = (prev: ChatMessage[]) => {
        if (scope === 'me' || !result.message) {
          return prev.filter((item) => item.messageId !== message.messageId)
        }
        return prev.map((item) =>
          item.messageId === message.messageId
            ? { ...item, ...result.message, isDeleted: true, content: '' }
            : item,
        )
      }
      setLocalMessages(apply)
      setSecondaryLocalMessages(apply)
      if (replyTo?.messageId === message.messageId) setReplyTo(null)
      if (secondaryReplyTo?.messageId === message.messageId) setSecondaryReplyTo(null)
      if (forwardingMessage?.messageId === message.messageId) setForwardingMessage(null)
      if (selectedUserId) await invalidateChatCaches(selectedUserId)
      if (secondaryUserId) await invalidateChatCaches(secondaryUserId)
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('chat.deleteError')))
    }
  }

  async function handleForwardTo(toUserId: string) {
    if (!forwardingMessage) return
    setActionError(null)
    try {
      const result = await forwardMessage({
        messageId: forwardingMessage.messageId,
        toUserId,
      }).unwrap()
      setForwardingMessage(null)
      if (selectedUserId === toUserId) {
        mergeMessage(result)
      }
      if (secondaryUserId === toUserId) {
        mergeSecondaryMessage(result)
      }
      await invalidateChatCaches(toUserId)
      if (selectedUserId && selectedUserId !== toUserId) {
        await invalidateChatCaches(selectedUserId)
      }
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('chat.forwardError')))
    }
  }

  async function handleSelectContact(contact: ChatContact) {
    setActionError(null)
    setReplyTo(null)
    setForwardingMessage(null)
    setSecondaryContact(null)
    setSecondaryLocalMessages([])
    setSecondaryReplyTo(null)
    setDualMobileTab('asker')

    if (hasPermission(PERMISSIONS.chatAccess)) {
      try {
        const assignment = await claimSupportConversation({
          otherUserId: contact.contactUserId,
        }).unwrap()

        if (assignment.isLockedByOtherAgent && !viewerIsSuperAdmin) {
          setIsConversationLocked(true)
          setLockAgentName(assignment.assignedAgentName)
          setSupervisingAgentName(null)
          setSelectedContact(contact)
          setLocalMessages([])
          return
        }

        setIsConversationLocked(false)
        setLockAgentName(null)
        setSupervisingAgentName(
          viewerIsSuperAdmin && assignment.assignedAgentId && !assignment.isAssignedToMe
            ? assignment.assignedAgentName
            : null,
        )
        setSelectedContact({
          ...contact,
          assignedAgentId: assignment.assignedAgentId,
          assignedAgentName: assignment.assignedAgentName,
          isAssignedToMe: assignment.isAssignedToMe,
          isLockedByOtherAgent: assignment.isLockedByOtherAgent,
        })
        return
      } catch (err) {
        const rtkErr = err as { status?: number; data?: { assignedAgentName?: string | null } }
        if (rtkErr.status === 409 && !viewerIsSuperAdmin) {
          setIsConversationLocked(true)
          setLockAgentName(rtkErr.data?.assignedAgentName ?? null)
          setSupervisingAgentName(null)
          setSelectedContact(contact)
          setLocalMessages([])
          return
        }
      }
    }

    setIsConversationLocked(false)
    setLockAgentName(null)
    setSupervisingAgentName(null)
    setSelectedContact(contact)
  }

  async function handleChatWithSupplier(target: AskSupplierTarget) {
    const supplierId = target.supplierUserId?.trim()
    if (!supplierId) return
    if (selectedUserId && supplierId.toLowerCase() === selectedUserId.toLowerCase()) {
      return
    }

    const existing = contacts.find((c) => c.contactUserId === supplierId)
    const contact: ChatContact = existing ?? {
      contactUserId: supplierId,
      displayName: target.displayName?.trim() || t('chat.supplierChat'),
      avatarUrl: target.avatarUrl ?? null,
      lastMessagePreview: null,
      lastMessageType: null,
      lastMessageRelativeTime: null,
      lastMessageSentAtUtc: null,
      unreadCount: 0,
      contactLastSeenAtUtc: null,
      isOnline: false,
    }

    setSecondaryContact(contact)
    setSecondaryReplyTo(null)
    setDualMobileTab('supplier')
    setActionError(null)

    if (hasPermission(PERMISSIONS.chatAccess)) {
      try {
        await claimSupportConversation({ otherUserId: supplierId }).unwrap()
      } catch {
        // Secondary pane can still open even if claim fails (e.g. already claimed).
      }
    }

    const productId = target.productId?.trim()
    if (!productId) return

    const content = buildAskSupplierPriceMessage({
      productId,
      productName: target.productName,
      productCode: target.productCode,
      unitName: target.unitName,
      quantityLabel: target.quantityLabel,
      supplierPriceFormatted: target.supplierPriceFormatted,
      supplierPriceUsd: target.supplierPriceUsd,
      imagePath: target.imagePath,
      requesterUserId: selectedUserId,
    })

    const optimisticId = pushOptimisticMessage(supplierId, true, null, 1, content)
    await handleSend(supplierId, true, null, () => undefined, 1, content, optimisticId)
  }

  function handleCloseSecondaryPane() {
    setSecondaryContact(null)
    setSecondaryLocalMessages([])
    setSecondaryReplyTo(null)
    setDualMobileTab('asker')
  }

  async function handleCloseConversation() {
    if (!selectedUserId || !hasPermission(PERMISSIONS.chatAccess)) return
    setActionError(null)

    try {
      await releaseSupportConversation({ otherUserId: selectedUserId }).unwrap()
      if (secondaryUserId) {
        await releaseSupportConversation({ otherUserId: secondaryUserId }).catch(() => undefined)
      }
      setSelectedContact(null)
      setLocalMessages([])
      handleCloseSecondaryPane()
      setIsConversationLocked(false)
      setLockAgentName(null)
      setSupervisingAgentName(null)
      await invalidateChatCaches(selectedUserId)
    } catch (err) {
      setActionError(getRtkErrorMessage(err as never, t('chat.closeError')))
    }
  }

  function handleStartChat(userId: string, displayName: string, avatarUrl: string | null) {
    const existing = contacts.find((c) => c.contactUserId === userId)
    if (existing) {
      setSelectedContact(existing)
      return
    }

    setSelectedContact({
      contactUserId: userId,
      displayName,
      avatarUrl,
      lastMessagePreview: null,
      lastMessageType: null,
      lastMessageRelativeTime: null,
      lastMessageSentAtUtc: null,
      unreadCount: 0,
      contactLastSeenAtUtc: null,
      isOnline: false,
    })
  }

  useEffect(() => {
    const state = location.state as OpenChatWithState | null
    const open = state?.openChatWith
    if (!open?.userId?.trim()) return

    handleStartChat(
      open.userId.trim(),
      open.displayName?.trim() || '—',
      open.avatarUrl ?? null,
    )
    navigate(location.pathname, { replace: true, state: {} })
    // Intentionally only when navigation brings openChatWith state.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [location.state])

  if (!myUserId) {
    return (
      <div className="p-6 text-sm text-[var(--text-muted)]">{t('chat.authRequired')}</div>
    )
  }

  const showThreadLoading = threadLoading && localMessages.length === 0

  const showMobileThread = Boolean(selectedContact)

  return (
    <div className="chat-page flex h-[calc(100dvh-4rem)] min-h-0 flex-col overflow-hidden lg:h-[calc(100svh-9rem)] lg:max-h-[calc(100svh-9rem)]">
      <div className={`mb-3 shrink-0 items-center justify-between px-1 ${showMobileThread ? 'hidden lg:flex' : 'flex'}`}>
        <div className="flex items-center gap-3">
          <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-[#3B7FC7] to-[#619d51] shadow-md">
            <img src="/ProjectImages/SouqLogo.png" alt="" className="h-8 w-8 object-contain" />
          </div>
          <div>
            <h1 className="brand-gradient-text text-2xl font-extrabold">{t('nav.chat')}</h1>
            {inbox?.fromCache ? (
              <p className="text-xs text-slate-500">{t('chat.cachedInbox')}</p>
            ) : null}
          </div>
        </div>
      </div>

      {actionError ? (
        <div
          className={`shrink-0 rounded-xl border border-red-200 bg-red-50 px-4 py-2 text-sm text-red-700 ${
            showMobileThread
              ? 'fixed bottom-24 start-4 end-4 z-50 shadow-lg lg:static lg:mb-3 lg:block'
              : 'mb-3'
          }`}
        >
          {actionError}
        </div>
      ) : null}

      <div className="chat-shell flex min-h-0 flex-1 overflow-hidden rounded-none border-0 shadow-none lg:rounded-3xl lg:border lg:border-[#3B7FC7]/20 lg:shadow-xl lg:shadow-[#3B7FC7]/10">
        <ChatContactsPanel
          contacts={displayedContacts}
          selectedUserId={selectedUserId}
          onSelect={handleSelectContact}
          isLoading={inboxLoading || (isSearching && isSearchingConversations)}
          isSearching={isSearching}
          searchValue={searchValue}
          onSearchChange={setSearchValue}
          newChatUsers={newChatUsers}
          onStartChat={handleStartChat}
          className={showMobileThread ? 'hidden lg:flex' : 'flex'}
          t={t}
        />

        <div
          className={`min-h-0 min-w-0 flex-1 flex-col ${
            showMobileThread ? 'flex' : 'hidden lg:flex'
          }`}
        >
          {isDualPane ? (
            <div className="flex shrink-0 gap-1 border-b border-[#3B7FC7]/20 bg-white px-2 py-1.5 lg:hidden dark:bg-slate-900">
              <button
                type="button"
                onClick={() => setDualMobileTab('asker')}
                className={`flex-1 rounded-lg px-3 py-2 text-xs font-semibold transition ${
                  dualMobileTab === 'asker'
                    ? 'bg-[#3B7FC7] text-white'
                    : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300'
                }`}
              >
                {t('chat.askerChat')}
              </button>
              <button
                type="button"
                onClick={() => setDualMobileTab('supplier')}
                className={`flex-1 rounded-lg px-3 py-2 text-xs font-semibold transition ${
                  dualMobileTab === 'supplier'
                    ? 'bg-[#619d51] text-white'
                    : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300'
                }`}
              >
                {t('chat.supplierChat')}
              </button>
            </div>
          ) : null}

          <div
            className={`flex min-h-0 flex-1 ${
              isDualPane ? 'flex-col lg:flex-row' : 'flex-col'
            }`}
          >
            <ChatThreadPanel
              contact={selectedContact}
              messages={localMessages}
              myUserId={myUserId}
              isLoading={showThreadLoading}
              isRefreshing={threadFetching && localMessages.length > 0 && !isLoadingOlder}
              hasMore={hasMoreMessages}
              isLoadingOlder={isLoadingOlder}
              onLoadOlder={() => void handleLoadOlderMessages()}
              isLocked={isConversationLocked}
              lockAgentName={lockAgentName}
              supervisingAgentName={supervisingAgentName}
              supportSessions={supportSessions}
              canCloseConversation={
                hasPermission(PERMISSIONS.chatAccess) &&
                !isConversationLocked &&
                (Boolean(selectedContact?.isAssignedToMe) ||
                  (viewerIsSuperAdmin &&
                    Boolean(threadDetails?.activeAgentId ?? selectedContact?.assignedAgentId)))
              }
              isClosingConversation={isReleasingConversation}
              onCloseConversation={handleCloseConversation}
              onSendText={handleSendText}
              onSendImages={handleSendImages}
              onSendVoice={handleSendVoice}
              onSendVideo={handleSendVideo}
              onSendDocument={handleSendDocument}
              onSendLocation={handleSendLocation}
              onReply={(message) => {
                if (message.isDeleted || message.deliveryStatus === 'sending') return
                setReplyTo(message)
              }}
              onForward={(message) => {
                if (message.isDeleted || message.deliveryStatus === 'sending') return
                setForwardingMessage(message)
              }}
              onDeleteMessage={handleDeleteMessage}
              replyTo={replyTo}
              onCancelReply={() => setReplyTo(null)}
              forwardingMessage={isDualPane && dualMobileTab === 'supplier' ? null : forwardingMessage}
              forwardContacts={contacts}
              onForwardTo={handleForwardTo}
              onCloseForward={() => setForwardingMessage(null)}
              onBack={() => {
                handleCloseSecondaryPane()
                setSelectedContact(null)
              }}
              companyDisplay={companyDisplay}
              paneLabel={isDualPane ? t('chat.askerChat') : null}
              onChatWithSupplier={handleChatWithSupplier}
              className={
                isDualPane
                  ? dualMobileTab === 'asker'
                    ? 'flex min-h-0 flex-1'
                    : 'hidden min-h-0 flex-1 lg:flex'
                  : 'flex min-h-0 flex-1'
              }
              t={t}
            />

            {isDualPane ? (
              <div
                aria-hidden
                className="hidden w-1 shrink-0 self-stretch bg-[#3B7FC7]/55 lg:block dark:bg-[#7eb6ef]/70"
              />
            ) : null}

            {secondaryContact ? (
              <ChatThreadPanel
                contact={secondaryContact}
                messages={secondaryLocalMessages}
                myUserId={myUserId}
                isLoading={secondaryThreadLoading && secondaryLocalMessages.length === 0}
                isRefreshing={
                  secondaryThreadFetching &&
                  secondaryLocalMessages.length > 0 &&
                  !isSecondaryLoadingOlder
                }
                hasMore={secondaryHasMoreMessages}
                isLoadingOlder={isSecondaryLoadingOlder}
                onLoadOlder={() => void handleLoadOlderSecondaryMessages()}
                supportSessions={secondarySupportSessions}
                onSendText={handleSendSecondaryText}
                onSendImages={handleSendSecondaryImages}
                onSendVoice={handleSendSecondaryVoice}
                onSendVideo={handleSendSecondaryVideo}
                onSendDocument={handleSendSecondaryDocument}
                onSendLocation={handleSendSecondaryLocation}
                onReply={(message) => {
                  if (message.isDeleted || message.deliveryStatus === 'sending') return
                  setSecondaryReplyTo(message)
                }}
                onForward={(message) => {
                  if (message.isDeleted || message.deliveryStatus === 'sending') return
                  setForwardingMessage(message)
                }}
                onDeleteMessage={handleDeleteMessage}
                replyTo={secondaryReplyTo}
                onCancelReply={() => setSecondaryReplyTo(null)}
                forwardingMessage={
                  isDualPane && dualMobileTab === 'asker' ? null : forwardingMessage
                }
                forwardContacts={contacts}
                onForwardTo={handleForwardTo}
                onCloseForward={() => setForwardingMessage(null)}
                companyDisplay={secondaryCompanyDisplay}
                paneLabel={t('chat.supplierChat')}
                onClosePane={handleCloseSecondaryPane}
                className={
                  dualMobileTab === 'supplier'
                    ? 'flex min-h-0 flex-1'
                    : 'hidden min-h-0 flex-1 lg:flex'
                }
                t={t}
              />
            ) : null}
          </div>
        </div>
      </div>
    </div>
  )
}
