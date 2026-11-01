const trimSlash = (value: string) => value.replace(/\/+$/, '')

export const API_BASE_URL = trimSlash(
  import.meta.env.VITE_API_BASE_URL || 'https://api.alrasmarketapp.com/api',
)

export const MEDIA_BASE_URL = trimSlash(
  import.meta.env.VITE_MEDIA_BASE_URL || 'https://cdn.alrasmarketapp.com',
)

/** Web OAuth client — the same one the mobile app passes as `serverClientId`. */
export const GOOGLE_WEB_CLIENT_ID =
  import.meta.env.VITE_GOOGLE_CLIENT_ID ||
  '592516755028-omkgbtoesqbj89g1ds07h6jqu4r7979i.apps.googleusercontent.com'

export const LANDING_URL = 'https://alrasmarketapp.com'
export const PRIVACY_URL = `${LANDING_URL}/privacy`

export const SUPPORT_PHONE_DISPLAY = '+971 4 228 5598'
export const SUPPORT_PHONE_TEL = '+97142285598'
export const SUPPORT_EMAIL = 'support@alrasmarketapp.com'
