export type AdminLiveCounts = {
  pendingUsers: number
  pendingProfileEdits: number
  pendingAds: number
  pendingAdEdits: number
  pendingOrders: number
  pendingRetailOrders: number
  pendingBookingOrders: number
  pendingOffersOrders: number
  pendingCategoriesOrders: number
  pendingOffers: number
  pendingRequestOfferAds: number
  pendingShippingAds: number
}

export type AdminRealtimeAlertType =
  | 'newUser'
  | 'profileEdit'
  | 'newAd'
  | 'adEdit'
  | 'newOrder'
  | 'newOffer'
  | 'newShippingAd'
  | 'chat'

export type AdminRealtimeAlert = {
  type: AdminRealtimeAlertType
  referenceId?: string | null
  displayName?: string | null
  secondaryName?: string | null
  tertiaryName?: string | null
  quantity?: string | null
  unitName?: string | null
  details?: string | null
}

export type AdminNavCounts = {
  users: number
  profileEdits: number
  ads: number
  adEdits: number
  retailOrders: number
  bookingOrders: number
  offersOrders: number
  categoriesOrders: number
  offers: number
  shipping: number
  chat: number
}

function pickNumber(...values: unknown[]): number {
  for (const value of values) {
    if (typeof value === 'number' && Number.isFinite(value)) {
      return value
    }
  }
  return 0
}

export function normalizeAdminLiveCounts(raw: Record<string, unknown>): AdminLiveCounts {
  return {
    pendingUsers: pickNumber(raw.pendingUsers, raw.PendingUsers),
    pendingProfileEdits: pickNumber(raw.pendingProfileEdits, raw.PendingProfileEdits),
    pendingAds: pickNumber(raw.pendingAds, raw.PendingAds),
    pendingAdEdits: pickNumber(raw.pendingAdEdits, raw.PendingAdEdits),
    pendingOrders: pickNumber(raw.pendingOrders, raw.PendingOrders),
    pendingRetailOrders: pickNumber(raw.pendingRetailOrders, raw.PendingRetailOrders),
    pendingBookingOrders: pickNumber(raw.pendingBookingOrders, raw.PendingBookingOrders),
    pendingOffersOrders: pickNumber(raw.pendingOffersOrders, raw.PendingOffersOrders),
    pendingCategoriesOrders: pickNumber(
      raw.pendingCategoriesOrders,
      raw.PendingCategoriesOrders,
    ),
    pendingOffers: pickNumber(raw.pendingOffers, raw.PendingOffers),
    pendingRequestOfferAds: pickNumber(
      raw.pendingRequestOfferAds,
      raw.PendingRequestOfferAds,
    ),
    pendingShippingAds: pickNumber(raw.pendingShippingAds, raw.PendingShippingAds),
  }
}

export function normalizeAdminRealtimeAlert(raw: Record<string, unknown>): AdminRealtimeAlert {
  const type = String(raw.type ?? raw.Type ?? '').trim() as AdminRealtimeAlertType
  return {
    type: type || 'newUser',
    referenceId: (raw.referenceId ?? raw.ReferenceId ?? null) as string | null,
    displayName: (raw.displayName ?? raw.DisplayName ?? null) as string | null,
    secondaryName: (raw.secondaryName ?? raw.SecondaryName ?? null) as string | null,
    tertiaryName: (raw.tertiaryName ?? raw.TertiaryName ?? null) as string | null,
    quantity: (raw.quantity ?? raw.Quantity ?? null) as string | null,
    unitName: (raw.unitName ?? raw.UnitName ?? null) as string | null,
    details: (raw.details ?? raw.Details ?? null) as string | null,
  }
}
