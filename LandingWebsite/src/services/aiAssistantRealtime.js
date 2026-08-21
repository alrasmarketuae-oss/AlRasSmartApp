import { askAlRasAgent } from './aiAssistantApi'

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

/**
 * Live Ask AI: REST answer + typewriter stream (reliable on the public website).
 */
export function createAskAiSession() {
  let closed = false
  let abort = null

  return {
    async ask({ message, handlers }) {
      if (closed) return

      abort?.abort()
      abort = new AbortController()
      const { signal } = abort

      handlers.onThinking?.(true)
      try {
        const result = await askAlRasAgent({ message, language: 'auto', signal })
        if (closed || signal.aborted) return

        const answer = String(result?.answer || result?.Answer || '').trim()
        if (!answer) {
          throw new Error('Empty answer')
        }

        const offerSupportCallback = Boolean(
          result?.offerSupportCallback ?? result?.OfferSupportCallback,
        )

        handlers.onThinking?.(false)
        handlers.onResponseStarted?.()

        const chars = Array.from(answer)
        for (let i = 0; i < chars.length; i += 4) {
          if (closed || signal.aborted) return
          handlers.onDelta?.(chars.slice(i, i + 4).join(''))
          await sleep(8)
        }

        if (closed || signal.aborted) return
        handlers.onCompleted?.(answer, { offerSupportCallback, raw: result })
      } catch (err) {
        if (closed || signal.aborted || err?.name === 'AbortError') return
        handlers.onThinking?.(false)
        handlers.onError?.(err?.message || 'AI Assistant is unavailable right now.')
      }
    },

    async close() {
      closed = true
      abort?.abort()
      abort = null
    },
  }
}
