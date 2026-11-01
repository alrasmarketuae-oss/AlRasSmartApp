import { useCallback, useEffect, useRef, useState, type ClipboardEvent, type KeyboardEvent } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { destinationFor, useAuth } from '../auth/AuthProvider'
import { sendEmailOtp, verifyEmailOtp } from '../auth/authApi'
import { AuthLayout, AuthTopBar, LoadingOverlay, PrimaryButton } from '../auth/components'
import { isPendingAdminApproval, isPendingApprovalMessage } from '../auth/loginResponse'
import { useI18n } from '../i18n/I18nProvider'
import { usePageTitle } from '../lib/usePageTitle'
import { Icon } from '../ui/Icon'
import { useToast } from '../ui/Toast'

const RESEND_SECONDS = 80
const LENGTH = 6

const formatTime = (seconds: number) => `${String(Math.floor(seconds / 60)).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`

function webmailFor(email: string) {
  const domain = email.split('@')[1]?.toLowerCase() ?? ''
  if (domain.includes('gmail')) return 'https://mail.google.com/mail/u/0/#inbox'
  if (/(outlook|hotmail|live|msn)\./.test(domain)) return 'https://outlook.live.com/mail/0/inbox'
  if (domain.includes('yahoo')) return 'https://mail.yahoo.com'
  if (domain.includes('icloud') || domain.includes('me.com')) return 'https://www.icloud.com/mail'
  return `mailto:${email}`
}

