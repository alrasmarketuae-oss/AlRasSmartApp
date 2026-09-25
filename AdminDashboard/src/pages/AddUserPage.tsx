import { useMemo, useState } from 'react'
import type { FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAppPreferences } from '../context/AppPreferencesProvider'
import { hasPermission, PERMISSIONS } from '../lib/permissions'
import { useCreateAdminUserMutation } from '../store'
import type { CreateAdminUserPayload } from '../store/adminApi'
import { getRtkErrorMessage } from '../utils/rtkError'

type AccountKind = 'shipping' | 'supplier' | 'customer'
type CustomerKind = 'company' | 'person'

type FormState = {
  fullName: string
  companyName: string
  email: string
  password: string
  phoneNumber: string
  landNumber: string
  licenseNumber: string
  commercialRegister: string
  taxNumber: string
  website: string
  preferredLanguage: 'en' | 'ar'
  addressLine1: string
  cityName: string
  area: string
  street: string
  building: string
  postalCode: string
}

const emptyForm = (): FormState => ({
  fullName: '',
  companyName: '',
  email: '',
  password: '',
  phoneNumber: '',
  landNumber: '',
  licenseNumber: '',
  commercialRegister: '',
  taxNumber: '',
  website: '',
  preferredLanguage: 'en',
  addressLine1: '',
  cityName: '',
  area: '',
  street: '',
  building: '',
  postalCode: '',
})

function resolveAccountType(
  kind: AccountKind,
  customerKind: CustomerKind,
): CreateAdminUserPayload['accountType'] {
  if (kind === 'shipping') return 'shippingCompany'
  if (kind === 'supplier') return 'supplier'
  return customerKind === 'company' ? 'companyCustomer' : 'person'
}

