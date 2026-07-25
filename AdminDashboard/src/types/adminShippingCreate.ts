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

/** @deprecated Use ShippingProviderPayload */
export type CreateShippingProviderPayload = ShippingProviderPayload
