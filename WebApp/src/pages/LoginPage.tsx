import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { loginRequest } from '../auth/authApi'
import {
  AccentIndicator,
  AuthField,
  AuthLayout,
  AuthTopBar,
  FieldLabel,
  GlassCard,
  GradientButton,
  LoadingOverlay,
  OrDivider,
  PasswordToggle,
} from '../auth/components'
import { emailFromGoogleCredential, GoogleSignInButton } from '../auth/GoogleSignInButton'
import { useLoginFlow } from '../auth/useLoginFlow'
import { useI18n } from '../i18n/I18nProvider'
import { usePageTitle } from '../lib/usePageTitle'

export default function LoginPage() {
  const { t, lang } = useI18n()
  usePageTitle(t('login'))
  const { onSuccess, onError } = useLoginFlow()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({})
  const [loading, setLoading] = useState(false)

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    const next = {
      email: email.trim() ? undefined : t('thisFieldIsRequired'),
      password: password.trim() ? undefined : t('thisFieldIsRequired'),
    }
    setErrors(next)
    if (next.email || next.password) return
    setLoading(true)
    try {
      const response = await loginRequest({ email: email.trim(), password: password.trim(), provider: 'local', preferredLanguage: lang })
      await onSuccess(response, email.trim(), 'local')
    } catch (error) {
      onError((error as Error).message, email.trim())
    } finally {
      setLoading(false)
    }
  }

  const loginWithGoogle = async (idToken: string) => {
    const googleEmail = emailFromGoogleCredential(idToken)
    setLoading(true)
    try {
      const response = await loginRequest({ email: googleEmail, password: '', provider: 'google', token: idToken, preferredLanguage: lang })
      await onSuccess(response, googleEmail, 'google')
    } catch (error) {
      onError((error as Error).message, googleEmail)
    } finally {
      setLoading(false)
    }
  }

  return (
    <AuthLayout>
      <AuthTopBar backFallback="/welcome" />
      <div className="flex flex-1 flex-col justify-center py-6">
        <div className="mb-5 text-center">
          <h1 className="text-2xl font-bold text-auth-title">{t('welcomeBack')}</h1>
          <p className="mt-1.5 text-sm text-auth-body">{t('signInToContinue')}</p>
          <div className="mt-3">
            <AccentIndicator />
          </div>
        </div>
        <GlassCard>
          <form onSubmit={submit} noValidate className="space-y-3.5">
            <div>
              <FieldLabel htmlFor="login-email">{t('email')}</FieldLabel>
              <AuthField
                id="login-email"
                icon="mail"
                type="email"
                autoComplete="email"
                inputMode="email"
                placeholder={t('enterYourEmail')}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                error={errors.email}
              />
            </div>
            <div>
              <FieldLabel htmlFor="login-password">{t('password')}</FieldLabel>
              <AuthField
                id="login-password"
                icon="lock"
                type={showPassword ? 'text' : 'password'}
                autoComplete="current-password"
                placeholder={t('enterYourPassword')}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                error={errors.password}
                trailing={<PasswordToggle visible={showPassword} onToggle={() => setShowPassword((v) => !v)} />}
              />
            </div>
            <div className="flex justify-end">
              <Link to="/forgot-password" className="text-[13px] font-semibold text-brand-light hover:underline">
                {t('forgotPassword')}
              </Link>
            </div>
            <GradientButton disabled={loading}>{t('login')}</GradientButton>
            <OrDivider label={t('or')} />
            <GoogleSignInButton onCredential={loginWithGoogle} disabled={loading} />
          </form>
        </GlassCard>
      </div>
      <p className="pb-2 text-center text-sm text-auth-body">
        {t('dontHaveAnAccount')}{' '}
        <Link to="/register" className="font-bold text-brand-dark hover:underline">
          {t('createAccount')}
        </Link>
      </p>
      {loading && <LoadingOverlay />}
    </AuthLayout>
  )
}
