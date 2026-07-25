export type AdminAuditLogItem = {
  id: string
  actorUserId: string
  actorName: string
  action: string
  entityType: string
  entityId: string | null
  summary: string
  detailsJson: string | null
  createdAtUtc: string
  ageSeconds: number
}

export type AdminAuditLogsResponse = {
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  serverUtcNow: string
  items: AdminAuditLogItem[]
}

export type AdminAuditLogsFilters = {
  page?: number
  pageSize?: number
  search?: string
  action?: string
  entityType?: string
  fromUtc?: string
  toUtc?: string
}
