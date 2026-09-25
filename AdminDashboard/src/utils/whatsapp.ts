/** Digits-only phone for wa.me links. */
export function digitsOnlyPhone(phone: string): string {
  return phone.replace(/\D/g, '')
}

/**
 * Split a phone field that may contain several numbers
 * (e.g. "+971 55…, +971 50…; +971 52…").
 */
export function splitPhoneNumbers(phone: string | null | undefined): string[] {
  if (!phone?.trim()) return []
  return phone
    .split(/[,;/|]+|\s{2,}|\n+/)
    .map((part) => part.trim())
    .filter((part) => digitsOnlyPhone(part).length >= 8)
}

/** Build https://wa.me/{digits} for a single phone, or null if too short. */
export function whatsappHref(phone: string | null | undefined): string | null {
  if (!phone?.trim()) return null
  const digits = digitsOnlyPhone(phone)
  if (digits.length < 8) return null
  return `https://wa.me/${digits}`
}
