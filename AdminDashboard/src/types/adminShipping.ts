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
  postCount: number
  registrationDate: string
  fromCountryName: string
  fromPortName: string
  toCountryName: string
  toPortName: string
  routeSummary: string
}

export type AdminShippingProviderDetail = AdminShippingProvider & {
  fullName: string
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
  shipments: AdminShipmentLogItem[]
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
