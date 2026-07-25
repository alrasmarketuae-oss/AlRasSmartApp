/**
 * API: https://api.alrasmarketapp.com
 * Media CDN: https://cdn.alrasmarketapp.com
 *
 * dev + prod → اتصال مباشر بالسيرفر (بدون Vite proxy)
 */

export const PRODUCTION_API = 'https://api.alrasmarketapp.com'
export const PRODUCTION_MEDIA_CDN = 'https://cdn.alrasmarketapp.com'

const trim = (v) => (v ?? '').trim().replace(/\/$/, '')

export const API_BASE_URL = trim(import.meta.env.VITE_API_BASE_URL) || PRODUCTION_API

/** CDN/public media origin. Falls back to dedicated CDN host when unset. */
export const ASSETS_BASE_URL =
  trim(import.meta.env.VITE_MEDIA_BASE_URL) || PRODUCTION_MEDIA_CDN

/** Cloudflare Turnstile site key (public). */
export const TURNSTILE_SITE_KEY = trim(
  import.meta.env.VITE_TURNSTILE_SITE_KEY,
) || '0x4AAAAAAD7I9E75I-MfhsJ-'

export function apiUrl(path) {
  const p = path.startsWith('/') ? path : `/${path}`
  return `${API_BASE_URL}${p}`
}

export function getApiOriginLabel() {
  return API_BASE_URL
}
