import { ASSETS_BASE_URL } from '../config/api.js'

/** Legacy R2 public host — rewritten to the CDN when resolving absolute media URLs. */
const LEGACY_MEDIA_HOST = 'pub-63bb2df7433f4fd4a71249ac40f944ca.r2.dev'

function rewriteLegacyMediaHost(absoluteUrl: string): string {
  try {
    const uri = new URL(absoluteUrl)
    if (uri.hostname.toLowerCase() !== LEGACY_MEDIA_HOST) return absoluteUrl
    if (!ASSETS_BASE_URL) return absoluteUrl
    const cdn = new URL(ASSETS_BASE_URL)
    uri.protocol = cdn.protocol
    uri.host = cdn.host
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
    return rewriteLegacyMediaHost(unwrappedAbsolute)
  }

  const normalized = slashNormalized.startsWith('/') ? slashNormalized : `/${slashNormalized}`
  if (!ASSETS_BASE_URL) {
    return normalized
  }

  return `${ASSETS_BASE_URL}${normalized}`
}
