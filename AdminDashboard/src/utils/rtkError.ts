import type { FetchBaseQueryError } from '@reduxjs/toolkit/query'
import type { SerializedError } from '@reduxjs/toolkit'

export function getRtkErrorMessage(
  error: FetchBaseQueryError | SerializedError | undefined,
  fallback: string,
): string {
  if (!error) return fallback

  if ('data' in error && error.data) {
    if (typeof error.data === 'string') return error.data
    if (typeof error.data === 'object' && error.data !== null && 'message' in error.data) {
      return String((error.data as { message: string }).message)
    }
  }

  if ('message' in error && error.message) {
    return error.message
  }

  return fallback
}
