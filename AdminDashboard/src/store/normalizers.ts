import type {
  AdminProduct,
  AdminProductVideo,
  AdminProductsResponse,
  AdminProductStats,
} from '../types/adminProduct'
import type {
  AdminOrder,
  AdminOrderStatusHistory,
  AdminOrdersResponse,
  AdminOrderStats,
} from '../types/adminOrder'
import type {
  AdminShipmentLogItem,
  AdminShippingProvider,
  AdminShippingProviderDetail,
  AdminShippingProvidersResponse,
  AdminShippingStats,
} from '../types/adminShipping'
import type { GeoCountry, GeoPortsByCountryResponse } from '../types/geo'
import type { Category, CategoriesResponse } from '../types/category'
import type { AdminUser, AdminUsersResponse } from '../types/user'
import type { AdminUserDetail } from '../types/adminUserDetail'
import type { HomeBanner, HomeBannersResponse } from '../types/banner'


type RawUser = AdminUser & {
  PhoneNumber?: string | null
  TypeLabelAr?: string
  StatusLabelAr?: string
  OrdersCount?: number
  CompanyName?: string | null
  FullNameEn?: string | null
  FullNameAr?: string | null
  CompanyNameEn?: string | null
  CompanyNameAr?: string | null
  IsCustomer?: boolean
  isCustomer?: boolean
  IsVerified?: boolean
  IsRejected?: boolean
  IsApproved?: boolean
  isApproved?: boolean
  HasPendingProfileChanges?: boolean
  hasPendingProfileChanges?: boolean
  CanApprove?: boolean
  canApprove?: boolean
}

function isCustomerCompanyAccount(roleId: number, isCustomer?: boolean | null): boolean {
  return roleId === 2 && isCustomer === true
}

function resolveUserStatusLabelAr(
  isActive: boolean,
  isVerified: boolean,
  roleId: number,
  isRejected = false,
  isApproved = true,
  hasPendingProfileChanges = false,
): string {
  if (isRejected) return 'مرفوض'
  if (hasPendingProfileChanges) return 'بانتظار الموافقة'
  if (!isActive) {
    if ((roleId === 2 || roleId === 5) && !isApproved) return 'بانتظار الموافقة'
    return 'موقوف'
  }
  return isVerified ? 'مكتمل' : 'غير مكتمل'
}

export function normalizeUser(raw: RawUser): AdminUser {
  const roleId = raw.roleId ?? 0
  const isCustomer = raw.isCustomer ?? raw.IsCustomer ?? false
  const isRejected = raw.isRejected ?? raw.IsRejected ?? false
  const isApproved = raw.isApproved ?? raw.IsApproved ?? true
  const hasPendingProfileChanges =
    raw.hasPendingProfileChanges ?? raw.HasPendingProfileChanges ?? false
  const isVerified = raw.isVerified ?? raw.IsVerified ?? false
  const canApprove =
    raw.canApprove
    ?? raw.CanApprove
    ?? (
      !isRejected
      && (
        ((roleId === 2 || roleId === 5) && !isApproved && isVerified)
        || hasPendingProfileChanges
      )
    )
  return {
    id: raw.id,
    fullName: raw.fullName,
    fullNameEn: raw.fullNameEn ?? raw.FullNameEn ?? null,
    fullNameAr: raw.fullNameAr ?? raw.FullNameAr ?? null,
    email: raw.email,
    phoneNumber: raw.phoneNumber ?? raw.PhoneNumber ?? null,
    roleId,
    roleName:
      raw.roleName ??
      (isCustomerCompanyAccount(roleId, isCustomer) ? 'Customer' : ''),
    roleLabelAr: raw.roleLabelAr ?? '',
    typeLabelAr:
      raw.typeLabelAr ||
      raw.TypeLabelAr ||
      (isCustomerCompanyAccount(roleId, isCustomer)
        ? 'عميل'
        : roleId === 2
          ? 'مورد'
          : roleId === 3
            ? 'عميل'
            : roleId === 1
              ? 'مدير'
              : '—'),
    statusLabelAr:
      raw.statusLabelAr ||
      raw.StatusLabelAr ||
      resolveUserStatusLabelAr(
        raw.isActive,
        raw.isVerified,
        roleId,
        isRejected,
        isApproved,
        hasPendingProfileChanges,
      ),
    isActive: raw.isActive,
    isVerified: raw.isVerified,
    isCustomer,
    isRejected,
    hasPendingProfileChanges,
    canApprove,
    createdAt: raw.createdAt,
    imgPath: raw.imgPath,
    companyName: raw.companyName ?? raw.CompanyName ?? null,
    companyNameEn: raw.companyNameEn ?? raw.CompanyNameEn ?? null,
    companyNameAr: raw.companyNameAr ?? raw.CompanyNameAr ?? null,
    ordersCount: raw.ordersCount ?? raw.OrdersCount ?? 0,
  }
}

export function normalizeUsersResponse(
  data: AdminUsersResponse & { Items?: RawUser[] },
): AdminUsersResponse {
  const items = data.items ?? data.Items ?? []
  return {
    page: data.page ?? data.Page ?? 1,
    pageSize: data.pageSize ?? data.PageSize ?? 20,
    totalCount: data.totalCount ?? data.TotalCount ?? 0,
    totalPages: data.totalPages ?? data.TotalPages ?? 1,
    items: items.map((item) => normalizeUser(item as RawUser)),
  }
}

type RawProduct = AdminProduct & {
  ProductId?: string
  Name?: string
  Description?: string | null
  PriceUsd?: number
  Currency?: string
  PriceFormatted?: string
  Quantity?: number
  Negotiable?: boolean | null
  CategoryName?: string
  CategoryId?: number | null
  categoryId?: number | null
  ProductTypeId?: number | null
  productTypeId?: number | null
  ProductTypeName?: string
  UnitName?: string
  OwnerName?: string
  OwnerCompanyName?: string | null
  OwnerEmail?: string
  StatusLabelAr?: string
  IsApproved?: boolean
  CreatedAt?: string
  UpdatedAt?: string | null
  updatedAt?: string | null
  IsEditResubmit?: boolean
  isEditResubmit?: boolean
  PrimaryImagePath?: string | null
  ImagePaths?: string[]
  OriginCountryName?: string
  DestinationCountryName?: string
  LoadingPortName?: string
  ArrivalPortName?: string
  ShippingDescription?: string
  ShippingRouteSummary?: string
  ShippingDuration?: string
  OfferDuration?: string
  offerDuration?: string
  ProductAddress?: string | null
  productAddress?: string | null
  pendingOffersCount?: number
  PendingOffersCount?: number
  activeOffersCount?: number
  ActiveOffersCount?: number
  hasRetailPricing?: boolean
  HasRetailPricing?: boolean
  retailPrice?: number | null
  RetailPrice?: number | null
  retailUnitName?: string | null
  RetailUnitName?: string | null
  retailQuantity?: number | null
  RetailQuantity?: number | null
  retailDescription?: string | null
  RetailDescription?: string | null
  retailPackaging?: number | null
  RetailPackaging?: number | null
  retailPackagingDetails?: string | null
  RetailPackagingDetails?: string | null
  requestTypeId?: number | null
  RequestTypeId?: number | null
  requestTypeName?: string | null
  RequestTypeName?: string | null
  bookingPriceTypeId?: number | null
  BookingPriceTypeId?: number | null
  bookingPriceTypeName?: string | null
  BookingPriceTypeName?: string | null
  packaging?: number | null
  Packaging?: number | null
  packagingDetails?: string | null
  PackagingDetails?: string | null
}