export default function OtpPage() {
  const { t } = useI18n()
  usePageTitle(t('otpCode'))
  const [params] = useSearchParams()
  const navigate = useNavigate()
  const toast = useToast()
  const { session, savePending, logout } = useAuth()
  const email = (params.get('email') || session?.email || '').trim()

  const [digits, setDigits] = useState<string[]>(Array(LENGTH).fill(''))
  const [secondsLeft, setSecondsLeft] = useState(RESEND_SECONDS)
  const [loading, setLoading] = useState(false)
  const inputs = useRef<(HTMLInputElement | null)[]>([])

  useEffect(() => {
    if (secondsLeft <= 0) return
    const id = window.setTimeout(() => setSecondsLeft((s) => s - 1), 1000)
    return () => window.clearTimeout(id)
  }, [secondsLeft])

  useEffect(() => {
    inputs.current[0]?.focus()
  }, [])

  const setAt = (index: number, value: string) => {
    const clean = value.replace(/\D/g, '')
    if (clean.length > 1) {
      fill(clean, index)
      return
    }
    setDigits((current) => current.map((d, i) => (i === index ? clean : d)))
    if (clean && index < LENGTH - 1) inputs.current[index + 1]?.focus()
  }

  const fill = (text: string, from = 0) => {
    const chars = text.replace(/\D/g, '').slice(0, LENGTH - from).split('')
    setDigits((current) => current.map((d, i) => (i >= from && i - from < chars.length ? chars[i - from] : d)))
    inputs.current[Math.min(from + chars.length, LENGTH - 1)]?.focus()
  }

  const onKeyDown = (index: number, event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Backspace' && !digits[index] && index > 0) inputs.current[index - 1]?.focus()
  }

  const onPaste = (event: ClipboardEvent<HTMLInputElement>) => {
    event.preventDefault()
    fill(event.clipboardData.getData('text'))
  }

  const verify = useCallback(async () => {
    const code = digits.join('')
    if (code.length !== LENGTH) {
      toast.error(t('enterCodeSentToEmail'))
      return
    }
    setLoading(true)
    try {
      const response = await verifyEmailOtp(email, code)
      const next = savePending({
        token: response.token ?? '',
        id: response.id ?? session?.id ?? '',
        email: response.email ?? email,
        name: response.name ?? session?.name ?? '',
        companyName: response.companyName ?? session?.companyName ?? '',
        roleName: response.roleName ?? session?.roleName ?? '',
        roleId: response.roleId ?? '',
        phone: response.phone ?? session?.phone ?? '',
        imgPath: response.imgPath ?? '',
        isCompanyAccount: response.isCompanyAccount ?? session?.isCompanyAccount ?? false,
        isShippingCompanyAccount: response.isShippingCompanyAccount ?? session?.isShippingCompanyAccount ?? false,
        isCustomer: response.isCustomer ?? session?.isCustomer ?? null,
        isApproved: isPendingAdminApproval(response) ? false : response.isApproved,
        isVerified: response.isVerified ?? true,
      })
      toast.success(t('verifiedSuccessfully'))
      navigate(destinationFor(next), { replace: true })
    } catch (error) {
      const message = (error as Error).message
      if (isPendingApprovalMessage(message)) {
        savePending({ token: '', email, isCompanyAccount: true, isApproved: false, isVerified: true })
        navigate('/under-review', { replace: true })
        return
      }
      toast.error(message)
    } finally {
      setLoading(false)
    }
  }, [digits, email, navigate, savePending, session, t, toast])

  const resend = async () => {
    if (secondsLeft > 0) return
    try {
      await sendEmailOtp(email)
      toast.success(t('codeSent'))
      setSecondsLeft(RESEND_SECONDS)
    } catch (error) {
      toast.error((error as Error).message)
    }
  }

  return (
    <AuthLayout>
      <AuthTopBar showBack={false} />
      <div className="mt-2 flex justify-start">
        <button
          type="button"
          onClick={() => {
            logout()
            navigate('/login', { replace: true })
          }}
          className="flex items-center gap-1.5 rounded-lg px-2 py-1.5 text-sm font-semibold text-[#d92d20] hover:bg-red-50"
        >
          <Icon name="logout" size={20} />
          {t('logout')}
        </button>
      </div>

      <div className="flex flex-1 flex-col items-center justify-center py-6 text-center">
        <span className="grid size-20 place-items-center rounded-full bg-brand/10 text-brand">
          <Icon name="mail" size={38} />
        </span>
        <h1 className="mt-5 text-2xl font-bold text-auth-title">{t('otpCode')}</h1>
        <p className="mt-2 text-sm text-auth-body">{t('enterCodeSentToEmail')}</p>
        {email && (
          <p dir="ltr" className="mt-1 text-sm font-bold text-auth-title">
            {email}
          </p>
        )}

        <div dir="ltr" className="mt-7 flex w-full max-w-sm justify-center gap-2 sm:gap-3">
          {digits.map((digit, index) => (
            <input
              key={index}
              ref={(el) => {
                inputs.current[index] = el
              }}
              value={digit}
              inputMode="numeric"
              autoComplete={index === 0 ? 'one-time-code' : 'off'}
              maxLength={LENGTH}
              onChange={(e) => setAt(index, e.target.value)}
              onKeyDown={(e) => onKeyDown(index, e)}
              onPaste={onPaste}
              aria-label={`Digit ${index + 1}`}
              className={`aspect-square w-full max-w-[54px] rounded-xl border-2 bg-white text-center text-xl font-bold text-auth-title outline-none transition focus:border-brand ${digit ? 'border-brand/60' : 'border-auth-border'}`}
            />
          ))}
        </div>

        <p className="mt-3 text-xs text-auth-hint">{t('codeValidFor10Minutes')}</p>

        <div className="mt-5 flex items-center gap-2 text-sm">
          <Icon name="timer" size={18} className="text-brand" />
          <span className="font-semibold text-auth-label">{t('countdown')}:</span>
          <span dir="ltr" className="font-bold tabular-nums text-brand">
            {formatTime(secondsLeft)}
          </span>
        </div>
        <button
          type="button"
          onClick={() => void resend()}
          disabled={secondsLeft > 0}
          className="mt-2 text-sm font-bold text-brand underline disabled:text-auth-hint disabled:no-underline"
        >
          {t('resendCode')}
        </button>

        {email && (
          <a href={webmailFor(email)} target="_blank" rel="noopener noreferrer" className="mt-4 inline-flex items-center gap-2 rounded-xl border border-brand/30 px-4 py-2.5 text-sm font-semibold text-brand hover:bg-brand/5">
            <Icon name="mail" size={18} />
            {t('openEmailForCode')}
          </a>
        )}

        <div className="mt-8 w-full">
          <PrimaryButton onClick={() => void verify()} loading={loading}>
            {t('confirm')}
          </PrimaryButton>
        </div>
      </div>
      {loading && <LoadingOverlay />}
    </AuthLayout>
  )
}
