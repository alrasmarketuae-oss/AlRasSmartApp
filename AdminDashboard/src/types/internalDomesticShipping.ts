export type InternalDomesticShippingRate = {
  id: number
  emirateNameEn: string
  emirateNameAr: string
  priceAed: number
}

export type InternalDomesticShippingResponse = {
  items: InternalDomesticShippingRate[]
  /** AED per kg above free 10 kg (0–255). */
  excessKgRateAed: number
  freeWeightKg: number
}

export type UpdateInternalDomesticShippingPayload = {
  rates: Array<{
    id: number
    priceAed: number
  }>
  excessKgRateAed: number
}
