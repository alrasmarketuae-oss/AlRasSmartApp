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

/** Load an asset for download/blur. Prefer public CDN, then authenticated admin proxy. */
export async function fetchAdminAssetBlob(urlOrPath: string): Promise<Blob> {
  const absolute = resolveAssetUrl(urlOrPath)
  if (absolute.startsWith('http://') || absolute.startsWith('https://')) {
    try {
      const direct = await fetch(absolute, { method: 'GET', cache: 'no-store', mode: 'cors' })
      if (direct.ok) {
        return direct.blob()
      }
    } catch {
      // Fall through to authenticated admin proxy.
    }
  }

  const relativePath = toAssetRelativePath(urlOrPath)
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
      redirect: 'follow',
    },
  )

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
