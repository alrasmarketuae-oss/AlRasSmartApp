import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import ChatContactsPanel from '../components/chat/ChatContactsPanel'
import ChatThreadPanel from '../components/chat/ChatThreadPanel'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { useChat } from '../context/ChatProvider'
import { useDebouncedValue } from '../hooks/useDebouncedValue'
import { getAuthUser, getChatWrapSecret, saveChatWrapSecret } from '../lib/authStorage'
import { hasPermission, isSuperAdmin, PERMISSIONS } from '../lib/permissions'
import {
  createOptimisticMessageId,
  mergeThreadWithPending,
  revokeMessagePreview,
} from '../lib/chatOptimistic'
import {
  decryptChatPayload,
  encryptChatPayload,
  ensureSupportE2eKeys,
  isChatE2eEnvelope,
  resolveChatKeyWrapSecrets,
} from '../lib/chatE2e'
import {
  useGetChatInboxQuery,
  useGetChatConversationDetailsQuery,
  useGetUsersQuery,
  useMarkChatSeenMutation,
  useMarkChatDeliveredMutation,
  useSearchChatConversationsQuery,
  useSendChatMessageMutation,
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
import { getRtkErrorMessage } from '../utils/rtkError'

type OpenChatWithState = {
  openChatWith?: {
    userId: string
    displayName: string
    avatarUrl?: string | null
  }
}

export default function ChatPage() {
  const { t } = useAppPreferences()
  const dispatch = useAppDispatch()
  const location = useLocation()
  const navigate = useNavigate()
  const { subscribeReceiveMessage, subscribeMessageUpdated, subscribeConversationSeen, subscribeMessagesDelivered } = useChat()
  const authUser = getAuthUser()
  const myUserId = authUser?.id ?? null
  const viewerIsSuperAdmin = isSuperAdmin(authUser?.roleName)

  const [selectedContact, setSelectedContact] = useState<ChatContact | null>(null)
  const [searchValue, setSearchValue] = useState('')
  const [localMessages, setLocalMessages] = useState<ChatMessage[]>([])
  const [actionError, setActionError] = useState<string | null>(null)
  const [isConversationLocked, setIsConversationLocked] = useState(false)
  const [lockAgentName, setLockAgentName] = useState<string | null>(null)
  const [supervisingAgentName, setSupervisingAgentName] = useState<string | null>(null)

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
    pollingInterval: 10_000,
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

  const {
    data: threadDetails,
    isLoading: threadLoading,
    isFetching: threadFetching,
  } = useGetChatConversationDetailsQuery(selectedUserId ?? '', {
    skip: !selectedUserId || (isConversationLocked && !viewerIsSuperAdmin),
    pollingInterval: 10_000,
    ...liveQueryOptions,
  })

  const supportSessions = threadDetails?.supportSessions ?? []

  const [sendMessage] = useSendChatMessageMutation()
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
    let cancelled = false
    async function hydrate() {
      const source = threadDetails?.messages ?? []
      const decrypted: ChatMessage[] = []
      for (const m of source) {
        decrypted.push(await decryptForDisplay(m))
      }
      if (cancelled) return
      setLocalMessages((prev) =>
        mergeThreadWithPending(decrypted, prev, selectedUserId, myUserId),
      )
    }
    void hydrate()
    return () => {
      cancelled = true
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [threadDetails?.messages, selectedUserId, myUserId])

  useEffect(() => {
    if (!selectedUserId) return
    if (isConversationLocked) return
    void markDelivered({ otherUserId: selectedUserId }).catch(() => undefined)
    void markSeen({ otherUserId: selectedUserId }).catch(() => undefined)
  }, [selectedUserId, isConversationLocked, markSeen, markDelivered, localMessages.length])

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

  const replaceOptimisticMessage = useCallback(
    (optimisticId: string, confirmed: ChatMessage) => {
      setLocalMessages((prev) => {
        const optimistic = prev.find((message) => message.messageId === optimisticId)
        if (optimistic) {
          revokeMessagePreview(optimistic)
        }
        return prev
          .filter((message) => message.messageId !== optimisticId)
          .concat(confirmed)
          .sort((a, b) => a.sentAtUtc.localeCompare(b.sentAtUtc))
      })
    },
    [],
  )

  const markOptimisticFailed = useCallback((optimisticId: string) => {
    setLocalMessages((prev) =>
      prev.map((message) =>
        message.messageId === optimisticId
          ? { ...message, deliveryStatus: 'failed', relativeTime: t('chat.failed') }
          : message,
      ),
    )
  }, [t])

  useEffect(() => {
    return subscribeReceiveMessage((message) => {
      const currentOther = selectedUserIdRef.current
      if (
        currentOther &&
        (message.fromUserId === currentOther || message.toUserId === currentOther)
      ) {
        void decryptForDisplay(message).then((decoded) => {
          mergeMessage(decoded)
          if (decoded.fromUserId === currentOther) {
            void markDelivered({ otherUserId: decoded.fromUserId }).catch(() => undefined)
            void markSeen({ otherUserId: decoded.fromUserId }).catch(() => undefined)
          }
        })
      }
    })
  }, [subscribeReceiveMessage, mergeMessage, markSeen, markDelivered])

  useEffect(() => {
    return subscribeConversationSeen((payload) => {
      // Customer (viewer) read our support messages — match by selected contact.
      const currentOther = selectedUserIdRef.current
      if (!currentOther) return
      if (payload.viewerUserId.toLowerCase() !== currentOther.toLowerCase()) return

      setLocalMessages((prev) =>
        prev.map((message) =>
          message.toUserId.toLowerCase() === currentOther.toLowerCase()
            ? { ...message, isSeen: true, isDelivered: true, seenAtUtc: payload.seenAtUtc }
            : message,
        ),
      )
    })
  }, [subscribeConversationSeen])

  useEffect(() => {
    return subscribeMessagesDelivered((payload) => {
      const deliveredSet = new Set(payload.messageIds)
      if (deliveredSet.size === 0) return

      setLocalMessages((prev) =>
        prev.map((message) =>
          deliveredSet.has(message.messageId)
            ? { ...message, isDelivered: true, deliveredAtUtc: payload.deliveredAtUtc }
            : message,
        ),
      )
    })
  }, [subscribeMessagesDelivered])

  useEffect(() => {
    return subscribeMessageUpdated((message) => {
      mergeMessage(message)
    })
  }, [subscribeMessageUpdated, mergeMessage])

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

  function pushOptimisticMessage(
    messageType: ChatMessageTypeCode,
    content: string,
    localPreviewUrl?: string,
    localPreviewMime?: string,
  ): string {
    if (!selectedUserId || !myUserId) return ''

    const optimisticId = createOptimisticMessageId()
    const optimistic: ChatMessage = {
      messageId: optimisticId,
      fromUserId: myUserId,
      toUserId: selectedUserId,
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
    }

    mergeMessage(optimistic)
    return optimisticId
  }

  async function handleSend(messageType: ChatMessageTypeCode, content: string, optimisticId: string) {
    if (!selectedUserId) return
    setActionError(null)

    try {
      let wireContent = content
      try {
        const e2e = await ensureE2eReady()
        if (e2e.supportUserId && e2e.publicKeyJwk) {
          const peer = await fetchPublicKey(selectedUserId).unwrap()
          if (peer.publicKeySpkiBase64) {
            wireContent = await encryptChatPayload({
              plaintext: content,
              myUserId: e2e.supportUserId,
              peerUserId: selectedUserId,
              myPublicKeyJwk: e2e.publicKeyJwk,
              peerPublicKeyJwk: peer.publicKeySpkiBase64,
            })
          }
        }
      } catch {
        wireContent = content
      }

      const result = await sendMessage({
        toUserId: selectedUserId,
        messageType,
        content: wireContent,
      }).unwrap()
      replaceOptimisticMessage(optimisticId, { ...result, content })
      await invalidateChatCaches(selectedUserId)
    } catch (err) {
      markOptimisticFailed(optimisticId)
      setActionError(getRtkErrorMessage(err as never, t('chat.sendError')))
    }
  }

  async function handleSendText(text: string) {
    if (!selectedUserId) return
    const optimisticId = pushOptimisticMessage(1, text)
    await handleSend(1, text, optimisticId)
  }

  async function handleSendImages(files: File[]) {
    if (!selectedUserId || files.length === 0) return
    setActionError(null)

    const previewUrl = files.length === 1 ? URL.createObjectURL(files[0]) : undefined
    const optimisticId = pushOptimisticMessage(3, previewUrl ?? `${files.length} images`, previewUrl)

    try {
      const upload = files.length === 1
        ? await uploadMedia({ file: files[0], messageType: 3 }).unwrap()
        : await uploadImages({ files }).unwrap()
      await handleSend(3, upload.content, optimisticId)
    } catch (err) {
      markOptimisticFailed(optimisticId)
      setActionError(getRtkErrorMessage(err as never, t('chat.uploadError')))
    }
  }

  async function handleSendVoice(file: File) {
    if (!selectedUserId) return
    setActionError(null)

    const previewUrl = URL.createObjectURL(file)
    const optimisticId = pushOptimisticMessage(2, previewUrl, previewUrl, file.type || undefined)

    try {
      const upload = await uploadMedia({ file, messageType: 2 }).unwrap()
      await handleSend(2, upload.content, optimisticId)
    } catch (err) {
      markOptimisticFailed(optimisticId)
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
    const optimisticId = pushOptimisticMessage(5, previewUrl, previewUrl, file.type || undefined)

    try {
      const upload = await uploadMedia({ file, messageType: 5 }).unwrap()
      await handleSend(5, upload.content, optimisticId)
    } catch (err) {
      markOptimisticFailed(optimisticId)
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
    const optimisticId = pushOptimisticMessage(6, placeholder)

    try {
      const upload = await uploadMedia({ file, messageType: 6 }).unwrap()
      await handleSend(6, upload.content, optimisticId)
    } catch (err) {
      markOptimisticFailed(optimisticId)
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
          const optimisticId = pushOptimisticMessage(4, payload)
          await handleSend(4, payload, optimisticId)
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

  async function handleSelectContact(contact: ChatContact) {
    setActionError(null)

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

  async function handleCloseConversation() {
    if (!selectedUserId || !hasPermission(PERMISSIONS.chatAccess)) return
    setActionError(null)

    try {
      await releaseSupportConversation({ otherUserId: selectedUserId }).unwrap()
      setSelectedContact(null)
      setLocalMessages([])
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
        <ChatThreadPanel
          contact={selectedContact}
          messages={localMessages}
          myUserId={myUserId}
          isLoading={showThreadLoading}
          isRefreshing={threadFetching && localMessages.length > 0}
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
          onBack={() => setSelectedContact(null)}
          className={showMobileThread ? 'flex' : 'hidden lg:flex'}
          t={t}
        />
      </div>
    </div>
  )
}