export function normalizeProduct(raw: RawProduct): AdminProduct {
  const retailPriceRaw = raw.retailPrice ?? raw.RetailPrice
  const retailPrice =
    retailPriceRaw == null ? null : Number(retailPriceRaw)
  const retailQuantityRaw = raw.retailQuantity ?? raw.RetailQuantity
  const retailQuantity =
    retailQuantityRaw == null ? null : Number(retailQuantityRaw)
  const hasRetailPricingFlag =
    raw.hasRetailPricing ?? raw.HasRetailPricing ?? false
  const hasRetailPricing =
    Boolean(hasRetailPricingFlag) ||
    (retailPrice != null && !Number.isNaN(retailPrice) && retailPrice > 0)
  const requestTypeIdRaw: unknown = raw.requestTypeId ?? raw.RequestTypeId
  const requestTypeId =
    requestTypeIdRaw == null || requestTypeIdRaw === ''
      ? null
      : Number(requestTypeIdRaw)

  const bookingPriceTypeIdRaw: unknown =
    raw.bookingPriceTypeId ?? raw.BookingPriceTypeId
  const bookingPriceTypeId =
    bookingPriceTypeIdRaw == null || bookingPriceTypeIdRaw === ''
      ? null
      : Number(bookingPriceTypeIdRaw)

  const retailDescription =
    raw.retailDescription ?? raw.RetailDescription ?? null

  const retailPackaging = (() => {
    const value = raw.retailPackaging ?? raw.RetailPackaging
    if (value == null) return null
    const n = Number(value)
    return Number.isFinite(n) && n > 0 && n <= 255 ? n : null
  })()

  const retailPackagingDetails =
    raw.retailPackagingDetails ?? raw.RetailPackagingDetails ?? null

  return {
    productId: String(raw.productId ?? raw.ProductId ?? '').trim(),
    name: raw.name ?? raw.Name ?? '',
    description: raw.description ?? raw.Description ?? null,
    priceUsd: raw.priceUsd ?? raw.PriceUsd ?? 0,
    currency: raw.currency ?? raw.Currency ?? 'AED',
    priceFormatted: raw.priceFormatted ?? raw.PriceFormatted ?? '',
    quantity: raw.quantity ?? raw.Quantity ?? 0,
    negotiable:
      raw.negotiable ??
      raw.Negotiable ??
      null,
    categoryName: raw.categoryName ?? raw.CategoryName ?? '—',
    categoryId: (() => {
      const value = raw.categoryId ?? raw.CategoryId
      if (value == null) return null
      const n = Number(value)
      return Number.isFinite(n) && n > 0 ? n : null
    })(),
    productTypeId: (() => {
      const value = raw.productTypeId ?? raw.ProductTypeId
      if (value == null) return null
      const n = Number(value)
      return Number.isFinite(n) ? n : null
    })(),
    productTypeName: raw.productTypeName ?? raw.ProductTypeName ?? '—',
    unitName: raw.unitName ?? raw.UnitName ?? '—',
    ownerName: raw.ownerName ?? raw.OwnerName ?? '—',
    ownerCompanyName: raw.ownerCompanyName ?? raw.OwnerCompanyName ?? null,
    ownerEmail: raw.ownerEmail ?? raw.OwnerEmail ?? '—',
    statusLabelAr: raw.statusLabelAr ?? raw.StatusLabelAr ?? 'قيد المراجعة',
    isApproved: raw.isApproved ?? raw.IsApproved ?? false,
    createdAt: raw.createdAt ?? raw.CreatedAt ?? '',
    updatedAt: raw.updatedAt ?? raw.UpdatedAt ?? null,
    isEditResubmit: raw.isEditResubmit ?? raw.IsEditResubmit ?? false,
    primaryImagePath: raw.primaryImagePath ?? raw.PrimaryImagePath ?? null,
    imagePaths: raw.imagePaths ?? raw.ImagePaths ?? [],
    originCountryName: raw.originCountryName ?? raw.OriginCountryName ?? '',
    destinationCountryName:
      raw.destinationCountryName ?? raw.DestinationCountryName ?? '',
    loadingPortName: raw.loadingPortName ?? raw.LoadingPortName ?? '',
    arrivalPortName: raw.arrivalPortName ?? raw.ArrivalPortName ?? '',
    shippingDescription:
      raw.shippingDescription ?? raw.ShippingDescription ?? '',
    shippingRouteSummary:
      raw.shippingRouteSummary ?? raw.ShippingRouteSummary ?? '',
    shippingDuration:
      raw.shippingDuration ?? raw.ShippingDuration ?? '',
    offerDuration: raw.offerDuration ?? raw.OfferDuration ?? '',
    productAddress: raw.productAddress ?? raw.ProductAddress ?? null,
    pendingOffersCount: Number(
      raw.pendingOffersCount ?? raw.PendingOffersCount ?? 0,
    ),
    activeOffersCount: Number(
      raw.activeOffersCount ?? raw.ActiveOffersCount ?? 0,
    ),
    hasRetailPricing,
    retailPrice:
      retailPrice != null && !Number.isNaN(retailPrice) ? retailPrice : null,
    retailUnitName: raw.retailUnitName ?? raw.RetailUnitName ?? null,
    retailQuantity:
      retailQuantity != null && !Number.isNaN(retailQuantity)
        ? retailQuantity
        : null,
    retailDescription: retailDescription,
    retailPackaging: retailPackaging,
    retailPackagingDetails: retailPackagingDetails,
    requestTypeId:
      requestTypeId != null && !Number.isNaN(requestTypeId)
        ? requestTypeId
        : null,
    requestTypeName: raw.requestTypeName ?? raw.RequestTypeName ?? null,
    bookingPriceTypeId:
      bookingPriceTypeId != null && !Number.isNaN(bookingPriceTypeId)
        ? bookingPriceTypeId
        : null,
    bookingPriceTypeName:
      raw.bookingPriceTypeName ?? raw.BookingPriceTypeName ?? null,
    packaging: (() => {
      const value = raw.packaging ?? raw.Packaging
      if (value == null) return null
      const n = Number(value)
      return Number.isFinite(n) && n > 0 && n <= 255 ? n : null
    })(),
    packagingDetails: raw.packagingDetails ?? raw.PackagingDetails ?? null,
  }
}

type RawProductImage = {
  id?: number
  Id?: number
  path?: string
  Path?: string
}

type RawProductDocument = {
  id?: number
  Id?: number
  path?: string
  Path?: string
}

type RawProductVideo = {
  id?: number
  Id?: number
  path?: string
  Path?: string
  isMuted?: boolean
  IsMuted?: boolean
  durationSeconds?: number | null
  DurationSeconds?: number | null
}

type RawProductDetail = RawProduct & {
  CategoryId?: number | null
  categoryId?: number | null
  ProductTypeId?: number | null
  productTypeId?: number | null
  UnitId?: number | null
  unitId?: number | null
  StatusId?: number | null
  statusId?: number | null
  ViewsCount?: number
  viewsCount?: number
  OwnerPhone?: string | null
  ownerPhone?: string | null
  OwnerCity?: string | null
  ownerCity?: string | null
  SupplierNotesEn?: string | null
  supplierNotesEn?: string | null
  VideoPath?: string | null
  videoPath?: string | null
  VideoPaths?: string[] | null
  videoPaths?: string[] | null
  VideoDurationSeconds?: number | null
  videoDurationSeconds?: number | null
  IsVideoMuted?: boolean
  isVideoMuted?: boolean
  Videos?: RawProductVideo[] | null
  videos?: RawProductVideo[] | null
  Images?: RawProductImage[]
  images?: RawProductImage[]
  Documents?: RawProductDocument[]
  documents?: RawProductDocument[]
  PendingEdit?: RawPendingProductEdit | null
  pendingEdit?: RawPendingProductEdit | null
}

type RawPendingProductEdit = {
  previousName?: string | null
  PreviousName?: string | null
  proposedName?: string | null
  ProposedName?: string | null
  previousDescription?: string | null
  PreviousDescription?: string | null
  proposedDescription?: string | null
  ProposedDescription?: string | null
  previousPrice?: number
  PreviousPrice?: number
  proposedPrice?: number
  ProposedPrice?: number
  previousCurrency?: string | null
  PreviousCurrency?: string | null
  proposedCurrency?: string | null
  ProposedCurrency?: string | null
  previousQuantity?: number
  PreviousQuantity?: number
  proposedQuantity?: number
  ProposedQuantity?: number
  previousVideoPath?: string | null
  PreviousVideoPath?: string | null
  proposedVideoPath?: string | null
  ProposedVideoPath?: string | null
  previousImagePaths?: string[]
  PreviousImagePaths?: string[]
  proposedImagePaths?: string[]
  ProposedImagePaths?: string[]
  previousDocumentPaths?: string[]
  PreviousDocumentPaths?: string[]
  proposedDocumentPaths?: string[]
  ProposedDocumentPaths?: string[]
}

