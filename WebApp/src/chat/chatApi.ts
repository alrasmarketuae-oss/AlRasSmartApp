import { api, ApiError } from '../lib/api'
import { API_BASE_URL, MEDIA_BASE_URL } from '../lib/config'

export const SUPPORT_ADMIN_ID = 'BD469D54-8B82-47F3-A1F0-E1C5D91DDEB0'
export const CHAT_PAGE_SIZE = 20

export const MessageType = { text: 1, voice: 2, image: 3, location: 4, video: 5, file: 6 } as const
export type ChatMessageType = (typeof MessageType)[keyof typeof MessageType]

export type ChatMessage = {
  messageId: string
  fromUserId: string
  toUserId: string
  messageType: ChatMessageType
  content: string
  sentAtUtc: string
  isEdited?: boolean
  isSeen?: boolean
  isDelivered?: boolean
  mediaMimeType?: string | null
  supportAgentId?: string | null
  supportAgentName?: string | null
  replyToMessageId?: string | null
  replyToPreview?: string | null
  replyToMessageType?: ChatMessageType | null
  isForwarded?: boolean
  isDeleted?: boolean
  /** client-only */
  status?: 'sending' | 'failed'
  localFile?: { url: string; name: string }
}

export type SupportSession = {
  agentUserId: string
  agentName: string
  assignedAtUtc: string
  releasedAtUtc?: string | null
  isActive: boolean
  customerUserId: string
}

export type Conversation = {
  messages: ChatMessage[]
  supportSessions: SupportSession[]
  activeAgentId?: string | null
  activeAgentName?: string | null
  hasMore: boolean
  nextBeforeMessageId?: string | null
}

export const sameId = (a?: string | null, b?: string | null) => !!a && !!b && a.toLowerCase() === b.toLowerCase()

export function normalizeMessage(raw: Record<string, unknown>): ChatMessage {
  return {
    ...(raw as unknown as ChatMessage),
    messageId: String(raw.messageId ?? raw.id ?? ''),
    messageType: Number(raw.messageType ?? 1) as ChatMessageType,
    content: String(raw.content ?? ''),
    sentAtUtc: String(raw.sentAtUtc ?? new Date().toISOString()),
  }
}

export async function fetchConversation(otherUserId: string, before?: string | null): Promise<Conversation> {
  const data = await api.get<Conversation>('/Chat/conversation', { query: { otherUserId, limit: CHAT_PAGE_SIZE, before: before ?? undefined } })
  return {
    messages: (data?.messages ?? []).map((m) => normalizeMessage(m as unknown as Record<string, unknown>)),
    supportSessions: data?.supportSessions ?? [],
    activeAgentId: data?.activeAgentId,
    activeAgentName: data?.activeAgentName,
    hasMore: !!data?.hasMore,
    nextBeforeMessageId: data?.nextBeforeMessageId ?? null,
  }
}

export async function sendChatMessage(toUserId: string, messageType: ChatMessageType, content: string, replyToMessageId?: string | null) {
  const data = await api.post<Record<string, unknown>>('/Chat/messages', { toUserId, messageType, content, ...(replyToMessageId ? { replyToMessageId } : {}) })
  return normalizeMessage(data)
}

export const deleteChatMessage = (messageId: string, scope: 'me' | 'everyone') =>
  api.post<{ message?: Record<string, unknown> }>(`/Chat/messages/${encodeURIComponent(messageId)}/delete`, { scope })

export const markSeen = (otherUserId: string) => api.post('/Chat/seen', { otherUserId }).catch(() => undefined)
export const markDelivered = (otherUserId: string) => api.post('/Chat/delivered', { otherUserId }).catch(() => undefined)
export const pingPresence = () => api.post('/Chat/presence', {}).catch(() => undefined)

type Presign = { uploadUrl: string; path: string; contentType?: string; requiredHeaders?: Record<string, string> }

const extensionOf = (file: File) => {
  const fromName = file.name.match(/\.[a-z0-9]+$/i)?.[0]?.toLowerCase()
  if (fromName) return fromName
  if (file.type.includes('webm')) return '.webm'
  if (file.type.includes('ogg')) return '.ogg'
  if (file.type.includes('mp4')) return file.type.startsWith('audio') ? '.m4a' : '.mp4'
  return ''
}

