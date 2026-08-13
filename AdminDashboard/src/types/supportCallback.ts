export type SupportCallbackStatus = 'Pending' | 'Contacted' | 'Closed'

export type SupportCallbackItem = {
  id: string
  userId: string | null
  fullName: string
  phone: string
  email: string
  question: string | null
  language: string
  status: SupportCallbackStatus | string
  source: string | null
  createdAtUtc: string
  contactedAtUtc: string | null
  adminNotes: string | null
  ageSeconds: number
}

export type SupportCallbacksResponse = {
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  serverUtcNow?: string
  items: SupportCallbackItem[]
}

export type SupportCallbacksFilters = {
  page?: number
  pageSize?: number
  search?: string
  status?: string
}

export function normalizeSupportCallbackItem(
  raw: Record<string, unknown>,
): SupportCallbackItem {
  return {
    id: String(raw.id ?? raw.Id ?? ''),
    userId: (raw.userId ?? raw.UserId ?? null) as string | null,
    fullName: String(raw.fullName ?? raw.FullName ?? ''),
    phone: String(raw.phone ?? raw.Phone ?? ''),
    email: String(raw.email ?? raw.Email ?? ''),
    question: (raw.question ?? raw.Question ?? null) as string | null,
    language: String(raw.language ?? raw.Language ?? 'ar'),
    status: String(raw.status ?? raw.Status ?? 'Pending'),
    source: (raw.source ?? raw.Source ?? null) as string | null,
    createdAtUtc: String(raw.createdAtUtc ?? raw.CreatedAtUtc ?? ''),
    contactedAtUtc: (raw.contactedAtUtc ?? raw.ContactedAtUtc ?? null) as string | null,
    adminNotes: (raw.adminNotes ?? raw.AdminNotes ?? null) as string | null,
    ageSeconds: Number(raw.ageSeconds ?? raw.AgeSeconds ?? 0),
  }
}
