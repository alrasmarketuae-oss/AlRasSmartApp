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
  updatedAt: string
}

export type UpdateSystemSettingsPayload = Omit<SystemSettings, 'updatedAt'>
