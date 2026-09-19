export type ShippingProviderPayload = {
  companyName: string
  fullName: string
  email: string
  phoneNumber: string
  fromCountryName: string
  fromPortName: string
  toCountryName: string
  toPortName: string
  container20ftPriceUsd: number
  container40ftPriceUsd: number
}

export type ShippingPostPayload = {
  fromCountryName: string
  fromPortName: string
  toCountryName: string
  toPortName: string
  phoneNumber: string
  container20ftPriceUsd: number | null
  container40ftPriceUsd: number | null
  details: string | null
  minDurationDays: number | null
  maxDurationDays: number | null
}

/** @deprecated Use ShippingProviderPayload */
export type CreateShippingProviderPayload = ShippingProviderPayload
