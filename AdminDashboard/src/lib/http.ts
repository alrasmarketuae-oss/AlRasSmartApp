import { apiUrl, getApiOriginLabel } from '../config/api.js'
import { clearAuthSession, getAuthToken } from './authStorage'

const AUTH_REDIRECT_MESSAGE_KEY = 'rasalsouq_admin_auth_message'

export function setAuthRedirectMessage(message: string): void {
  sessionStorage.setItem(AUTH_REDIRECT_MESSAGE_KEY, message)
}

export function consumeAuthRedirectMessage(): string | null {
  const message = sessionStorage.getItem(AUTH_REDIRECT_MESSAGE_KEY)
  if (message) {
    sessionStorage.removeItem(AUTH_REDIRECT_MESSAGE_KEY)
  }
  return message
}

function mapNetworkError(error: unknown): Error {
  const base = getApiOriginLabel()
  const detail = error instanceof Error ? error.message : String(error)
  const isReset =
    detail.includes('Failed to fetch') ||
    detail.includes('NetworkError') ||
    detail.includes('ERR_CONNECTION_RESET') ||
    detail.includes('connection was closed') ||
    detail.includes('Load failed')

  if (isReset) {
    return new Error(
      `تعذر الاتصال بـ ${base}. تحقق أن الـ API شغال على SmarterASP.`,
    )
  }

  return new Error(`تعذر الاتصال بالسيرفر: ${detail}`)
}

async function readResponseBody(response: Response): Promise<unknown> {
  const contentType = response.headers.get('content-type') ?? ''
  const raw = await response.text()

  if (!raw.trim()) {
    return {}
  }

  if (
    contentType.includes('application/json') ||
    raw.trimStart().startsWith('{') ||
    raw.trimStart().startsWith('[')
  ) {
    try {
      return JSON.parse(raw) as unknown
    } catch {
      throw new Error('استجابة غير صالحة من السيرفر (JSON تالف).')
    }
  }

  if (raw.includes('<html') || raw.includes('<!DOCTYPE')) {
    throw new Error(
      `السيرفر أرجع صفحة HTML بدل JSON (${response.status}). تحقق أن الـ API .NET يعمل وليس ملفات الفرونت فقط.`,
    )
  }

  throw new Error(`استجابة غير متوقعة من السيرفر (${response.status}).`)
}

type RequestOptions = Omit<RequestInit, 'body'> & {
  body?: unknown
  auth?: boolean
}

/**
 * طلب HTTP موحّد يستخدم رابط الـ API من src/config/api.js
 */
export async function apiRequest<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { body, headers, auth = false, ...rest } = options
  const token = getAuthToken()

  let response: Response
  try {
    response = await fetch(apiUrl(path), {
      ...rest,
      headers: {
        'Content-Type': 'application/json',
        ...(auth && token ? { Authorization: `Bearer ${token}` } : {}),
        ...headers,
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    })
  } catch (error) {
    throw mapNetworkError(error)
  }

  let data: unknown
  try {
    data = await readResponseBody(response)
  } catch (error) {
    if (!response.ok) {
      throw error instanceof Error
        ? error
        : new Error(`حدث خطأ في الطلب (${response.status}).`)
    }
    throw error
  }

  if (!response.ok) {
    if (response.status === 401 && auth) {
      clearAuthSession()
      setAuthRedirectMessage('انتهت الجلسة. سجّل الدخول مرة أخرى.')
      const loginPath = '/login'
      if (window.location.pathname !== loginPath) {
        window.location.replace(loginPath)
      }
    }

    const error = data as {
      message?: string
      detail?: string
      title?: string
    }
    const message =
      error.message ??
      error.detail ??
      error.title ??
      (response.status === 403
        ? 'غير مصرح بهذا الإجراء.'
        : response.status === 401
          ? 'بيانات الدخول غير صحيحة أو غير مصرح لهذا الحساب.'
          : `حدث خطأ في الطلب (${response.status}).`)
    throw new Error(message)
  }

  return data as T
}
