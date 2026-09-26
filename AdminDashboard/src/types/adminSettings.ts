export type CategoryCommission = {
  categoryId: number
  nameEn: string
  nameAr?: string
  commissionPercent: number
}

export type SystemSettings = {
  retailCommissionPercent: number
  bookingCommissionPercent: number
  requestsCommissionPercent: number
  offersCommissionPercent: number
  shippingCommissionPercent: number
  categoryCommissions: CategoryCommission[]
  appName: string
  supportEmail: string | null
  phoneNumber: string | null
  landlineNumber: string | null
  timezone: string | null
  address: string | null
  featuredAdPriceAed: number
  adDisplayDurationDays: number
  androidLatestVersion: string | null
  iosLatestVersion: string | null
  androidMinVersion: string | null
  iosMinVersion: string | null
  androidStoreUrl: string | null
  iosStoreUrl: string | null
  appUpdateMessageAr: string | null
  appUpdateMessageEn: string | null
  updatedAt: string
}

export type UpdateSystemSettingsPayload = Omit<SystemSettings, 'updatedAt'>
