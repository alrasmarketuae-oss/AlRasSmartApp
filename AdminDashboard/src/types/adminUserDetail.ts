export type AdminUserCompanyImage = {
  id: number
  imagePath: string
  isPrimary: boolean
}

export type PendingCompanyProfileChanges = {
  companyName: string | null
  commercialRegister: string | null
  taxNumber: string | null
  landNumber: string | null
  fullName: string | null
  phoneNumber: string | null
}

export type AdminUserDetail = {
  id: string
  fullName: string
  fullNameEn?: string | null
  fullNameAr?: string | null
  email: string
  phoneNumber: string | null
  landNumber: string | null
  roleId: number
  roleName: string
  roleLabelAr: string
  typeLabelAr: string
  statusLabelAr: string
  isActive: boolean
  isVerified: boolean
  isCustomer: boolean
  isRejected: boolean
  rejectionReason: string | null
  createdAt: string
  imgPath: string | null
  companyName: string | null
  companyNameEn?: string | null
  companyNameAr?: string | null
  licenseNumber: string | null
  licencePath: string | null
  commercialRegister: string | null
  taxNumber: string | null
  pendingProfileChanges: PendingCompanyProfileChanges | null
  companyImages: AdminUserCompanyImage[]
  ordersCount: number
  canApprove: boolean
  canDeactivate: boolean
  canDelete: boolean
}