function normalizeProductDocument(raw: RawProductDocument) {
  return {
    id: raw.id ?? raw.Id ?? 0,
    path: raw.path ?? raw.Path ?? '',
  }
}

function normalizeProductImage(raw: RawProductImage) {
  return {
    id: raw.id ?? raw.Id ?? 0,
    path: raw.path ?? raw.Path ?? '',
  }
}

function normalizeProductVideo(raw: RawProductVideo): AdminProductVideo | null {
  const path = String(raw.path ?? raw.Path ?? '').trim()
  if (!path) return null
  return {
    id: Number(raw.id ?? raw.Id ?? 0),
    path,
    isMuted: raw.isMuted ?? raw.IsMuted ?? true,
    durationSeconds: raw.durationSeconds ?? raw.DurationSeconds ?? null,
  }
}

export function normalizeProductDetail(raw: RawProductDetail) {
  const base = normalizeProduct(raw)
  const images = (raw.images ?? raw.Images ?? []).map(normalizeProductImage)
  const documents = (raw.documents ?? raw.Documents ?? []).map(normalizeProductDocument)
  const videos = (raw.videos ?? raw.Videos ?? [])
    .map(normalizeProductVideo)
    .filter((video): video is AdminProductVideo => video != null)
  const legacyVideoPaths = (raw.videoPaths ?? raw.VideoPaths ?? [])
    .map((path) => (typeof path === 'string' ? path.trim() : ''))
    .filter(Boolean)
  const primaryVideoPath = String(raw.videoPath ?? raw.VideoPath ?? '').trim()
  const videoPaths = videos.length > 0
    ? videos.map((video) => video.path)
    : primaryVideoPath && !legacyVideoPaths.some(
          (path) => path.toLowerCase() === primaryVideoPath.toLowerCase(),
        )
      ? [primaryVideoPath, ...legacyVideoPaths]
      : legacyVideoPaths.length > 0
        ? legacyVideoPaths
        : primaryVideoPath
          ? [primaryVideoPath]
          : []

  return {
    ...base,
    categoryId: raw.categoryId ?? raw.CategoryId ?? null,
    productTypeId: raw.productTypeId ?? raw.ProductTypeId ?? null,
    unitId: raw.unitId ?? raw.UnitId ?? null,
    statusId: raw.statusId ?? raw.StatusId ?? null,
    viewsCount: raw.viewsCount ?? raw.ViewsCount ?? 0,
    ownerPhone: raw.ownerPhone ?? raw.OwnerPhone ?? null,
    ownerCity: raw.ownerCity ?? raw.OwnerCity ?? null,
    supplierNotesEn: raw.supplierNotesEn ?? raw.SupplierNotesEn ?? null,
    videoPath: raw.videoPath ?? raw.VideoPath ?? videos[0]?.path ?? null,
    videoPaths,
    videoDurationSeconds:
      raw.videoDurationSeconds ?? raw.VideoDurationSeconds ?? null,
    videos,
    images: images.length > 0
      ? images
      : base.imagePaths.map((path, index) => ({ id: index, path })),
    documents,
    pendingEdit: normalizePendingProductEdit(raw.pendingEdit ?? raw.PendingEdit),
  }
}

function normalizePendingProductEdit(
  raw: RawPendingProductEdit | null | undefined,
) {
  if (!raw) return null
  return {
    previousName: raw.previousName ?? raw.PreviousName ?? null,
    proposedName: raw.proposedName ?? raw.ProposedName ?? null,
    previousDescription: raw.previousDescription ?? raw.PreviousDescription ?? null,
    proposedDescription: raw.proposedDescription ?? raw.ProposedDescription ?? null,
    previousPrice: Number(raw.previousPrice ?? raw.PreviousPrice ?? 0),
    proposedPrice: Number(raw.proposedPrice ?? raw.ProposedPrice ?? 0),
    previousCurrency: raw.previousCurrency ?? raw.PreviousCurrency ?? null,
    proposedCurrency: raw.proposedCurrency ?? raw.ProposedCurrency ?? null,
    previousQuantity: Number(raw.previousQuantity ?? raw.PreviousQuantity ?? 0),
    proposedQuantity: Number(raw.proposedQuantity ?? raw.ProposedQuantity ?? 0),
    previousVideoPath: raw.previousVideoPath ?? raw.PreviousVideoPath ?? null,
    proposedVideoPath: raw.proposedVideoPath ?? raw.ProposedVideoPath ?? null,
    previousImagePaths: raw.previousImagePaths ?? raw.PreviousImagePaths ?? [],
    proposedImagePaths: raw.proposedImagePaths ?? raw.ProposedImagePaths ?? [],
    previousDocumentPaths:
      raw.previousDocumentPaths ?? raw.PreviousDocumentPaths ?? [],
    proposedDocumentPaths:
      raw.proposedDocumentPaths ?? raw.ProposedDocumentPaths ?? [],
  }
}

type RawLookupItem = { id?: number; Id?: number; name?: string; Name?: string }

export function normalizeProductLookups(data: {
  productTypes?: RawLookupItem[]
  ProductTypes?: RawLookupItem[]
  units?: RawLookupItem[]
  Units?: RawLookupItem[]
}) {
  const mapItem = (raw: RawLookupItem) => ({
    id: raw.id ?? raw.Id ?? 0,
    name: raw.name ?? raw.Name ?? '',
  })

  return {
    productTypes: (data.productTypes ?? data.ProductTypes ?? []).map(mapItem),
    units: (data.units ?? data.Units ?? []).map(mapItem),
  }
}

type RawProductsResponse = AdminProductsResponse & {
  Items?: RawProduct[]
  Page?: number
  PageSize?: number
  TotalCount?: number
  TotalPages?: number
}

export function normalizeProductsResponse(
  data: RawProductsResponse,
): AdminProductsResponse {
  return {
    page: data.page ?? data.Page ?? 1,
    pageSize: data.pageSize ?? data.PageSize ?? 20,
    totalCount: data.totalCount ?? data.TotalCount ?? 0,
    totalPages: data.totalPages ?? data.TotalPages ?? 1,
    items: (data.items ?? data.Items ?? []).map((item) => normalizeProduct(item)),
  }
}

export function normalizeProductStats(data: Record<string, unknown>): AdminProductStats {
  return {
    totalAds: Number(data.totalAds ?? data.TotalAds ?? 0),
    totalAdsChangePercent: Number(
      data.totalAdsChangePercent ?? data.TotalAdsChangePercent ?? 0,
    ),
    offersCount: Number(data.offersCount ?? data.OffersCount ?? 0),
    retailCount: Number(data.retailCount ?? data.RetailCount ?? 0),
    bookingCount: Number(data.bookingCount ?? data.BookingCount ?? 0),
  }
}

type RawCategory = {
  categoryId?: number
  CategoryId?: number
  nameEn?: string
  NameEn?: string
  nameAr?: string
  NameAr?: string
  imgPath?: string
  ImgPath?: string
  commissionPercent?: number
  CommissionPercent?: number
  isHide?: boolean
  IsHide?: boolean
}

export function normalizeCategory(raw: RawCategory): Category {
  return {
    categoryId: raw.categoryId ?? raw.CategoryId ?? 0,
    nameEn: raw.nameEn ?? raw.NameEn ?? '',
    nameAr: raw.nameAr ?? raw.NameAr ?? '',
    imgPath: raw.imgPath ?? raw.ImgPath ?? '',
    commissionPercent: raw.commissionPercent ?? raw.CommissionPercent ?? 0,
    isHide: raw.isHide ?? raw.IsHide ?? false,
  }
}

export function normalizeCategoriesResponse(
  data: CategoriesResponse & { Items?: RawCategory[] },
): CategoriesResponse {
  const items = data.items ?? data.Items ?? []
  return {
    count: data.count ?? items.length,
    items: items.map((item) => normalizeCategory(item)),
  }
}

type RawOrderImage = { id?: number; Id?: number; path?: string; Path?: string }

type RawRelatedOrder = {
  id?: number
  Id?: number
  productId?: string
  ProductId?: string
  productName?: string
  ProductName?: string
  productNameEn?: string | null
  ProductNameEn?: string | null
  productNameAr?: string | null
  ProductNameAr?: string | null
  primaryImagePath?: string | null
  PrimaryImagePath?: string | null
  quantity?: number
  Quantity?: number
  statusId?: number
  StatusId?: number
  supplierName?: string | null
  SupplierName?: string | null
}

