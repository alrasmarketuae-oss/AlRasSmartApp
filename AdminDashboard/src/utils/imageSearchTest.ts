import { apiUrl } from '../config/api.js'
import { getAuthToken } from '../lib/authStorage'
import {
  normalizeImageSearchTestResult,
  type ImageSearchTestResult,
} from '../types/adminImageSearch'

export async function runImageSearchTest(file: File): Promise<ImageSearchTestResult> {
  const token = getAuthToken()
  const form = new FormData()
  form.append('File', file)

  const response = await fetch(apiUrl('/api/admin/image-search/test'), {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: form,
  })

  const data: unknown = await response.json().catch(() => ({}))

  if (!response.ok) {
    const error = data as { message?: string }
    throw new Error(error.message ?? 'Image search test failed.')
  }

  return normalizeImageSearchTestResult(data as Record<string, unknown>)
}