/** presign → PUT → confirm, falling back to multipart `/Chat/upload` (returns the message `content`). */
export async function uploadChatMedia(file: File, messageType: ChatMessageType): Promise<{ content: string; messageType: ChatMessageType }> {
  const kind = messageType === MessageType.image ? 'image' : messageType === MessageType.video ? 'video' : messageType === MessageType.voice ? 'voice' : 'file'
  try {
    const body = kind === 'image' ? {} : { extension: extensionOf(file), fileName: file.name, contentType: file.type }
    const presign = await api.post<Presign>(`/Chat/presign/${kind}`, body)
    const headers: Record<string, string> = { 'Content-Type': presign.contentType || file.type || 'application/octet-stream', ...(presign.requiredHeaders ?? {}) }
    const put = await fetch(presign.uploadUrl, { method: 'PUT', body: file, headers })
    if (!put.ok) throw new ApiError('upload failed', put.status, null)
    const confirmed = await api.post<{ content: string; messageType: number }>('/Chat/confirm-upload', {
      path: presign.path,
      messageType,
      fileName: file.name,
      sizeBytes: file.size,
    })
    return { content: confirmed.content, messageType: Number(confirmed.messageType ?? messageType) as ChatMessageType }
  } catch {
    const form = new FormData()
    form.append('MessageType', String(messageType))
    form.append('File', file)
    const uploaded = await api.upload<{ content: string; messageType: number }>('/Chat/upload', form)
    return { content: uploaded.content, messageType: Number(uploaded.messageType ?? messageType) as ChatMessageType }
  }
}

const API_ORIGIN = new URL(API_BASE_URL).origin

/** `/Chat/...` and `/api/...` stream from the API; everything else from the CDN. */
export function attachmentUrl(path: string) {
  const p = path.trim().replace(/\\/g, '/')
  if (/^https?:\/\//i.test(p)) return p
  if (/^\/?(chat|api)\//i.test(p)) return `${API_ORIGIN}/${p.replace(/^\/+/, '')}`
  return `${MEDIA_BASE_URL}/${p.replace(/^\/+/, '')}`
}

export function parseImages(content: string): string[] {
  const text = content.trim()
  if (text.startsWith('{')) {
    try {
      const parsed = JSON.parse(text) as { images?: string[] }
      if (Array.isArray(parsed.images)) return parsed.images.filter(Boolean)
    } catch {
      /* single path */
    }
  }
  return text ? [text] : []
}

export function parseFile(content: string): { path: string; name: string; size?: number } {
  const text = content.trim()
  if (text.startsWith('{')) {
    try {
      const parsed = JSON.parse(text) as { path?: string; name?: string; size?: number }
      if (parsed.path) return { path: parsed.path, name: parsed.name || parsed.path.split('/').pop() || 'file', size: parsed.size }
    } catch {
      /* bare path */
    }
  }
  return { path: text, name: text.split('/').pop() || 'file' }
}

export function parseLocation(content: string): { lat: number; lng: number; label?: string } | null {
  try {
    const parsed = JSON.parse(content) as { lat?: number; lng?: number; label?: string }
    if (typeof parsed.lat === 'number' && typeof parsed.lng === 'number') return { lat: parsed.lat, lng: parsed.lng, label: parsed.label }
  } catch {
    /* invalid */
  }
  return null
}

const ASK_MARKER = /ASK_FOR_PRICE_PRODUCT:\s*([0-9a-fA-F-]{36})/

/** Ask-for-price payload sent from product pages (see productLinks.askForPriceMessage). */
export function parseAskForPrice(content: string) {
  const match = content.match(ASK_MARKER) ?? content.match(/Product ID:\s*([0-9a-fA-F-]{36})/i)
  if (!match) return null
  const line = (key: string) => content.match(new RegExp(`^${key}:\\s*(.+)$`, 'im'))?.[1]?.trim() ?? ''
  return {
    productId: match[1],
    name: line('Product Name'),
    code: line('Product Code'),
    quantity: line('Quantity'),
    image: line('Image'),
  }
}

export function fileMessageType(file: File): ChatMessageType {
  if (file.type.startsWith('image/')) return MessageType.image
  if (file.type.startsWith('video/')) return MessageType.video
  if (file.type.startsWith('audio/')) return MessageType.voice
  return MessageType.file
}