type RawOrder = AdminOrder & {
  ProductId?: string
  CustomerName?: string
  CustomerNameEn?: string | null
  CustomerNameAr?: string | null
  CustomerEmail?: string
  CustomerPhone?: string | null
  CustomerUserId?: string | null
  SupplierName?: string
  SupplierNameEn?: string | null
  SupplierNameAr?: string | null
  SupplierEmail?: string
  SupplierPhone?: string | null
  SupplierUserId?: string | null
  SupplierAvatarPath?: string | null
  ProductName?: string
  ProductDescription?: string | null
  ProductTypeName?: string
  productTypeName?: string
  IsRetailPurchase?: boolean
  isRetailPurchase?: boolean
  CategoryName?: string
  PrimaryImagePath?: string | null
  UnitName?: string
  StatusId?: number
  StatusName?: string
  StatusLabelAr?: string
  UnitPrice?: number
  TotalPrice?: number
  AmountFormatted?: string
  Currency?: string
  currency?: string
  CommissionPercent?: number
  commissionPercent?: number
  SupplierUnitPrice?: number
  supplierUnitPrice?: number
  SupplierTotalPrice?: number
  supplierTotalPrice?: number
  CustomerUnitPrice?: number
  customerUnitPrice?: number
  CustomerTotalPrice?: number
  customerTotalPrice?: number
  AppProfitAmount?: number
  appProfitAmount?: number
  ChargedUnitPrice?: number
  chargedUnitPrice?: number
  ChargedTotalPrice?: number
  chargedTotalPrice?: number
  SupplierUnitPriceFormatted?: string
  supplierUnitPriceFormatted?: string
  SupplierTotalPriceFormatted?: string
  supplierTotalPriceFormatted?: string
  CustomerUnitPriceFormatted?: string
  customerUnitPriceFormatted?: string
  CustomerTotalPriceFormatted?: string
  customerTotalPriceFormatted?: string
  AppProfitFormatted?: string
  appProfitFormatted?: string
  Quantity?: number
  RequestedQuantity?: number
  ProductAvailableQuantity?: number | null
  PaymentMethod?: number
  PaymentMethodName?: string
  CreatedAt?: string
  IsApproved?: boolean
  IsAdminApproved?: boolean
  Notes?: string | null
  VideoPaths?: string[]
  Images?: RawOrderImage[]
  Videos?: RawOrderImage[]
  DocumentPaths?: string[]
  ProductImagePaths?: string[]
  ProductDocumentPaths?: string[]
  PortId?: number | null
  PortName?: string | null
  portName?: string | null
  PortCountryName?: string | null
  portCountryName?: string | null
  OriginCountryName?: string
  originCountryName?: string
  DestinationCountryName?: string
  destinationCountryName?: string
  LoadingPortName?: string
  loadingPortName?: string
  ArrivalPortName?: string
  arrivalPortName?: string
  ShippingDescription?: string
  shippingDescription?: string
  ShippingRouteSummary?: string
  shippingRouteSummary?: string
  ShippingDuration?: string
  shippingDuration?: string
  ProductAddress?: string | null
  productAddress?: string | null
  ProductLatitude?: number | null
  ProductLongitude?: number | null
  VatAed?: number
  ShippingCostAed?: number
  IsSelfPickup?: boolean
  DeliveryAddressLine?: string | null
  DeliveryCityName?: string | null
  DeliveryLatitude?: number | null
  DeliveryLongitude?: number | null
  ChargedShippingAed?: number
  ChargedGrandTotalAed?: number
  ChargedGrandTotalFormatted?: string
  StripeSessionId?: string | null
  stripeSessionId?: string | null
  PaymentIntentId?: string | null
  paymentIntentId?: string | null
  OrderGroupId?: string | null
  orderGroupItemCount?: number
  OrderGroupItemCount?: number
  relatedOrders?: RawRelatedOrder[]
  RelatedOrders?: RawRelatedOrder[]
  orderGroupId?: string | null
  PendingOrderId?: string | null
  pendingOrderId?: string | null
  StripeRefundId?: string | null
  stripeRefundId?: string | null
  RefundedAtUtc?: string | null
  refundedAtUtc?: string | null
  IsRefunded?: boolean
  isRefunded?: boolean
}

function normalizeOrderImage(raw: RawOrderImage) {
  return {
    id: raw.id ?? raw.Id ?? 0,
    path: raw.path ?? raw.Path ?? '',
  }
}

function normalizeOrderVideo(raw: RawOrderImage) {
  return {
    id: raw.id ?? raw.Id ?? 0,
    path: raw.path ?? raw.Path ?? '',
  }
}

function normalizeOrderStatusHistory(raw: {
  id?: number
  Id?: number
  statusId?: number
  StatusId?: number
  statusNameEn?: string
  StatusNameEn?: string
  statusNameAr?: string
  StatusNameAr?: string
  createdAtUtc?: string
  CreatedAtUtc?: string
}): AdminOrderStatusHistory {
  return {
    id: raw.id ?? raw.Id ?? 0,
    statusId: raw.statusId ?? raw.StatusId ?? 0,
    statusNameEn: raw.statusNameEn ?? raw.StatusNameEn ?? '',
    statusNameAr: raw.statusNameAr ?? raw.StatusNameAr ?? '',
    createdAtUtc: raw.createdAtUtc ?? raw.CreatedAtUtc ?? '',
  }
}

