import { lazy, Suspense, useEffect, useRef, useState, type FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import type { RegisterAddress } from '../auth/authApi'
import { AuthLayout, AuthTopBar, CountryCodeSelect, FieldError, IconField, PasswordField, PrimaryButton } from '../auth/components'
import { registrationDraft } from '../auth/registrationDraft'
import { useI18n } from '../i18n/I18nProvider'
import { PRIVACY_URL } from '../lib/config'
import { usePageTitle } from '../lib/usePageTitle'
import { Icon } from '../ui/Icon'
import { useToast } from '../ui/Toast'

const AddressPickerModal = lazy(() => import('../auth/AddressPickerModal'))

const EMAIL_RE = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/

function isValidWebsite(value: string) {
  const trimmed = value.trim()
  if (!trimmed || trimmed === 'https://' || trimmed === 'http://') return true
  try {
    const url = new URL(/^https?:\/\//.test(trimmed) ? trimmed : `https://${trimmed}`)
    return !!url.hostname && url.hostname.includes('.')
  } catch {
    return false
  }
}

type Errors = Partial<Record<'companyName' | 'ownerName' | 'address' | 'phone' | 'email' | 'password' | 'website', string>>

function ProfilePhotoPicker({ file, onChange }: { file: File | null; onChange: (file: File | null) => void }) {
  const { t } = useI18n()
  const inputRef = useRef<HTMLInputElement>(null)
  const [preview, setPreview] = useState<string | null>(null)

  useEffect(() => {
    if (!file) {
      setPreview(null)
      return
    }
    const url = URL.createObjectURL(file)
    setPreview(url)
    return () => URL.revokeObjectURL(url)
  }, [file])

  return (
    <div className="flex items-center gap-3">
      <button
        type="button"
        onClick={() => inputRef.current?.click()}
        className="relative grid size-[84px] place-items-center overflow-hidden rounded-full border-2 border-dashed border-brand/40 bg-white text-brand shadow-[0_3px_10px_rgba(0,0,0,0.05)]"
        aria-label={t('profilePhoto')}
      >
        {preview ? <img src={preview} alt="" className="size-full object-cover" /> : <Icon name="camera" size={28} />}
        <span className="absolute bottom-1 end-1 grid size-6 place-items-center rounded-full bg-brand text-white ring-2 ring-white">
          <Icon name={preview ? 'check' : 'upload'} size={13} strokeWidth={2.4} />
        </span>
      </button>
      <div>
        <p className="text-[13px] font-semibold text-auth-label">
          {t('profilePhoto')}
          <span className="text-auth-hint">{t('optional')}</span>
        </p>
        {file && (
          <button type="button" onClick={() => inputRef.current?.click()} className="text-xs font-semibold text-brand hover:underline">
            {t('change')}
          </button>
        )}
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => {
          const picked = e.target.files?.[0]
          if (picked) onChange(picked)
          e.target.value = ''
        }}
      />
    </div>
  )
}

export default function RegisterPage() {
  const { t, isAr } = useI18n()
  usePageTitle(t('createAccount'))
  const navigate = useNavigate()
  const toast = useToast()
  const existing = registrationDraft.get()

  const [companyName, setCompanyName] = useState(existing?.companyName ?? '')
  const [ownerName, setOwnerName] = useState(existing?.fullName ?? '')
  const [licenseNumber, setLicenseNumber] = useState(existing?.licenseNumber ?? '')
  const [taxNumber, setTaxNumber] = useState(existing?.taxNumber ?? '')
  const [website, setWebsite] = useState(existing?.website ?? '')
  const [phoneCode, setPhoneCode] = useState('+971')
  const [phone, setPhone] = useState('')
  const [landCode, setLandCode] = useState('+971')
  const [landline, setLandline] = useState('')
  const [email, setEmail] = useState(existing?.email ?? '')
  const [password, setPassword] = useState('')
  const [accepted, setAccepted] = useState(false)
  const [profileLogo, setProfileLogo] = useState<File | null>(existing?.profileLogo ?? null)
  const [address, setAddress] = useState<RegisterAddress | null>(existing?.address ?? null)
  const [addressSummary, setAddressSummary] = useState(existing?.addressSummary ?? '')
  const [pickerOpen, setPickerOpen] = useState(false)
  const [errors, setErrors] = useState<Errors>({})
  const [submitted, setSubmitted] = useState(false)

  const submit = (event: FormEvent) => {
    event.preventDefault()
    setSubmitted(true)
    if (!accepted) {
      toast.error(t('mustAcceptTerms'))
      return
    }
    const required = t('thisFieldIsRequired')
    const next: Errors = {
      companyName: companyName.trim() ? undefined : required,
      ownerName: ownerName.trim() ? undefined : required,
      address: address ? undefined : t('locationRequired'),
      phone: phone.trim() ? undefined : required,
      email: !email.trim() ? required : EMAIL_RE.test(email.trim()) ? undefined : t('invalidEmail'),
      password: !password.trim() ? required : password.trim().length < 6 ? t('passwordMin6') : undefined,
      website: isValidWebsite(website) ? undefined : t('invalidWebsite'),
    }
    setErrors(next)
    if (Object.values(next).some(Boolean)) {
      if (!address && Object.entries(next).filter(([, v]) => v).length === 1) toast.error(t('setAddressFirst'))
      return
    }

    registrationDraft.set({
      fullName: ownerName.trim(),
      companyName: companyName.trim(),
      email: email.trim(),
      password: password.trim(),
      phoneNumber: `${phoneCode} ${phone.trim()}`,
      landNumber: landline.trim() ? `${landCode} ${landline.trim()}` : '',
      licenseNumber: licenseNumber.trim(),
      taxNumber: taxNumber.trim(),
      website: website.trim(),
      address: { ...address!, contactPerson: ownerName.trim() },
      addressSummary,
      profileLogo,
    })
    navigate('/register/documents')
  }

  const locationPicker = (
    <div>
      <span className="mb-2 block text-[13px] font-semibold text-auth-label">{t('locationAddress')}</span>
      <button
        type="button"
        onClick={() => setPickerOpen(true)}
        className={`flex w-full items-center gap-3 rounded-[14px] border bg-white px-3.5 py-3.5 text-start shadow-[0_3px_10px_rgba(0,0,0,0.04)] hover:border-brand ${errors.address ? 'border-[#d92d20]' : 'border-auth-border'}`}
      >
        <span className="grid size-10 shrink-0 place-items-center rounded-full bg-brand/12 text-brand">
          <Icon name="addLocation" size={22} />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block text-sm font-bold text-brand">{t('setLocation')}</span>
          <span className="mt-1 line-clamp-2 block text-xs leading-snug text-auth-body">{addressSummary || t('locationHint')}</span>
        </span>
        <Icon name={isAr ? 'chevronLeft' : 'chevronRight'} size={22} className="text-[#98A2B3]" />
      </button>
      {!address && submitted && <FieldError message={t('locationRequired')} />}
    </div>
  )

  const licenseField = (
    <IconField label={t('tradeLicenseNumber')} icon="badge" placeholder={t('enterTradeLicenseNumber')} value={licenseNumber} onChange={(e) => setLicenseNumber(e.target.value)} />
  )

  return (
    <AuthLayout wide>
      <AuthTopBar backFallback="/welcome" />
      <form onSubmit={submit} noValidate className="mx-auto w-full max-w-xl pb-4 pt-5">
        <h1 className="text-[26px] font-extrabold leading-tight text-auth-title">{t('createAccount')}</h1>
        <p className="mt-1.5 text-[13px] font-medium text-auth-body">{t('joinUs')}</p>

        <div className="mt-5">
          <ProfilePhotoPicker file={profileLogo} onChange={setProfileLogo} />
        </div>

        <div className="mt-5 grid gap-3.5 sm:grid-cols-2 sm:gap-x-4">
          <IconField
            label={t('companyName')}
            icon="building"
            placeholder={t('enterCompanyName')}
            autoComplete="organization"
            value={companyName}
            onChange={(e) => setCompanyName(e.target.value)}
            error={errors.companyName}
          />
          <IconField
            label={t('ownerName')}
            icon="person"
            placeholder={t('enterOwnerName')}
            autoComplete="name"
            value={ownerName}
            onChange={(e) => setOwnerName(e.target.value)}
            error={errors.ownerName}
          />
          <div className="sm:col-span-2">{locationPicker}</div>
          {licenseField}
          <IconField label={t('taxNumber')} icon="receipt" placeholder={t('taxNumber')} value={taxNumber} onChange={(e) => setTaxNumber(e.target.value)} />
          <div className="sm:col-span-2">
            <IconField
              label={t('website')}
              icon="globe"
              type="url"
              dir="ltr"
              placeholder={t('websiteHint')}
              value={website}
              onChange={(e) => setWebsite(e.target.value)}
              error={errors.website}
            />
          </div>

          <div className="grid grid-cols-5 gap-3">
            <div className="col-span-2">
              <CountryCodeSelect label={t('countryCode')} value={phoneCode} onChange={setPhoneCode} />
            </div>
            <div className="col-span-3">
              <IconField
                label={t('phoneNumber')}
                icon="phone"
                type="tel"
                dir="ltr"
                inputMode="tel"
                autoComplete="tel-national"
                placeholder="XX XXX XXXX"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                error={errors.phone}
              />
            </div>
          </div>
          <div className="grid grid-cols-5 gap-3">
            <div className="col-span-2">
              <CountryCodeSelect label={t('countryCode')} value={landCode} onChange={setLandCode} />
            </div>
            <div className="col-span-3">
              <IconField
                label={t('landlinePhone')}
                icon="phone"
                type="tel"
                dir="ltr"
                inputMode="tel"
                placeholder="XX XXX XXXX"
                value={landline}
                onChange={(e) => setLandline(e.target.value)}
              />
            </div>
          </div>

          <IconField
            label={t('email')}
            icon="mail"
            type="email"
            inputMode="email"
            autoComplete="email"
            placeholder={t('enterYourEmail')}
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            error={errors.email}
          />
          <PasswordField
            label={t('password')}
            placeholder={t('enterYourPassword')}
            autoComplete="new-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            error={errors.password}
          />
        </div>

        <label className="mt-4 flex cursor-pointer items-center gap-2 text-[13px] font-medium text-auth-label">
          <input type="checkbox" checked={accepted} onChange={(e) => setAccepted(e.target.checked)} className="size-[18px] rounded accent-brand" />
          <span>
            {t('agreeToTermsPrefix')}
            <a href={PRIVACY_URL} target="_blank" rel="noopener noreferrer" className="font-bold text-brand underline">
              {t('policyAndPrivacy')}
            </a>
          </span>
        </label>

        <div className="mt-5">
          <PrimaryButton type="submit">
            {t('next')}
            <Icon name={isAr ? 'arrowBack' : 'arrowForward'} size={20} />
          </PrimaryButton>
        </div>

        <p className="mt-4 text-center text-sm font-medium text-auth-body">
          {t('alreadyHaveAccount')}{' '}
          <Link to="/login" className="text-[15px] font-extrabold text-brand hover:underline">
            {t('login')}
          </Link>
        </p>
      </form>

      {pickerOpen && (
        <Suspense fallback={null}>
          <AddressPickerModal
            open={pickerOpen}
            onClose={() => setPickerOpen(false)}
            contactPerson={ownerName.trim()}
            onSaved={(picked, summary) => {
              setAddress(picked)
              setAddressSummary(summary)
              setErrors((current) => ({ ...current, address: undefined }))
            }}
          />
        </Suspense>
      )}
    </AuthLayout>
  )
}
