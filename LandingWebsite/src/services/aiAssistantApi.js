import { API_BASE_URL } from '../data/config'

/**
 * Public Ask AI → backend Al-Ras Agent (AllowAnonymous).
 */
export async function askAlRasAgent({ message, language, signal }) {
  const res = await fetch(`${API_BASE_URL}/AiAssistant/ask`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    signal,
    body: JSON.stringify({
      message: String(message ?? '').trim(),
      // Let the backend match the user's message language (any language).
      language: 'auto',
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