export function normalizeOrder(raw: RawOrder): AdminOrder {
  return {
    id: raw.id ?? (raw as { Id?: number }).Id ?? 0,
    productId: raw.productId ?? raw.ProductId ?? '',
    customerName: raw.customerName ?? raw.CustomerName ?? '—',
    customerNameEn: raw.customerNameEn ?? raw.CustomerNameEn ?? null,
    customerNameAr: raw.customerNameAr ?? raw.CustomerNameAr ?? null,
    customerEmail: raw.customerEmail ?? raw.CustomerEmail ?? '—',
    customerPhone: raw.customerPhone ?? raw.CustomerPhone ?? null,
    customerUserId: (() => {
      const value = raw.customerUserId ?? raw.CustomerUserId
      if (value == null) return null
      const text = String(value).trim()
      return text.length > 0 ? text : null
    })(),
    supplierName: raw.supplierName ?? raw.SupplierName ?? '—',
    supplierNameEn: raw.supplierNameEn ?? raw.SupplierNameEn ?? null,
    supplierNameAr: raw.supplierNameAr ?? raw.SupplierNameAr ?? null,
    supplierEmail: raw.supplierEmail ?? raw.SupplierEmail ?? '—',
    supplierPhone: raw.supplierPhone ?? raw.SupplierPhone ?? null,
    supplierUserId: (() => {
      const value = raw.supplierUserId ?? raw.SupplierUserId
      if (value == null) return null
      const text = String(value).trim()
      return text.length > 0 ? text : null
    })(),
    supplierAvatarPath: raw.supplierAvatarPath ?? raw.SupplierAvatarPath ?? null,
    productName: raw.productName ?? raw.ProductName ?? '—',
    productDescription: raw.productDescription ?? raw.ProductDescription ?? null,
    productTypeName: raw.productTypeName ?? raw.ProductTypeName ?? '—',
    requestTypeId: (() => {
      const value = (raw as { requestTypeId?: number | null; RequestTypeId?: number | null })
        .requestTypeId ?? (raw as { RequestTypeId?: number | null }).RequestTypeId
      if (value == null || value === ('' as never)) return null
      const n = Number(value)
      return Number.isFinite(n) && n > 0 ? n : null
    })(),
    requestTypeName:
      (raw as { requestTypeName?: string | null; RequestTypeName?: string | null })
        .requestTypeName ??
      (raw as { RequestTypeName?: string | null }).RequestTypeName ??
      null,
    negotiable: (() => {
      const value =
        (raw as { negotiable?: boolean | null; Negotiable?: boolean | null }).negotiable ??
        (raw as { Negotiable?: boolean | null }).Negotiable
      return value == null ? null : Boolean(value)
    })(),
    offerDuration:
      (raw as { offerDuration?: string | null; OfferDuration?: string | null })
        .offerDuration ??
      (raw as { OfferDuration?: string | null }).OfferDuration ??
      null,
    packaging: (() => {
      const value =
        (raw as { packaging?: number | null; Packaging?: number | null }).packaging ??
        (raw as { Packaging?: number | null }).Packaging
      if (value == null) return null
      const n = Number(value)
      return Number.isFinite(n) && n > 0 && n <= 255 ? n : null
    })(),
    packagingDetails:
      (raw as { packagingDetails?: string | null; PackagingDetails?: string | null })
        .packagingDetails ??
      (raw as { PackagingDetails?: string | null }).PackagingDetails ??
      null,
    isRetailPurchase: Boolean(
      raw.isRetailPurchase ?? (raw as { IsRetailPurchase?: boolean }).IsRetailPurchase,
    ),
    categoryName: raw.categoryName ?? raw.CategoryName ?? '—',
    categoryId: raw.categoryId ?? (raw as { CategoryId?: number | null }).CategoryId ?? null,
    primaryImagePath: raw.primaryImagePath ?? raw.PrimaryImagePath ?? null,
    unitName: raw.unitName ?? raw.UnitName ?? '—',
    statusId: raw.statusId ?? raw.StatusId ?? 0,
    statusName: raw.statusName ?? raw.StatusName ?? '',
    statusLabelAr: raw.statusLabelAr ?? raw.StatusLabelAr ?? '',
    unitPrice: raw.unitPrice ?? raw.UnitPrice ?? 0,
    totalPrice: raw.totalPrice ?? raw.TotalPrice ?? 0,
    amountFormatted: raw.amountFormatted ?? raw.AmountFormatted ?? '',
    currency: raw.currency ?? raw.Currency ?? 'AED',
    commissionPercent: raw.commissionPercent ?? raw.CommissionPercent ?? 0,
    supplierUnitPrice: raw.supplierUnitPrice ?? raw.SupplierUnitPrice ?? 0,
    supplierTotalPrice: raw.supplierTotalPrice ?? raw.SupplierTotalPrice ?? 0,
    customerUnitPrice: raw.customerUnitPrice ?? raw.CustomerUnitPrice ?? 0,
    customerTotalPrice: raw.customerTotalPrice ?? raw.CustomerTotalPrice ?? 0,
    appProfitAmount: raw.appProfitAmount ?? raw.AppProfitAmount ?? 0,
    chargedUnitPrice: raw.chargedUnitPrice ?? raw.ChargedUnitPrice ?? raw.unitPrice ?? raw.UnitPrice ?? 0,
    chargedTotalPrice: raw.chargedTotalPrice ?? raw.ChargedTotalPrice ?? raw.totalPrice ?? raw.TotalPrice ?? 0,
    supplierUnitPriceFormatted:
      raw.supplierUnitPriceFormatted ?? raw.SupplierUnitPriceFormatted ?? '',
    supplierTotalPriceFormatted:
      raw.supplierTotalPriceFormatted ?? raw.SupplierTotalPriceFormatted ?? '',
    customerUnitPriceFormatted:
      raw.customerUnitPriceFormatted ?? raw.CustomerUnitPriceFormatted ?? '',
    customerTotalPriceFormatted:
      raw.customerTotalPriceFormatted ?? raw.CustomerTotalPriceFormatted ?? '',
    appProfitFormatted: raw.appProfitFormatted ?? raw.AppProfitFormatted ?? '',
    listingUnitPrice: Number(
      (raw as { listingUnitPrice?: number; ListingUnitPrice?: number }).listingUnitPrice ??
        (raw as { ListingUnitPrice?: number }).ListingUnitPrice ??
        0,
    ),
    listingUnitPriceFormatted:
      (raw as { listingUnitPriceFormatted?: string; ListingUnitPriceFormatted?: string })
        .listingUnitPriceFormatted ??
      (raw as { ListingUnitPriceFormatted?: string }).ListingUnitPriceFormatted ??
      '',
    isBelowListingPrice: Boolean(
      (raw as { isBelowListingPrice?: boolean; IsBelowListingPrice?: boolean })
        .isBelowListingPrice ??
        (raw as { IsBelowListingPrice?: boolean }).IsBelowListingPrice,
    ),
    hasAdminAdvertiserPrice: Boolean(
      (raw as { hasAdminAdvertiserPrice?: boolean; HasAdminAdvertiserPrice?: boolean })
        .hasAdminAdvertiserPrice ??
        (raw as { HasAdminAdvertiserPrice?: boolean }).HasAdminAdvertiserPrice,
    ),
    adminAdvertiserUnitPrice:
      (raw as { adminAdvertiserUnitPrice?: number | null; AdminAdvertiserUnitPrice?: number | null })
        .adminAdvertiserUnitPrice ??
      (raw as { AdminAdvertiserUnitPrice?: number | null }).AdminAdvertiserUnitPrice ??
      null,
    adminAdvertiserTotalPrice:
      (raw as { adminAdvertiserTotalPrice?: number | null; AdminAdvertiserTotalPrice?: number | null })
        .adminAdvertiserTotalPrice ??
      (raw as { AdminAdvertiserTotalPrice?: number | null }).AdminAdvertiserTotalPrice ??
      null,
    adminAdvertiserUnitPriceFormatted:
      (raw as { adminAdvertiserUnitPriceFormatted?: string; AdminAdvertiserUnitPriceFormatted?: string })
        .adminAdvertiserUnitPriceFormatted ??
      (raw as { AdminAdvertiserUnitPriceFormatted?: string }).AdminAdvertiserUnitPriceFormatted ??
      '',
    adminAdvertiserTotalPriceFormatted:
      (raw as { adminAdvertiserTotalPriceFormatted?: string; AdminAdvertiserTotalPriceFormatted?: string })
        .adminAdvertiserTotalPriceFormatted ??
      (raw as { AdminAdvertiserTotalPriceFormatted?: string }).AdminAdvertiserTotalPriceFormatted ??
      '',
    quantity: raw.quantity ?? raw.Quantity ?? 0,
    requestedQuantity:
      raw.requestedQuantity ??
      raw.RequestedQuantity ??
      raw.quantity ??
      raw.Quantity ??
      0,
    productAvailableQuantity:
      raw.productAvailableQuantity ?? raw.ProductAvailableQuantity ?? null,
    productViewsCount: Number(
      (raw as { productViewsCount?: number; ProductViewsCount?: number })
        .productViewsCount ??
        (raw as { ProductViewsCount?: number }).ProductViewsCount ??
        0,
    ),
    paymentMethod: raw.paymentMethod ?? raw.PaymentMethod ?? 0,
    paymentMethodName: raw.paymentMethodName ?? raw.PaymentMethodName ?? '',
    createdAt: raw.createdAt ?? raw.CreatedAt ?? '',
    isApproved: raw.isApproved ?? raw.IsApproved ?? false,
    isAdminApproved: raw.isAdminApproved ?? raw.IsAdminApproved ?? false,
    notes: raw.notes ?? raw.Notes ?? null,
    videoPaths: raw.videoPaths ?? raw.VideoPaths ?? [],
    videos: (raw.videos ?? raw.Videos ?? []).map((item) => normalizeOrderVideo(item)),
    images: (raw.images ?? raw.Images ?? []).map((item) => normalizeOrderImage(item)),
    documentPaths: (raw.documentPaths ?? raw.DocumentPaths ?? []) as string[],
    productImagePaths: (raw.productImagePaths ?? raw.ProductImagePaths ?? []) as string[],
    productDocumentPaths: (raw.productDocumentPaths ??
      raw.ProductDocumentPaths ??
      []) as string[],
    portId: raw.portId ?? raw.PortId ?? null,
    portName: raw.portName ?? raw.PortName ?? null,
    portCountryName: raw.portCountryName ?? raw.PortCountryName ?? null,
    originCountryName: raw.originCountryName ?? raw.OriginCountryName ?? '',
    destinationCountryName:
      raw.destinationCountryName ?? raw.DestinationCountryName ?? '',
    loadingPortName: raw.loadingPortName ?? raw.LoadingPortName ?? '',
    arrivalPortName: raw.arrivalPortName ?? raw.ArrivalPortName ?? '',
    shippingDescription:
      raw.shippingDescription ?? raw.ShippingDescription ?? '',
    shippingRouteSummary:
      raw.shippingRouteSummary ?? raw.ShippingRouteSummary ?? '',
    shippingDuration:
      raw.shippingDuration ?? raw.ShippingDuration ?? '',
    productAddress: raw.productAddress ?? raw.ProductAddress ?? null,
    productLatitude: raw.productLatitude ?? raw.ProductLatitude ?? null,
    productLongitude: raw.productLongitude ?? raw.ProductLongitude ?? null,
    vatAed: raw.vatAed ?? raw.VatAed ?? 0,
    shippingCostAed: raw.shippingCostAed ?? raw.ShippingCostAed ?? 0,
    isSelfPickup: raw.isSelfPickup ?? raw.IsSelfPickup ?? false,
    deliveryAddressLine: raw.deliveryAddressLine ?? raw.DeliveryAddressLine ?? null,
    deliveryCityName: raw.deliveryCityName ?? raw.DeliveryCityName ?? null,
    deliveryLatitude: raw.deliveryLatitude ?? raw.DeliveryLatitude ?? null,
    deliveryLongitude: raw.deliveryLongitude ?? raw.DeliveryLongitude ?? null,
    chargedShippingAed: raw.chargedShippingAed ?? raw.ChargedShippingAed ?? 0,
    chargedGrandTotalAed: raw.chargedGrandTotalAed ?? raw.ChargedGrandTotalAed ?? 0,
    chargedGrandTotalFormatted:
      raw.chargedGrandTotalFormatted ?? raw.ChargedGrandTotalFormatted ?? '',
    stripeSessionId: raw.stripeSessionId ?? raw.StripeSessionId ?? null,
    paymentIntentId: raw.paymentIntentId ?? raw.PaymentIntentId ?? null,
    orderGroupId:
      raw.orderGroupId != null
        ? String(raw.orderGroupId)
        : raw.OrderGroupId != null
          ? String(raw.OrderGroupId)
          : null,
    orderGroupItemCount: Number(raw.orderGroupItemCount ?? raw.OrderGroupItemCount ?? 1),
    relatedOrders: (raw.relatedOrders ?? raw.RelatedOrders ?? []).map((item) => ({
      id: Number(item.id ?? item.Id ?? 0),
      productId: String(item.productId ?? item.ProductId ?? ''),
      productName: String(item.productName ?? item.ProductName ?? '—'),
      productNameEn: (item.productNameEn ?? item.ProductNameEn ?? null) as string | null,
      productNameAr: (item.productNameAr ?? item.ProductNameAr ?? null) as string | null,
      primaryImagePath: (item.primaryImagePath ?? item.PrimaryImagePath ?? null) as string | null,
      quantity: Number(item.quantity ?? item.Quantity ?? 0),
      statusId: Number(item.statusId ?? item.StatusId ?? 0),
      supplierName: (item.supplierName ?? item.SupplierName ?? null) as string | null,
    })),
    pendingOrderId:
      raw.pendingOrderId != null
        ? String(raw.pendingOrderId)
        : raw.PendingOrderId != null
          ? String(raw.PendingOrderId)
          : null,
    stripeRefundId: raw.stripeRefundId ?? raw.StripeRefundId ?? null,
    refundedAtUtc: raw.refundedAtUtc ?? raw.RefundedAtUtc ?? null,
    isRefunded: raw.isRefunded ?? raw.IsRefunded ?? false,
    returnReason: raw.returnReason ?? (raw as { ReturnReason?: string | null }).ReturnReason ?? null,
    returnMediaPaths:
      (raw.returnMediaPaths ??
        (raw as { ReturnMediaPaths?: string[] }).ReturnMediaPaths ??
        []) as string[],
    returnRequestedAtUtc:
      raw.returnRequestedAtUtc ??
      (raw as { ReturnRequestedAtUtc?: string | null }).ReturnRequestedAtUtc ??
      null,
    returnAdminResponse:
      raw.returnAdminResponse ??
      (raw as { ReturnAdminResponse?: string | null }).ReturnAdminResponse ??
      null,
    returnRespondedAtUtc:
      raw.returnRespondedAtUtc ??
      (raw as { ReturnRespondedAtUtc?: string | null }).ReturnRespondedAtUtc ??
      null,
    needsAttention: raw.needsAttention ?? (raw as { NeedsAttention?: boolean }).NeedsAttention ?? false,
    canMarkReceived:
      raw.canMarkReceived ?? (raw as { CanMarkReceived?: boolean }).CanMarkReceived ?? false,
    statusHistory: (
      (raw.statusHistory as unknown[] | undefined) ??
      (raw as { StatusHistory?: unknown[] }).StatusHistory ??
      []
    ).map((item) =>
      normalizeOrderStatusHistory(item as Parameters<typeof normalizeOrderStatusHistory>[0]),
    ),
  }
}

