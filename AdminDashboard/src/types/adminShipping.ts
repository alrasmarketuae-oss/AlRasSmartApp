export type AdminShippingStats = {
  totalShipments: number
  completed: number
  inDelivery: number
  late: number
  successRate: number
}

export type AdminShipmentLogItem = {
  id: number
  shipmentCode: string
  orderId: number
  statusId: number
  statusName: string
  statusLabelAr: string
  createdAt: string
}

export type AdminShippingProvider = {
  id: string
  companyName: string
  imgPath: string | null
  email: string
  phoneNumber: string | null
  cityName: string | null
  isActive: boolean
  totalShipments: number
  phoneRevealCount: number
  postCount: number
  registrationDate: string
  fromCountryName: string
  fromPortName: string
  toCountryName: string
  toPortName: string
  routeSummary: string
}

export type AdminShippingPhoneRevealViewer = {
  viewerUserId: string
  viewerName: string
  viewerEmail: string | null
  viewerPhone: string | null
  revealCount: number
}

export type AdminShippingPostItem = {
  id: number
  fromCountryName: string
  fromCountryNameAr: string | null
  fromPortName: string
  fromPortUnLocode: string | null
  toCountryName: string
  toCountryNameAr: string | null
  toPortName: string
  toPortUnLocode: string | null
  routeSummary: string
  routeSummaryAr: string
  container20ftPriceUsd: number | null
  container40ftPriceUsd: number | null
  container20ftPriceFormatted: string
  container40ftPriceFormatted: string
  phoneNumber: string | null
  details: string | null
  minDurationDays: number | null
  maxDurationDays: number | null
  status: number
  statusLabelAr: string
  isApproved: boolean
  canApprove: boolean
  createdAt: string
}

export type AdminShippingProviderDetail = AdminShippingProvider & {
  fullName: string
  landNumber: string | null
  commercialRegister: string | null
  taxNumber: string | null
  website: string | null
  fromCountryId: number
  fromPortId: number
  toCountryId: number
  toPortId: number
  fromCountryNameAr: string | null
  fromPortUnLocode: string | null
  toCountryNameAr: string | null
  toPortUnLocode: string | null
  routeSummaryAr: string
  container20ftPriceUsd: number
  container40ftPriceUsd: number
  container20ftPriceFormatted: string
  container40ftPriceFormatted: string
  registrationLinkSent: boolean
  stats: AdminShippingStats
  phoneRevealCount: number
  phoneRevealsByViewer: AdminShippingPhoneRevealViewer[]
  shipments: AdminShipmentLogItem[]
  posts: AdminShippingPostItem[]
  latestPostId: number
  postStatus: number
  postStatusLabelAr: string
  isPostApproved: boolean
  canApprovePost: boolean
}

export type AdminShippingProvidersResponse = {
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  items: AdminShippingProvider[]
}

export type AdminShippingFilters = {
  page?: number
  pageSize?: number
  search?: string
}
