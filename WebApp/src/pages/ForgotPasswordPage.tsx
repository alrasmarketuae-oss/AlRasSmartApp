import { useState, type FormEvent } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { forgotPasswordRequest } from '../auth/authApi'
import { AccentIndicator, AuthField, AuthLayout, AuthTopBar, FieldLabel, GlassCard, GradientButton, LoadingOverlay } from '../auth/components'
import { useI18n } from '../i18n/I18nProvider'
import { usePageTitle } from '../lib/usePageTitle'
import { useToast } from '../ui/Toast'

const EMAIL_RE = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/

export default function ForgotPasswordPage() {
  const { t } = useI18n()
  usePageTitle(t('forgotPasswordTitle'))
  const navigate = useNavigate()
  const toast = useToast()
  const [params] = useSearchParams()
  const [email, setEmail] = useState(params.get('email') ?? '')
  const [error, setError] = useState<string>()
  const [loading, setLoading] = useState(false)

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    const trimmed = email.trim()
    const problem = !trimmed ? t('thisFieldIsRequired') : EMAIL_RE.test(trimmed) ? undefined : t('invalidEmail')
    setError(problem)
    if (problem) return
    setLoading(true)
    try {
      const message = await forgotPasswordRequest(trimmed)
      toast.success(message || t('codeSent'))
      navigate(`/reset-password?email=${encodeURIComponent(trimmed)}`)
    } catch (err) {
      toast.error((err as Error).message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <AuthLayout>
      <AuthTopBar backFallback="/login" />
      <div className="flex flex-1 flex-col justify-center py-6">
        <div className="mb-5 text-center">
          <h1 className="text-2xl font-bold text-auth-title">{t('forgotPasswordTitle')}</h1>
          <p className="mt-1.5 text-sm text-auth-body">{t('forgotPasswordSubtitle')}</p>
          <div className="mt-3">
            <AccentIndicator />
          </div>
        </div>
        <GlassCard>
          <form onSubmit={submit} noValidate className="space-y-4">
            <div>
              <FieldLabel htmlFor="fp-email">{t('email')}</FieldLabel>
              <AuthField
                id="fp-email"
                icon="mail"
                type="email"
                inputMode="email"
                autoComplete="email"
                placeholder={t('enterYourEmail')}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                error={error}
              />
            </div>
            <GradientButton disabled={loading}>{t('sendCode')}</GradientButton>
          </form>
        </GlassCard>
        <Link to="/login" className="mt-5 text-center text-sm font-bold text-brand-dark hover:underline">
          {t('backToLogin')}
        </Link>
      </div>
      {loading && <LoadingOverlay />}
    </AuthLayout>
  )
}