export function normalizeOrdersResponse(
  data: AdminOrdersResponse & {
    Items?: RawOrder[]
    Page?: number
    PageSize?: number
    TotalCount?: number
    TotalPages?: number
  },
): AdminOrdersResponse {
  return {
    page: data.page ?? data.Page ?? 1,
    pageSize: data.pageSize ?? data.PageSize ?? 20,
    totalCount: data.totalCount ?? data.TotalCount ?? 0,
    totalPages: data.totalPages ?? data.TotalPages ?? 1,
    items: (data.items ?? data.Items ?? []).map((item) => normalizeOrder(item)),
  }
}

export function normalizeOrderStats(data: Record<string, unknown>): AdminOrderStats {
  return {
    totalOrders: Number(data.totalOrders ?? data.TotalOrders ?? 0),
    totalOrdersChangePercent: Number(
      data.totalOrdersChangePercent ?? data.TotalOrdersChangePercent ?? 0,
    ),
    orderedCount: Number(data.orderedCount ?? data.OrderedCount ?? 0),
    shippingCount: Number(data.shippingCount ?? data.ShippingCount ?? 0),
    deliveredCount: Number(data.deliveredCount ?? data.DeliveredCount ?? 0),
  }
}

type RawShippingProvider = AdminShippingProvider & {
  Id?: string
  CompanyName?: string
  ImgPath?: string | null
  Email?: string
  PhoneNumber?: string | null
  CityName?: string | null
  IsActive?: boolean
  TotalShipments?: number
  PostCount?: number
  RegistrationDate?: string
  FromCountryName?: string
  FromPortName?: string
  ToCountryName?: string
  ToPortName?: string
  RouteSummary?: string
}

type RawShippingDetail = AdminShippingProviderDetail & {
  FullName?: string
  LandNumber?: string | null
  CommercialRegister?: string | null
  TaxNumber?: string | null
  FromCountryId?: number
  FromPortId?: number
  ToCountryId?: number
  ToPortId?: number
  FromCountryName?: string
  FromCountryNameAr?: string | null
  FromPortName?: string
  FromPortUnLocode?: string | null
  ToCountryName?: string
  ToCountryNameAr?: string | null
  ToPortName?: string
  ToPortUnLocode?: string | null
  RouteSummary?: string
  RouteSummaryAr?: string
  Container20ftPriceUsd?: number
  Container40ftPriceUsd?: number
  Container20ftPriceFormatted?: string
  Container40ftPriceFormatted?: string
  RegistrationLinkSent?: boolean
  Stats?: RawShippingStats
  Shipments?: RawShipmentLogItem[]
  LatestPostId?: number
  PostStatus?: number
  PostStatusLabelAr?: string
  IsPostApproved?: boolean
  CanApprovePost?: boolean
}

type RawShippingStats = AdminShippingStats & {
  TotalShipments?: number
  Completed?: number
  InDelivery?: number
  Late?: number
  SuccessRate?: number
}

type RawShipmentLogItem = AdminShipmentLogItem & {
  ShipmentCode?: string
  OrderId?: number
  StatusId?: number
  StatusName?: string
  StatusLabelAr?: string
  CreatedAt?: string
}

export function normalizeShippingStats(raw: RawShippingStats): AdminShippingStats {
  return {
    totalShipments: raw.totalShipments ?? raw.TotalShipments ?? 0,
    completed: raw.completed ?? raw.Completed ?? 0,
    inDelivery: raw.inDelivery ?? raw.InDelivery ?? 0,
    late: raw.late ?? raw.Late ?? 0,
    successRate: raw.successRate ?? raw.SuccessRate ?? 0,
  }
}

