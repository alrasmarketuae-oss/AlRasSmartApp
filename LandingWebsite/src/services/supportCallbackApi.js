import { API_BASE_URL } from '../data/config'

/** Public support callback — AllowAnonymous (same as mobile AI form). */
export async function createSupportCallback({
  fullName,
  phone,
  email,
  question,
  language = 'auto',
  source = 'landing_ask_ai',
}) {
  const res = await fetch(`${API_BASE_URL}/support-callbacks`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({
      fullName: String(fullName ?? '').trim(),
      phone: String(phone ?? '').trim(),
      email: String(email ?? '').trim(),
      question: String(question ?? '').trim() || undefined,
      language,
      source,
    }),
  })

  if (!res.ok) {
    let detail = `HTTP ${res.status}`
    try {
      const err = await res.json()
      if (err?.message) detail = err.message
    } catch {
      /* ignore */
    }
    throw new Error(detail)
  }

  return res.json()
}
