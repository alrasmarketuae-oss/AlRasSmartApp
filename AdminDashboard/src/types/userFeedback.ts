export type UserFeedbackStatus = 'Pending' | 'InReview' | 'Resolved' | 'Closed'

export type UserFeedbackType = 'Complaint' | 'Suggestion'

export type UserFeedbackItem = {
  id: string
  userId: string | null
  type: UserFeedbackType | string
  subject: string
  message: string
  orderReference: string | null
  fullName: string
  email: string | null
  phone: string | null
  language: string
  status: UserFeedbackStatus | string
  source: string | null
  createdAtUtc: string
  resolvedAtUtc: string | null
  adminNotes: string | null
  ageSeconds: number
}

export type UserFeedbackResponse = {
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  serverUtcNow?: string
  items: UserFeedbackItem[]
}

export type UserFeedbackFilters = {
  page?: number
  pageSize?: number
  search?: string
  status?: string
  type?: string
}

export function normalizeUserFeedbackItem(
  raw: Record<string, unknown>,
): UserFeedbackItem {
  return {
    id: String(raw.id ?? raw.Id ?? ''),
    userId: (raw.userId ?? raw.UserId ?? null) as string | null,
    type: String(raw.type ?? raw.Type ?? 'Complaint'),
    subject: String(raw.subject ?? raw.Subject ?? ''),
    message: String(raw.message ?? raw.Message ?? ''),
    orderReference: (raw.orderReference ?? raw.OrderReference ?? null) as string | null,
    fullName: String(raw.fullName ?? raw.FullName ?? ''),
    email: (raw.email ?? raw.Email ?? null) as string | null,
    phone: (raw.phone ?? raw.Phone ?? null) as string | null,
    language: String(raw.language ?? raw.Language ?? 'ar'),
    status: String(raw.status ?? raw.Status ?? 'Pending'),
    source: (raw.source ?? raw.Source ?? null) as string | null,
    createdAtUtc: String(raw.createdAtUtc ?? raw.CreatedAtUtc ?? ''),
    resolvedAtUtc: (raw.resolvedAtUtc ?? raw.ResolvedAtUtc ?? null) as string | null,
    adminNotes: (raw.adminNotes ?? raw.AdminNotes ?? null) as string | null,
    ageSeconds: Number(raw.ageSeconds ?? raw.AgeSeconds ?? 0),
  }
}