export function normalizeShipmentLogItem(raw: RawShipmentLogItem): AdminShipmentLogItem {
  return {
    id: raw.id,
    shipmentCode: raw.shipmentCode ?? raw.ShipmentCode ?? '',
    orderId: raw.orderId ?? raw.OrderId ?? 0,
    statusId: raw.statusId ?? raw.StatusId ?? 0,
    statusName: raw.statusName ?? raw.StatusName ?? '',
    statusLabelAr: raw.statusLabelAr ?? raw.StatusLabelAr ?? '',
    createdAt: raw.createdAt ?? raw.CreatedAt ?? '',
  }
}

export function normalizeShippingProvider(raw: RawShippingProvider): AdminShippingProvider {
  return {
    id: String(raw.id ?? raw.Id ?? ''),
    companyName: raw.companyName ?? raw.CompanyName ?? '',
    imgPath: raw.imgPath ?? raw.ImgPath ?? null,
    email: raw.email ?? raw.Email ?? '',
    phoneNumber: raw.phoneNumber ?? raw.PhoneNumber ?? null,
    cityName: raw.cityName ?? raw.CityName ?? null,
    isActive: raw.isActive ?? raw.IsActive ?? false,
    totalShipments: raw.totalShipments ?? raw.TotalShipments ?? 0,
    postCount: raw.postCount ?? raw.PostCount ?? 0,
    registrationDate: raw.registrationDate ?? raw.RegistrationDate ?? '',
    fromCountryName: raw.fromCountryName ?? raw.FromCountryName ?? '',
    fromPortName: raw.fromPortName ?? raw.FromPortName ?? '',
    toCountryName: raw.toCountryName ?? raw.ToCountryName ?? '',
    toPortName: raw.toPortName ?? raw.ToPortName ?? '',
    routeSummary: raw.routeSummary ?? raw.RouteSummary ?? '',
  }
}

export function normalizeShippingProviderDetail(
  raw: RawShippingDetail,
): AdminShippingProviderDetail {
  const base = normalizeShippingProvider(raw)
  return {
    ...base,
    fullName: raw.fullName ?? raw.FullName ?? '',
    landNumber: raw.landNumber ?? raw.LandNumber ?? null,
    commercialRegister: raw.commercialRegister ?? raw.CommercialRegister ?? null,
    taxNumber: raw.taxNumber ?? raw.TaxNumber ?? null,
    fromCountryId: raw.fromCountryId ?? raw.FromCountryId ?? 0,
    fromPortId: raw.fromPortId ?? raw.FromPortId ?? 0,
    toCountryId: raw.toCountryId ?? raw.ToCountryId ?? 0,
    toPortId: raw.toPortId ?? raw.ToPortId ?? 0,
    fromCountryNameAr: raw.fromCountryNameAr ?? raw.FromCountryNameAr ?? null,
    fromPortUnLocode: raw.fromPortUnLocode ?? raw.FromPortUnLocode ?? null,
    toCountryNameAr: raw.toCountryNameAr ?? raw.ToCountryNameAr ?? null,
    toPortUnLocode: raw.toPortUnLocode ?? raw.ToPortUnLocode ?? null,
    routeSummaryAr: raw.routeSummaryAr ?? raw.RouteSummaryAr ?? '',
    container20ftPriceUsd: raw.container20ftPriceUsd ?? raw.Container20ftPriceUsd ?? 0,
    container40ftPriceUsd: raw.container40ftPriceUsd ?? raw.Container40ftPriceUsd ?? 0,
    container20ftPriceFormatted:
      raw.container20ftPriceFormatted ?? raw.Container20ftPriceFormatted ?? '',
    container40ftPriceFormatted:
      raw.container40ftPriceFormatted ?? raw.Container40ftPriceFormatted ?? '',
    registrationLinkSent: raw.registrationLinkSent ?? raw.RegistrationLinkSent ?? false,
    stats: normalizeShippingStats(raw.stats ?? raw.Stats ?? {}),
    shipments: (raw.shipments ?? raw.Shipments ?? []).map((item) =>
      normalizeShipmentLogItem(item),
    ),
    latestPostId: raw.latestPostId ?? raw.LatestPostId ?? 0,
    postStatus: raw.postStatus ?? raw.PostStatus ?? 0,
    postStatusLabelAr: raw.postStatusLabelAr ?? raw.PostStatusLabelAr ?? '',
    isPostApproved: raw.isPostApproved ?? raw.IsPostApproved ?? false,
    canApprovePost: raw.canApprovePost ?? raw.CanApprovePost ?? false,
  }
}

export function normalizeShippingProvidersResponse(
  data: AdminShippingProvidersResponse & {
    Items?: RawShippingProvider[]
    Page?: number
    PageSize?: number
    TotalCount?: number
    TotalPages?: number
  },
): AdminShippingProvidersResponse {
  return {
    page: data.page ?? data.Page ?? 1,
    pageSize: data.pageSize ?? data.PageSize ?? 20,
    totalCount: data.totalCount ?? data.TotalCount ?? 0,
    totalPages: data.totalPages ?? data.TotalPages ?? 1,
    items: (data.items ?? data.Items ?? []).map((item) => normalizeShippingProvider(item)),
  }
}

type RawUserCompanyImage = {
  id?: number
  Id?: number
  imagePath?: string
  ImagePath?: string
  isPrimary?: boolean
  IsPrimary?: boolean
}

type RawUserDetail = AdminUserDetail & {
  PhoneNumber?: string | null
  LandNumber?: string | null
  RoleName?: string
  RoleLabelAr?: string
  TypeLabelAr?: string
  StatusLabelAr?: string
  IsActive?: boolean
  IsVerified?: boolean
  IsRejected?: boolean
  isRejected?: boolean
  IsApproved?: boolean
  isApproved?: boolean
  RejectionReason?: string | null
  rejectionReason?: string | null
  CanDeactivate?: boolean
  canDeactivate?: boolean
  CanDelete?: boolean
  canDelete?: boolean
  CreatedAt?: string
  ImgPath?: string | null
  CompanyName?: string | null
  FullNameEn?: string | null
  FullNameAr?: string | null
  CompanyNameEn?: string | null
  CompanyNameAr?: string | null
  LicenseNumber?: string | null
  LicencePath?: string | null
  CommercialRegister?: string | null
  TaxNumber?: string | null
  PendingProfileChanges?: {
    companyName?: string | null
    CompanyName?: string | null
    commercialRegister?: string | null
    CommercialRegister?: string | null
    taxNumber?: string | null
    TaxNumber?: string | null
    landNumber?: string | null
    LandNumber?: string | null
    fullName?: string | null
    FullName?: string | null
    phoneNumber?: string | null
    PhoneNumber?: string | null
  } | null
  pendingProfileChanges?: {
    companyName?: string | null
    CompanyName?: string | null
    commercialRegister?: string | null
    CommercialRegister?: string | null
    taxNumber?: string | null
    TaxNumber?: string | null
    landNumber?: string | null
    LandNumber?: string | null
    fullName?: string | null
    FullName?: string | null
    phoneNumber?: string | null
    PhoneNumber?: string | null
  } | null
  CompanyImages?: RawUserCompanyImage[]
  Addresses?: Record<string, unknown>[]
  OrdersCount?: number
  CanApprove?: boolean
  IsCustomer?: boolean
  isCustomer?: boolean
}

