export type MissedProductSearchItem = {
  id: string
  queryText: string
  userId: string | null
  userDisplayName: string | null
  userEmail: string | null
  userPhone: string | null
  notes: string | null
  createdAtUtc: string
  ageSeconds: number
}

export type MissedProductSearchesResponse = {
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  serverUtcNow: string
  items: MissedProductSearchItem[]
}

export type MissedProductSearchesFilters = {
  page?: number
  pageSize?: number
  search?: string
  fromUtc?: string
  toUtc?: string
}
