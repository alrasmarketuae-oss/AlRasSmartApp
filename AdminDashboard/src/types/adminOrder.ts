export type AdminOrderImage = {
  id: number
  path: string
}

export type AdminOrderVideo = {
  id: number
  path: string
}

export type AdminOrderStatusHistory = {
  id: number
  statusId: number
  statusNameEn: string
  statusNameAr: string
  createdAtUtc: string
}

export type AdminOrder = {
  id: number
  productId: string
  customerName: string
  customerNameEn?: string | null
  customerNameAr?: string | null
  customerEmail: string
  customerPhone: string | null
  customerUserId?: string | null
  supplierName: string
  supplierNameEn?: string | null
  supplierNameAr?: string | null
  supplierEmail: string
  supplierPhone: string | null
  supplierUserId?: string | null
  supplierAvatarPath?: string | null
  productName: string
  productDescription: string | null
  productTypeName: string
  /** Product Local / Rexport price type. */
  requestTypeId?: number | null
  requestTypeName?: string | null
  negotiable?: boolean | null
  offerDuration?: string | null
  packaging?: number | null
  packagingDetails?: string | null
  /** Cart/hybrid retail channel. False for wholesale category Purchase Orders. */
  isRetailPurchase?: boolean
  categoryName: string
  categoryId?: number | null
  primaryImagePath: string | null
  unitName: string
  statusId: number
  statusName: string
  statusLabelAr: string
  unitPrice: number
  totalPrice: number
  amountFormatted: string
  currency: string
  commissionPercent: number
  supplierUnitPrice: number
  supplierTotalPrice: number
  customerUnitPrice: number
  customerTotalPrice: number
  appProfitAmount: number
  chargedUnitPrice: number
  chargedTotalPrice: number
  supplierUnitPriceFormatted: string
  supplierTotalPriceFormatted: string
  customerUnitPriceFormatted: string
  customerTotalPriceFormatted: string
  appProfitFormatted: string
  listingUnitPrice?: number
  listingUnitPriceFormatted?: string
  isBelowListingPrice?: boolean
  hasAdminAdvertiserPrice?: boolean
  adminAdvertiserUnitPrice?: number | null
  adminAdvertiserTotalPrice?: number | null
  adminAdvertiserUnitPriceFormatted?: string
  adminAdvertiserTotalPriceFormatted?: string
  quantity: number
  requestedQuantity: number
  productAvailableQuantity?: number | null
  /** Views count of the related product/ad. */
  productViewsCount?: number
  paymentMethod: number
  paymentMethodName: string
  createdAt: string
  isApproved: boolean
  isAdminApproved: boolean
  notes: string | null
  videoPaths: string[]
  videos: AdminOrderVideo[]
  images: AdminOrderImage[]
  documentPaths: string[]
  productImagePaths: string[]
  productDocumentPaths: string[]
  portId: number | null
  portName: string | null
  portCountryName: string | null
  originCountryName: string
  destinationCountryName: string
  loadingPortName: string
  arrivalPortName: string
  shippingDescription: string
  shippingRouteSummary: string
  shippingDuration: string
  productAddress: string | null
  productLatitude: number | null
  productLongitude: number | null
  vatAed: number
  shippingCostAed: number
  isSelfPickup: boolean
  deliveryAddressLine: string | null
  deliveryCityName: string | null
  deliveryLatitude: number | null
  deliveryLongitude: number | null
  chargedShippingAed: number
  chargedGrandTotalAed: number
  chargedGrandTotalFormatted: string
  stripeSessionId: string | null
  paymentIntentId: string | null
  orderGroupId: string | null
  pendingOrderId: string | null
  stripeRefundId: string | null
  refundedAtUtc: string | null
  isRefunded: boolean
  returnReason?: string | null
  returnMediaPaths?: string[]
  returnRequestedAtUtc?: string | null
  returnAdminResponse?: string | null
  returnRespondedAtUtc?: string | null
  needsAttention?: boolean
  canMarkReceived?: boolean
  statusHistory?: AdminOrderStatusHistory[]
}

export type AdminOrdersResponse = {
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  items: AdminOrder[]
}

export type AdminOrdersFilters = {
  page?: number
  pageSize?: number
  statusId?: number
  productTypeId?: number
  excludeProductTypeId?: number
  productId?: string
  search?: string
  createdFrom?: string
  createdTo?: string
  orderChannel?: 'retail' | 'booking' | 'offers' | 'categories'
  /** Request-offer workflow: awaitingAdmin | awaitingSeller | sellerApproved */
  offerReview?: 'awaitingAdmin' | 'awaitingSeller' | 'sellerApproved' | 'all'
}

export type AdminOrderStats = {
  totalOrders: number
  totalOrdersChangePercent: number
  orderedCount: number
  shippingCount: number
  deliveredCount: number
}
