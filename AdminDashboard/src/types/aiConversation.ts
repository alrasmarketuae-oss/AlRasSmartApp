export type AiConversationListItem = {
  id: string
  userId: string
  clientSessionId: string
  titlePreview: string | null
  lastMessageAtUtc: string
  messageCount: number
  companyName: string | null
  contactFullName: string | null
  companyImageUrl: string | null
}

export type AiConversationMessage = {
  id: number
  role: 'user' | 'assistant'
  content: string
  language: string
  usedKnowledge: boolean | null
  sources: string[] | null
  createdAtUtc: string
}

export type AiConversationMessagesPage = {
  messages: AiConversationMessage[]
  hasMore: boolean
  nextBeforeMessageId: number | null
}

export type AiConversationListPage = {
  items: AiConversationListItem[]
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
}

export type AiConversationReportRequest = {
  conversationId: string
  language: 'ar' | 'en'
}

function readString(raw: unknown, fallback = ''): string {
  return raw == null ? fallback : String(raw)
}

export function normalizeAiConversationListItem(
  raw: Record<string, unknown>,
): AiConversationListItem {
  return {
    id: readString(raw.id ?? raw.Id),
    userId: readString(raw.userId ?? raw.UserId),
    clientSessionId: readString(raw.clientSessionId ?? raw.ClientSessionId),
    titlePreview: (raw.titlePreview ?? raw.TitlePreview ?? null) as string | null,
    lastMessageAtUtc: readString(raw.lastMessageAtUtc ?? raw.LastMessageAtUtc),
    messageCount: Number(raw.messageCount ?? raw.MessageCount ?? 0),
    companyName: (raw.companyName ?? raw.CompanyName ?? null) as string | null,
    contactFullName: (raw.contactFullName ?? raw.ContactFullName ?? null) as string | null,
    companyImageUrl: (raw.companyImageUrl ?? raw.CompanyImageUrl ?? null) as string | null,
  }
}

export function normalizeAiConversationMessage(
  raw: Record<string, unknown>,
): AiConversationMessage {
  const roleRaw = readString(raw.role ?? raw.Role, 'user').toLowerCase()
  const sourcesRaw = raw.sources ?? raw.Sources
  return {
    id: Number(raw.id ?? raw.Id ?? 0),
    role: roleRaw === 'assistant' ? 'assistant' : 'user',
    content: readString(raw.content ?? raw.Content),
    language: readString(raw.language ?? raw.Language, 'en'),
    usedKnowledge:
      raw.usedKnowledge != null || raw.UsedKnowledge != null
        ? Boolean(raw.usedKnowledge ?? raw.UsedKnowledge)
        : null,
    sources: Array.isArray(sourcesRaw)
      ? sourcesRaw.map((item) => String(item))
      : null,
    createdAtUtc: readString(raw.createdAtUtc ?? raw.CreatedAtUtc),
  }
}

export function normalizeAiConversationMessagesPage(
  raw: Record<string, unknown>,
): AiConversationMessagesPage {
  const messagesRaw = (raw.messages ?? raw.Messages ?? []) as Array<Record<string, unknown>>
  const next = raw.nextBeforeMessageId ?? raw.NextBeforeMessageId
  return {
    messages: messagesRaw.map((item) => normalizeAiConversationMessage(item)),
    hasMore: Boolean(raw.hasMore ?? raw.HasMore),
    nextBeforeMessageId: next == null ? null : Number(next),
  }
}

export function normalizeAiConversationListPage(
  raw: Record<string, unknown>,
): AiConversationListPage {
  const itemsRaw = (raw.items ?? raw.Items ?? []) as Array<Record<string, unknown>>
  return {
    items: itemsRaw.map((item) => normalizeAiConversationListItem(item)),
    page: Number(raw.page ?? raw.Page ?? 1),
    pageSize: Number(raw.pageSize ?? raw.PageSize ?? 20),
    totalCount: Number(raw.totalCount ?? raw.TotalCount ?? 0),
    totalPages: Number(raw.totalPages ?? raw.TotalPages ?? 1),
  }
}
