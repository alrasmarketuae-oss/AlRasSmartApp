import { apiUrl } from '../config/api.js'
import { getPaymentAuthToken } from '../lib/authStorage'

export interface CheckoutStatusResponse {
  status: string
  orderGroupId?: string | null
  orderStatusId?: number | null
}

export async function fetchCheckoutStatus(
  sessionId: string,
): Promise<CheckoutStatusResponse> {
  const token = getPaymentAuthToken()
  const url = apiUrl(
    `/api/payments/CheckoutStatus?sessionId=${encodeURIComponent(sessionId)}`,
  )

  let response: Response
  try {
    response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    })
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error)
    throw new Error(`تعذر الاتصال بالسيرفر: ${detail}`)
  }

  const data: unknown = await response.json().catch(() => ({}))

  if (!response.ok) {
    const error = data as { message?: string }
    throw new Error(
      error.message ?? `حدث خطأ في الطلب (${response.status}).`,
    )
  }

  return data as CheckoutStatusResponse
}
