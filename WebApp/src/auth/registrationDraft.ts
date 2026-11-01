import type { RegisterAddress } from './authApi'

export type RegistrationDraft = {
  fullName: string
  companyName: string
  email: string
  password: string
  phoneNumber: string
  landNumber: string
  licenseNumber: string
  taxNumber: string
  website: string
  address: RegisterAddress
  addressSummary: string
  profileLogo: File | null
}

/** Kept in memory only so the password never reaches the URL or web storage. */
let draft: RegistrationDraft | null = null

export const registrationDraft = {
  get: () => draft,
  set: (next: RegistrationDraft) => {
    draft = next
  },
  clear: () => {
    draft = null
  },
}
