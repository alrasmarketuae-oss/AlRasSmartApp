export type AdminUserCompanyImage = {
  id: number
  imagePath: string
  isPrimary: boolean
}

export type AdminUserAddress = {
  addressId: string
  addressTypeId: number
  addressTypeNameEn: string
  addressTypeNameAr: string
  formattedAddress: string
  postalCode: string | null
  latitude: number | null
  longitude: number | null
  coordinates: string | null
  mapsUrl: string | null
}

export type PendingCompanyProfileChanges = {
  companyName: string | null
  commercialRegister: string | null
  taxNumber: string | null
  website: string | null
  landNumber: string | null
  fullName: string | null
  phoneNumber: string | null
  licencePath: string | null
  companyImagesChanged: boolean
  companyImagePaths: string[]
}

export type RegistrationCompletionRequest = {
  missingLocation: boolean
  missingImages: boolean
  missingDocuments: boolean
  message: string | null
  requestedAtUtc: string
}

export type AdminShippingPhoneRevealCompany = {
  companyUserId: string
  companyName: string
  revealCount: number
}

export type AdminShippingPhoneRevealViewer = {
  viewerUserId: string
  viewerName: string
  viewerEmail: string | null
  viewerPhone: string | null
  revealCount: number
}

export type AdminUserDetail = {
  id: string
  fullName: string
  fullNameEn?: string | null
  fullNameAr?: string | null
  email: string
  phoneNumber: string | null
  landNumber: string | null
  preferredLanguage?: string | null
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
  website: string | null
  pendingProfileChanges: PendingCompanyProfileChanges | null
  registrationCompletionRequest: RegistrationCompletionRequest | null
  companyImages: AdminUserCompanyImage[]
  addresses: AdminUserAddress[]
  ordersCount: number
  productsCount: number
  shippingPhoneRevealCount: number
  shippingPhoneRevealsByCompany: AdminShippingPhoneRevealCompany[]
  shippingPhoneRevealsByViewer: AdminShippingPhoneRevealViewer[]
  canApprove: boolean
  canDeactivate: boolean
  canDelete: boolean
  canConvertToSupplier: boolean
  canConvertToCompanyCustomer: boolean
}
