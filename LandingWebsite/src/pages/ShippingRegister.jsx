import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import SeoHelmet from '../components/SeoHelmet'
import CountryDialCodeSelect from '../components/CountryDialCodeSelect'
import { STORE_LINKS } from '../data/config'
import { content } from '../data/content'
import {
  registerShippingCompany,
  sendEmailOtp,
  verifyEmailOtp,
} from '../services/shippingAuthApi'

const EMAIL_RE = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/
const RESEND_SECONDS = 80

function Field({ label, children, optional }) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-semibold text-slate-700">
        {label}
        {optional ? (
          <span className="ms-1 text-xs font-medium text-slate-400">(optional)</span>
        ) : null}
      </label>
      {children}
    </div>
  )
}

const inputClass =
  'w-full rounded-xl border border-slate-300 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none transition focus:border-brand-blue focus:ring-2 focus:ring-brand-blue/20'

export default function ShippingRegister({ lang }) {
  const t = content[lang].shippingRegisterPage
  const isAr = lang === 'ar'

  const [step, setStep] = useState('form') // form | otp | done
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [info, setInfo] = useState('')

  const [companyName, setCompanyName] = useState('')
  const [ownerName, setOwnerName] = useState('')
  const [commercialRegister, setCommercialRegister] = useState('')
  const [taxNumber, setTaxNumber] = useState('')
  const [website, setWebsite] = useState('')
  const [phoneCode, setPhoneCode] = useState('+971')
  const [phone, setPhone] = useState('')
  const [landlineCode, setLandlineCode] = useState('+971')
  const [landline, setLandline] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [acceptedTerms, setAcceptedTerms] = useState(false)
  const [otp, setOtp] = useState('')
  const [resendLeft, setResendLeft] = useState(0)

  useEffect(() => {
    if (resendLeft <= 0) return undefined
    const id = window.setInterval(() => {
      setResendLeft((s) => (s <= 1 ? 0 : s - 1))
    }, 1000)
    return () => window.clearInterval(id)
  }, [resendLeft])

  const websiteError = useMemo(() => {
    const trimmed = website.trim()
    if (!trimmed || trimmed === 'https://' || trimmed === 'http://') return ''
    const candidate =
      trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : `https://${trimmed}`
    try {
      const uri = new URL(candidate)
      if (!uri.hostname) return t.invalidWebsite
      return ''
    } catch {
      return t.invalidWebsite
    }
  }, [website, t.invalidWebsite])

  async function handleRegister(e) {
    e.preventDefault()
    setError('')
    setInfo('')

    if (!acceptedTerms) {
      setError(t.mustAcceptTerms)
      return
    }
    if (!companyName.trim() || !ownerName.trim() || !commercialRegister.trim() || !taxNumber.trim()) {
      setError(t.requiredFields)
      return
    }
    if (!phone.trim()) {
      setError(t.requiredFields)
      return
    }
    if (!EMAIL_RE.test(email.trim())) {
      setError(t.invalidEmail)
      return
    }
    if (password.trim().length < 6) {
      setError(t.passwordMin)
      return
    }
    if (websiteError) {
      setError(websiteError)
      return
    }

    setLoading(true)
    try {
      await registerShippingCompany({
        companyName,
        fullName: ownerName,
        email,
        password,
        phoneNumber: `${phoneCode} ${phone.trim()}`,
        landNumber: landline.trim() ? `${landlineCode} ${landline.trim()}` : '',
        commercialRegister,
        taxNumber,
        website: website.trim(),
        preferredLanguage: lang === 'ar' ? 'ar' : 'en',
      })
      setStep('otp')
      setResendLeft(RESEND_SECONDS)
      setInfo(t.otpSent)
      setOtp('')
    } catch (err) {
      setError(err?.message || t.registerFailed)
    } finally {
      setLoading(false)
    }
  }

  async function handleVerifyOtp(e) {
    e.preventDefault()
    setError('')
    setInfo('')
    if (!/^\d{6}$/.test(otp.trim())) {
      setError(t.otpInvalid)
      return
    }
    setLoading(true)
    try {
      await verifyEmailOtp({ email: email.trim(), otp: otp.trim() })
      setStep('done')
      setInfo(t.verified)
    } catch (err) {
      setError(err?.message || t.otpFailed)
    } finally {
      setLoading(false)
    }
  }

  async function handleResend() {
    if (resendLeft > 0 || loading) return
    setError('')
    setInfo('')
    setLoading(true)
    try {
      await sendEmailOtp(email.trim())
      setResendLeft(RESEND_SECONDS)
      setInfo(t.otpResent)
    } catch (err) {
      setError(err?.message || t.otpFailed)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="py-10 sm:py-12">
      <SeoHelmet pageKey="shippingRegister" lang={lang} />
      <div className="mx-auto max-w-2xl px-4 sm:px-6">
        <div className="mb-8 overflow-hidden rounded-3xl bg-gradient-to-br from-orange-500 to-amber-500 p-8 text-center text-white shadow-xl sm:p-10">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-white/20 text-3xl">
            🚢
          </div>
          <h1 className="text-2xl font-extrabold sm:text-3xl">{t.heading}</h1>
          <p className="mx-auto mt-3 max-w-xl text-sm text-white/90 sm:text-base">{t.intro}</p>
        </div>

        <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm sm:p-8">
          {error ? (
            <div className="mb-4 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {error}
            </div>
          ) : null}
          {info ? (
            <div className="mb-4 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
              {info}
            </div>
          ) : null}

          {step === 'form' ? (
            <form onSubmit={handleRegister} className="space-y-4">
              <Field label={t.companyName}>
                <input
                  className={inputClass}
                  value={companyName}
                  onChange={(e) => setCompanyName(e.target.value)}
                  placeholder={t.companyNameHint}
                  required
                />
              </Field>
              <Field label={t.ownerName}>
                <input
                  className={inputClass}
                  value={ownerName}
                  onChange={(e) => setOwnerName(e.target.value)}
                  placeholder={t.ownerNameHint}
                  required
                />
              </Field>
              <Field label={t.commercialRegister}>
                <input
                  className={inputClass}
                  value={commercialRegister}
                  onChange={(e) => setCommercialRegister(e.target.value)}
                  required
                />
              </Field>
              <Field label={t.taxNumber}>
                <input
                  className={inputClass}
                  value={taxNumber}
                  onChange={(e) => setTaxNumber(e.target.value)}
                  required
                />
              </Field>
              <Field label={t.website} optional>
                <input
                  className={inputClass}
                  value={website}
                  onChange={(e) => setWebsite(e.target.value)}
                  placeholder="https://"
                  dir="ltr"
                />
              </Field>

              <div className="grid gap-3 sm:grid-cols-5">
                <div className="sm:col-span-2">
                  <CountryDialCodeSelect
                    label={t.countryCode}
                    value={phoneCode}
                    onChange={setPhoneCode}
                    disabled={loading}
                  />
                </div>
                <div className="sm:col-span-3">
                  <Field label={t.phone}>
                    <input
                      className={inputClass}
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="XX XXX XXXX"
                      inputMode="tel"
                      dir="ltr"
                      required
                    />
                  </Field>
                </div>
              </div>

              <div className="grid gap-3 sm:grid-cols-5">
                <div className="sm:col-span-2">
                  <CountryDialCodeSelect
                    label={t.countryCode}
                    value={landlineCode}
                    onChange={setLandlineCode}
                    disabled={loading}
                  />
                </div>
                <div className="sm:col-span-3">
                  <Field label={t.landline} optional>
                    <input
                      className={inputClass}
                      value={landline}
                      onChange={(e) => setLandline(e.target.value)}
                      placeholder="XX XXX XXXX"
                      inputMode="tel"
                      dir="ltr"
                    />
                  </Field>
                </div>
              </div>

              <Field label={t.email}>
                <input
                  className={inputClass}
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder={t.emailHint}
                  dir="ltr"
                  required
                />
              </Field>
              <Field label={t.password}>
                <input
                  className={inputClass}
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder={t.passwordHint}
                  dir="ltr"
                  required
                  minLength={6}
                />
              </Field>

              <label className="flex cursor-pointer items-start gap-2 text-sm text-slate-600">
                <input
                  type="checkbox"
                  className="mt-1"
                  checked={acceptedTerms}
                  onChange={(e) => setAcceptedTerms(e.target.checked)}
                />
                <span>
                  {t.acceptTermsPrefix}{' '}
                  <Link to="/terms" className="font-semibold text-brand-blue underline">
                    {t.termsLink}
                  </Link>{' '}
                  {t.and}{' '}
                  <Link to="/privacy" className="font-semibold text-brand-blue underline">
                    {t.privacyLink}
                  </Link>
                </span>
              </label>

              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-xl bg-brand-blue px-4 py-3 text-sm font-bold text-white transition hover:opacity-95 disabled:opacity-60"
              >
                {loading ? t.submitting : t.signUp}
              </button>
            </form>
          ) : null}

          {step === 'otp' ? (
            <form onSubmit={handleVerifyOtp} className="space-y-4">
              <p className={`text-sm text-slate-600 ${isAr ? 'text-right' : 'text-left'}`}>
                {t.otpIntro} <strong dir="ltr">{email.trim()}</strong>
              </p>
              <Field label={t.otpLabel}>
                <input
                  className={`${inputClass} text-center tracking-[0.35em]`}
                  value={otp}
                  onChange={(e) =>
                    setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))
                  }
                  inputMode="numeric"
                  maxLength={6}
                  placeholder="••••••"
                  dir="ltr"
                  required
                />
              </Field>
              <p className="text-xs text-slate-500">{t.otpHint}</p>
              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-xl bg-brand-blue px-4 py-3 text-sm font-bold text-white disabled:opacity-60"
              >
                {loading ? t.submitting : t.verifyOtp}
              </button>
              <button
                type="button"
                disabled={loading || resendLeft > 0}
                onClick={handleResend}
                className="w-full rounded-xl border border-slate-300 px-4 py-2.5 text-sm font-semibold text-slate-700 disabled:opacity-50"
              >
                {resendLeft > 0 ? t.resendIn.replace('{s}', String(resendLeft)) : t.resendOtp}
              </button>
              <button
                type="button"
                className="w-full text-sm font-semibold text-brand-blue"
                onClick={() => {
                  setStep('form')
                  setError('')
                  setInfo('')
                }}
              >
                {t.backToForm}
              </button>
            </form>
          ) : null}

          {step === 'done' ? (
            <div className={`space-y-4 ${isAr ? 'text-right' : 'text-left'}`}>
              <p className="text-lg font-bold text-emerald-700">{t.successTitle}</p>
              <p className="text-sm text-slate-600">{t.successBody}</p>
              <div className="flex flex-col gap-2 sm:flex-row">
                <a
                  href={STORE_LINKS.android}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex flex-1 items-center justify-center rounded-xl bg-brand-blue px-4 py-3 text-sm font-bold text-white"
                >
                  {t.downloadAndroid}
                </a>
                <a
                  href={STORE_LINKS.ios}
                  target="_blank"
                  rel="noreferrer"
                  className="inline-flex flex-1 items-center justify-center rounded-xl border border-slate-300 px-4 py-3 text-sm font-bold text-slate-800"
                >
                  {t.downloadIos}
                </a>
              </div>
            </div>
          ) : null}
        </div>
      </div>
    </div>
  )
}