export function normalizeUserDetail(raw: RawUserDetail): AdminUserDetail {
  const roleId = raw.roleId ?? 0
  const isActive = raw.isActive ?? raw.IsActive ?? false
  const isVerified = raw.isVerified ?? raw.IsVerified ?? false
  const isRejected = raw.isRejected ?? raw.IsRejected ?? false
  const isApproved = raw.isApproved ?? raw.IsApproved ?? true
  const isCustomer = raw.isCustomer ?? raw.IsCustomer ?? false
  const pendingRaw = raw.pendingProfileChanges ?? raw.PendingProfileChanges
  const hasPendingProfileChanges = Boolean(pendingRaw)

  return {
    id: raw.id,
    fullName: raw.fullName,
    fullNameEn: raw.fullNameEn ?? raw.FullNameEn ?? null,
    fullNameAr: raw.fullNameAr ?? raw.FullNameAr ?? null,
    email: raw.email,
    phoneNumber: raw.phoneNumber ?? raw.PhoneNumber ?? null,
    landNumber: raw.landNumber ?? raw.LandNumber ?? null,
    roleId,
    roleName:
      raw.roleName ??
      raw.RoleName ??
      (isCustomerCompanyAccount(roleId, isCustomer) ? 'Customer' : ''),
    roleLabelAr: raw.roleLabelAr ?? raw.RoleLabelAr ?? '',
    typeLabelAr:
      raw.typeLabelAr ||
      raw.TypeLabelAr ||
      (isCustomerCompanyAccount(roleId, isCustomer)
        ? 'عميل'
        : roleId === 2
          ? 'مورد'
          : roleId === 3
            ? 'عميل'
            : roleId === 1
              ? 'مدير'
              : '—'),
    statusLabelAr:
      raw.statusLabelAr ||
      raw.StatusLabelAr ||
      resolveUserStatusLabelAr(
        isActive,
        isVerified,
        roleId,
        isRejected,
        isApproved,
        hasPendingProfileChanges,
      ),
    isActive,
    isVerified,
    isCustomer,
    isRejected,
    rejectionReason: raw.rejectionReason ?? raw.RejectionReason ?? null,
    createdAt: raw.createdAt ?? raw.CreatedAt ?? '',
    imgPath: raw.imgPath ?? raw.ImgPath ?? null,
    companyName: raw.companyName ?? raw.CompanyName ?? null,
    companyNameEn: raw.companyNameEn ?? raw.CompanyNameEn ?? null,
    companyNameAr: raw.companyNameAr ?? raw.CompanyNameAr ?? null,
    licenseNumber: raw.licenseNumber ?? raw.LicenseNumber ?? null,
    licencePath: raw.licencePath ?? raw.LicencePath ?? null,
    commercialRegister: raw.commercialRegister ?? raw.CommercialRegister ?? null,
    taxNumber: raw.taxNumber ?? raw.TaxNumber ?? null,
    pendingProfileChanges: (() => {
      const pending = raw.pendingProfileChanges ?? raw.PendingProfileChanges
      if (!pending) return null
      const companyName = pending.companyName ?? pending.CompanyName ?? null
      const commercialRegister =
        pending.commercialRegister ?? pending.CommercialRegister ?? null
      const taxNumber = pending.taxNumber ?? pending.TaxNumber ?? null
      const landNumber = pending.landNumber ?? pending.LandNumber ?? null
      const fullName = pending.fullName ?? pending.FullName ?? null
      const phoneNumber = pending.phoneNumber ?? pending.PhoneNumber ?? null
      if (
        companyName == null &&
        commercialRegister == null &&
        taxNumber == null &&
        landNumber == null &&
        fullName == null &&
        phoneNumber == null
      ) {
        return null
      }
      return {
        companyName,
        commercialRegister,
        taxNumber,
        landNumber,
        fullName,
        phoneNumber,
      }
    })(),
    companyImages: (raw.companyImages ?? raw.CompanyImages ?? []).map((image: RawUserCompanyImage) => ({
      id: image.id ?? image.Id ?? 0,
      imagePath: image.imagePath ?? image.ImagePath ?? '',
      isPrimary: image.isPrimary ?? image.IsPrimary ?? false,
    })),
    addresses: (raw.addresses ?? raw.Addresses ?? []).map((item: Record<string, unknown>) => ({
      addressId: String(item.addressId ?? item.AddressId ?? ''),
      addressTypeId: Number(item.addressTypeId ?? item.AddressTypeId ?? 4),
      addressTypeNameEn: String(item.addressTypeNameEn ?? item.AddressTypeNameEn ?? ''),
      addressTypeNameAr: String(item.addressTypeNameAr ?? item.AddressTypeNameAr ?? ''),
      formattedAddress: String(item.formattedAddress ?? item.FormattedAddress ?? ''),
      postalCode: (item.postalCode ?? item.PostalCode ?? null) as string | null,
      latitude:
        item.latitude != null || item.Latitude != null
          ? Number(item.latitude ?? item.Latitude)
          : null,
      longitude:
        item.longitude != null || item.Longitude != null
          ? Number(item.longitude ?? item.Longitude)
          : null,
      coordinates: (item.coordinates ?? item.Coordinates ?? null) as string | null,
      mapsUrl: (item.mapsUrl ?? item.MapsUrl ?? null) as string | null,
    })),
    ordersCount: raw.ordersCount ?? raw.OrdersCount ?? 0,
    canApprove:
      raw.canApprove ??
      raw.CanApprove ??
      (!isRejected &&
        (((roleId === 2 || roleId === 5) && !isApproved && isVerified) ||
          Boolean(raw.pendingProfileChanges ?? raw.PendingProfileChanges))),
    canDeactivate: raw.canDeactivate ?? raw.CanDeactivate ?? roleId !== 1,
    canDelete:
      raw.canDelete ??
      raw.CanDelete ??
      (roleId !== 1 && (!isApproved || (raw.ordersCount ?? raw.OrdersCount ?? 0) === 0)),
  }
}

type RawGeoCountry = {
  id?: number
  Id?: number
  countryNameEn?: string
  CountryNameEn?: string
  countryNameAr?: string | null
  CountryNameAr?: string | null
  iso2Code?: string
  Iso2Code?: string
}

type RawGeoPort = {
  id?: number
  Id?: number
  portNameEn?: string
  PortNameEn?: string
  unLocode?: string | null
  UnLocode?: string | null
}

export function normalizeGeoCountries(data: RawGeoCountry[] | null | undefined): GeoCountry[] {
  return (data ?? [])
    .map((raw) => ({
      id: Number(raw.id ?? raw.Id ?? 0),
      countryNameEn: String(raw.countryNameEn ?? raw.CountryNameEn ?? '').trim(),
      countryNameAr: raw.countryNameAr ?? raw.CountryNameAr ?? null,
      iso2Code: String(raw.iso2Code ?? raw.Iso2Code ?? '').trim(),
    }))
    .filter((country) => country.id > 0 && country.countryNameEn.length > 0)
    .sort((a, b) => a.countryNameEn.localeCompare(b.countryNameEn))
}

export function normalizeGeoPortsByCountry(
  data: { country?: string; Country?: string; ports?: RawGeoPort[]; Ports?: RawGeoPort[] } | null | undefined,
): GeoPortsByCountryResponse {
  const ports = (data?.ports ?? data?.Ports ?? [])
    .map((raw) => ({
      id: Number(raw.id ?? raw.Id ?? 0),
      portNameEn: String(raw.portNameEn ?? raw.PortNameEn ?? '').trim(),
      unLocode: raw.unLocode ?? raw.UnLocode ?? null,
    }))
    .filter((port) => port.id > 0 && port.portNameEn.length > 0)
    .sort((a, b) => a.portNameEn.localeCompare(b.portNameEn))

  return {
    country: String(data?.country ?? data?.Country ?? ''),
    ports,
  }
}

type RawHomeBanner = {
  id?: number
  Id?: number
  imagePath?: string
  ImagePath?: string
  linkUrl?: string
  LinkUrl?: string
  displayOrder?: number
  DisplayOrder?: number
}

export function normalizeHomeBanner(raw: RawHomeBanner): HomeBanner {
  return {
    id: raw.id ?? raw.Id ?? 0,
    imagePath: raw.imagePath ?? raw.ImagePath ?? '',
    linkUrl: raw.linkUrl ?? raw.LinkUrl ?? '',
    displayOrder: raw.displayOrder ?? raw.DisplayOrder ?? 0,
  }
}

export function normalizeHomeBannersResponse(raw: unknown): HomeBannersResponse {
  const data = raw as { count?: number; Count?: number; items?: RawHomeBanner[]; Items?: RawHomeBanner[] }
  const items = (data.items ?? data.Items ?? []).map(normalizeHomeBanner)
  return {
    count: data.count ?? data.Count ?? items.length,
    items: [...items].sort((a, b) => a.displayOrder - b.displayOrder),
  }
}

