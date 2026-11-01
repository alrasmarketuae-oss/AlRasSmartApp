import { API_BASE_URL } from './config'
import { readStoredSession } from './sessionStorage'

export class ApiError extends Error {
  readonly status: number
  readonly data: unknown

  constructor(message: string, status: number, data: unknown) {
    super(message)
    this.status = status
    this.data = data
  }
}

type Query = Record<string, string | number | boolean | undefined | null>

type RequestOptions = {
  query?: Query
  body?: unknown
  form?: FormData
  signal?: AbortSignal
  auth?: boolean
  /** Lets the request outlive the page (tab close / refresh). */
  keepalive?: boolean
}

function buildUrl(path: string, query?: Query) {
  const url = new URL(`${API_BASE_URL}${path.startsWith('/') ? path : `/${path}`}`)
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, String(value))
    }
  }
  return url.toString()
}

/** Pulls the most useful human message out of ASP.NET error payloads. */
export function extractErrorMessage(data: unknown, fallback: string): string {
  if (typeof data === 'string' && data.trim()) return data.trim()
  if (data && typeof data === 'object') {
    const record = data as Record<string, unknown>
    for (const key of ['message', 'Message', 'detail', 'title', 'error']) {
      const value = record[key]
      if (typeof value === 'string' && value.trim()) return value.trim()
    }
    const errors = record.errors
    if (errors && typeof errors === 'object') {
      const first = Object.values(errors as Record<string, unknown>).flat()[0]
      if (typeof first === 'string' && first.trim()) return first.trim()
    }
  }
  return fallback
}

async function request<T>(method: string, path: string, options: RequestOptions = {}): Promise<T> {
  const lang = localStorage.getItem('alras_web_lang') === 'ar' ? 'ar' : 'en'
  const headers: Record<string, string> = { Accept: 'application/json', 'Accept-Language': lang, 'X-Preferred-Language': lang }
  const token = options.auth === false ? null : readStoredSession()?.token
  if (token) headers.Authorization = `Bearer ${token}`

  let body: BodyInit | undefined
  if (options.form) {
    body = options.form
  } else if (options.body !== undefined) {
    headers['Content-Type'] = 'application/json'
    body = JSON.stringify(options.body)
  }

  let response: Response
  try {
    response = await fetch(buildUrl(path, options.query), { method, headers, body, signal: options.signal, keepalive: options.keepalive })
  } catch (error) {
    if ((error as Error).name === 'AbortError') throw error
    throw new ApiError('Network error. Check your connection and try again.', 0, null)
  }

  const text = await response.text()
  let data: unknown = null
  if (text) {
    try {
      data = JSON.parse(text)
    } catch {
      data = text
    }
  }

  if (!response.ok) {
    throw new ApiError(extractErrorMessage(data, `Request failed (${response.status})`), response.status, data)
  }
  return data as T
}

export const api = {
  get: <T>(path: string, options?: RequestOptions) => request<T>('GET', path, options),
  post: <T>(path: string, body?: unknown, options?: RequestOptions) => request<T>('POST', path, { ...options, body }),
  put: <T>(path: string, body?: unknown, options?: RequestOptions) => request<T>('PUT', path, { ...options, body }),
  patch: <T>(path: string, body?: unknown, options?: RequestOptions) => request<T>('PATCH', path, { ...options, body }),
  delete: <T>(path: string, options?: RequestOptions) => request<T>('DELETE', path, options),
  upload: <T>(path: string, form: FormData, options?: RequestOptions) => request<T>('POST', path, { ...options, form }),
  putUpload: <T>(path: string, form: FormData, options?: RequestOptions) => request<T>('PUT', path, { ...options, form }),
}
