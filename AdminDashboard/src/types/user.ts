export type AdminUser = {
  id: string
  fullName: string
  email: string
  phoneNumber: string | null
  roleId: number
  roleName: string
  roleLabelAr: string
  typeLabelAr: string
  statusLabelAr: string
  isActive: boolean
  isVerified: boolean
  isCustomer: boolean
  isRejected?: boolean
  hasPendingProfileChanges?: boolean
  canApprove?: boolean
  createdAt: string
  imgPath: string | null
  companyName: string | null
  ordersCount: number
}

export type AdminUsersResponse = {
  Page?: number
  PageSize?: number
  TotalCount?: number
  TotalPages?: number
  Items?: AdminUser[]
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  items: AdminUser[]
}
