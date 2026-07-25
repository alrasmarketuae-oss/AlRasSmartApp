import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { login } from '../api/auth'
import TurnstileWidget from '../components/auth/TurnstileWidget'
import PreferencesControls from '../components/layout/PreferencesControls'
import { TURNSTILE_SITE_KEY } from '../config/api'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { saveAuthSession, saveChatWrapSecret } from '../lib/authStorage'
import { deriveChatKeyWrapSecret } from '../lib/chatE2e'
import { unlockAlertSound } from '../lib/alertSound'
import { consumeAuthRedirectMessage } from '../lib/http'
import { canAccessDashboard, getDefaultRoute } from '../lib/permissions'

function EyeIcon({ open }: { open: boolean }) {
  if (open) {
    return (
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.5"
        className="h-5 w-5"
        aria-hidden
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M2.036 12.322a1 1 0 0 1 0-.644C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z"
        />
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z"
        />
      </svg>
    )
  }

  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.5"
      className="h-5 w-5"
      aria-hidden
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M3.98 8.223A10.477 10.477 0 0 0 1.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.451 10.451 0 0 1 12 4.5c4.756 0 8.773 3.162 10.065 7.498a10.522 10.522 0 0 1-4.293 5.774M6.228 6.228 3 3m3.228 3.228 3.65 3.65m7.894 7.894L21 21m-3.228-3.228-3.65-3.65m0 0a3 3 0 1 0-4.243-4.243m4.242 4.242L9.88 9.88"
      />
    </svg>
  )
}

export default function LoginPage() {
  const navigate = useNavigate()
  const { t, dir, theme, locale } = useAppPreferences()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [turnstileToken, setTurnstileToken] = useState<string | null>(null)
  const [turnstileReset, setTurnstileReset] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  useEffect(() => {
    const redirectMessage = consumeAuthRedirectMessage()
    if (redirectMessage) {
      setError(redirectMessage)
    }
  }, [])

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError(null)

    if (!TURNSTILE_SITE_KEY) {
      setError(t('login.turnstileMissingKey'))
      return
    }

    if (!turnstileToken) {
      setError(t('login.turnstileRequired'))
      return
    }

    setIsSubmitting(true)

    // تفعيل الصوت فوراً ضمن نفس نقرة المستخدم (قبل أي await)
    void unlockAlertSound()

    try {
      const result = await login({
        loginProviderName: 'Local',
        email: email.trim(),
        password,
        turnstileToken,
        clientApp: 'AdminDashboard',
      })

      if (!canAccessDashboard(result.roleName, result.permissions ?? [])) {
        throw new Error(t('login.unauthorized'))
      }

      saveAuthSession(result)
      const wrapSecret = await deriveChatKeyWrapSecret({
        password,
        email: result.email,
        userId: result.id,
      })
      if (wrapSecret) saveChatWrapSecret(wrapSecret)
      navigate(getDefaultRoute(), { replace: true })
    } catch (err) {
      const message =
        err instanceof Error ? err.message : t('login.unexpectedError')
      console.error('[login]', err)
      setError(message)
      setTurnstileToken(null)
      setTurnstileReset((n) => n + 1)
    } finally {
      setIsSubmitting(false)
    }
  }

  const turnstileTheme =
    theme === 'dark' ? 'dark' : theme === 'light' ? 'light' : 'auto'

  return (
    <div
      dir={dir}
      className="admin-page-bg relative flex min-h-svh flex-col items-center justify-center px-4 py-10"
    >
      <div className="absolute top-4 end-4">
        <PreferencesControls />
      </div>

      <div className="mb-8 flex w-full max-w-md flex-col items-center text-center">
        <img
          src="/ProjectImages/SouqLogo.png"
          alt={t('appName')}
          className="mb-5 h-24 w-24 object-contain"
        />
        <h1 className="admin-text text-2xl font-bold tracking-tight">
          {t('login.title')}
        </h1>
        <p className="admin-text-muted mt-2 text-sm">{t('login.subtitle')}</p>
      </div>

      <div className="admin-card w-full max-w-md p-8 shadow-lg shadow-slate-200/80 dark:shadow-none">
        <form className="space-y-5" onSubmit={handleSubmit} noValidate>
          <div>
            <label
              htmlFor="email"
              className="admin-text mb-2 block text-sm font-medium"
            >
              {t('login.email')}
            </label>
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder={t('login.emailPlaceholder')}
              className="admin-input w-full px-4 py-3"
            />
          </div>

          <div>
            <label
              htmlFor="password"
              className="admin-text mb-2 block text-sm font-medium"
            >
              {t('login.password')}
            </label>
            <div className="relative" dir="ltr">
              <input
                id="password"
                name="password"
                type={showPassword ? 'text' : 'password'}
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder={t('login.passwordPlaceholder')}
                dir={dir}
                className="admin-input w-full py-3 pr-4 pl-12"
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                className="admin-text-subtle transition hover:text-slate-600 dark:hover:text-slate-300"
                aria-label={
                  showPassword ? t('login.hidePassword') : t('login.showPassword')
                }
              >
                <EyeIcon open={showPassword} />
              </button>
            </div>
          </div>

          <div className="space-y-2">
            <p className="admin-text-muted text-center text-xs">
              {t('login.turnstileHint')}
            </p>
            <TurnstileWidget
              siteKey={TURNSTILE_SITE_KEY}
              theme={turnstileTheme}
              language={locale === 'ar' ? 'ar' : 'en'}
              resetSignal={turnstileReset}
              onToken={setTurnstileToken}
            />
          </div>

          {error ? (
            <p
              role="alert"
              className="admin-alert-error px-3 py-2 text-center"
            >
              {error}
            </p>
          ) : null}

          <button
            type="submit"
            disabled={isSubmitting || !turnstileToken}
            className="keep-white w-full rounded-xl bg-blue-600 py-3 text-base font-semibold text-white transition hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-70"
          >
            {isSubmitting ? t('login.submitting') : t('login.submit')}
          </button>
        </form>
      </div>
    </div>
  )
}
