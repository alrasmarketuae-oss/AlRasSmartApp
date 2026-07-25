export type AdminPermissionDefinition = {
  key: string
  labelAr: string
  labelEn: string
  groupKey: string
  groupLabelAr: string
  groupLabelEn: string
}

export type AdminEmployee = {
  id: string
  fullName: string
  email: string
  phoneNumber: string | null
  isActive: boolean
  permissions: string[]
  createdAt: string
}

export type AdminEmployeeDetail = AdminEmployee

export type AdminEmployeesResponse = {
  items: AdminEmployee[]
  totalCount: number
  page: number
  pageSize: number
  totalPages: number
}

export type CreateEmployeePayload = {
  fullName: string
  email: string
  password: string
  phoneNumber?: string
  permissions: string[]
}

export type UpdateEmployeePayload = {
  fullName: string
  phoneNumber?: string
  isActive: boolean
  permissions: string[]
  newPassword?: string
}