export default function AddUserPage() {
  const { t, locale } = useAppPreferences()
  const navigate = useNavigate()
  const canManage = hasPermission(PERMISSIONS.usersManage)
  const [kind, setKind] = useState<AccountKind | null>(null)
  const [customerKind, setCustomerKind] = useState<CustomerKind | null>(null)
  const [form, setForm] = useState<FormState>(emptyForm)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [createUser, { isLoading }] = useCreateAdminUserMutation()

  const accountType = useMemo(() => {
    if (!kind) return null
    if (kind === 'customer' && !customerKind) return null
    return resolveAccountType(kind, customerKind ?? 'person')
  }, [kind, customerKind])

  const showCompanyFields =
    accountType === 'supplier' ||
    accountType === 'companyCustomer' ||
    accountType === 'shippingCompany'
  const showPersonName = accountType === 'person' || accountType === 'supplier' || accountType === 'companyCustomer'
  const showAddress = accountType === 'supplier' || accountType === 'companyCustomer'
  const phoneRequired = accountType === 'shippingCompany'

  function patchForm(patch: Partial<FormState>) {
    setForm((prev) => ({ ...prev, ...patch }))
  }

  function resetType() {
    setKind(null)
    setCustomerKind(null)
    setForm(emptyForm())
    setError(null)
    setSuccess(null)
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (!canManage || !accountType) return
    setError(null)
    setSuccess(null)

    const payload: CreateAdminUserPayload = {
      accountType,
      email: form.email.trim(),
      password: form.password,
      phoneNumber: form.phoneNumber.trim() || undefined,
      preferredLanguage: form.preferredLanguage,
      fullName: form.fullName.trim() || undefined,
      companyName: form.companyName.trim() || undefined,
      landNumber: form.landNumber.trim() || undefined,
      licenseNumber: form.licenseNumber.trim() || undefined,
      commercialRegister: form.commercialRegister.trim() || undefined,
      taxNumber: form.taxNumber.trim() || undefined,
      website: form.website.trim() || undefined,
    }

    if (showAddress && (form.addressLine1.trim() || form.cityName.trim())) {
      payload.address = {
        addressLine1: form.addressLine1.trim() || undefined,
        cityName: form.cityName.trim() || undefined,
        area: form.area.trim() || undefined,
        street: form.street.trim() || undefined,
        building: form.building.trim() || undefined,
        postalCode: form.postalCode.trim() || undefined,
      }
    }

    try {
      const result = await createUser(payload).unwrap()
      setSuccess(result.message || t('users.addUserSuccess'))
      window.setTimeout(() => {
        navigate(`/users/${result.userId}`)
      }, 700)
    } catch (err) {
      setError(getRtkErrorMessage(err, t('users.addUserError')))
    }
  }

  if (!canManage) {
    return (
      <div className="admin-card space-y-3 p-6">
        <p className="admin-text font-semibold">{t('users.addUserDenied')}</p>
        <Link to="/users" className="text-sm font-semibold text-[#3B7FC7] hover:underline">
          {t('users.backToList')}
        </Link>
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-3xl space-y-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="admin-text text-2xl font-bold">{t('users.addUserTitle')}</h1>
          <p className="admin-text-muted mt-2 text-sm leading-relaxed">
            {t('users.addUserDescription')}
          </p>
        </div>
        <Link
          to="/users"
          className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-800"
        >
          {t('users.backToList')}
        </Link>
      </div>

      <div className="admin-card space-y-5 p-5 sm:p-6">
        <div>
          <p className="admin-text mb-3 text-sm font-bold">{t('users.chooseAccountKind')}</p>
          <div className="grid gap-3 sm:grid-cols-3">
            {(
              [
                ['customer', t('users.kindCustomer')],
                ['supplier', t('users.kindSupplier')],
                ['shipping', t('users.kindShipping')],
              ] as const
            ).map(([value, label]) => (
              <button
                key={value}
                type="button"
                onClick={() => {
                  setKind(value)
                  setCustomerKind(null)
                  setError(null)
                  setSuccess(null)
                }}
                className={`rounded-xl border px-4 py-3 text-start text-sm font-semibold transition ${
                  kind === value
                    ? 'border-[#3B7FC7] bg-[#3B7FC7]/10 text-[#3B7FC7]'
                    : 'border-slate-200 text-slate-700 hover:border-slate-300 dark:border-slate-600 dark:text-slate-200'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {kind === 'customer' ? (
          <div>
            <p className="admin-text mb-3 text-sm font-bold">{t('users.chooseCustomerKind')}</p>
            <div className="grid gap-3 sm:grid-cols-2">
              {(
                [
                  ['person', t('users.client')],
                  ['company', t('users.companyCustomer')],
                ] as const
              ).map(([value, label]) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => {
                    setCustomerKind(value)
                    setError(null)
                    setSuccess(null)
                  }}
                  className={`rounded-xl border px-4 py-3 text-start text-sm font-semibold transition ${
                    customerKind === value
                      ? 'border-[#3B7FC7] bg-[#3B7FC7]/10 text-[#3B7FC7]'
                      : 'border-slate-200 text-slate-700 hover:border-slate-300 dark:border-slate-600 dark:text-slate-200'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        ) : null}

        {accountType ? (
          <form className="space-y-4" onSubmit={handleSubmit}>
            <p className="rounded-lg bg-emerald-50 px-3 py-2 text-xs font-medium text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-200">
              {t('users.addUserNoOtpNote')}
            </p>

            <div className="grid gap-3 sm:grid-cols-2">
              {showPersonName ? (
                <label className="block text-sm">
                  <span className="admin-text-muted mb-1 block font-semibold">
                    {accountType === 'person'
                      ? t('users.fullName')
                      : t('users.ownerName')}
                  </span>
                  <input
                    required={accountType === 'person'}
                    value={form.fullName}
                    onChange={(e) => patchForm({ fullName: e.target.value })}
                    className="admin-input w-full"
                  />
                </label>
              ) : null}

              {showCompanyFields ? (
                <label className="block text-sm">
                  <span className="admin-text-muted mb-1 block font-semibold">
                    {t('users.companyName')}
                  </span>
                  <input
                    required
                    value={form.companyName}
                    onChange={(e) => patchForm({ companyName: e.target.value })}
                    className="admin-input w-full"
                  />
                </label>
              ) : null}

              <label className="block text-sm">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {t('users.email')}
                </span>
                <input
                  required
                  type="email"
                  value={form.email}
                  onChange={(e) => patchForm({ email: e.target.value })}
                  className="admin-input w-full"
                  dir="ltr"
                />
              </label>

              <label className="block text-sm">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {t('users.password')}
                </span>
                <input
                  required
                  type="password"
                  minLength={6}
                  value={form.password}
                  onChange={(e) => patchForm({ password: e.target.value })}
                  className="admin-input w-full"
                  dir="ltr"
                />
              </label>

              <label className="block text-sm">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {t('users.phone')}
                  {phoneRequired ? ' *' : ''}
                </span>
                <input
                  required={phoneRequired}
                  value={form.phoneNumber}
                  onChange={(e) => patchForm({ phoneNumber: e.target.value })}
                  className="admin-input w-full"
                  dir="ltr"
                />
              </label>

              <label className="block text-sm">
                <span className="admin-text-muted mb-1 block font-semibold">
                  {t('users.preferredLanguage')}
                </span>
                <select
                  value={form.preferredLanguage}
                  onChange={(e) =>
                    patchForm({
                      preferredLanguage: e.target.value === 'ar' ? 'ar' : 'en',
                    })
                  }
                  className="admin-input w-full"
                >
                  <option value="en">{locale === 'ar' ? 'الإنجليزية' : 'English'}</option>
                  <option value="ar">{locale === 'ar' ? 'العربية' : 'Arabic'}</option>
                </select>
              </label>
            </div>

            {showCompanyFields ? (
              <div className="grid gap-3 sm:grid-cols-2">
                <label className="block text-sm">
                  <span className="admin-text-muted mb-1 block font-semibold">
                    {t('users.landLine')}
                  </span>
                  <input
                    value={form.landNumber}
                    onChange={(e) => patchForm({ landNumber: e.target.value })}
                    className="admin-input w-full"
                  />
                </label>
                {accountType !== 'shippingCompany' ? (
                  <label className="block text-sm">
                    <span className="admin-text-muted mb-1 block font-semibold">
                      {t('users.licenseNumber')}
                    </span>
                    <input
                      value={form.licenseNumber}
                      onChange={(e) => patchForm({ licenseNumber: e.target.value })}
                      className="admin-input w-full"
                    />
                  </label>
                ) : null}
                <label className="block text-sm">
                  <span className="admin-text-muted mb-1 block font-semibold">
                    {t('users.commercialRegister')}
                  </span>
                  <input
                    value={form.commercialRegister}
                    onChange={(e) => patchForm({ commercialRegister: e.target.value })}
                    className="admin-input w-full"
                  />
                </label>
                <label className="block text-sm">
                  <span className="admin-text-muted mb-1 block font-semibold">
                    {t('users.taxNumber')}
                  </span>
                  <input
                    value={form.taxNumber}
                    onChange={(e) => patchForm({ taxNumber: e.target.value })}
                    className="admin-input w-full"
                  />
                </label>
                <label className="block text-sm sm:col-span-2">
                  <span className="admin-text-muted mb-1 block font-semibold">
                    {t('users.website')}
                  </span>
                  <input
                    value={form.website}
                    onChange={(e) => patchForm({ website: e.target.value })}
                    className="admin-input w-full"
                    dir="ltr"
                    placeholder="https://"
                  />
                </label>
              </div>
            ) : null}

            {showAddress ? (
              <div className="space-y-3">
                <p className="admin-text text-sm font-bold">{t('users.primaryAddress')}</p>
                <div className="grid gap-3 sm:grid-cols-2">
                  <label className="block text-sm sm:col-span-2">
                    <span className="admin-text-muted mb-1 block font-semibold">
                      {t('users.addressText')}
                    </span>
                    <input
                      value={form.addressLine1}
                      onChange={(e) => patchForm({ addressLine1: e.target.value })}
                      className="admin-input w-full"
                    />
                  </label>
                  <label className="block text-sm">
                    <span className="admin-text-muted mb-1 block font-semibold">
                      {t('users.city')}
                    </span>
                    <input
                      value={form.cityName}
                      onChange={(e) => patchForm({ cityName: e.target.value })}
                      className="admin-input w-full"
                    />
                  </label>
                  <label className="block text-sm">
                    <span className="admin-text-muted mb-1 block font-semibold">
                      {t('users.area')}
                    </span>
                    <input
                      value={form.area}
                      onChange={(e) => patchForm({ area: e.target.value })}
                      className="admin-input w-full"
                    />
                  </label>
                  <label className="block text-sm">
                    <span className="admin-text-muted mb-1 block font-semibold">
                      {t('users.street')}
                    </span>
                    <input
                      value={form.street}
                      onChange={(e) => patchForm({ street: e.target.value })}
                      className="admin-input w-full"
                    />
                  </label>
                  <label className="block text-sm">
                    <span className="admin-text-muted mb-1 block font-semibold">
                      {t('users.building')}
                    </span>
                    <input
                      value={form.building}
                      onChange={(e) => patchForm({ building: e.target.value })}
                      className="admin-input w-full"
                    />
                  </label>
                  <label className="block text-sm">
                    <span className="admin-text-muted mb-1 block font-semibold">
                      {t('users.postalCode')}
                    </span>
                    <input
                      value={form.postalCode}
                      onChange={(e) => patchForm({ postalCode: e.target.value })}
                      className="admin-input w-full"
                    />
                  </label>
                </div>
              </div>
            ) : null}

            {error ? (
              <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/40 dark:text-red-200">
                {error}
              </p>
            ) : null}
            {success ? (
              <p className="rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-800 dark:bg-emerald-950/40 dark:text-emerald-200">
                {success}
              </p>
            ) : null}

            <div className="flex flex-wrap gap-3">
              <button
                type="submit"
                disabled={isLoading}
                className="rounded-lg bg-[#3B7FC7] px-4 py-2.5 text-sm font-semibold text-white hover:bg-[#326ea9] disabled:opacity-60"
              >
                {isLoading ? t('users.creatingUser') : t('users.createUser')}
              </button>
              <button
                type="button"
                onClick={resetType}
                className="rounded-lg border border-slate-200 px-4 py-2.5 text-sm font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-200"
              >
                {t('users.resetForm')}
              </button>
            </div>
          </form>
        ) : null}
      </div>
    </div>
  )
}
