import { useEffect, useRef, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { fetchCheckoutStatus } from '../api/payments'
import PreferencesControls from '../components/layout/PreferencesControls'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { getPaymentAuthToken, saveCustomerAuthToken } from '../lib/authStorage'

type PageState =
  | 'loading'
  | 'pending'
  | 'processing'
  | 'completed'
  | 'returnToApp'
  | 'error'

const MAX_POLLS = 30
const POLL_INTERVAL_MS = 2000

function mapApiStatus(status: string): PageState {
  switch (status) {
    case 'pending':
      return 'pending'
    case 'processing':
      return 'processing'
    case 'completed':
      return 'completed'
    case 'not_found':
    case 'invalid':
      return 'error'
    default:
      return 'pending'
  }
}

export default function PaymentSuccessPage() {
  const { t } = useAppPreferences()
  const [searchParams] = useSearchParams()
    const sessionId = searchParams.get('session_id')?.trim() ?? ''
    const tokenFromUrl = searchParams.get('token')?.trim() ?? ''
    const [pageState, setPageState] = useState<PageState>('loading')
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const pollCountRef = useRef(0)
  const stoppedRef = useRef(false)

  const statusCopy: Record<
    PageState,
    { title: string; detail?: string }
  > = {
    loading: { title: t('payment.loading') },
    pending: {
      title: t('payment.pending'),
      detail: t('payment.pendingDetail'),
    },
    processing: {
      title: t('payment.processing'),
      detail: t('payment.processingDetail'),
    },
    completed: {
      title: t('payment.completed'),
      detail: t('payment.completedDetail'),
    },
    returnToApp: {
      title: t('payment.returnToApp'),
      detail: t('payment.returnToAppDetail'),
    },
    error: {
      title: t('payment.error'),
      detail: t('payment.errorDetail'),
    },
  }

  useEffect(() => {
    stoppedRef.current = false
    pollCountRef.current = 0

    if (!sessionId) {
      setPageState('error')
      setErrorMessage(t('payment.noSession'))
      return
    }

    if (tokenFromUrl) {
      saveCustomerAuthToken(tokenFromUrl)
    }

    // Stripe redirects have no app/dashboard JWT. Do not show a red failure page —
    // payment completion is confirmed by webhook + the mobile app poll.
    if (!getPaymentAuthToken()) {
      setPageState('returnToApp')
      setErrorMessage(null)
      return
    }

    let timeoutId: ReturnType<typeof setTimeout> | undefined

    async function poll() {
      if (stoppedRef.current) return

      pollCountRef.current += 1

      try {
        const result = await fetchCheckoutStatus(sessionId)
        const mapped = mapApiStatus(result.status)

        if (mapped === 'error' || mapped === 'completed') {
          stoppedRef.current = true
          setPageState(mapped)
          return
        }

        setPageState(mapped)

        if (pollCountRef.current >= MAX_POLLS) {
          stoppedRef.current = true
          setPageState('error')
          setErrorMessage(t('payment.timeout'))
          return
        }

        timeoutId = setTimeout(poll, POLL_INTERVAL_MS)
      } catch (err) {
        stoppedRef.current = true
        setPageState('error')
        setErrorMessage(
          err instanceof Error ? err.message : t('login.unexpectedError'),
        )
      }
    }

    void poll()

    return () => {
      stoppedRef.current = true
      if (timeoutId) clearTimeout(timeoutId)
    }
  }, [sessionId, tokenFromUrl, t])

  const copy = statusCopy[pageState]
  const isPolling =
    pageState === 'loading' || pageState === 'pending' || pageState === 'processing'

  return (
    <div className="admin-page-bg flex min-h-svh flex-col items-center justify-center px-4 py-10">
      <div className="absolute end-4 top-4">
        <PreferencesControls compact />
      </div>

      <div className="mb-8 flex w-full max-w-md flex-col items-center text-center">
        <img
          src="/ProjectImages/SouqLogo.png"
          alt={t('payment.appName')}
          className="mb-5 h-24 w-24 object-contain"
        />
        <h1 className="admin-text text-2xl font-bold tracking-tight">
          {t('payment.appName')}
        </h1>
        <p className="admin-text-muted mt-2 text-sm">{t('payment.confirmTitle')}</p>
      </div>

      <div className="admin-card w-full max-w-md rounded-3xl p-8 text-center shadow-lg shadow-slate-200/80 dark:shadow-none">
        {isPolling ? (
          <div
            className="mx-auto mb-6 h-12 w-12 animate-spin rounded-full border-4 border-slate-200 border-t-blue-600"
            role="status"
            aria-label={t('loading')}
          />
        ) : pageState === 'completed' || pageState === 'returnToApp' ? (
          <div
            className="mx-auto mb-6 flex h-12 w-12 items-center justify-center rounded-full bg-green-100 text-green-600"
            aria-hidden
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              className="h-7 w-7"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M5 13l4 4L19 7"
              />
            </svg>
          </div>
        ) : (
          <div
            className="mx-auto mb-6 flex h-12 w-12 items-center justify-center rounded-full bg-red-100 text-red-600"
            aria-hidden
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              className="h-7 w-7"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </div>
        )}

        <h2 className="admin-text text-xl font-bold">{copy.title}</h2>

        {copy.detail ? (
          <p className="admin-text-muted mt-4 text-sm">{copy.detail}</p>
        ) : null}

        {errorMessage ? (
          <p
            role="alert"
            className="admin-alert-error mt-4 px-3 py-2"
          >
            {errorMessage}
          </p>
        ) : null}
      </div>
    </div>
  )
}
