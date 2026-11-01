export type ApiProduct = {
  productId: string
  productCode?: string | null
  nameEn?: string | null
  nameAr?: string | null
  productName?: string | null
  price?: number | string | null
  currency?: string | null
  priceAed?: number | string | null
  usdPrice?: number | string | null
  ownerPrice?: number | string | null
  ownerCurrency?: string | null
  ownerUsdPrice?: number | string | null
  ownerId?: string | null
  quantity?: number | string | null
  description?: string | null
  descriptionEn?: string | null
  descriptionAr?: string | null
  statusNameEn?: string | null
  discountPercentage?: number | string | null
  discountDays?: number | string | null
  offerDuration?: string | null
  showPrice?: boolean | null
  videos?: { path?: string; videoPath?: string; url?: string; durationSeconds?: number; isMuted?: boolean }[] | null
  videoPath?: string | null
  videoPaths?: string[] | null
  videoDurationSeconds?: number | null
  createdAt?: string | null
  categoryId?: number | null
  categoryName?: string | null
  categoryNameEn?: string | null
  categoryNameAr?: string | null
  productTypeId?: number | null
  productTypeName?: string | null
  productTypeNameEn?: string | null
  unitName?: string | null
  unitNameEn?: string | null
  unitNameAr?: string | null
  hasRetailPricing?: boolean | null
  retailPrice?: number | string | null
  ownerRetailPrice?: number | string | null
  retailUnitName?: string | null
  retailUnitNameEn?: string | null
  retailUnitNameAr?: string | null
  retailQuantity?: number | string | null
  retailDescriptionEn?: string | null
  retailDescriptionAr?: string | null
  requestTypeId?: number | null
  requestTypeName?: string | null
  requestTypeNameEn?: string | null
  bookingPriceTypeId?: number | null
  bookingPriceTypeName?: string | null
  shippingDescriptionEn?: string | null
  isListingSoldOut?: boolean | null
  images?: (string | { path?: string; imagePath?: string; ImagePath?: string })[] | null
  retailCode?: string | null
  createdLanguage?: string | null
  bookingPriceTypeNameEn?: string | null
  productTypeNameAr?: string | null
  requestType?: string | { id?: number; nameEn?: string } | null
  negotiable?: boolean | string | null
  packaging?: number | string | null
  packagingDetails?: string | null
  retailPackaging?: number | string | null
  retailPackagingDetails?: string | null
  minimumOrderQuantity?: number | string | null
  maximumOrderQuantity?: number | string | null
  documents?: (string | { path?: string; documentPath?: string })[] | null
  supplierNotes?: string | null
  supplierNotesEn?: string | null
  supplierNotesAr?: string | null
  shipping?: ShippingInfo | null
  originCountryName?: string | null
  originCountryNameEn?: string | null
  originCountryNameAr?: string | null
  destinationCountryName?: string | null
  destinationCountryNameEn?: string | null
  destinationCountryNameAr?: string | null
  loadingPortName?: string | null
  loadingPortNameEn?: string | null
  arrivalPortName?: string | null
  arrivalPortNameEn?: string | null
  routeFromCountry?: string | null
  routeToCountry?: string | null
  routeFromPort?: string | null
  routeToPort?: string | null
  routeSummary?: string | null
  additionalShippingNotes?: string | null
  shippingDescriptionAr?: string | null
  shippingDuration?: string | number | null
  address?: string | null
  viewsCount?: number | null
  categoryImagePath?: string | null
}

export type ShippingInfo = {
  originCountryName?: string | null
  originCountryNameEn?: string | null
  originCountryNameAr?: string | null
  destinationCountryName?: string | null
  destinationCountryNameEn?: string | null
  destinationCountryNameAr?: string | null
  loadingPortName?: string | null
  loadingPortNameEn?: string | null
  arrivalPortName?: string | null
  arrivalPortNameEn?: string | null
  routeFromCountry?: string | null
  routeToCountry?: string | null
  routeFromPort?: string | null
  routeToPort?: string | null
  routeSummary?: string | null
  additionalShippingNotes?: string | null
}

export type Paged<T> = {
  items: T[]
  page: number
  pageSize: number
  totalPages?: number
  totalCount?: number
  count?: number
}

export type Category = {
  categoryId: number
  nameEn: string
  nameAr?: string | null
  imgPath?: string | null
  isHide?: boolean
}

export type Banner = {
  id: number
  imagePath: string
  linkUrl?: string | null
  displayOrder?: number
}

export type AppVersionInfo = {
  androidStoreUrl?: string | null
  iosStoreUrl?: string | null
}
