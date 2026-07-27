import { apiUrl } from '../config/api.js'
import { resolveAssetUrl } from '../lib/assets'
import { getAuthToken } from '../lib/authStorage'

/** Extract a wwwroot-relative path from a full asset URL or relative path. */
export function filenameFromAssetPath(path: string, fallback = 'file'): string {
  const base = path.split(/[/\\]/).pop()?.trim()
  return base && base.length > 0 ? base : fallback
}

export function toAssetRelativePath(urlOrPath: string): string {
  const trimmed = urlOrPath.trim()
  if (!trimmed) return ''

  try {
    if (/^https?:\/\//i.test(trimmed)) {
      return new URL(trimmed).pathname.replace(/^\/+/, '')
    }
  } catch {
    // fall through
  }

  return trimmed.replace(/\\/g, '/').replace(/^\/+/, '')
}

/**
 * Load an asset for download/blur via the authenticated API proxy.
 * Do not fetch the public CDN directly — R2/CDN does not send CORS headers
 * for the admin dashboard origin (browser reports a CORS error on save).
 */
export async function fetchAdminAssetBlob(urlOrPath: string): Promise<Blob> {
  const relativePath =
    toAssetRelativePath(urlOrPath) || toAssetRelativePath(resolveAssetUrl(urlOrPath))
  if (!relativePath) {
    throw new Error('Invalid asset path')
  }

  const token = getAuthToken()
  const response = await fetch(
    apiUrl(`/api/admin/assets?path=${encodeURIComponent(relativePath)}`),
    {
      method: 'GET',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      cache: 'no-store',
      // Manual: a CDN redirect would drop Authorization and hit CORS again.
      redirect: 'manual',
    },
  )

  if (response.type === 'opaqueredirect' || (response.status >= 300 && response.status < 400)) {
    throw new Error(`Download redirected unexpectedly (${response.status})`)
  }

  if (!response.ok) {
    throw new Error(`Download failed (${response.status})`)
  }

  return response.blob()
}

/** Download a remote asset (image/document) with a suggested filename. */
export async function downloadAsset(
  url: string,
  filename: string,
): Promise<void> {
  if (!url?.trim()) return

  try {
    const blob = await fetchAdminAssetBlob(url)
    const objectUrl = URL.createObjectURL(blob)
    const anchor = document.createElement('a')
    anchor.href = objectUrl
    anchor.download = filename
    anchor.rel = 'noopener'
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
    URL.revokeObjectURL(objectUrl)
  } catch {
    // Last resort: open original URL in a new tab.
    const anchor = document.createElement('a')
    anchor.href = resolveAssetUrl(url) || url
    anchor.download = filename
    anchor.target = '_blank'
    anchor.rel = 'noopener'
    document.body.appendChild(anchor)
    anchor.click()
    anchor.remove()
  }
}
