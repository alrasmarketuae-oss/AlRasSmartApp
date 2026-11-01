import { MEDIA_BASE_URL } from './config'

const LEGACY_MEDIA_HOST = 'pub-63bb2df7433f4fd4a71249ac40f944ca.r2.dev'
const API_MEDIA_HOST = 'api.alrasmarketapp.com'

const MEDIA_PATH_MARKERS = [
  'product-images/',
  'product-videos/',
  'product-documents/',
  'home-banners/',
  'images/categories/',
  'branding/',
  'chat-',
]

function isMediaObjectPath(path: string) {
  const lower = path.toLowerCase().replace(/^\/+/, '')
  return MEDIA_PATH_MARKERS.some((marker) => lower.startsWith(marker) || lower.includes(`/${marker}`))
}

function rewriteMediaUrl(url: string) {
  let parsed: URL
  try {
    parsed = new URL(url)
  } catch {
    return url
  }
  const host = parsed.host.toLowerCase()
  const cdn = new URL(MEDIA_BASE_URL)
  if (host === cdn.host.toLowerCase()) return url
  const shouldRewrite = host === LEGACY_MEDIA_HOST || (host === API_MEDIA_HOST && isMediaObjectPath(parsed.pathname))
  if (!shouldRewrite) return url
  parsed.protocol = cdn.protocol
  parsed.host = cdn.host
  return parsed.toString()
}

/** Relative DB path or absolute URL → public CDN media URL (mirrors the app's resolver). */
export function resolveMediaUrl(path?: string | null): string {
  if (!path) return ''
  const trimmed = path.trim().replace(/\\/g, '/')
  if (!trimmed) return ''
  const unwrapped = trimmed.replace(/^\/+(https?:\/)/, '$1')
  if (/^https?:\/\//i.test(unwrapped)) return rewriteMediaUrl(unwrapped)
  return `${MEDIA_BASE_URL}/${unwrapped.replace(/^\/+/, '')}`
}
