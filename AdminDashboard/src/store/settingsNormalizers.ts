import type { CategoryCommission, SystemSettings } from '../types/adminSettings'

type RawCategoryCommission = CategoryCommission & {
  CategoryId?: number
  NameEn?: string
  NameAr?: string
  CommissionPercent?: number
}

type RawSettings = SystemSettings & {
  RetailCommissionPercent?: number
  BookingCommissionPercent?: number
  RequestsCommissionPercent?: number
  OffersCommissionPercent?: number
  ShippingCommissionPercent?: number
  CategoryCommissions?: RawCategoryCommission[]
  AppName?: string
  SupportEmail?: string | null
  PhoneNumber?: string | null
  LandlineNumber?: string | null
  Timezone?: string | null
  Address?: string | null
  FeaturedAdPriceAed?: number
  AdDisplayDurationDays?: number
  AndroidLatestVersion?: string | null
  IosLatestVersion?: string | null
  AndroidMinVersion?: string | null
  IosMinVersion?: string | null
  AndroidStoreUrl?: string | null
  IosStoreUrl?: string | null
  AppUpdateMessageAr?: string | null
  AppUpdateMessageEn?: string | null
  UpdatedAt?: string
}

function normalizeCategoryCommission(raw: RawCategoryCommission): CategoryCommission {
  return {
    categoryId: raw.categoryId ?? raw.CategoryId ?? 0,
    nameEn: raw.nameEn ?? raw.NameEn ?? '',
    nameAr: raw.nameAr ?? raw.NameAr ?? '',
    commissionPercent: raw.commissionPercent ?? raw.CommissionPercent ?? 0,
  }
}

export function normalizeSystemSettings(raw: RawSettings): SystemSettings {
  const categoryCommissions = (raw.categoryCommissions ?? raw.CategoryCommissions ?? []).map(
    normalizeCategoryCommission,
  )

  return {
    retailCommissionPercent:
      raw.retailCommissionPercent ?? raw.RetailCommissionPercent ?? 0,
    bookingCommissionPercent:
      raw.bookingCommissionPercent ?? raw.BookingCommissionPercent ?? 0,
    requestsCommissionPercent:
      raw.requestsCommissionPercent ?? raw.RequestsCommissionPercent ?? 0,
    offersCommissionPercent:
      raw.offersCommissionPercent ?? raw.OffersCommissionPercent ?? 0,
    shippingCommissionPercent:
      raw.shippingCommissionPercent ?? raw.ShippingCommissionPercent ?? 0,
    categoryCommissions,
    appName: raw.appName ?? raw.AppName ?? '',
    supportEmail: raw.supportEmail ?? raw.SupportEmail ?? null,
    phoneNumber: raw.phoneNumber ?? raw.PhoneNumber ?? null,
    landlineNumber: raw.landlineNumber ?? raw.LandlineNumber ?? null,
    timezone: raw.timezone ?? raw.Timezone ?? null,
    address: raw.address ?? raw.Address ?? null,
    featuredAdPriceAed: raw.featuredAdPriceAed ?? raw.FeaturedAdPriceAed ?? 0,
    adDisplayDurationDays:
      raw.adDisplayDurationDays ?? raw.AdDisplayDurationDays ?? 0,
    androidLatestVersion: raw.androidLatestVersion ?? raw.AndroidLatestVersion ?? null,
    iosLatestVersion: raw.iosLatestVersion ?? raw.IosLatestVersion ?? null,
    androidMinVersion: raw.androidMinVersion ?? raw.AndroidMinVersion ?? null,
    iosMinVersion: raw.iosMinVersion ?? raw.IosMinVersion ?? null,
    androidStoreUrl: raw.androidStoreUrl ?? raw.AndroidStoreUrl ?? null,
    iosStoreUrl: raw.iosStoreUrl ?? raw.IosStoreUrl ?? null,
    appUpdateMessageAr: raw.appUpdateMessageAr ?? raw.AppUpdateMessageAr ?? null,
    appUpdateMessageEn: raw.appUpdateMessageEn ?? raw.AppUpdateMessageEn ?? null,
    updatedAt: raw.updatedAt ?? raw.UpdatedAt ?? '',
  }
}
