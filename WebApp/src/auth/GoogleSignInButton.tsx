import { useEffect, useRef, useState } from 'react'
import { useI18n } from '../i18n/I18nProvider'
import { GOOGLE_WEB_CLIENT_ID } from '../lib/config'

type GoogleCredentialResponse = { credential?: string }

type GoogleAccounts = {
  id: {
    initialize: (config: {
      client_id: string
      callback: (response: GoogleCredentialResponse) => void
      ux_mode?: 'popup' | 'redirect'
      auto_select?: boolean
      cancel_on_tap_outside?: boolean
    }) => void
    renderButton: (parent: HTMLElement, options: Record<string, unknown>) => void
    disableAutoSelect: () => void
  }
}

declare global {
  interface Window {
    google?: { accounts: GoogleAccounts }
  }
}

const SCRIPT_SRC = 'https://accounts.google.com/gsi/client'
let scriptPromise: Promise<void> | null = null

function loadGoogleScript(): Promise<void> {
  if (window.google?.accounts) return Promise.resolve()
  scriptPromise ??= new Promise<void>((resolve, reject) => {
    const script = document.createElement('script')
    script.src = SCRIPT_SRC
    script.async = true
    script.defer = true
    script.onload = () => resolve()
    script.onerror = () => {
      scriptPromise = null
      reject(new Error('Failed to load Google Sign-In'))
    }
    document.head.appendChild(script)
  })
  return scriptPromise
}

export function emailFromGoogleCredential(credential: string): string {
  try {
    const payload = credential.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')
    const padded = payload + '='.repeat((4 - (payload.length % 4)) % 4)
    const json = JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(padded), (c) => c.charCodeAt(0))))
    return typeof json.email === 'string' ? json.email : ''
  } catch {
    return ''
  }
}

/** Official Google button (GIS). Emits the ID token the backend already validates. */
export function GoogleSignInButton({ onCredential, disabled }: { onCredential: (idToken: string) => void; disabled?: boolean }) {
  const { lang } = useI18n()
  const containerRef = useRef<HTMLDivElement>(null)
  const callbackRef = useRef(onCredential)
  const [failed, setFailed] = useState(false)

  useEffect(() => {
    callbackRef.current = onCredential
  }, [onCredential])

  useEffect(() => {
    let cancelled = false
    loadGoogleScript()
      .then(() => {
        const container = containerRef.current
        if (cancelled || !container || !window.google) return
        window.google.accounts.id.initialize({
          client_id: GOOGLE_WEB_CLIENT_ID,
          ux_mode: 'popup',
          auto_select: false,
          cancel_on_tap_outside: true,
          callback: (response) => {
            if (response.credential) callbackRef.current(response.credential)
          },
        })
        container.innerHTML = ''
        window.google.accounts.id.renderButton(container, {
          type: 'standard',
          theme: 'outline',
          size: 'large',
          text: 'signin_with',
          shape: 'rectangular',
          logo_alignment: 'center',
          locale: lang,
          width: Math.min(400, Math.max(220, container.clientWidth)),
        })
      })
      .catch(() => !cancelled && setFailed(true))
    return () => {
      cancelled = true
    }
  }, [lang])

  if (failed) return null

  return (
    <div className={`flex min-h-[44px] justify-center ${disabled ? 'pointer-events-none opacity-60' : ''}`}>
      <div ref={containerRef} className="flex w-full justify-center" />
    </div>
  )
}
