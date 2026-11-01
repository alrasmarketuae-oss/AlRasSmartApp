import { useState, type FormEvent } from 'react'
import { Navigate, useNavigate, useSearchParams } from 'react-router-dom'
import { forgotPasswordReset } from '../auth/authApi'
import { AccentIndicator, AuthField, AuthLayout, AuthTopBar, FieldLabel, GlassCard, GradientButton, LoadingOverlay, PasswordToggle } from '../auth/components'
import { useI18n } from '../i18n/I18nProvider'
import { usePageTitle } from '../lib/usePageTitle'
import { useToast } from '../ui/Toast'

type Errors = Partial<Record<'code' | 'password' | 'confirm', string>>

export default function ResetPasswordPage() {
  const { t } = useI18n()
  usePageTitle(t('resetPassword'))
  const [params] = useSearchParams()
  const email = params.get('email') ?? ''
  const navigate = useNavigate()
  const toast = useToast()
  const [code, setCode] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [visible, setVisible] = useState(false)
  const [errors, setErrors] = useState<Errors>({})
  const [loading, setLoading] = useState(false)

  if (!email) return <Navigate to="/forgot-password" replace />

  const submit = async (event: FormEvent) => {
    event.preventDefault()
    const required = t('thisFieldIsRequired')
    const next: Errors = {
      code: code.trim() ? undefined : required,
      password: !password ? required : password.length < 6 ? t('passwordMin6') : undefined,
      confirm: !confirm ? required : confirm !== password ? t('passwordsDoNotMatch') : undefined,
    }
    setErrors(next)
    if (Object.values(next).some(Boolean)) return
    setLoading(true)
    try {
      const message = await forgotPasswordReset(email, code, password)
      toast.success(message || t('passwordResetDone'))
      navigate('/login', { replace: true })
    } catch (err) {
      toast.error((err as Error).message)
    } finally {
      setLoading(false)
    }
  }

  const toggle = <PasswordToggle visible={visible} onToggle={() => setVisible((v) => !v)} />

  return (
    <AuthLayout>
      <AuthTopBar backFallback="/forgot-password" />
      <div className="flex flex-1 flex-col justify-center py-6">
        <div className="mb-5 text-center">
          <h1 className="text-2xl font-bold text-auth-title">{t('resetPassword')}</h1>
          <p className="mt-1.5 text-sm text-auth-body">{t('resetPasswordSubtitle')}</p>
          <p dir="ltr" className="mt-1 text-sm font-semibold text-auth-title">
            {email}
          </p>
          <div className="mt-3">
            <AccentIndicator />
          </div>
        </div>
        <GlassCard>
          <form onSubmit={submit} noValidate className="space-y-3.5">
            <div>
              <FieldLabel htmlFor="rp-code">{t('verificationCode')}</FieldLabel>
              <AuthField
                id="rp-code"
                icon="badge"
                inputMode="numeric"
                autoComplete="one-time-code"
                placeholder="••••••"
                value={code}
                onChange={(e) => setCode(e.target.value)}
                error={errors.code}
              />
            </div>
            <div>
              <FieldLabel htmlFor="rp-password">{t('newPassword')}</FieldLabel>
              <AuthField
                id="rp-password"
                icon="lock"
                type={visible ? 'text' : 'password'}
                autoComplete="new-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                error={errors.password}
                trailing={toggle}
              />
            </div>
            <div>
              <FieldLabel htmlFor="rp-confirm">{t('confirmPassword')}</FieldLabel>
              <AuthField
                id="rp-confirm"
                icon="lock"
                type={visible ? 'text' : 'password'}
                autoComplete="new-password"
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                error={errors.confirm}
              />
            </div>
            <GradientButton disabled={loading}>{t('resetPassword')}</GradientButton>
          </form>
        </GlassCard>
      </div>
      {loading && <LoadingOverlay />}
    </AuthLayout>
  )
}
