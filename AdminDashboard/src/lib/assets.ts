import { ASSETS_BASE_URL, PRODUCTION_API } from '../config/api.js'

/** Legacy R2 public host — rewritten to the CDN when resolving absolute media URLs. */
const LEGACY_MEDIA_HOST = 'pub-63bb2df7433f4fd4a71249ac40f944ca.r2.dev'

const API_MEDIA_HOST = (() => {
  try {
    return new URL(PRODUCTION_API).hostname.toLowerCase()
  } catch {
    return 'api.alrasmarketapp.com'
  }
})()

function rewriteMediaHost(absoluteUrl: string, fromHost: string): string {
  try {
    const uri = new URL(absoluteUrl)
    if (uri.hostname.toLowerCase() !== fromHost) return absoluteUrl
    if (!ASSETS_BASE_URL) return absoluteUrl
    const cdn = new URL(ASSETS_BASE_URL)
    uri.protocol = cdn.protocol
    uri.host = cdn.host
    uri.port = cdn.port
    return uri.toString()
  } catch {
    return absoluteUrl
  }
}

function rewriteLegacyMediaHost(absoluteUrl: string): string {
  return rewriteMediaHost(absoluteUrl, LEGACY_MEDIA_HOST)
}

function rewriteApiMediaHost(absoluteUrl: string): string {
  const rewritten = rewriteMediaHost(absoluteUrl, API_MEDIA_HOST)
  if (rewritten !== absoluteUrl) return rewritten

  // Also rewrite dev/staging API hosts when they serve media paths.
  try {
    const uri = new URL(absoluteUrl)
    const path = uri.pathname.toLowerCase()
    const looksLikeMedia =
      path.includes('/images/profiles/') ||
      path.includes('/company-images/') ||
      path.includes('/images/categories/')
    if (!looksLikeMedia || !ASSETS_BASE_URL) return absoluteUrl
    const cdn = new URL(ASSETS_BASE_URL)
    uri.protocol = cdn.protocol
    uri.host = cdn.host
    uri.port = cdn.port
    return uri.toString()
  } catch {
    return absoluteUrl
  }
}

/** يحوّل مسار الصورة النسبي من الـ API إلى رابط كامل على الـ CDN */
export function resolveAssetUrl(path: string | null | undefined): string {
  if (!path?.trim()) return ''

  const trimmed = path.trim()
  const slashNormalized = trimmed.replace(/\\/g, '/')
  const unwrappedAbsolute = slashNormalized.replace(/^\/+(https?:\/\/)/i, '$1')

  if (unwrappedAbsolute.startsWith('http://') || unwrappedAbsolute.startsWith('https://')) {
    return rewriteApiMediaHost(rewriteLegacyMediaHost(unwrappedAbsolute))
  }

  const normalized = slashNormalized.startsWith('/') ? slashNormalized : `/${slashNormalized}`
  if (!ASSETS_BASE_URL) {
    return normalized
  }

  return `${ASSETS_BASE_URL}${normalized}`
}
