export type ChatMessageType = 'Text' | 'Voice' | 'Image' | 'Location'

export type ChatMessageTypeCode = 1 | 2 | 3 | 4 | 5

export type ChatContact = {
  contactUserId: string
  displayName: string
  avatarUrl: string | null
  lastMessagePreview: string | null
  lastMessageType: string | null
  lastMessageRelativeTime: string | null
  lastMessageSentAtUtc: string | null
  unreadCount: number
  contactLastSeenAtUtc: string | null
  isOnline: boolean
  assignedAgentId?: string | null
  assignedAgentName?: string | null
  isAssignedToMe?: boolean
  isLockedByOtherAgent?: boolean
}

export type ChatSupportAssignment = {
  customerUserId: string
  assignedAgentId: string | null
  assignedAgentName: string | null
  isAssignedToMe: boolean
  isLockedByOtherAgent: boolean
  assignedAtUtc: string | null
}

export type ChatSupportSession = {
  agentUserId: string
  agentName: string
  assignedAtUtc: string
  releasedAtUtc: string | null
  isActive: boolean
}

export type ChatConversationDetails = {
  messages: ChatMessage[]
  supportSessions: ChatSupportSession[]
  activeAgentId: string | null
  activeAgentName: string | null
}

export type ChatDeliveryStatus = 'sending' | 'sent' | 'failed'

export type ChatMessage = {
  messageId: string
  fromUserId: string
  toUserId: string
  messageType: ChatMessageTypeCode
  content: string
  sentAtUtc: string
  relativeTime: string
  isEdited: boolean
  isSeen: boolean
  seenAtUtc: string | null
  isDelivered: boolean
  deliveredAtUtc: string | null
  /** MIME type for voice messages (from server content sniffing). */
  mediaMimeType?: string | null
  /** Outgoing message still uploading / not confirmed by server */
  deliveryStatus?: ChatDeliveryStatus
  /** Local blob URL for optimistic image/voice preview */
  localPreviewUrl?: string
  localPreviewMime?: string
  supportAgentId?: string | null
  supportAgentName?: string | null
}

export type ChatInbox = {
  contacts: ChatContact[]
  myLastSeenAtUtc: string | null
  totalUnreadCount: number
  fromCache: boolean
}

export type ChatUnreadSummary = {
  totalUnread: number
}

export type ChatPresence = {
  userId: string
  lastSeenAtUtc: string | null
  isOnline: boolean
}

export type ChatLocationContent = {
  lat: number
  lng: number
  label?: string
}

export type SendChatMessagePayload = {
  toUserId: string
  messageType: ChatMessageTypeCode
  content: string
}

export type ChatUploadResult = {
  content: string
  messageType: ChatMessageTypeCode
  mediaMimeType?: string | null
}

export type ChatUploadImagesResult = {
  paths: string[]
  content: string
  messageType: ChatMessageTypeCode
}

export type ChatMessagesDeliveredPayload = {
  fromUserId: string
  toUserId: string
  messageIds: string[]
  deliveredAtUtc: string
  markedCount: number
}

export type ConversationSeenPayload = {
  viewerUserId: string
  otherUserId: string
  seenAtUtc: string
  markedCount: number
}

export function messageTypeLabel(type: ChatMessageTypeCode | string): string {
  switch (type) {
    case 1:
    case 'Text':
      return 'نص'
    case 2:
    case 'Voice':
      return 'صوت'
    case 3:
    case 'Image':
      return 'صورة'
    case 4:
    case 'Location':
      return 'موقع'
    case 5:
    case 'Video':
      return 'فيديو'
    default:
      return 'رسالة'
  }
}

export function parseLocationContent(content: string): ChatLocationContent | null {
  try {
    const parsed = JSON.parse(content) as ChatLocationContent
    if (typeof parsed.lat === 'number' && typeof parsed.lng === 'number') {
      return parsed
    }
    return null
  } catch {
    return null
  }
}

export function parseImageContent(content: string): string[] {
  const trimmed = content.trim()
  if (!trimmed) return []

  if (trimmed.startsWith('{') && trimmed.includes('"images"')) {
    try {
      const parsed = JSON.parse(trimmed) as { images?: unknown }
      if (Array.isArray(parsed.images)) {
        return parsed.images.filter((item): item is string => typeof item === 'string' && item.length > 0)
      }
    } catch {
      return []
    }
  }

  if (trimmed.startsWith('/chat-images/')) {
    return [trimmed]
  }

  if (trimmed.startsWith('blob:')) {
    return [trimmed]
  }

  return [trimmed]
}

export function normalizeChatMessage(raw: Partial<ChatMessage> & Record<string, unknown>): ChatMessage {
  return {
    messageId: String(raw.messageId ?? ''),
    fromUserId: String(raw.fromUserId ?? ''),
    toUserId: String(raw.toUserId ?? ''),
    messageType: Number(raw.messageType ?? 1) as ChatMessageTypeCode,
    content: String(raw.content ?? ''),
    sentAtUtc: String(raw.sentAtUtc ?? new Date().toISOString()),
    relativeTime: String(raw.relativeTime ?? ''),
    isEdited: Boolean(raw.isEdited),
    isSeen: Boolean(raw.isSeen),
    seenAtUtc: raw.seenAtUtc ? String(raw.seenAtUtc) : null,
    isDelivered: Boolean(raw.isDelivered),
    deliveredAtUtc: raw.deliveredAtUtc ? String(raw.deliveredAtUtc) : null,
    mediaMimeType: raw.mediaMimeType ? String(raw.mediaMimeType) : null,
    supportAgentId: (raw.supportAgentId ?? raw.SupportAgentId ?? null) as string | null,
    supportAgentName: (raw.supportAgentName ?? raw.SupportAgentName ?? null) as string | null,
  }
}

export function normalizeChatSupportSession(
  raw: Record<string, unknown>,
): ChatSupportSession {
  return {
    agentUserId: String(raw.agentUserId ?? raw.AgentUserId ?? ''),
    agentName: String(raw.agentName ?? raw.AgentName ?? ''),
    assignedAtUtc: String(raw.assignedAtUtc ?? raw.AssignedAtUtc ?? ''),
    releasedAtUtc: (raw.releasedAtUtc ?? raw.ReleasedAtUtc ?? null) as string | null,
    isActive: Boolean(raw.isActive ?? raw.IsActive),
  }
}

export function normalizeChatConversationDetails(
  raw: Record<string, unknown>,
): ChatConversationDetails {
  const messagesRaw = (raw.messages ?? raw.Messages ?? []) as Array<Record<string, unknown>>
  const sessionsRaw = (raw.supportSessions ?? raw.SupportSessions ?? []) as Array<
    Record<string, unknown>
  >

  return {
    messages: messagesRaw.map((message) => normalizeChatMessage(message)),
    supportSessions: sessionsRaw.map((session) => normalizeChatSupportSession(session)),
    activeAgentId: (raw.activeAgentId ?? raw.ActiveAgentId ?? null) as string | null,
    activeAgentName: (raw.activeAgentName ?? raw.ActiveAgentName ?? null) as string | null,
  }
}
