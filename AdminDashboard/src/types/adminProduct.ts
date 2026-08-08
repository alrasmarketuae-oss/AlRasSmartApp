export type AdminProduct = {
  productId: string
  name: string
  description: string | null
  priceUsd: number
  currency: string
  priceFormatted: string
  quantity: number
  negotiable: boolean | null
  categoryName: string
  categoryId?: number | null
  productTypeId?: number | null
  productTypeName: string
  unitName: string
  ownerName: string
  ownerCompanyName: string | null
  ownerEmail: string
  statusLabelAr: string
  isApproved: boolean
  createdAt: string
  updatedAt?: string | null
  isEditResubmit?: boolean
  primaryImagePath: string | null
  imagePaths: string[]
  originCountryName: string
  destinationCountryName: string
  loadingPortName: string
  arrivalPortName: string
  shippingDescription: string
  shippingRouteSummary: string
  shippingDuration: string
  offerDuration: string
  productAddress: string | null
  pendingOffersCount?: number
  /** Optional dual retail pricing (alongside wholesale/main price). */
  hasRetailPricing?: boolean
  retailPrice?: number | null
  retailUnitName?: string | null
  retailQuantity?: number | null
  /** Optional dual retail details (hybrid category ads only). */
  retailDescription?: string | null
  /** Packing type id 1–255. */
  retailPackaging?: number | null
  retailPackagingDetails?: string | null
  requestTypeId?: number | null
  requestTypeName?: string | null
  bookingPriceTypeId?: number | null
  bookingPriceTypeName?: string | null
  /** Packing type id 1–255. */
  packaging?: number | null
  packagingDetails?: string | null
}

export type AdminProductImage = {
  id: number
  path: string
}

export type AdminProductDocument = {
  id: number
  path: string
}

export type AdminProductVideo = {
  id: number
  path: string
  isMuted: boolean
  durationSeconds?: number | null
}

export type AdminPendingProductEdit = {
  previousName: string | null
  proposedName: string | null
  previousDescription: string | null
  proposedDescription: string | null
  previousPrice: number
  proposedPrice: number
  previousCurrency: string | null
  proposedCurrency: string | null
  previousQuantity: number
  proposedQuantity: number
  previousVideoPath: string | null
  proposedVideoPath: string | null
  previousImagePaths: string[]
  proposedImagePaths: string[]
  previousDocumentPaths: string[]
  proposedDocumentPaths: string[]
}

export type AdminProductDetail = AdminProduct & {
  categoryId: number | null
  productTypeId: number | null
  unitId: number | null
  statusId: number | null
  viewsCount: number
  ownerPhone: string | null
  ownerCity: string | null
  supplierNotesEn: string | null
  videoPath: string | null
  videoPaths: string[]
  videoDurationSeconds: number | null
  videos: AdminProductVideo[]
  images: AdminProductImage[]
  documents: AdminProductDocument[]
  pendingEdit?: AdminPendingProductEdit | null
}

export type AdminProductLookupItem = {
  id: number
  name: string
}

export type AdminProductLookups = {
  productTypes: AdminProductLookupItem[]
  units: AdminProductLookupItem[]
}

export type AdminUpdateProductPayload = {
  nameEn: string
  usdPrice: number
  currency?: string | null
  quantity: number
  descriptionEn?: string | null
  categoryId?: number | null
  productTypeName: string
  unitName: string
  supplierNotesEn?: string | null
  /**
   * Optional "edit like the mobile app" fields. All optional: omitted => leave unchanged.
   * For geo fields an explicit empty string means "clear" (e.g. booking ad switched to FOB).
   */
  negotiable?: boolean | null
  packaging?: number | null
  packagingDetails?: string | null
  shippingDuration?: string | null
  offerDuration?: string | null
  discountPercentage?: number | null
  discountDays?: number | null
  requestTypeName?: string | null
  bookingPriceTypeName?: string | null
  originCountryName?: string | null
  destinationCountryName?: string | null
  loadingPortName?: string | null
  arrivalPortName?: string | null
  enableRetailPricing?: boolean | null
  retailPrice?: number | null
  retailUnitName?: string | null
  retailQuantity?: number | null
  retailPackaging?: number | null
  retailPackagingDetails?: string | null
  retailDescriptionEn?: string | null
}

export type AdminProductsResponse = {
  page: number
  pageSize: number
  totalCount: number
  totalPages: number
  items: AdminProduct[]
}

export type AdminProductsFilters = {
  page?: number
  pageSize?: number
  search?: string
  approval?: 'pending' | 'approved' | 'rejected' | 'all'
  categoryId?: number
  productTypeId?: number
  excludeProductTypeId?: number
  status?: number
  createdFrom?: string
  createdTo?: string
  /** Request ads that have offers awaiting admin review. */
  hasPendingOffers?: boolean
  /** Seller re-submitted an edited ad for approval. */
  editResubmitOnly?: boolean
  /** Filter ads owned by this user (company). */
  ownerId?: string
  lang?: 'ar' | 'en'
}

export type AdminProductStats = {
  totalAds: number
  totalAdsChangePercent: number
  offersCount: number
  retailCount: number
  bookingCount: number
}
