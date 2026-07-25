import {
  fetchBaseQuery,
  type BaseQueryFn,
  type FetchArgs,
  type FetchBaseQueryError,
} from '@reduxjs/toolkit/query'
import { API_BASE_URL } from '../config/api.js'
import { clearAuthSession, getAuthToken } from '../lib/authStorage'
import { setAuthRedirectMessage } from '../lib/http'

/** RTK Query → API مباشرة (بدون proxy) */
const rawBaseQuery = fetchBaseQuery({
  baseUrl: API_BASE_URL,
  prepareHeaders: (headers) => {
    const token = getAuthToken()
    if (token) {
      headers.set('Authorization', `Bearer ${token}`)
    }
    headers.set('Content-Type', 'application/json')
    return headers
  },
})

export const adminBaseQuery: BaseQueryFn<
  string | FetchArgs,
  unknown,
  FetchBaseQueryError
> = async (args, api, extraOptions) => {
  let result
  try {
    result = await rawBaseQuery(args, api, extraOptions)
  } catch (error) {
    const message =
      error instanceof Error && error.message.includes('fetch')
        ? 'تعذر الاتصال بالسيرفر — تحقق أن الـ API يعمل على الاستضافة.'
        : error instanceof Error
          ? error.message
          : 'تعذر الاتصال بالسيرفر.'
    return { error: { status: 'FETCH_ERROR', error: message } }
  }

  if (result.error?.status === 401) {
    clearAuthSession()
    setAuthRedirectMessage('انتهت الجلسة. سجّل الدخول مرة أخرى.')
    if (window.location.pathname !== '/login') {
      window.location.replace('/login')
    }
  }

  return result
}
