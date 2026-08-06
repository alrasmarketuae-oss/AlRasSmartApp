/** Digits-only phone for wa.me links. */
export function digitsOnlyPhone(phone: string): string {
  return phone.replace(/\D/g, '')
}

/** Build https://wa.me/{digits} or null if phone is too short. */
export function whatsappHref(phone: string | null | undefined): string | null {
  if (!phone?.trim()) return null
  const digits = digitsOnlyPhone(phone)
  if (digits.length < 8) return null
  return `https://wa.me/${digits}`
}
