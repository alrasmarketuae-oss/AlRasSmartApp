import { useEffect, useRef } from 'react'

declare global {
  interface Window {
    turnstile?: {
      render: (
        element: HTMLElement,
        options: {
          sitekey: string
          callback?: (token: string) => void
          'error-callback'?: () => void
          'expired-callback'?: () => void
          theme?: 'light' | 'dark' | 'auto'
          language?: string
        },
      ) => string
      reset: (widgetId?: string) => void
      remove: (widgetId?: string) => void
    }
    onTurnstileApiLoad?: () => void
  }
}

const SCRIPT_ID = 'cf-turnstile-script'
const SCRIPT_SRC =
  'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit&onload=onTurnstileApiLoad'

type TurnstileWidgetProps = {
  siteKey: string
  onToken: (token: string | null) => void
  theme?: 'light' | 'dark' | 'auto'
  language?: string
  resetSignal?: number
}

function loadTurnstileScript(): Promise<void> {
  if (window.turnstile) return Promise.resolve()

  return new Promise((resolve, reject) => {
    const existing = document.getElementById(SCRIPT_ID) as HTMLScriptElement | null
    if (existing) {
      window.onTurnstileApiLoad = () => resolve()
      if (window.turnstile) resolve()
      return
    }

    window.onTurnstileApiLoad = () => resolve()
    const script = document.createElement('script')
    script.id = SCRIPT_ID
    script.src = SCRIPT_SRC
    script.async = true
    script.defer = true
    script.onerror = () => reject(new Error('Failed to load Turnstile'))
    document.head.appendChild(script)
  })
}

export default function TurnstileWidget({
  siteKey,
  onToken,
  theme = 'auto',
  language,
  resetSignal = 0,
}: TurnstileWidgetProps) {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const widgetIdRef = useRef<string | null>(null)
  const onTokenRef = useRef(onToken)
  onTokenRef.current = onToken

  useEffect(() => {
    let cancelled = false

    async function mount() {
      if (!siteKey.trim() || !containerRef.current) return

      try {
        await loadTurnstileScript()
        if (cancelled || !containerRef.current || !window.turnstile) return

        if (widgetIdRef.current) {
          try {
            window.turnstile.remove(widgetIdRef.current)
          } catch {
            /* ignore */
          }
          widgetIdRef.current = null
        }

        containerRef.current.innerHTML = ''
        widgetIdRef.current = window.turnstile.render(containerRef.current, {
          sitekey: siteKey,
          theme,
          language,
          callback: (token) => onTokenRef.current(token),
          'error-callback': () => onTokenRef.current(null),
          'expired-callback': () => onTokenRef.current(null),
        })
      } catch {
        onTokenRef.current(null)
      }
    }

    void mount()

    return () => {
      cancelled = true
      if (widgetIdRef.current && window.turnstile) {
        try {
          window.turnstile.remove(widgetIdRef.current)
        } catch {
          /* ignore */
        }
        widgetIdRef.current = null
      }
    }
  }, [siteKey, theme, language])

  useEffect(() => {
    if (!resetSignal || !widgetIdRef.current || !window.turnstile) return
    onTokenRef.current(null)
    try {
      window.turnstile.reset(widgetIdRef.current)
    } catch {
      /* ignore */
    }
  }, [resetSignal])

  return <div ref={containerRef} className="flex justify-center" />
}
